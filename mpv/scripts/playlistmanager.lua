local settings = {
  --linux=true, windows=false, nil=auto
  linux_over_windows = nil,

  --path where you want to save playlists, notice trailing \ or /. Do not use shortcuts like ~ or $HOME
  playlist_savepath = "/tmp",

  --osd when navigating in seconds
  osd_duration_seconds = 5,

  --filetypes to search from directory, {''} for all, {'mkv','mp4'} for specific
  loadfiles_filetypes = {'mkv', 'avi', 'mp4', 'ogv', 'webm', 'rmvb', 'flv', 'wmv', 'mpeg', 'mpg', 'm4v', '3gp',
'mp3', 'wav', 'ogv', 'flac', 'm4a', 'wma', 'jpg', 'gif', 'png', 'jpeg', 'webp'},

  --sort playlist on mpv start
  sortplaylist_on_start = false,

  --amount of entries to show before slicing. Optimal value depends on font/video size etc.
  showamount = 13,

  --replaces matches on filenames based on extension, put as false to not replace anything
  --replaces executed in index order, if order doesn't matter many rules can be placed inside one index
  --uses :gsub('pattern', 'replace'), read more http://lua-users.org/wiki/StringLibraryTutorial
  filename_replace = {
    [1] = {
      ['ext'] = { ['all']=true },   --apply rule to all files
      ['rules'] = {
        [1] = { ['_'] = ' ' },  --change underscore to space
      },
    },
    [2] = {
      ['ext'] = { ['mkv']=true, ['mp4']=true },   --apply rule to mkv and mp4 only
      ['rules'] = {
        [1] = { ['^(.+)%..+$']='%1' },          --remove extension
        [2] = { ['%s*[%[%(].-[%]%)]%s*']='' },  --remove brackets, their content and surrounding white space
        [3] = { ['(%w)%.(%w)']='%1 %2' },       --change dots between alphanumeric chars to spaces
      },
    },
  },

  --set title of window with stripped name, prefix and suffix("" for empty suffix)
  set_title_stripped = true,
  title_prefix = "",
  title_suffix = " - mpv",

  --slice long filenames, and how many chars to show
  slice_longfilenames = {false, 70},

  --show playlist every time a new file is loaded
  --NOTE: using osd-playing-message will interfere with this setting, if you prefer it use 0 here
  --2 shows playlist, 1 shows current file(filename strip above applied), 0 shows nothing
  --instead of using this you can also call script-message playlistmanager show playlist/filename
  --ex. KEY playlist-next ; script-message playlistmanager show playlist
  show_playlist_on_fileload = 0,

  --sync cursor when file is loaded from outside reasons(file-ending, playlist-next shortcut etc.)
  --has the sideeffect of moving cursor if file happens to change when navigating
  --good side is cursor always following current file when going back and forth files with playlist-next/prev
  sync_cursor_on_load = true,

  --keybindings force override only while playlist is visible
  --allowing you to use common overlapping keybinds
  dynamic_binds = true,

  --playlist display signs, {"prefix", "suffix"}
  playing_str = {"->", ""},
  cursor_str = {">", "<"},
  cursor_str_selected = {">>", "<<"},
  --top and bottom if playlist entries are sliced off from display
  playlist_sliced_str = {"...", "..."},

}
require 'mp.options'
read_options(settings, "playlistmanager")


local utils = require 'mp.utils'
local msg = require 'mp.msg'

--check os
if settings.linux_over_windows==nil then
  local o = {}
  if mp.get_property_native('options/vo-mmcss-profile', o) ~= o then
    settings.linux_over_windows = false
  else
    settings.linux_over_windows = true
  end
end

function on_loaded()
  filename = mp.get_property("filename")
  path = utils.join_path(mp.get_property('working-directory'), mp.get_property('path'))
  directory = utils.split_path(path)
  refresh_globals()

  if settings.sync_cursor_on_load then cursor=pos end

  strippedname = stripfilename(mp.get_property('media-title'))
  if settings.show_playlist_on_fileload == 2 then
    showplaylist()
  elseif settings.show_playlist_on_fileload == 1 then
    mp.commandv('show-text', strippedname)
  end
  if settings.set_title_stripped then mp.set_property("title", settings.title_prefix..strippedname..settings.title_suffix) end
end

function on_closed()
  strippedname = nil
  path = nil
  directory = nil
  filename = nil
end

function refresh_globals()
  pos = mp.get_property_number('playlist-pos', 0)
  plen = mp.get_property_number('playlist-count', 0)
end

function escapepath(dir, escapechar)
  return string.gsub(dir, escapechar, '\\'..escapechar)
end

--create file search query with path to search files, extensions in a table, unix as true(windows false)
function create_searchquery(path, extensions, unix)
  local query = ' '
  for i in pairs(extensions) do
    if unix then
      if extensions[i] ~= "" then extensions[i] = "*"..extensions[i] end
      query = query..extensions[i]..' '
    else
      query = query..'"'..path..'*'..extensions[i]..'" '
    end
  end
  if unix then
    return 'cd "'..escapepath(path, '"')..'";ls -1vp'..query..'2>/dev/null'
  else
    return 'dir /b'..query:gsub("/", "\\")
  end
