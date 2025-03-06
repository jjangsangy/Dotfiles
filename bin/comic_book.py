#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "rarfile",
#     "py7zr",
#     "click",
#     "rich",
#     "pillow",
# ]
# ///

import glob
import operator
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from abc import ABC, abstractmethod

# ==============================================================
# CONVERT SUBCOMMAND CODE (Comic Archive Converter)
# ==============================================================
from typing import Callable, Dict, Iterable, Self, Type, TypeVar

import click
import py7zr
import rarfile
from PIL import Image
from rich.console import Console
from rich.progress import (
    BarColumn,
    MofNCompleteColumn,
    Progress,
    SpinnerColumn,
    TaskProgressColumn,
    TextColumn,
    TimeElapsedColumn,
    TimeRemainingColumn,
)

T = TypeVar("T", bound=Type)

ARCHIVERS: Dict[str, Type] = {}


def register_archiver(*filetypes: str) -> Callable[[T], T]:
    """Decorator to register archiver classes."""

    def register(cls: T) -> T:
        for filetype in filetypes:
            ARCHIVERS[filetype] = cls
        return cls

    return register


def alphanum_key(s: str) -> list[str | int]:
    """
    Split a string into a list of strings and integers for natural sorting.
    """
    return [int(text) if text.isdigit() else text for text in re.split("([0-9]+)", s)]


def split_image(img: Image.Image, size_threshold: int) -> list[Image.Image]:
    """
    Recursively splits an image horizontally until the image's total pixels are below size_threshold.
    """
    width, height = img.size
    if width * height < size_threshold:
        return [img]
    middle = height // 2
    top_half = img.crop((0, 0, width, middle))
    bottom_half = img.crop((0, middle, width, height))
    return split_image(top_half, size_threshold) + split_image(
        bottom_half, size_threshold
    )


def split_images(
    images: Iterable[Image.Image], size_threshold: int = 5_000_000
) -> list[Image.Image]:
    return sum([split_image(i, size_threshold) for i in images], [])


# Base class for archives.
class ArchiveBase(ABC):
    IMG_EXTENSIONS = {
        ".jpeg",
        ".jpg",
        ".png",
        ".tiff",
        ".tif",
        ".bmp",
        ".webp",
        ".heif",
        ".heic",
    }

    def __init__(self: Self, path: str | pathlib.Path) -> None:
        self.path = pathlib.Path(path)

    def __repr__(self: Self) -> str:
        return f"{self.__class__.__name__}('{self.path}')"

    @abstractmethod
    def extract(self: Self, dest: pathlib.Path) -> None:
        raise NotImplementedError

    @staticmethod
    @abstractmethod
    def compress(source_dir: pathlib.Path, dest: pathlib.Path) -> None:
        raise NotImplementedError

    @abstractmethod
    def get_images(self: Self) -> list[Image.Image]:
        """Return a list of PIL Image objects."""
        raise NotImplementedError


@register_archiver(".cbz", ".zip")
class ArchiveCBZ(ArchiveBase):
    def extract(self: Self, dest: pathlib.Path) -> None:
        with zipfile.ZipFile(self.path, "r") as zf:
            zf.extractall(path=dest)

    @staticmethod
    def compress(source_dir: pathlib.Path, dest: pathlib.Path) -> None:
        base_name = str(dest.with_suffix(""))
        archive = shutil.make_archive(base_name, "zip", root_dir=source_dir)
        os.replace(archive, dest)

    def get_images(self: Self) -> list[Image.Image]:
        with zipfile.ZipFile(self.path) as zf:
            images = sorted(
                [
                    (file, Image.open(zf.open(file)))
                    for file in zf.namelist()
                    if os.path.splitext(file)[-1].lower() in self.IMG_EXTENSIONS
                ],
                key=lambda x: alphanum_key(str(x[0])),
            )
        return [img for _, img in images]


