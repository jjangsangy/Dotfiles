function convert_hevc
    for i in *
        if string match -q '*.srt' $i
            and not string match -q '*h265.srt' $i
            mv $i (string split -f1 -r -m1 . $i).h265.srt
        else if string match -q '*.h265.mp4' $i
            continue
        else if string match -q '*.mp4' $i
            hevcencode $i
            and rm $i
        end
    end
    check_media.py *
end
