function kindle_comic_converter
  if not type -q kcc-c2e
    echo "Kindle Comic Converter CLI not installed" >&2
    return 1
  end
  kcc-c2e --profile=KoF --manga-style --format=EPUB --upscale --splitter=1 $argv
end
