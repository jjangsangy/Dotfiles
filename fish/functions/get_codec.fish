function get_codec --argument vid_input
    ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 $vid_input
end
