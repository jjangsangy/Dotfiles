#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "rarfile",
#     "py7zr",
#     "click",
#     "rich",
#     "pillow",
# ]
# ///
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
from typing import Iterable, List, Optional, Union

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

# ==============================================================
# CONVERT SUBCOMMAND CODE (Comic Archive Converter)
# ==============================================================


# Base class for archives.
class Archive:
    ext = None  # e.g. ".cbz", ".cbr", etc.

    @staticmethod
    def extract(source: pathlib.Path, dest: pathlib.Path):
        raise NotImplementedError

    @staticmethod
    def compress(source_dir: pathlib.Path, target: pathlib.Path):
        raise NotImplementedError


class ArchiveCBZ(Archive):
    ext = ".cbz"

    @staticmethod
    def extract(source: pathlib.Path, dest: pathlib.Path):
        with zipfile.ZipFile(source, "r") as zf:
            zf.extractall(path=dest)

    @staticmethod
    def compress(source_dir: pathlib.Path, target: pathlib.Path):
        with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for root, _, files in os.walk(source_dir):
                root_path = pathlib.Path(root)
                for file in files:
                    full_path = root_path / file
                    zf.write(full_path, arcname=full_path.relative_to(source_dir))


class ArchiveCBR(Archive):
    ext = ".cbr"

    @staticmethod
    def extract(source: pathlib.Path, dest: pathlib.Path):
        with rarfile.RarFile(str(source)) as rf:
            rf.extractall(path=str(dest))

    @staticmethod
    def compress(source_dir: pathlib.Path, target: pathlib.Path):
        try:
            subprocess.run(["rar"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except FileNotFoundError:
            raise RuntimeError(
                "RAR command-line tool is not installed or not in PATH; cannot create CBR files."
            )
        cmd = ["rar", "a", "-idq", str(target), "*"]
        subprocess.run(cmd, cwd=source_dir, check=True)


class ArchiveCB7(Archive):
    ext = ".cb7"

    @staticmethod
    def extract(source: pathlib.Path, dest: pathlib.Path):
        with py7zr.SevenZipFile(source, mode="r") as sz:
            sz.extractall(path=str(dest))

    @staticmethod
    def compress(source_dir: pathlib.Path, target: pathlib.Path):
        with py7zr.SevenZipFile(target, mode="w") as sz:
            sz.writeall(str(source_dir), arcname=".")


class ArchiveCBT(Archive):
    ext = ".cbt"

    @staticmethod
    def extract(source: pathlib.Path, dest: pathlib.Path):
        with tarfile.open(source, "r:*") as tf:
            tf.extractall(path=dest)

    @staticmethod
    def compress(source_dir: pathlib.Path, target: pathlib.Path):
        with tarfile.open(target, "w") as tf:
            for root, _, files in os.walk(source_dir):
                root_path = pathlib.Path(root)
                for file in files:
                    full_path = root_path / file
                    tf.add(full_path, arcname=full_path.relative_to(source_dir))


ARCHIVE_CLASSES = {
    ArchiveCBZ.ext: ArchiveCBZ,
    ArchiveCBR.ext: ArchiveCBR,
    ArchiveCB7.ext: ArchiveCB7,
    ArchiveCBT.ext: ArchiveCBT,
}

# ==============================================================
# SPLIT SUBCOMMAND CODE (Image Exporters & Split Logic)
# ==============================================================

EXPORTERS = {}


def register_exporter(*filetypes):
    """Decorator to register exporters."""

    def register(cls):
        for filetype in filetypes:
            EXPORTERS[filetype] = cls
        return cls

    return register


class ImageExporterBase(ABC):
    """
    Base class for extracting images from different locations.
    """

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
        ".svg",
    }

    def __init__(self, path: Union[str, pathlib.Path]) -> None:
        self.path = pathlib.Path(path)

    def __repr__(self):
        return f"{self.__class__.__name__}('{self.path}')"

    @abstractmethod
    def get_images(self) -> List[Image.Image]:
        """Return a list of PIL Image objects."""

    @abstractmethod
    def copy_tree(self, output_dir: Union[str, pathlib.Path]) -> None:
        """Copies all files recursively to the output directory."""


@register_exporter("/")
class DirectoryExporter(ImageExporterBase):
    def get_images(self) -> List[Image.Image]:
        images = sorted(
            [
                (file, Image.open(file))
                for file in self.path.iterdir()
                if file.suffix.lower() in self.IMG_EXTENSIONS
            ],
            key=lambda x: alphanum_key(str(x[0])),
        )
        return [i[1] for i in images]

    def copy_tree(self, output_dir: Union[str, pathlib.Path]) -> None:
        shutil.copytree(self.path, output_dir, dirs_exist_ok=True)


@register_exporter(".cbz", ".zip")
class ZipExporter(ImageExporterBase):
    def get_images(self) -> List[Image.Image]:
        with zipfile.ZipFile(self.path) as zf:
            images = sorted(
                [
                    (file.filename, Image.open(zf.open(file.filename)))
                    for file in zf.filelist
                    if os.path.splitext(file.filename)[-1].lower()
                    in self.IMG_EXTENSIONS
                ],
                key=lambda x: alphanum_key(str(x[0])),
            )
        return [i[1] for i in images]

    def copy_tree(self, output_dir: Union[str, pathlib.Path]) -> None:
        shutil.unpack_archive(self.path, extract_dir=output_dir, format="zip")


@register_exporter(".rar", ".cbr")
class RarExporter(ImageExporterBase):
    def get_images(self) -> List[Image.Image]:
        with rarfile.RarFile(self.path) as rf:
            images = sorted(
                [
                    (file, Image.open(rf.open(file)))
                    for file in rf.namelist()
                    if os.path.splitext(file)[-1].lower() in self.IMG_EXTENSIONS
                ],
                key=lambda x: alphanum_key(str(x[0])),
            )
        return [i[1] for i in images]

    def copy_tree(self, output_dir: Union[str, pathlib.Path]) -> None:
        with rarfile.RarFile(self.path) as rf:
            rf.extractall(path=pathlib.Path(output_dir).parent)


def exporter_factory(d: pathlib.Path) -> Optional[ImageExporterBase]:
    """
    Create an exporter object based on the path's type.
    """
    if d.is_dir() and "/" in EXPORTERS:
        return EXPORTERS["/"](d)
    elif d.suffix.lower() in EXPORTERS:
        return EXPORTERS[d.suffix.lower()](d)
    else:
        return None


def alphanum_key(s: str) -> List[Union[str, int]]:
    """
    Split a string into a list of strings and integers for natural sorting.
    """
    return [int(text) if text.isdigit() else text for text in re.split("([0-9]+)", s)]


def split_image(img: Image.Image, size_threshold: int) -> List[Image.Image]:
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
) -> List[Image.Image]:
    return sum([split_image(i, size_threshold) for i in images], [])


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
    type=click.Choice(["cbz", "cbr", "cb7", "cbt"], case_sensitive=False),
    help="Target filetype extension (without the dot).",
)
def convert(directories, target_ext):
    """
    Convert all comic book archives in the provided directories from one format to another.
    """
    console = Console()
    target_ext = f".{target_ext.lower()}"
    if target_ext not in ARCHIVE_CLASSES:
        console.print(f"[red]Target extension {target_ext} is not supported.[/red]")
        sys.exit(1)

    files_to_convert = []
    for directory in directories:
        for file_path in directory.iterdir():
            ext = file_path.suffix.lower()
            if ext in ARCHIVE_CLASSES:
                if ext == target_ext:
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
                    ARCHIVE_CLASSES[ext].extract(file_path, extract_dir)
                    temp_target = temp_dir_path / (file_path.stem + target_ext)
                    ARCHIVE_CLASSES[target_ext].compress(extract_dir, temp_target)
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
    Split manhwa files (chapters) from input_dir until each resulting image is below the given size threshold.
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
            exporter = exporter_factory(chapter)
            if not exporter:
                continue

            original_images = exporter.get_images()
            output_chapter_dir = output_dir / chapter.stem
            if output_chapter_dir.exists():
                shutil.rmtree(output_chapter_dir)

            # Determine the largest image (by total pixels).
            max_image_size = max(
                [operator.mul(*img.size) for img in original_images], default=0
            )
            if max_image_size < size_threshold:
                exporter.copy_tree(output_chapter_dir)
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
                        img_task, advance=1, description=f"\t[cyan]{num:03}.jpg[/cyan]"
                    )
                    output_filepath = output_chapter_dir / f"{num:03}.jpg"
                    image.convert("RGB").save(
                        str(output_filepath), format="JPEG", quality=85
                    )
                pb.remove_task(img_task)
    console.print("[green]Splitting complete.[/green]")


if __name__ == "__main__":
    cli()
