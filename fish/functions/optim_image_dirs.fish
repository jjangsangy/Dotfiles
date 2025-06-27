function optim_image_dirs
    switch $argv[1]
        case jpeg
            find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) -print0 \
                | xargs -0 -n1 -P(nproc) \
                jpegoptim --max=75 --strip-all --all-progressive
        case png
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
        case webp
            find . -type f -iname '*.webp' -print0 \
                | xargs -0 -n1 -P (nproc) bash -c '
                    f="$0"
                    echo "→ Optimizing: $f"
                    cwebp -q 75 -metadata none "$f" -o "${f}.tmp" \
                        && mv "${f}.tmp" "$f"
                '
        case '*'
            echo "Usage: optim_image_dirs [jpeg|png|webp]"
    end
end
