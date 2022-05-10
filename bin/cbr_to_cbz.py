#!/usr/bin/env python3
"""
Convert all cbr files in directories passed as arguments.

Usage:
    cbr_to_cbz.py *dirs
"""

import contextlib
import os
import pathlib
import shutil
import sys
import tempfile
import zipfile

import rarfile

for extract_file in sys.argv[1:]:
    extract_file = pathlib.Path(extract_file)

    with tempfile.TemporaryDirectory() as temp_zip:
        temp_zip = pathlib.Path(temp_zip)
        cbz_path = temp_zip / extract_file.with_suffix(".cbz").name

        with zipfile.ZipFile(cbz_path, "x") as zipf:
            with contextlib.ExitStack() as rar_stack:
                temp_rar = pathlib.Path(
                    rar_stack.enter_context(tempfile.TemporaryDirectory())
                )
                rarf = rar_stack.enter_context(rarfile.RarFile(str(extract_file)))

                print(f"Converting file {extract_file}")
                rarf.extractall(path=str(temp_rar))

                for root, dirs, files in os.walk(temp_rar):
                    root = pathlib.Path(root)

                    for file in files:
                        file = pathlib.Path(file)
                        full_path = root / file
                        zipf.write(full_path, arcname=full_path.relative_to(temp_rar))

        shutil.copy(str(cbz_path), str(extract_file.parent / cbz_path.name))