end

function stripfilename(pathfile)
  local ext = pathfile:match("^.+%.(.+)$")
  if not ext then ext = "" end
  local tmp = pathfile
  if settings.filename_replace then
    for k,v in ipairs(settings.filename_replace) do
      if v['ext'][ext] or v['ext']['all'] then
        for ruleindex, indexrules in ipairs(v['rules']) do
          for rule, override in pairs(indexrules) do
            tmp = tmp:gsub(rule, override)
          end
        end
      end
    end
  end
  if settings.slice_longfilenames[1] and tmp:len()>settings.slice_longfilenames[2]+5 then
    tmp = tmp:sub(1, settings.slice_longfilenames[2]).." ..."
  end
  return tmp
end

cursor = 0
function showplaylist(duration)
  --update playlist length and position
  refresh_globals()
  --do not display playlist with 0 files
  if plen == 0 then return end
  add_keybinds()
  if cursor>plen then cursor=0 end
  local playlist = {}
  for i=0,plen-1,1
  do
    local l_path, l_file = utils.split_path(mp.get_property('playlist/'..i..'/filename'))
    playlist[i] = stripfilename(l_file)
  end
  output = "Playing: "..strippedname.."\n\n"
  output = output.."Playlist - "..(cursor+1).." / "..plen.."\n"
  local b = cursor - math.floor(settings.showamount/2)
  local showall = false
  local showrest = false
  if b<0 then b=0 end
  if plen <= settings.showamount then
    b=0
    showall=true
  end
  if b > math.max(plen-settings.showamount-1, 0) then
    b=plen-settings.showamount
    showrest=true
  end
  if b > 0 and not showall then output=output..settings.playlist_sliced_str[1].."\n" end
  for a=b,b+settings.showamount-1,1 do
    if a == plen then break end
    if a == pos then output = output..settings.playing_str[1] end
    if a == cursor then
      if tag then
        output = output..settings.cursor_str_selected[1]..playlist[a]..settings.cursor_str_selected[2].."\n"
      else
        output = output..settings.cursor_str[1]..playlist[a]..settings.cursor_str[2].."\n"
      end
    else
      output = output..playlist[a].."\n"
    end
    if a == pos then output = output..settings.playing_str[2] end
    if a == b+settings.showamount-1 and not showall and not showrest then
      output=output..settings.playlist_sliced_str[2]
    end
  end
  mp.osd_message(output, (tonumber(duration) or settings.osd_duration_seconds))
  keybindstimer:kill()
  keybindstimer:resume()
end

tag=nil
function tagcurrent()
  refresh_globals()
  if plen == 0 then return end
  if not tag then
    tag=cursor
  else
    tag=nil
  end
  showplaylist()
end

function removefile()
  refresh_globals()
  if plen == 0 then return end
  tag = nil
  if cursor==pos then mp.command("script-message unseenplaylist mark true \"playlistmanager avoid conflict when removing file\"") end
  mp.commandv("playlist-remove", cursor)
  if cursor==plen-1 then cursor = cursor - 1 end
  showplaylist()
end

function moveup()
  refresh_globals()
  if plen == 0 then return end
  if cursor~=0 then
    if tag then mp.commandv("playlist-move", cursor,cursor-1) end
    cursor = cursor-1
  else
    if tag then mp.commandv("playlist-move", cursor,plen) end
    cursor = plen-1
  end
  showplaylist()
end

function movedown()
  refresh_globals()
  if plen == 0 then return end
  if cursor ~= plen-1 then
    if tag then mp.commandv("playlist-move", cursor,cursor+2) end
    cursor = cursor + 1
  else
    if tag then mp.commandv("playlist-move", cursor,0) end
    cursor = 0
  end
  showplaylist()
end

function jumptofile()
  refresh_globals()
  if plen == 0 then return end
  tag = nil
  if cursor < pos then
    for x=1,math.abs(cursor-pos),1 do
      mp.commandv("playlist-prev", "weak")
    end
  elseif cursor>pos then
    for x=1,math.abs(cursor-pos),1 do
      mp.commandv("playlist-next", "weak")
    end
  else
    if cursor~=plen-1 then
      cursor = cursor + 1
    end
    mp.commandv("playlist-next", "weak")
  end
  if settings.show_playlist_on_fileload == 0 then mp.osd_message("") end
  remove_keybinds()
end

