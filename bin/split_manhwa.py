#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "pillow",
#     "rarfile",
#     "rich",
# ]
# ///

import operator
import os
import pathlib
import re
import shutil
import zipfile
from abc import ABC, abstractmethod
from argparse import ArgumentDefaultsHelpFormatter, ArgumentParser, Namespace
from typing import Iterable, List, Optional, Union

import rarfile
from PIL import Image
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

EXPORTERS = {}


def register_exporter(*filetypes):
    """
    Decorator which registers exporters
    """

    def register(cls):
        for filetype in filetypes:
            EXPORTERS[filetype] = cls
        return cls

    return register


class ImageExporterBase(ABC):
    """
    Base class for extracting images from different locations.

    Must implement abstract methods
        * get_images
        * copy_tree
    """

    IMG_EXTENSIONS = set(
        [
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
        ]
    )

    def __init__(self, path: Union[str, pathlib.Path]) -> None:
        self.path = pathlib.Path(path)

    def __repr__(self):
        return f"{self.__class__.__name__}('{self.path}')"

    @abstractmethod
    def get_images(self) -> List[Image.Image]:
        """
        Returns a list of all images as a list of PIL Image files
        """

    @abstractmethod
    def copy_tree(self, output_dir: Union[str, pathlib.Path]) -> None:
        """
        Copies all files recursively from the origin to an
        output directory
        """


@register_exporter("/")
class DirectoryExporter(ImageExporterBase):
    def get_images(self) -> List[Image.Image]:
        images = sorted(
            [
                (file, Image.open(file))
                for file in self.path.iterdir()
                if file.suffix in self.IMG_EXTENSIONS
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
                    if os.path.splitext(file.filename)[-1] in self.IMG_EXTENSIONS
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
                    if os.path.splitext(file)[-1] in self.IMG_EXTENSIONS
                ],
                key=lambda x: alphanum_key(str(x[0])),
            )
        return [i[1] for i in images]

    def copy_tree(self, output_dir: Union[str, pathlib.Path]) -> None:
        with rarfile.RarFile(self.path) as rf:
            rf.extractall(path=pathlib.Path(output_dir).parent)


def exporter_factory(d: pathlib.Path) -> Optional[ImageExporterBase]:
    """
    Creates an exporter object depending on the suffix of the path

    Parameters
    ----------
    d: location of the image files
    """
    if d.is_dir() and "/" in EXPORTERS:
        return EXPORTERS["/"](d)
    elif d.suffix in EXPORTERS:
        return EXPORTERS[d.suffix](d)
    else:
        return None


def split_image(img: Image.Image, size_threshold: int) -> List[Image.Image]:
    """
    Recursively splits an image horizontally until the resulting images are
    smaller than the size threshold.

    Parameters
    ----------
    image_path: The path to the image file that is to be split.
    size_threshold: The maximum size (in total pixels) allowed for the resulting images.
    """
    # Calculate the dimensions to split the image into two parts
    width, height = img.size
    if width * height < size_threshold:
        return [img]

    middle = height // 2

    # Split the image into top and bottom halves
    top_half = img.crop((0, 0, width, middle))
    bottom_half = img.crop((0, middle, width, height))

    # recursively split images
    result = []
    result.extend(split_image(top_half, size_threshold))
    result.extend(split_image(bottom_half, size_threshold))

    return result


def alphanum_key(s: str) -> List[Union[str, int]]:
    """
    Turn a string into a list of string and number chunks.

    Parameters
    ----------
    s: String to convert

    Examples
    --------
    "hello 2" -> ["hello ", 2]
    "hello 10" -> ["hello ", 10]
    """
    return [int(text) if text.isdigit() else text for text in re.split("([0-9]+)", s)]


def split_images(
    images: Iterable[Image.Image],
    size_threshold: int = 5_000_000,
) -> List[Image.Image]:
    return sum([split_image(i, size_threshold) for i in images], [])


def cli() -> Namespace:
    parser = ArgumentParser(
        description="Split manhwa files until they reach a certain size threshold",
        formatter_class=ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--output-dir",
        "-o",
        default="Results",
        type=pathlib.Path,
        help="Output directory to store results in",
    )
    parser.add_argument(
        "--size-threshold",
        "-s",
        default=5_000_000,
        type=int,
        help="Maximum size in total pixels for resulting images",
    )
    parser.add_argument(
        "input_dir",
        type=pathlib.Path,
        help="Input directory to read files from",
    )
    args = parser.parse_args()

    if args.output_dir.exists() and args.output_dir.samefile(args.input_dir):
        raise ValueError("Cannot save into the same directory you're reading from")

    if args.size_threshold <= 500_000:
        raise ValueError("Cannot make images smaller than 500,000 pixels")

    return args


def main():
    args = cli()

    sorted_chapters = list(
        sorted(args.input_dir.iterdir(), key=lambda x: alphanum_key(str(x)))
    )
    with Progress(
        SpinnerColumn("dots2"),
        TextColumn("{task.description}"),
        BarColumn(bar_width=None),
        TaskProgressColumn(),
        MofNCompleteColumn(),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
        transient=True,
    ) as pb:
        ch_pb = pb.add_task("[green]Chapters: [/green]", total=len(sorted_chapters))

        for d in sorted_chapters:
            pb.update(
                task_id=ch_pb, advance=1, description=f"[green]{d.name: >.20}[/green]"
            )
            if not (exporter := exporter_factory(d)):
                continue

            original_images = exporter.get_images()
            output_chapter_dir: pathlib.Path = args.output_dir / d.stem

            # Delete folder if it exists
            if output_chapter_dir.exists():
                shutil.rmtree(output_chapter_dir)

            # Whether to copy the directory or write split files
            max_image_size = max([operator.mul(*i.size) for i in original_images])
            if max_image_size < args.size_threshold:
                exporter.copy_tree(output_chapter_dir)
            else:
                converted_images = split_images(
                    original_images, size_threshold=args.size_threshold
                )
                output_chapter_dir.mkdir(exist_ok=True, parents=True)
                img_pb = pb.add_task(
                    "\t[yellow]001.jpg[/yellow]",
                    total=len(converted_images),
                    transient=True,
                )
                for num, image in enumerate(converted_images, 1):
                    pb.update(
                        task_id=img_pb,
                        advance=1,
                        description=f"\t[yellow]{num:03}.jpg[/yellow]",
                    )
                    output_filepath = str(output_chapter_dir / f"{num:03}.jpg")
                    image.convert("RGB").save(
                        output_filepath, format="JPEG", quality=85
                    )

                pb.remove_task(img_pb)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
