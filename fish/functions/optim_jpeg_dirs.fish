function optim_jpeg_dirs
    find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0 \
        | xargs -0 -n1 -P(nproc) \
        jpegoptim --max=75 --strip-all --all-progressive
end
