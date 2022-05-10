#!/usr/bin/env python3
"""
Extract the cover image from compressed binary formats
"""

import os
import os.path
import pathlib
import argparse

from zipfile import ZipFile


parser = argparse.ArgumentParser(description="Extract Manga Covers")
parser.add_argument("-e", "--ext", nargs=1, default="cbz", help="Extension", choices=["cbz"])
args = parser.parse_args()

root = pathlib.Path(".")
files = sorted(list(root.glob(f"*.{args.ext}")))


for file in files:
    with ZipFile(file) as zf:
        member = [i for i in sorted(zf.namelist()) if not i.endswith("/")][0]
        img_bytes = zf.read(member)

    output_name = os.path.splitext(file.name)[0] + os.path.splitext(member)[1]
    print(f'Extracting file "{member}" to "{output_name}"')
    with open(output_name, "wb") as fp:
        fp.write(img_bytes)
