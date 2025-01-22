function zip_manga -d 'convert manga directory into cbz format'
  set -l cur_dir $PWD

  if not type --quiet zip
    echo "zip utility does not exist" >&2
    return 1
  end

  for i in $argv
    if cd $i 2>/dev/null
      if not count (find . -maxdepth 3 -type f -name '*.jpg' -or -name '*.png' -or -name '*.jpeg' -or -name '*.webp') >/dev/null
        continue
      end
      zip -0 -r ../(string trim -r -c/ $i).cbz *; or return 1
      cd $cur_dir
    end
  end
end
