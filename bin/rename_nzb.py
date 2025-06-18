#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "typer",
#     "rich"
# ]
# ///

import os
import pathlib
import shutil
from typing import Annotated

import typer
from rich.progress import Progress


def walkdir(root: pathlib.Path) -> list[pathlib.Path]:
    extensions: list[str] = [".mov", ".wmv", ".mp4", ".mkv", ".m4v", ".avi"]
    files: list[pathlib.Path] = []
    for r, _, f in os.walk(root):
        r = pathlib.Path(r)
        for file in f:
            fullpath = r / file
            if any([str(file).endswith(i) for i in extensions]):
                files.append(fullpath)
    return files


app = typer.Typer()


@app.command()
def main(
    move: Annotated[
        bool,
        typer.Option("-m", "--move", help="Move files to current folder"),
    ] = False,
    root: Annotated[
        pathlib.Path, typer.Argument(help="The root directory to search for files.")
    ] = pathlib.Path("."),
):
    """
    Renames NZB files to their folder id.
    """
    if "podcasts" in str(root.absolute()).lower():
        raise ValueError(
            f"Error: Path contains 'Podcasts' - operation not allowed: {root.absolute()}"
        )

    dirs_to_process = []
    for d in root.iterdir():
        if d.is_dir() and not (d / "_unpack").is_dir():
            vid_files = walkdir(d)
            if vid_files:
                dirs_to_process.append((d, vid_files))

    with Progress() as progress:
        task = progress.add_task("[cyan]Moving files...", total=len(dirs_to_process))
        for d, vid_files in dirs_to_process:
            top_file = max(vid_files, key=lambda x: x.lstat().st_size)
            out_name = d.with_suffix(top_file.suffix)

            if move:
                shutil.move(top_file, out_name)
            else:
                shutil.move(top_file, d / out_name)
            progress.update(
                task,
                advance=1,
                description=f"[cyan]Moving [green]{top_file.name}[/green]...",
            )


if __name__ == "__main__":
    app()
