-- default keybinding: s
-- add the following to your input.conf to change the default keybinding:
-- keyname script_binding auto_load_subs
local mp = require 'mp'
local utils = require 'mp.utils'

local function display_error()
    mp.msg.warn("Subtitle download failed: ")
    mp.osd_message("Subtitle download failed")
end

local function load_sub_fn()
    local path = mp.get_property("path")
    local srt_path = string.gsub(path, "%.%w+$", ".srt")
    local t = { args = { "subliminal", "download", "--min-score", "50", "-s", "-f", "-l", "en", path } }

    mp.osd_message("Searching subtitle")
    local res = utils.subprocess(t)
    if res.error == nil then
        if mp.commandv("sub_add", srt_path) then
            mp.msg.warn("Subtitle download succeeded")
            mp.osd_message("Subtitle '" .. srt_path .. "' download succeeded")
        else
            display_error()
        end
    else
        display_error()
    end
end

mp.add_key_binding("s", "auto_load_subs", load_sub_fn)
