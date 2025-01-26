function extract_audio -d 'Extract audio track from media file using ffmpeg'
    if not type --quiet ffmpeg
        echo "ERROR: could not find ffmpeg command" >&2
        return
    end
    if not type --quiet ffprobe
        echo "ERROR: could not find ffprobe command" >&2
        return
    end

    for i in $argv
        set -l basename (string split '.' $i | head -n-1 | string join '.')
        set codec (ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $i)
        if [ $codec = "wmapro" ]
            set codec wma
        end
        if ! test -f $basename.$codec
            ffmpeg -i $i -vn -acodec copy $basename.$codec
        end
    end
end
