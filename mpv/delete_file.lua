local mp = require 'mp'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local os =  require 'os'
local io = require 'io'
local string = require 'string'
local options = require 'mp.options'


local function file_exists(filename)
  return io.open(filename, "r") ~= nil
end

local function get_filepaths()
  local dirname = mp.get_property_native('working-directory')
  local path = mp.get_property_native('path')
  local filepath = utils.join_path(dirname, path)

  -- Extract directory and filename from path
  local filedir, filename = utils.split_path(path)

  -- Prepend '.' to the filename
  local tmpfilename = "." .. filename

  -- Construct the tmp filepath by joining dirname, filedir, and tmpfilename
  local tmp = utils.join_path(utils.join_path(dirname, filedir), tmpfilename)

  return {
    filepath = filepath,
    tmp = tmp,
  }
end

-- Moves file from one place to another
local function move_file(from, to)
  local output = os.rename(from, to)
  if output == true then
      msg.info("Moved " .. from .. " to " .. to)
  else
      msg.fatal("Failed " .. from .. " to " .. to)
      msg.fatal(utils.to_string(output))
  end
  return output
end

-- Delete The Current Track
local function delete_current_track()
  local paths =  get_filepaths()
  local exists = file_exists(paths.filepath)

  if exists == true then
    mp.osd_message("'" .. paths.filepath .. "' deleting.", 5)
    move_file(paths.filepath, paths.tmp)
  else
    mp.osd_message("'" .. paths.filepath .. "' does not exist.", 5)
  end
end

-- Restore the last deleted track.
local function restore_prev_track()
  local paths =  get_filepaths()
  local exists = file_exists(paths.tmp)
  
  if exists == true then
    mp.osd_message("'" .. paths.filepath .. "' restoring.", 5)
    move_file(paths.tmp, paths.filepath)
  end
end


-- Removes tmp file before exit
local function clean_up(hook)
  local paths = get_filepaths()
  local exists = file_exists(paths.tmp)

  if exists then
    msg.info('deleting file' .. paths.tmp)
    local ret, err = os.remove(paths.tmp)
    if not ret then
      msg.error('Failed to delete ' .. paths.tmp .. '. Error: ' .. err)
    end
  end
end


mp.add_key_binding("d", "delete_current_track", delete_current_track, {repeatable=true})
mp.add_key_binding("r", "restore_prev_track",   restore_prev_track,   {repeatable=true})

mp.add_hook('on_unload', 50, clean_up)