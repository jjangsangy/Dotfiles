-- intro-fingerprint.lua
--
-- Description:
--   A script to skip intro sequences in videos by fingerprinting audio and video.
--   It uses Gradient Hash (dHash) for video frames and Constellation Hashing for audio.
--   When you mark an intro in one episode, the script can search for that same intro
--   in other episodes (using either video or audio matching) and skip it.
--
-- Requirements:
--   - ffmpeg must be in your system PATH.
--   - LuaJIT is highly recommended. The script uses FFI C-arrays for audio processing
--     to avoid massive Garbage Collection overhead.
--   - 'bit' library is optional (standard in LuaJIT). Used for faster processing if available.
--
-- Key Bindings:
--   Ctrl+i        : Save Intro (Capture current timestamp as intro fingerprint).
--                   Saves both video frame and audio spectrogram data to temp file.
--   Ctrl+s        : Skip Intro (Video). Scans the video stream for the captured fingerprint.
--   Ctrl+Shift+s  : Skip Intro (Audio). Scans the audio stream for the captured fingerprint.
--
-- Usage:
--   1. Open a video that contains the intro you want to skip.
--   2. Seek to the very end of the intro.
--   3. Press 'Ctrl+i' to save the fingerprint.
--   4. Open another video (e.g., next episode).
--   5. Press 'Ctrl+s' (Video scan) or 'Ctrl+Shift+s' (Audio scan) to find and skip the intro.
--
-- Implementation Details & Algorithms:
--   1. Video Fingerprinting (Gradient Hash / dHash):
--      - Resizes frame to 9x8 grayscale.
--      - Compares adjacent pixels: if P(x+1) > P(x), bit is 1, else 0.
--      - Generates a 64-bit hash (8 bytes).
--      - Matching uses Hamming Distance (count of differing bits).
--      - Assumptions: Intro is visually similar (low Hamming distance).
--        Ignores color and small aspect ratio changes.
--      - Search Strategy & Trade-offs:
--        The search starts around the timestamp of the saved fingerprint and expands outward.
--        Reason: ffmpeg video decoding is the most expensive part of the pipeline.
--        Scanning the entire video file linearly would be prohibitively slow.
--        By assuming the intro is at a similar location (common in episodes), we avoid
--        the "penalty" of decoding the whole stream. The average case is vastly faster.
--
--   2. Audio Fingerprinting (Constellation Hashing):
--      - Extracts audio segment using ffmpeg (s16le, mono).
--      - Performs FFT to get spectrogram.
--      - Identifies peak frequencies in time-frequency bins.
--      - Pairs peaks to form hashes: [f1][f2][delta_time].
--      - Matching uses a histogram of time offsets. The offset with the most
--        matches implies the synchronization point.
--      - Assumptions: Audio is identical or very similar. Robust to noise to some degree.
--      - Search Strategy & Trade-offs:
--        Audio processing uses a linear scan or large windows.
--        Reason: Unlike video, ffmpeg audio extraction is a relatively cheap operation.
--        The performance bottleneck here is not decoding, but the histogram generation
--        and the size of the data structures (storing and matching millions of hashes).
--        Therefore, the strategy focuses on managing memory and hash lookup complexity
--        rather than minimizing ffmpeg runtime.
--
--   3. Performance & Optimization:
--      - Uses 'ffmpeg' to extract raw data streams to avoid Lua decoding overhead.
--      - Uses LuaJIT FFI for zero-allocation data processing (Critical for performance).
--      - Implements custom FFI C-structs for Hash generation and Spectrogram storage
--        to eliminate millions of Lua table allocations during scanning.
--      - Uses optimized in-place FFT algorithm on C-arrays.
--      - Uses a sliding window search strategy centered on the saved timestamp.
--      - Uses async subprocesses and coroutines to prevent blocking the player
--        during scanning and allows graceful cancellation.
--

local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

-- Attempt to load FFI (LuaJIT only) and Bit library
local ffi_status, ffi = pcall(require, "ffi")
local bit_status, bit = pcall(require, "bit")

-- Global scanning state to prevent race conditions
local scanning = false
local current_scan_token = nil

-- Constants for fallback bitwise operations
local MASK_9 = 512       -- 2^9
local MASK_14 = 16384    -- 2^14
local SHIFT_14 = 16384   -- 2^14
local SHIFT_23 = 8388608 -- 2^23

