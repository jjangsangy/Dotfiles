#!/usr/bin/env python3
"""
Extract the cover image from compressed binary formats
"""

import argparse
import os
import os.path
import pathlib
from zipfile import ZipFile

parser = argparse.ArgumentParser(
    description="extract manga covers and install into calibre directory",
)
parser.add_argument(
    "-e", "--ext", type=str, default="cbz", help="filename extension", choices=["cbz"]
)
parser.add_argument(
    "-m",
    "--manga-dir",
    type=str,
    default=".",
    help="directory location for manga files",
)
parser.add_argument(
    "-a",
    "--calibre-author",
    type=str,
    default="KCC",
    help="author name as located in calibre directory",
)
parser.add_argument(
    "-d",
    "--calibre-dir",
    type=str,
    default="~/Calibre Library",
    help="calibre library dir",
)
args = parser.parse_args()

calibre_path = pathlib.Path(args.calibre_dir).expanduser() / args.calibre_author
manga_path = pathlib.Path(args.manga_dir)

assert calibre_path.is_dir(), f"calibre path to author does not exists {calibre_path}"
assert manga_path.is_dir(), f"path to manga files does not exist {manga_path}"

manga_files = sorted(list(manga_path.glob(f"*.{args.ext}")))
calibre_dirs = [
    i
    for i in sorted(calibre_path.iterdir())
    if i.is_dir() and not i.name.startswith(".")
]

if len(manga_files) != len(calibre_dirs):
    raise ValueError("length of directories and manga files do not match")

for calibre_dir, manga_file in zip(calibre_dirs, manga_files):
    with ZipFile(manga_file) as zf:
        member = [i for i in sorted(zf.namelist()) if not i.endswith("/")][0]
        img_bytes = zf.read(member)

    output_file = calibre_dir / ("cover" + os.path.splitext(member)[1])
    print(f'Extracting to: "{output_file}"')
    with output_file.open("wb") as fp:
        fp.write(img_bytes)
