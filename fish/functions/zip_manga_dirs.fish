function zip_manga_dirs
  set -l cur_dir $PWD

  argparse 'k/kcc' 'h/help' 'm/move=?' -- $argv; or return

  if set -q _flag_help
    echo "zip_manga_dirs [-k/--kcc] [-h/--help] [dirs]..."
    echo "    -k/--kcc: run kindle comic creator over cbz files"
    echo "              must have kcc-ec2 cli installed"
    echo "    -m/--move: upload to directory"
    echo "                 [default:/mnt/b/Manga]"
    echo "    -h/--help: display help page and exit"
    return
  end

  if set -q _flag_move
      if test -z $_flag_move
          set -f _flag_move /mnt/b/Manga
      end
      if not test -d $_flag_move
        echo "move directory $_flag_move does not exist" >&2
        return 1
      end
  end

  set -q _flag_kcc; and not type -q kcc-c2e; or not functions -q kindle_comic_converter
    and echo "kindle comic converter cli not installed" >&2
    and return 1
  not command -q rsync
    and echo "rsync command not installed" >&2
    and return 1
  not functions -q zip_manga
    and echo "zip_manga function not installed" >&2
    and return 1
  not functions -q pack_manga
    and echo "pack_manga function not installed" >&2
    and return 1

  for i in $argv
    if cd $i
      set -l dirs (find . -maxdepth 1 -mindepth 1 -type d | string replace -r '^\./' '')

      if zip_manga $dirs
        rm -rf $dirs
        if set -q _flag_kcc
          kindle_comic_converter *.cbz
        end
        pack_manga
        cd $cur_dir
        if set -q _flag_move
          rsync -av --progress (string trim -r -c '/' $i) $_flag_move/
            and rm -rf $i
        end
      else
        cd $cur_dir
        return 1
      end
      cd $cur_dir
    end
  end
end