-- Configuration
local options = {
    -- Toggle console debug printing (Performance stats, scan info)
    debug = true,

    -- Video: Gradient Hash requires specific geometry: 9x8
    width = 9,
    height = 8,
    -- Video: Time interval to check in seconds (0.20 = 200ms)
    interval = 0.20,
    -- Video: Tolerance for Hamming Distance (0-64).
    threshold = 12,
    -- Video: Initial window: seconds before/after saved timestamp to search
    search_window = 10,
    -- Video: Maximum window: Stop expanding after this offset
    max_search_window = 300,
    -- Video: Step size
    window_step = 30,

    -- Audio: Configuration
    audio_sample_rate = 11025,
    audio_fft_size = 2048,
    audio_hop_size = 1024,
    audio_target_t_min = 10,  -- min delay in frames for pairs
    audio_target_t_max = 100, -- max delay in frames for pairs
    audio_threshold = 10,     -- minimum magnitude for peaks
    audio_scan_limit = 900,   -- max seconds to scan (15 mins)
    audio_scan_window = 180,  -- sliding window size (3 mins)

    -- Name of the temp files
    temp_filename_video = "mpv_intro_skipper.dat",
    temp_filename_audio = "mpv_intro_skipper_audio.dat",
}

-- Frame size in bytes (9 * 8 = 72 bytes)
local FRAME_SIZE = options.width * options.height

-- Helper for debug logging
local function log_info(str)
    if options.debug then
        msg.info(str)
    end
end

local function abort_scan()
    if current_scan_token then
        mp.abort_async_command(current_scan_token)
        current_scan_token = nil
    end
    scanning = false
    log_info("Scan aborted.")
end

mp.register_event("end-file", abort_scan)

local function run_async(func)
    local co = coroutine.create(func)
    local function resume(...)
        local status, res = coroutine.resume(co, ...)
        if not status then
            msg.error("Coroutine error: " .. tostring(res))
            scanning = false
        end
    end
    resume()
end

local function async_subprocess(t)
    local co = coroutine.running()
    if not co then return utils.subprocess(t) end

    local cmd = {
        name = "subprocess",
        args = t.args,
        capture_stdout = true,
        capture_stderr = true
    }

    current_scan_token = mp.command_native_async(cmd, function(success, result, err)
        coroutine.resume(co, success, result, err)
    end)

    local success, result, err = coroutine.yield()
    current_scan_token = nil

    if not success then
        return { status = -1, error = err }
    end
    return result
end

-- Pre-calculate bit population count lookup table (0-255)
local POPCOUNT_TABLE = {}
for i = 0, 255 do
    local c = 0
    local n = i
    while n > 0 do
        if n % 2 == 1 then c = c + 1 end
        n = math.floor(n / 2)
    end
    POPCOUNT_TABLE[i] = c
end

if ffi_status then
    ffi.cdef [[
        typedef unsigned char uint8_t;
        typedef struct { double r; double i; } complex_t;
        typedef int16_t int16;
        typedef struct { uint32_t h; uint32_t t; } hash_entry;
    ]]
end

local function get_temp_dir()
    return os.getenv("TEMP") or os.getenv("TMP") or os.getenv("TMPDIR") or "/tmp"
end

local function get_fingerprint_path_video()
    local temp_dir = get_temp_dir()
    return utils.join_path(temp_dir, options.temp_filename_video)
end

local function get_fingerprint_path_audio()
    local temp_dir = get_temp_dir()
    return utils.join_path(temp_dir, options.temp_filename_audio)
end

-- ==========================================
-- VIDEO ALGORITHM: GRADIENT HASH (dHash)
-- ==========================================

local function compute_hash_from_chunk(bytes, start_index, is_ffi)
    local hash = {}

    for y = 0, 7 do
        local row_byte = 0
        local row_offset = (y * 9)

        for x = 0, 7 do
            local idx = start_index + row_offset + x
            local p1, p2

            if is_ffi then
                p1 = bytes[idx]
                p2 = bytes[idx + 1]
            else
                p1 = string.byte(bytes, idx + 1)
                p2 = string.byte(bytes, idx + 2)
            end

            if p1 < p2 then
                if bit_status then
                    row_byte = bit.bor(row_byte, bit.lshift(1, x))
                else
                    row_byte = row_byte + (2 ^ x)
                end
            end
        end
        hash[y + 1] = row_byte
    end
    return hash
end

