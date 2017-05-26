local utils = require 'mp.utils'
local os =  require 'os'
local io = require 'io'
local string = require 'string'
local options = require 'mp.options'
local msg = require 'mp.msg'


function get_filepaths()
  local dirname = mp.get_property('working-directory')
  local filename = mp.get_property('filename')
  local filepath = utils.join_path(dirname, filename)
  local tmp = utils.join_path(dirname, ".tmp")
  return { filepath = filepath, tmp = tmp }
end

-- Moves file from one place to another
function move_file(from, to)
  local output = utils.subprocess({
      args = { "mv", from, to}, cancellable = false
  })
  if output.status == 0 then
      msg.info("Moved " .. from .. " to " .. to)
  else
      msg.fatal("Failed " .. from .. " to " .. to)
      msg.fatal(utils.to_string(output))
  end
  return output
end

-- Delete The Current Track
function delete_current_track()
  local paths =  get_filepaths()
  mp.osd_message("'" .. paths.filepath.. "' deleting.", 1000)
  move_file(paths.filepath, paths.tmp)
end

-- Restore the last deleted track.
function restore_prev_track()
  local paths =  get_filepaths()
  mp.osd_message("'" .. paths.filepath .. "' restoring.", 1000)
  move_file(paths.tmp, paths.filepath)
end


-- Removes tmp file before exit
function clean_up()
  local paths = get_filepaths()
  local ret, err = os.remove(paths.tmp)
  if ret == true then mp.commandv("playlist-remove", "current") end
end


mp.add_key_binding("d", "delete_current_track", delete_current_track, {repeatable=false})
mp.add_key_binding("r", "restore_prev_track",   restore_prev_track,   {repeatable=false})

mp.add_hook('on_unload', 50, clean_up)
