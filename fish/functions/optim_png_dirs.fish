function optim_png_dirs
    find . -type f -iname '*.png' -print0 \
        | xargs -0 -n1 -P(nproc) bash -c '
      echo "→ Optimizing: $0"
      pngquant \
        --quality=65-85 \
        --speed=1 \
        --force \
        --ext .png \
        "$0"
    '
end