@register_archiver(".rar", ".cbr")
class ArchiveCBR(ArchiveBase):
    def extract(self: Self, dest: pathlib.Path) -> None:
        with rarfile.RarFile(self.path) as rf:
            rf.extractall(path=str(dest))

    @staticmethod
    def compress(source_dir: pathlib.Path, dest: pathlib.Path) -> None:
        try:
            subprocess.run(["rar"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except FileNotFoundError as err:
            raise RuntimeError(
                "RAR command-line tool is not installed or not in PATH; cannot create CBR files."
            ) from err

        cmd = ["rar", "a", "-idq", "-ep1", str(dest)] + glob.glob(str(source_dir / "*"))
        subprocess.run(cmd, cwd=source_dir, check=True)

    def get_images(self: Self) -> list[Image.Image]:
        with rarfile.RarFile(self.path) as rf:
            images = sorted(
                [
                    (file, Image.open(rf.open(file)))
                    for file in rf.namelist()
                    if os.path.splitext(file)[-1].lower() in self.IMG_EXTENSIONS
                ],
                key=lambda x: alphanum_key(str(x[0])),
            )
        return [img for _, img in images]


@register_archiver(".7z", ".cb7")
class ArchiveCB7(ArchiveBase):
    def extract(self: Self, dest: pathlib.Path) -> None:
        with py7zr.SevenZipFile(self.path, mode="r") as sz:
            sz.extractall(path=str(dest))

    @staticmethod
    def compress(source_dir: pathlib.Path, dest: pathlib.Path) -> None:
        with py7zr.SevenZipFile(dest, mode="w") as sz:
            sz.writeall(str(source_dir), arcname=".")

    def get_images(self: Self) -> list[Image.Image]:
        with py7zr.SevenZipFile(self.path, mode="r") as sz:
            all_files = sz.readall()
            images = sorted(
                [
                    (fname, Image.open(file_obj))
                    for fname, file_obj in all_files.items()
                    if os.path.splitext(fname)[-1].lower() in self.IMG_EXTENSIONS
                ],
                key=lambda x: alphanum_key(x[0]),
            )
        return [img for _, img in images]


@register_archiver(".tar", ".cbt")
class ArchiveCBT(ArchiveBase):
    def extract(self: Self, dest: pathlib.Path) -> None:
        with tarfile.open(self.path, "r:*") as tf:
            tf.extractall(path=dest, filter="data")

    @staticmethod
    def compress(source_dir: pathlib.Path, dest: pathlib.Path) -> None:
        with tarfile.open(dest, "w") as tf:
            for root, _, files in os.walk(source_dir):
                root_path = pathlib.Path(root)
                for file in files:
                    full_path = root_path / file
                    tf.add(full_path, arcname=full_path.relative_to(source_dir))

    def get_images(self: Self) -> list[Image.Image]:
        with tarfile.open(self.path, "r:*") as tf:
            members = tf.getmembers()
            images = sorted(
                [
                    (member.name, Image.open(tf.extractfile(member)).copy())
                    for member in members
                    if member.isfile()
                    and os.path.splitext(member.name)[-1].lower() in self.IMG_EXTENSIONS
                ],
                key=lambda x: alphanum_key(x[0]),
            )
        return [img for _, img in images]


@register_archiver("/")
class ArchiveDir(ArchiveBase):
    def extract(self: Self, dest: pathlib.Path) -> None:
        shutil.copytree(self.path, dest, dirs_exist_ok=True)

    @staticmethod
    def compress(source_dir: pathlib.Path, dest: pathlib.Path) -> None:
        shutil.copytree(source_dir, dest, dirs_exist_ok=True)

    def get_images(self: Self) -> list[Image.Image]:
        images = sorted(
            [
                (file, Image.open(file))
                for file in self.path.iterdir()
                if file.suffix.lower() in self.IMG_EXTENSIONS and file.is_file()
            ],
            key=lambda x: alphanum_key(str(x[0])),
        )
        return [img for _, img in images]


def archiver_factory(d: pathlib.Path) -> ArchiveBase | None:
    """
    Create an archiver object based on the path's type.
    """
    if d.is_dir() and "/" in ARCHIVERS:
        return ARCHIVERS["/"](d)
    elif d.suffix.lower() in ARCHIVERS:
        return ARCHIVERS[d.suffix.lower()](d)
    else:
        return None


# ==============================================================
# CLI GROUP DEFINITION (Both Subcommands)
# ==============================================================


@click.group()
def cli():
    """Comic Book Toolset CLI."""
    pass


# ----- CONVERT SUBCOMMAND -----
@cli.command()
@click.argument(
    "directories",
    type=click.Path(
        exists=True, file_okay=False, dir_okay=True, path_type=pathlib.Path
    ),
    nargs=-1,
)
@click.option(
    "--to",
    "target_ext",
    required=True,
    type=click.Choice(
        [i.lstrip(".") for i in ARCHIVERS if i != "/" and i.startswith(".cb")],
        case_sensitive=False,
    ),
    help="Target filetype extension (without the dot).",
)
def convert(directories, target_ext):
    """
    Convert different archive formats (cbr,cbz,etc..).
    """
    console = Console()
    target_ext = f".{target_ext.lower()}"
    if target_ext not in ARCHIVERS:
        console.print(f"[red]Target extension {target_ext} is not supported.[/red]")
        sys.exit(1)

    files_to_convert = []
    for directory in directories:
        for file_path in directory.iterdir():
            ext = file_path.suffix.lower()
            if ext in ARCHIVERS:
                if (ext == target_ext) or (ARCHIVERS[ext] is ARCHIVERS[target_ext]):
                    console.print(
                        f"[yellow]Skipping {file_path.name}: already a {target_ext} file.[/yellow]"
                    )
                else:
                    files_to_convert.append(file_path)

    if not files_to_convert:
        console.print("[blue]No files to convert.[/blue]")
        return

    with Progress(
        "[progress.description]{task.description}",
        BarColumn(),
        "[progress.percentage]{task.percentage:>3.0f}%",
        TimeElapsedColumn(),
        TimeRemainingColumn(),
        console=console,
    ) as progress:
        task = progress.add_task("Converting files...", total=len(files_to_convert))
        for file_path in files_to_convert:
            progress.update(
                task, description=f"Converting [bold]{file_path.name}[/bold]"
            )
            ext = file_path.suffix.lower()
            try:
                with tempfile.TemporaryDirectory() as temp_dir:
                    temp_dir_path = pathlib.Path(temp_dir)
                    extract_dir = temp_dir_path / "work"
                    extract_dir.mkdir()
                    ARCHIVERS[ext](file_path).extract(extract_dir)

                    temp_target = temp_dir_path / (file_path.stem + target_ext)
                    ARCHIVERS[target_ext].compress(extract_dir, temp_target)
                    dest = file_path.parent / temp_target.name
                    shutil.copy(str(temp_target), str(dest))
            except Exception as e:
                console.print(f"[red]Error processing {file_path.name}: {e}[/red]")
            progress.advance(task)
    console.print("[green]Conversion complete.[/green]")


# ----- SPLIT SUBCOMMAND -----
@cli.command()
@click.argument(
    "input_dir",
    type=click.Path(exists=True, file_okay=True, dir_okay=True, path_type=pathlib.Path),
)
@click.option(
    "--output-dir",
    "-o",
    default="Results",
    type=click.Path(file_okay=False, dir_okay=True, path_type=pathlib.Path),
    show_default=True,
    help="Output directory to store results in",
)
@click.option(
    "--size-threshold",
    "-s",
    default=5000000,
    type=int,
    show_default=True,
    help="Maximum size (in total pixels) for resulting images",
)
def split(input_dir, output_dir, size_threshold):
    """
    Split images in comic archives to all be under a size threshold.
    """
    console = Console()
    # Ensure we don't write to the same directory we're reading from.
    if output_dir.exists() and output_dir.samefile(input_dir):
        raise click.ClickException(
            "Cannot save into the same directory you're reading from"
        )
    if size_threshold <= 500000:
        raise click.ClickException("Cannot make images smaller than 500,000 pixels")

    sorted_chapters = sorted(input_dir.iterdir(), key=lambda x: alphanum_key(str(x)))
    with Progress(
        SpinnerColumn("dots2"),
        TextColumn("{task.description}"),
        BarColumn(bar_width=None),
        TaskProgressColumn(),
        MofNCompleteColumn(),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
        transient=True,
        console=console,
    ) as pb:
        ch_task = pb.add_task("[green]Chapters[/green]", total=len(sorted_chapters))
        for chapter in sorted_chapters:
            pb.update(
                ch_task, advance=1, description=f"[green]{chapter.name:.20}[/green]"
            )
            archiver = archiver_factory(chapter)
            if not archiver:
                continue

            original_images = archiver.get_images()
            output_chapter_dir = output_dir / chapter.stem
            if output_chapter_dir.exists():
                shutil.rmtree(output_chapter_dir)

            # Determine the largest image (by total pixels).
            max_image_size = max(
                [operator.mul(*img.size) for img in original_images], default=0
            )
            if max_image_size < size_threshold:
                archiver.extract(output_chapter_dir)
            else:
                converted_images = split_images(
                    original_images, size_threshold=size_threshold
                )
                output_chapter_dir.mkdir(exist_ok=True, parents=True)
                img_task = pb.add_task(
                    f"\t[cyan]{chapter.name}[/cyan]",
                    total=len(converted_images),
                    transient=True,
                )
                for num, image in enumerate(converted_images, 1):
                    pb.update(
                        img_task,
                        advance=1,
                        description=f"\t[cyan]{num:03}.jpg[/cyan]",
                    )
                    output_filepath = output_chapter_dir / f"{num:03}.jpg"
                    image.convert("RGB").save(
                        str(output_filepath), format="JPEG", quality=85
                    )
                pb.remove_task(img_task)
    console.print("[green]Splitting complete.[/green]")


if __name__ == "__main__":
    cli()
