#!/usr/bin/env python3

import os
import pathlib
import argparse
import shutil

def cli():
    parser = argparse.ArgumentParser(
         description='Renames NZB files to their folder id',
    )
    parser.add_argument('-m', '--move', action='store_true', help='Move file to current folder')
    return parser.parse_args()


def walkdir(root):
    extensions = ['.mov', '.wmv', '.mp4', '.mkv', '.m4v', '.avi']
    files = []
    for r, _, f in os.walk(root):
        r = pathlib.Path(r)
        for file in f:
            fullpath = r / file
            if any([str(file).endswith(i) for i in extensions]):
                files.append(fullpath)
    return files


if __name__ == '__main__':
    args = cli()
    root = pathlib.Path()

    for d in root.iterdir():
        if not d.is_dir() or (d / '_unpack').is_dir():
            continue

        vid_files = walkdir(d)
        if not vid_files:
            continue

        top_file = max(vid_files, key=lambda x: x.lstat().st_size)
        out_name = d.with_suffix(top_file.suffix)

        print(f'Moving file "{top_file}"')
        if args.move:
            shutil.move(top_file, out_name)
        else:
            shutil.move(top_file, d / out_name)