--Creates a playlist of all files in directory, will keep the order and position
--For exaple, Folder has 12 files, you open the 5th file and run this, the remaining 7 are added behind the 5th file and prior 4 files before it
--to change what extensions are accepted change settings.loadfiles_filetypes
function playlist()
  refresh_globals()
  if not path or not directory or plen == 0 then return end
  local popen, err = io.popen(create_searchquery(directory, settings.loadfiles_filetypes, settings.linux_over_windows))
  if popen then
    local cur = false
    local c, c2 = 0,0
    local filename = mp.get_property("filename")
    for file in popen:lines() do
      if file:sub(-1) ~= "/" then
        if cur == true then
          mp.commandv("loadfile", directory..file, "append")
          msg.info("Appended to playlist: " .. file)
          c2 = c2 + 1
        elseif file ~= filename then
            mp.commandv("loadfile", directory..file, "append")
            msg.info("Prepended to playlist: " .. file)
            mp.commandv("playlist-move", mp.get_property_number("playlist-count", 1)-1,  c)
            c = c + 1
        else
          cur = true
        end
      end
    end
    popen:close()
    if c2 > 0 or c>0 then mp.osd_message("Added "..c.." files before and "..c2.." files after current file") end
    cursor = mp.get_property_number('playlist-pos', 1)
  else
    msg.error("Could not scan for files: "..(err or ""))
  end
  plen = mp.get_property_number('playlist-count', 0)
end

--saves the current playlist into a m3u file
function save_playlist()
  local length = mp.get_property_number('playlist-count', 0)
  if length == 0 then return end
  local savepath = utils.join_path(settings.playlist_savepath, os.time().."-size_"..length.."-playlist.m3u")
  local file, err = io.open(savepath, "w")
  if not file then
    msg.error("Error in creating playlist file, check permissions and paths: "..(err or ""))
  else
    local i=0
    local pwd = mp.get_property("working-directory")
    local filename = mp.get_property('playlist/'..i..'/filename')
    local fullpath = filename
    if not filename:match("^%a%a+:%/%/") then
      fullpath = utils.join_path(pwd, filename)
    end
    while i < length do
      file:write(fullpath, "\n")
      i=i+1
    end
    msg.info("Playlist written to: "..savepath)
    file:close()
  end
end

function alphanumsort(o)
  local function padnum(d) local dec, n = string.match(d, "(%.?)0*(.+)")
    return #dec > 0 and ("%.12f"):format(d) or ("%s%03d%s"):format(dec, #n, n) end
    table.sort(o, function(a,b)
    return tostring(a):gsub("%.?%d+",padnum)..("%3d"):format(#b)
         < tostring(b):gsub("%.?%d+",padnum)..("%3d"):format(#a) end)
  return o
end

function sortplaylist()
  local length = mp.get_property_number('playlist-count', 0)
  if length < 2 then return end
  local playlist = {}
  for i=0,length,1
  do
    playlist[i+1] = mp.get_property('playlist/'..i..'/filename')
  end
  alphanumsort(playlist)
  local first = true
  for index,file in pairs(playlist) do
    mp.commandv("loadfile", file, first and "replace" or "append")
    first = false
  end
  cursor = 0
end

function shuffleplaylist()
  refresh_globals()
  if plen < 2 then return end
  mp.command("playlist-shuffle")
  while pos ~= 0 do
    mp.command("playlist-prev weak")
    refresh_globals()
  end
end

if settings.sortplaylist_on_start then
  mp.add_timeout(0.03, sortplaylist)
end

function add_keybinds()
  mp.add_forced_key_binding('UP', 'moveup', moveup, "repeatable")
  mp.add_forced_key_binding('DOWN', 'movedown', movedown, "repeatable")
  mp.add_forced_key_binding('RIGHT', 'tagcurrent', tagcurrent)
  mp.add_forced_key_binding('ENTER', 'jumptofile', jumptofile)
  mp.add_forced_key_binding('BS', 'removefile', removefile, "repeatable")
end

function remove_keybinds()
  if settings.dynamic_binds then
    mp.remove_key_binding('moveup')
    mp.remove_key_binding('movedown')
    mp.remove_key_binding('tagcurrent')
    mp.remove_key_binding('jumptofile')
    mp.remove_key_binding('removefile')
  end
end

keybindstimer = mp.add_periodic_timer(settings.osd_duration_seconds, remove_keybinds)
keybindstimer:kill()

if not settings.dynamic_binds then
  add_keybinds()
end

--script message handler
function handlemessage(msg, value, value2)
  if msg == "show" and value == "playlist" then showplaylist(value2) ; return end
  if msg == "show" and value == "filename" and strippedname and value2 then mp.commandv('show-text', strippedname, tonumber(value2)*1000 ) ; return end
  if msg == "show" and value == "filename" and strippedname then mp.commandv('show-text', strippedname ) ; return end
  if msg == "sort" then sortplaylist() ; return end
  if msg == "shuffle" then shuffleplaylist() ; return end
  if msg == "loadfiles" then playlist() ; return end
  if msg == "save" then save_playlist() ; return end
end

mp.register_script_message("playlistmanager", handlemessage)

mp.add_key_binding('CTRL+p', 'sortplaylist', sortplaylist)
mp.add_key_binding('CTRL+P', 'shuffleplaylist', shuffleplaylist)
mp.add_key_binding('P', 'loadfiles', playlist)
mp.add_key_binding('p', 'saveplaylist', save_playlist)
mp.add_key_binding('SHIFT+ENTER', 'showplaylist', showplaylist)

mp.register_event('file-loaded', on_loaded)
mp.register_event('end-file', on_closed)