local function hamming_distance(hash1, hash2)
    local dist = 0
    for i = 1, 8 do
        local val1 = hash1[i]
        local val2 = hash2[i]
        local xor_val

        if bit_status then
            xor_val = bit.bxor(val1, val2)
        else
            local a, b = val1, val2
            local res = 0
            for bit_i = 0, 7 do
                local p = 2 ^ bit_i
                local a_bit = (a % (p * 2) >= p)
                local b_bit = (b % (p * 2) >= p)
                if a_bit ~= b_bit then res = res + p end
            end
            xor_val = res
        end

        dist = dist + POPCOUNT_TABLE[xor_val]
    end
    return dist
end

local function scan_segment_video(start_time, duration, video_path, target_raw_bytes, stats)
    if duration <= 0 then return nil, nil end

    local args = {
        "ffmpeg",
        "-hide_banner", "-loglevel", "fatal",
        "-hwaccel", "auto",
    }

    local vf = string.format("fps=1/%s,scale=%d:%d:flags=bilinear,format=gray",
        options.interval, options.width, options.height)

    local rest_args = {
        "-ss", tostring(start_time),
        "-t", tostring(duration),
        "-skip_frame", "bidir",
        "-skip_loop_filter", "all",
        "-i", video_path,
        "-map", "v:0",
        "-vf", vf,
        "-f", "rawvideo",
        "-"
    }

    for _, v in ipairs(rest_args) do
        table.insert(args, v)
    end

    local ffmpeg_start = mp.get_time()
    local res = async_subprocess({ args = args })
    local ffmpeg_end = mp.get_time()

    if res.status ~= 0 or not res.stdout or #res.stdout == 0 then
        -- Silent fail is better for scan loops, but log if debug
        if options.debug then msg.error("FFmpeg failed during scan.") end
        return nil, nil
    end

    local stream = res.stdout
    local num_frames = math.floor(#stream / FRAME_SIZE)

    local target_hash
    if ffi_status then
        local t_ptr = ffi.cast("uint8_t*", target_raw_bytes)
        target_hash = compute_hash_from_chunk(t_ptr, 0, true)
    else
        target_hash = compute_hash_from_chunk(target_raw_bytes, 0, false)
    end

    local stream_ptr
    if ffi_status then
        stream_ptr = ffi.cast("uint8_t*", stream)
    end

    local best_dist = 65
    local best_index = -1

    for i = 0, num_frames - 1 do
        local offset = i * FRAME_SIZE
        local current_hash

        if ffi_status then
            current_hash = compute_hash_from_chunk(stream_ptr, offset, true)
        else
            current_hash = compute_hash_from_chunk(stream, offset, false)
        end

        local dist = hamming_distance(target_hash, current_hash)

        if dist < best_dist then
            best_dist = dist
            best_index = i
            if best_dist <= 2 then break end
        end
    end

    if stats then
        stats.ffmpeg = stats.ffmpeg + (ffmpeg_end - ffmpeg_start)
        stats.frames = stats.frames + num_frames
    end

    local match_timestamp = nil
    if best_index >= 0 then
        match_timestamp = start_time + (best_index * options.interval)
    end

    return best_dist, match_timestamp
end

-- ==========================================
-- AUDIO ALGORITHM: CONSTELLATION HASHING
-- ==========================================

-- Simple Cooley-Tukey FFT (Recursive for simplicity, optimized if possible)
-- Input: real array. Output: real, imag arrays.
local function fft_simple(real_in, n)
    if n <= 1 then return real_in, {} end

    -- This is a very basic Lua FFT. For production, a specialized library is better.
    -- However, for 2048 points, this recursion might be too deep/slow in Lua.
    -- We'll use an iterative bit-reversal approach.

    local m = math.log(n) / math.log(2)
    local cos = math.cos
    local sin = math.sin
    local pi = math.pi

    local real = {}
    local imag = {}

    -- Bit reversal
    for i = 0, n - 1 do
        local j = 0
        local k = i
        for _ = 1, m do
            j = j * 2 + (k % 2)
            k = math.floor(k / 2)
        end
        real[j + 1] = real_in[i + 1] or 0
        imag[j + 1] = 0
    end

    local k = 1
    while k < n do
        local step = k * 2
        for i = 0, k - 1 do
            local angle = -pi * i / k
            local w_real = cos(angle)
            local w_imag = sin(angle)

            for j = i, n - 1, step do
                local idx1 = j + 1
                local idx2 = j + k + 1

                local t_real = w_real * real[idx2] - w_imag * imag[idx2]
                local t_imag = w_real * imag[idx2] + w_imag * real[idx2]

                real[idx2] = real[idx1] - t_real
                imag[idx2] = imag[idx1] - t_imag
                real[idx1] = real[idx1] + t_real
                imag[idx1] = imag[idx1] + t_imag
            end
        end
        k = step
    end

    return real, imag
end

-- Extract peaks from magnitude spectrum
local function get_peaks(magnitudes, freq_bin_count)
    -- Divide into bands to ensure spread (optional, but good for robustness)
    -- We'll just take local maxima above threshold
    local peaks = {}
    local threshold = options.audio_threshold

    for i = 2, freq_bin_count - 1 do
        local m = magnitudes[i]
        if m > threshold and m > magnitudes[i - 1] and m > magnitudes[i + 1] then
            -- Store peak: frequency index
            table.insert(peaks, i)
        end
    end
    -- Sort peaks by magnitude? Optional. We just take them.
    -- Limit number of peaks per frame to avoid noise
    if #peaks > 5 then
        -- Keep top 5
        local sorted = {}
        for _, p in ipairs(peaks) do
            table.insert(sorted, { idx = p, mag = magnitudes[p] })
        end
        table.sort(sorted, function(a, b) return a.mag > b.mag end)
        peaks = {}
        for i = 1, 5 do
            table.insert(peaks, sorted[i].idx)
        end
    end
    return peaks
end

-- Generate hashes from spectrogram peaks
-- spectrogram: array of frames, each frame is list of peak freq indices
local function generate_hashes(spectrogram)
    local hashes = {} -- list of {hash, time_offset}

    for t1, peaks1 in ipairs(spectrogram) do
        for _, f1 in ipairs(peaks1) do
            -- Target zone
            for t2 = t1 + options.audio_target_t_min, math.min(#spectrogram, t1 + options.audio_target_t_max) do
                local peaks2 = spectrogram[t2]
                for _, f2 in ipairs(peaks2) do
                    local dt = t2 - t1
                    -- Hash: [f1:9][f2:9][dt:14]
                    local h
                    if bit_status then
                        h = bit.bor(
                            bit.lshift(bit.band(f1, 0x1FF), 23),
                            bit.lshift(bit.band(f2, 0x1FF), 14),
                            bit.band(dt, 0x3FFF)
                        )
                    else
                        -- Arithmetic fallback: (f1 % 512) << 23 | (f2 % 512) << 14 | (dt % 16384)
                        -- Since fields do not overlap, OR is equivalent to ADD.
                        h = (f1 % MASK_9) * SHIFT_23 +
                            (f2 % MASK_9) * SHIFT_14 +
                            (dt % MASK_14)
                    end
                    table.insert(hashes, { h = h, t = t1 - 1 })
                end
            end
        end
    end
    return hashes
end

-- FFI optimized FFT (Iterative, In-place)
local function fft_ffi(real, imag, n)
    -- Bit Reversal
    local j = 0
    for i = 0, n - 2 do
        if i < j then
            local tr, ti = real[i], imag[i]
            real[i], imag[i] = real[j], imag[j]
            real[j], imag[j] = tr, ti
        end
        local k = n / 2
        while k <= j do
            j = j - k
            k = k / 2
        end
        j = j + k
    end

    -- Butterfly
    local k = 1
    local pi = math.pi
    local cos = math.cos
    local sin = math.sin

    while k < n do
        local step = k * 2
        for i = 0, k - 1 do
            local angle = -pi * i / k
            local w_real = cos(angle)
            local w_imag = sin(angle)

            for idx = i, n - 1, step do
                local idx2 = idx + k
                local t_real = w_real * real[idx2] - w_imag * imag[idx2]
                local t_imag = w_real * imag[idx2] + w_imag * real[idx2]

                real[idx2] = real[idx] - t_real
                imag[idx2] = imag[idx] - t_imag
                real[idx] = real[idx] + t_real
                imag[idx] = imag[idx] + t_imag
            end
        end
        k = step
    end
end

-- FFI version of get_peaks
-- Writes up to 5 peaks into row_ptr[0..4]
-- Returns number of peaks found
local function get_peaks_ffi(mags, row_ptr, freq_bin_count)
    local count = 0
    local threshold = options.audio_threshold

    -- 0-based indexing for mags (FFI array)
    for i = 1, freq_bin_count - 2 do
        local m = mags[i]
        if m > threshold and m > mags[i - 1] and m > mags[i + 1] then
            -- Found a peak.
            -- Insertion sort into top 5
            local idx = i
            local pos = count
            while pos > 0 do
                -- Compare with magnitude of peak at row_ptr[pos-1]
                if mags[row_ptr[pos - 1]] < m then
                    pos = pos - 1
                else
                    break
                end
            end

            if pos < 5 then
                local end_k = count
                if end_k >= 5 then end_k = 4 end
                for k = end_k, pos + 1, -1 do
                    row_ptr[k] = row_ptr[k - 1]
                end

                row_ptr[pos] = idx
                if count < 5 then count = count + 1 end
            end
        end
    end
    return count
end

local function generate_hashes_ffi(peaks, counts, num_frames)
    -- Estimate max hashes: 5 peaks * 90 window * 5 peaks * num_frames
    local max_hashes = num_frames * 2250
    local hashes = ffi.new("hash_entry[?]", max_hashes)
    local count = 0

    local t_min = options.audio_target_t_min
    local t_max = options.audio_target_t_max

    for t1 = 0, num_frames - 1 do
        local c1 = counts[t1]
        if c1 > 0 then
            -- peaks is flattened int16_t array. row size 5.
            local p1_base = t1 * 5

            local limit_t2 = math.min(num_frames, t1 + t_max + 1)
            for t2 = t1 + t_min, limit_t2 - 1 do
                local c2 = counts[t2]
                if c2 > 0 then
                    local p2_base = t2 * 5
                    local dt = t2 - t1

                    for k1 = 0, c1 - 1 do
                        local f1 = peaks[p1_base + k1]
                        for k2 = 0, c2 - 1 do
                            local f2 = peaks[p2_base + k2]

                            local h = bit.bor(
                                bit.lshift(bit.band(f1, 0x1FF), 23),
                                bit.lshift(bit.band(f2, 0x1FF), 14),
                                bit.band(dt, 0x3FFF)
                            )

                            hashes[count].h = h
                            hashes[count].t = t1
                            count = count + 1
                        end
                    end
                end
            end
        end
    end

    return hashes, count
end

-- Process PCM data to hashes
local function process_audio_data(pcm_str)
    local fft_size = options.audio_fft_size
    local hop_size = options.audio_hop_size
    local spectrogram = {}

    -- --- FFI PATH ---
    if ffi_status then
        local num_samples = math.floor(#pcm_str / 2)
        local samples = ffi.new("double[?]", num_samples)
        local ptr = ffi.cast("int16_t*", pcm_str)

        -- Convert to double (0-indexed)
        for i = 0, num_samples - 1 do
            samples[i] = ptr[i] / 32768.0
        end

        -- Pre-calculate Hann Window
        local hann = ffi.new("double[?]", fft_size)
        for i = 0, fft_size - 1 do
            hann[i] = 0.5 * (1 - math.cos(2 * math.pi * i / (fft_size - 1)))
        end

        -- Buffers for FFT
        local real_buf = ffi.new("double[?]", fft_size)
        local imag_buf = ffi.new("double[?]", fft_size)
        local mag_buf = ffi.new("double[?]", fft_size / 2)

        local num_frames = math.floor((num_samples - fft_size) / hop_size) + 1
        if num_frames < 0 then num_frames = 0 end

        -- Spectrogram storage: 5 peaks per frame
        local peaks_flat = ffi.new("int16_t[?]", num_frames * 5)
        local counts = ffi.new("int8_t[?]", num_frames)

        for i = 0, num_frames - 1 do
            local sample_idx = i * hop_size
            for j = 0, fft_size - 1 do
                real_buf[j] = samples[sample_idx + j] * hann[j]
                imag_buf[j] = 0.0
            end

            fft_ffi(real_buf, imag_buf, fft_size)

            for k = 0, fft_size / 2 - 1 do
                mag_buf[k] = math.sqrt(real_buf[k] ^ 2 + imag_buf[k] ^ 2)
            end

            -- Writes directly to flat array
            counts[i] = get_peaks_ffi(mag_buf, peaks_flat + i * 5, fft_size / 2)
        end

        return generate_hashes_ffi(peaks_flat, counts, num_frames)
    end

    -- --- LUA TABLE PATH (Fallback) ---
    local samples = {}
    -- Convert s16le string to samples
    for i = 1, #pcm_str, 2 do
        local b1 = string.byte(pcm_str, i)
        local b2 = string.byte(pcm_str, i + 1)
        local val = b1 + b2 * 256
        if val > 32767 then val = val - 65536 end
        table.insert(samples, val / 32768.0)
    end

    local num_samples = #samples
    local hann = {}
    for i = 0, fft_size - 1 do
        hann[i + 1] = 0.5 * (1 - math.cos(2 * math.pi * i / (fft_size - 1)))
    end

    for i = 1, num_samples - fft_size + 1, hop_size do
        local window = {}
        for j = 0, fft_size - 1 do
            window[j + 1] = samples[i + j] * hann[j + 1]
        end

        local real, imag = fft_simple(window, fft_size)
        local mags = {}
        for k = 1, fft_size / 2 do
            mags[k] = math.sqrt(real[k] ^ 2 + imag[k] ^ 2)
        end

        local peaks = get_peaks(mags, fft_size / 2)
        table.insert(spectrogram, peaks)
    end

    local hashes = generate_hashes(spectrogram)
    return hashes, #hashes
end

-- ==========================================
-- MAIN FUNCTIONS
-- ==========================================

-- 1. SAVE FINGERPRINT (VIDEO + AUDIO)
local function save_intro()
    local path = mp.get_property("path")
    local time_pos = mp.get_property_number("time-pos")

    if not path or not time_pos then
        mp.osd_message("Cannot capture: No video playing", 2)
        return
    end

    -- --- VIDEO SAVE ---
    local fp_path_v = get_fingerprint_path_video()
    log_info("Saving video fingerprint to: " .. fp_path_v)

    local vf = string.format("scale=%d:%d:flags=bilinear,format=gray", options.width, options.height)
    local args_v = {
        "ffmpeg", "-hide_banner", "-loglevel", "fatal", "-hwaccel", "auto",
        "-ss", tostring(time_pos), "-i", path, "-map", "v:0",
        "-vframes", "1", "-vf", vf, "-f", "rawvideo", "-y", "-"
    }

    local res_v = utils.subprocess({ args = args_v, cancellable = false, capture_stderr = true })

    if res_v.status == 0 and res_v.stdout and #res_v.stdout > 0 then
        local file_v = io.open(fp_path_v, "wb")
        if file_v then
            file_v:write(tostring(time_pos) .. "\n")
            file_v:write(res_v.stdout)
            file_v:close()
        end
    else
        mp.osd_message("Error capturing video frame", 3)
    end

    -- --- AUDIO SAVE ---
    local fp_path_a = get_fingerprint_path_audio()
    log_info("Saving audio fingerprint to: " .. fp_path_a)

    local start_a = math.max(0, time_pos - 30)
    local dur_a = time_pos - start_a

    if dur_a > 1 then
        local args_a = {
            "ffmpeg", "-hide_banner", "-loglevel", "fatal",
            "-ss", tostring(start_a), "-t", tostring(dur_a),
            "-i", path, "-map", "a:0",
            "-ac", "1", "-ar", tostring(options.audio_sample_rate),
            "-f", "s16le", "-y", "-"
        }
        local res_a = utils.subprocess({ args = args_a, cancellable = false, capture_stderr = true })

        if res_a.status == 0 and res_a.stdout and #res_a.stdout > 0 then
            local hashes, count = process_audio_data(res_a.stdout)
            log_info("Generated " .. count .. " audio hashes")

            local file_a = io.open(fp_path_a, "wb")
            if file_a then
                -- Format:
                -- Line 1: Duration of the capture (offset to skip to)
                -- Lines 2+: hash time
                file_a:write(string.format("%.4f\n", dur_a))

                local factor = options.audio_hop_size / options.audio_sample_rate
                if ffi_status and type(hashes) == "cdata" then
                    for i = 0, count - 1 do
                        local h = hashes[i]
                        file_a:write(string.format("%d %.4f\n", h.h, h.t * factor))
                    end
                else
                    for _, h in ipairs(hashes) do
                        file_a:write(string.format("%d %.4f\n", h.h, h.t * factor))
                    end
                end
                file_a:close()
            end
        else
            log_info("Error capturing audio: " .. (res_a.stderr or "unknown"))
        end
    end
    mp.osd_message("Intro Captured! (Video + Audio)", 2)
end

-- 2. SKIP INTRO (VIDEO)
local function skip_intro()
    if scanning then
        mp.osd_message("Scan in progress...", 2)
        return
    end

    run_async(function()
        local fp_path = get_fingerprint_path_video()
        local file = io.open(fp_path, "rb")

        if not file then
            mp.osd_message("No intro captured yet.", 2)
            return
        end

        local saved_time_str = file:read("*line")
        local saved_time = tonumber(saved_time_str)

        if not saved_time then
            mp.osd_message("Corrupted fingerprint file.", 2)
            file:close()
            return
        end

        local target_bytes = file:read("*all")
        file:close()

        if not target_bytes or #target_bytes < FRAME_SIZE then
            mp.osd_message("Invalid fingerprint data.", 2)
            return
        end

        scanning = true

        local perf_stats = { ffmpeg = 0, lua = 0, frames = 0 }
        local scan_start_time = mp.get_time()

        local function finish_scan(message)
            scanning = false

            local total_dur = mp.get_time() - scan_start_time
            perf_stats.lua = total_dur - perf_stats.ffmpeg

            if options.debug then
                msg.info(string.format("TOTAL PERF (Video): FFmpeg: %.4fs | Lua: %.4fs | Total: %.4fs | Frames: %d",
                    perf_stats.ffmpeg, perf_stats.lua, total_dur, perf_stats.frames))
            end

            if message then mp.osd_message(message, 2) end
        end

        local current_video = mp.get_property("path")
        local total_duration = mp.get_property_number("duration") or math.huge

        mp.osd_message(
        string.format("Scanning Video %d%%...", math.floor(options.search_window / options.max_search_window * 100)), 60)

        local window_size = options.search_window
        local scanned_start = math.max(0, saved_time - window_size)
        local scanned_end = math.min(total_duration, saved_time + window_size)

        local dist, timestamp = scan_segment_video(scanned_start, scanned_end - scanned_start, current_video, target_bytes,
            perf_stats)

        if dist and dist <= options.threshold then
            mp.set_property("time-pos", timestamp)
            finish_scan(string.format("Skipped! (Dist: %d)", dist))
            return
        end

        while window_size <= options.max_search_window do
            if not scanning then break end

            local old_start = scanned_start
            local old_end = scanned_end

            window_size = window_size + options.window_step
            scanned_start = math.max(0, saved_time - window_size)
            scanned_end = math.min(total_duration, saved_time + window_size)

            if scanned_start == old_start and scanned_end == old_end then break end

            mp.osd_message(
            string.format("Scanning Video %d%%...", math.min(100, math.floor(window_size / options.max_search_window * 100))),
                60)

            if scanned_start < old_start then
                local d, t = scan_segment_video(scanned_start, old_start - scanned_start, current_video, target_bytes,
                    perf_stats)
                if d and d <= options.threshold then
                    mp.set_property("time-pos", t)
                    finish_scan(string.format("Skipped! (Dist: %d)", d))
                    return
                end
            end

            if not scanning then break end

            if scanned_end > old_end then
                local d, t = scan_segment_video(old_end, scanned_end - old_end, current_video, target_bytes, perf_stats)
                if d and d <= options.threshold then
                    mp.set_property("time-pos", t)
                    finish_scan(string.format("Skipped! (Dist: %d)", d))
                    return
                end
            end
        end

        if scanning then
            finish_scan("No match found.")
        end
    end)
end

-- 3. SKIP INTRO (AUDIO)
local function skip_intro_audio()
    if scanning then
        mp.osd_message("Scan in progress...", 2)
        return
    end

    run_async(function()
        local fp_path = get_fingerprint_path_audio()
        local file = io.open(fp_path, "r")
        if not file then
            mp.osd_message("No audio intro captured.", 2)
            return
        end

        -- Load saved hashes
        local saved_hashes = {} -- hash -> list of times

        -- Read first line: duration adjustment
        local dur_line = file:read("*line")
        local capture_duration = tonumber(dur_line)

        if not capture_duration then
            mp.osd_message("Invalid audio fingerprint file.", 2)
            file:close()
            return
        end

        local count = 0
        for line in file:lines() do
            local h, t = string.match(line, "(%d+) ([%d%.]+)")
            if h and t then
                h = tonumber(h)
                t = tonumber(t)
                if not saved_hashes[h] then saved_hashes[h] = {} end
                table.insert(saved_hashes[h], t)
                count = count + 1
            end
        end
        file:close()

        if count == 0 then
            mp.osd_message("Empty audio fingerprint.", 2)
            return
        end
        log_info("Loaded " .. count .. " audio hashes. Duration adj: " .. capture_duration)

        scanning = true
        mp.osd_message("Scanning Audio...", 10)

        -- Performance Stats
        local perf_stats = { ffmpeg = 0, lua = 0 }
        local scan_start_time = mp.get_time()

        -- Helper to finish and print stats
        local function finish_scan(message)
            scanning = false
            local total_dur = mp.get_time() - scan_start_time
            perf_stats.lua = total_dur - perf_stats.ffmpeg

            if options.debug then
                msg.info(string.format("TOTAL PERF (Audio): FFmpeg: %.4fs | Lua: %.4fs | Total: %.4fs",
                    perf_stats.ffmpeg, perf_stats.lua, total_dur))
            end
            if message then mp.osd_message(message, 2) end
        end

        local path = mp.get_property("path")
        local duration = mp.get_property_number("duration") or 0
        local max_scan_time = math.min(duration, options.audio_scan_limit)
        local cur_time = 0
        local window = options.audio_scan_window
        local overlap = 30 -- Overlap by 30s to catch matches on boundaries

        local best_score = 0
        local best_pos = nil
        local previous_score = 0

        while cur_time < max_scan_time do
            if not scanning then break end

            mp.osd_message(string.format("Scanning Audio %d%%...", math.floor(cur_time / max_scan_time * 100)), 1)

            local args = {
                "ffmpeg", "-hide_banner", "-loglevel", "fatal",
                "-ss", tostring(cur_time), "-t", tostring(window),
                "-i", path, "-map", "a:0",
                "-ac", "1", "-ar", tostring(options.audio_sample_rate),
                "-f", "s16le", "-y", "-"
            }

            local ffmpeg_start = mp.get_time()
            local res = async_subprocess({ args = args })
            perf_stats.ffmpeg = perf_stats.ffmpeg + (mp.get_time() - ffmpeg_start)

            if res.status ~= 0 or not res.stdout then
                break
            end

            if not scanning then break end

            local chunk_hashes, count = process_audio_data(res.stdout)

            -- Matching logic
            local offset_histogram = {}
            -- Histogram bin size: tolerance 0.1s
            local time_bin_width = 0.1
            local factor = options.audio_hop_size / options.audio_sample_rate

            if ffi_status and type(chunk_hashes) == "cdata" then
                for i = 0, count - 1 do
                    local ch = chunk_hashes[i]
                    local track_time = cur_time + (ch.t * factor)
                    local h = ch.h

                    local saved = saved_hashes[h]
                    if saved then
                        for _, fp_time in ipairs(saved) do
                            local offset = track_time - fp_time
                            local bin = math.floor(offset / time_bin_width)
                            offset_histogram[bin] = (offset_histogram[bin] or 0) + 1
                        end
                    end
                end
            else
                for _, ch in ipairs(chunk_hashes) do
                    local track_time = cur_time + (ch.t * factor)
                    local h = ch.h

                    local saved = saved_hashes[h]
                    if saved then
                        for _, fp_time in ipairs(saved) do
                            local offset = track_time - fp_time
                            local bin = math.floor(offset / time_bin_width)
                            offset_histogram[bin] = (offset_histogram[bin] or 0) + 1
                        end
                    end
                end
            end

            -- Check histogram for peak
            local local_best_bin = nil
            local local_max = 0
            for bin, cnt in pairs(offset_histogram) do
                if cnt > local_max then
                    local_max = cnt
                    local_best_bin = bin
                end
            end

            log_info(string.format("Chunk %.1f: Max matches %d at bin %s", cur_time, local_max, tostring(local_best_bin)))

            if local_max > options.audio_threshold and local_max > best_score then
                best_score = local_max
                local offset = local_best_bin * time_bin_width
                best_pos = offset + capture_duration
            end

            -- Gradient based early stopping:
            -- If previous window had a good match, and current window score dropped, we passed the peak.
            if previous_score > options.audio_threshold and local_max < previous_score then
                log_info(string.format("Gradient drop detected (%d -> %d). Stopping scan.", previous_score, local_max))
                break
            end
            previous_score = local_max

            cur_time = cur_time + (window - overlap)
        end

        if scanning then
            if best_pos and best_score > options.audio_threshold then
                mp.set_property("time-pos", best_pos)
                finish_scan(string.format("Skipped! (Audio Match: %d)", best_score))
            else
                finish_scan("No audio match found.")
            end
        end
    end)
end

mp.add_key_binding("Ctrl+i", "save-intro", save_intro)
mp.add_key_binding("Ctrl+s", "skip-intro", skip_intro)
mp.add_key_binding("Ctrl+Shift+s", "skip-intro-audio", skip_intro_audio)
