function optim_webp_dirs
    find . -type f -iname '*.webp' -print0 \
        | xargs -0 -n1 -P (nproc) bash -c '
            f="$0"
            echo "→ Optimizing: $f"
            cwebp -q 75 -metadata none "$f" -o "${f}.tmp" \
                && mv "${f}.tmp" "$f"
        '
end
