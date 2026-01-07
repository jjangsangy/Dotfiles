-- mpv Lua script to toggle playback speed with configurable default speed and hotkey

local mp = require 'mp'
local options = require 'mp.options'

-- Table to hold the configuration options
local opts = {
    default_speed = 3.0,  -- Default speed if not set in the configuration file
    hotkey = "\\"         -- Default hotkey if not set in the configuration file
}

-- Read options from script-opts/togglespeed.conf
options.read_options(opts, 'togglespeed')

-- Variable to store the last speed
local last_speed = nil

-- Function to toggle playback speed
local function toggle_speed()
    local current_speed = mp.get_property_number("speed")

    if current_speed ~= 1.0 then
        -- Save the current speed and set speed to 1.0
        last_speed = current_speed
        mp.set_property_number("speed", 1.0)
        mp.osd_message("Speed: 1.0x")
    else
        -- Set speed to last speed or default if no last speed is set
        local new_speed = last_speed or opts.default_speed
        mp.set_property_number("speed", new_speed)
        mp.osd_message("Speed: " .. new_speed .. "x")
    end
end

-- Assign keybinding from configuration or use default
mp.add_key_binding(opts.hotkey, "toggle_speed", toggle_speed)
