function pack_manga
  rename_kepub_epub

  set -l cbzs *.cbz
  set -l kepubs *.kepub

  if count $cbzs >/dev/null
    if not test -d "cbz (upscaled)"
      mkdir "cbz (upscaled)"
    end
    mv $cbzs "cbz (upscaled)"
    and echo "moved *.cbz into 'cbz (upscaled)'"
  end

  if count $kepubs >/dev/null
    if not test -d "kepub (upscaled)"
      mkdir "kepub (upscaled)"
    end
    mv $kepubs "kepub (upscaled)"
    and echo "moved *.kepub into 'kepub (upscaled)'"
  end
end
