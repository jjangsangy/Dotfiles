#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "rarfile",
#     "py7zr",
#     "typer",
#     "typing_extensions",
#     "pillow",
#     "torch",
#     "torchvision",
#     "pandas",
#     "plotext",
# ]
# ///
import glob
import math
import operator
import os
import pathlib
import re
import shutil
import subprocess
import tarfile
import tempfile
import zipfile
from abc import ABC, abstractmethod
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor
from multiprocessing import Manager, Queue
from typing import Callable, Dict, Iterable, Tuple, Type, TypeVar

import py7zr
import rarfile
import typer
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
from typing_extensions import Annotated, Self

T = TypeVar("T", bound=Type["ArchiveBase"])

ARCHIVERS: Dict[str, Type["ArchiveBase"]] = {}


def register_archiver(*filetypes: str) -> Callable[[T], T]:
    """Decorator to register archiver classes."""

    def register(cls: T) -> T:
        for filetype in filetypes:
            ARCHIVERS[filetype] = cls
        return cls

    return register


def create_chapter_zip(chapter_data: Tuple[int, str, str, str]) -> str:
    """Create a single chapter ZIP file"""
    idx, chapter_files, current_output_dir, input_dir_for_zip = chapter_data
    out_file = os.path.join(current_output_dir, f"Chapter {idx:03d}.cbz")

    with zipfile.ZipFile(out_file, "w", compression=zipfile.ZIP_STORED) as zf:
        for fname in chapter_files:
            full_path = os.path.join(input_dir_for_zip, fname)
            zf.write(full_path, arcname=fname)

    return out_file


def alphanum_key(s: str) -> list[str | int]:
    """
    Split a string into a list of strings and integers for natural sorting.
    """
    return [int(text) if text.isdigit() else text for text in re.split("([0-9]+)", s)]


def _split_image_iterative(img: Image.Image, size_threshold: int) -> list[Image.Image]:
    """
    Iteratively splits an image horizontally until all resulting image portions are below size_threshold.
    """
    result_images: list[Image.Image] = []
    # Use a list as a stack for images to be processed
    images_to_process = [img]

    while images_to_process:
        current_img = images_to_process.pop()
        width, height = current_img.size
        if width * height < size_threshold:
            result_images.append(current_img)
        else:
            # Split and add halves back to the stack
            middle = height // 2
            top_half = current_img.crop((0, 0, width, middle))
            bottom_half = current_img.crop((0, middle, width, height))
            # Add bottom_half first so top_half is processed next (LIFO)
            images_to_process.append(bottom_half)
            images_to_process.append(top_half)
    return result_images


def split_images(
    images: Iterable[Image.Image], size_threshold: int = 5_000_000
) -> list[Image.Image]:
    return sum([_split_image_iterative(i, size_threshold) for i in images], [])


def resize_image(img: Image.Image, size_threshold: int) -> Image.Image:
    """
    Resize an image proportionally so that its total number of pixels is below or equal to size_threshold.
    If the image is already within the threshold, it is returned unchanged.
    """
    width, height = img.size
    if width * height <= size_threshold:
        return img
    scale_factor = math.sqrt(size_threshold / (width * height))
    new_width = max(1, int(width * scale_factor))
    new_height = max(1, int(height * scale_factor))
    return img.resize((new_width, new_height), Image.Resampling.LANCZOS)


def resize_images(
    images: Iterable[Image.Image], size_threshold: int = 5_000_000
) -> list[Image.Image]:
    return [resize_image(image, size_threshold) for image in images]


# Base class for archives.
class ArchiveBase(ABC):
    IMG_EXTENSIONS: set[str] = {
        ".jpeg",
        ".jpg",
        ".png",
        ".tiff",
        ".tif",
        ".bmp",
        ".webp",
        ".heif",
        ".heic",
        ".jxl",
        ".avif",
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
            images: list[Tuple[str, Image.Image]] = sorted(
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

        cmd: list[str] = ["rar", "a", "-idq", "-ep1", str(dest)] + glob.glob(
            str(source_dir / "*")
        )
        subprocess.run(cmd, cwd=source_dir, check=True)

    def get_images(self: Self) -> list[Image.Image]:
        with rarfile.RarFile(self.path) as rf:
            images: list[Tuple[str, Image.Image]] = sorted(
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
            images: list[Tuple[str, Image.Image]] = sorted(
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


def _process_chapter_item_worker(
    chapter_path: pathlib.Path,
    output_dir: pathlib.Path,
    size_threshold: int,
    process_func: Callable[[Iterable[Image.Image], int], list[Image.Image]],
    progress_queue: Queue,
) -> None:
    """
    Worker function to process a single chapter/file in a separate process.
    Sends progress updates and errors back to the main process via a queue.
    """
    try:
        archiver = archiver_factory(chapter_path)
        if not archiver:
            progress_queue.put(
                {
                    "type": "error",
                    "chapter_name": chapter_path.name,
                    "message": f"Unsupported file type for {chapter_path.name}",
                }
            )
            return

        original_images = archiver.get_images()
        output_chapter_dir = output_dir / chapter_path.stem
        if output_chapter_dir.exists():
            shutil.rmtree(output_chapter_dir)

        max_image_size = max(
            [operator.mul(img.size[0], img.size[1]) for img in original_images],
            default=0,
        )

        if max_image_size < size_threshold:
            archiver.extract(output_chapter_dir)
            progress_queue.put(
                {
                    "type": "chapter_done",
                    "chapter_name": chapter_path.name,
                    "total_images": len(original_images),
                }
            )
        else:
            converted_images = process_func(original_images, size_threshold)
            output_chapter_dir.mkdir(exist_ok=True, parents=True)

            for num, image in enumerate(converted_images, 1):
                output_filepath = output_chapter_dir / f"{num:03}.webp"
                image.convert("RGB").save(
                    str(output_filepath), format="webp", quality=90
                )
                progress_queue.put(
                    {
                        "type": "image_saved",
                        "chapter_name": chapter_path.name,
                        "image_filename": f"{num:03}.webp",
                        "total_images": len(converted_images),
                    }
                )
            progress_queue.put(
                {
                    "type": "chapter_done",
                    "chapter_name": chapter_path.name,
                    "total_images": len(converted_images),
                }
            )

    except Exception as e:
        progress_queue.put(
            {
                "type": "error",
                "chapter_name": chapter_path.name,
                "message": str(e),
            }
        )


# ==============================================================
# CLI GROUP DEFINITION (Both Subcommands)
# ==============================================================


app = typer.Typer(add_completion=True)


# ----- CONVERT SUBCOMMAND -----
@app.command()
def convert(
    directories: Annotated[
        list[pathlib.Path],
        typer.Argument(
            exists=True, file_okay=False, dir_okay=True, help="Directories to convert."
        ),
    ],
    target_ext: Annotated[
        str,
        typer.Option(
            "--to",
            help=f"Target filetype extension (without the dot). Choices: {[i.lstrip('.') for i in ARCHIVERS if i != '/' and i.startswith('.cb')]}",
        ),
    ],
):
    """
    Convert different archive formats (cbr,cbz,etc..).
    """
    console = Console()
    target_ext = f".{target_ext.lower()}"
    if target_ext not in ARCHIVERS:
        console.print(f"[red]Target extension {target_ext} is not supported.[/red]")
        raise typer.Exit(code=1)

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


# ----- Clamp SUBCOMMAND -----
@app.command()
def clamp(
    input_dir: Annotated[
        pathlib.Path,
        typer.Argument(
            exists=True,
            file_okay=True,
            dir_okay=True,
            help="Input directory or file to process.",
        ),
    ],
    output_dir: Annotated[
        pathlib.Path,
        typer.Option(
            "-o",
            "--output-dir",
            help="Output directory to store results in",
        ),
    ] = pathlib.Path("Results"),
    size_threshold: Annotated[
        int,
        typer.Option(
            "-s",
            "--size-threshold",
            help="Maximum size (in total pixels) for resulting images",
        ),
    ] = 5000000,
    approach: Annotated[
        str,
        typer.Option(
            "-a",
            "--approach",
            help="Approach to enforce size threshold: 'split' to split images in half or 'resize' to scale images down",
            case_sensitive=False,
        ),
    ] = "split",
    num_workers: Annotated[
        int,
        typer.Option(
            "-w",
            "--workers",
            help="Number of worker processes to use for parallel processing. Defaults to the number of CPU cores.",
        ),
    ] = os.cpu_count() or 1,  # Ensure default is always an int
):
    """
    clamp image sizes in comic archives to all be under a size threshold.
    """
    console = Console()
    output_dir.mkdir(parents=True, exist_ok=True)

    # Ensure we don't write to the same directory we're reading from.
    if output_dir.samefile(input_dir):
        console.print(
            "[red]Cannot save into the same directory you're reading from[/red]"
        )
        raise typer.Exit(code=1)
    if size_threshold <= 500000:
        console.print("[red]Cannot make images smaller than 500,000 pixels[/red]")
        raise typer.Exit(code=1)

    # Map approach names to processing functions.
    process_func: Callable[[Iterable[Image.Image], int], list[Image.Image]] = {
        "split": split_images,
        "resize": resize_images,
    }[approach]

    # Determine items to process: either a single file or all files in a directory
    if input_dir.is_file():
        chapters_to_process = [input_dir]
    else:
        all_items = sorted(input_dir.iterdir(), key=lambda x: alphanum_key(str(x)))
        chapters_to_process = [
            item for item in all_items if archiver_factory(item) is not None
        ]

    if not chapters_to_process:
        console.print("[blue]No supported files or directories to process.[/blue]")
        return

    # Use a multiprocessing Manager to create a queue for progress updates
    with Manager() as manager:
        progress_queue = manager.Queue()
        image_tasks = {}  # To store rich progress sub-task IDs for images within a chapter

        with Progress(
            SpinnerColumn("dots2"),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(bar_width=None),
            TaskProgressColumn(),
            MofNCompleteColumn(),
            TimeElapsedColumn(),
            TimeRemainingColumn(),
            transient=False,  # Keep progress bar visible until all tasks are done
            console=console,
        ) as pb:
            main_task = pb.add_task(
                "[green]Overall Progress[/green]", total=len(chapters_to_process)
            )

            # Submit tasks to the ProcessPoolExecutor
            with ProcessPoolExecutor(max_workers=num_workers) as executor:
                futures = [
                    executor.submit(
                        _process_chapter_item_worker,
                        chapter_path=chapter_path,
                        output_dir=output_dir,
                        size_threshold=size_threshold,
                        process_func=process_func,
                        progress_queue=progress_queue,
                    )
                    for chapter_path in chapters_to_process
                ]

                # Monitor the queue for progress updates
                processed_chapters_count = 0
                while processed_chapters_count < len(chapters_to_process):
                    message = progress_queue.get()
                    chapter_name = message["chapter_name"]

                    if message["type"] == "image_saved":
                        if chapter_name not in image_tasks:
                            # Create a new sub-task for this chapter's images if it doesn't exist
                            image_tasks[chapter_name] = pb.add_task(
                                f"\t[cyan]{chapter_name}[/cyan]",
                                total=message["total_images"],
                                parent=main_task,
                                visible=True,
                            )
                        pb.update(
                            image_tasks[chapter_name],
                            advance=1,
                            description=f"\t[cyan]{chapter_name} - {message['image_filename']}[/cyan]",
                        )
                    elif message["type"] == "chapter_done":
                        if chapter_name in image_tasks:
                            pb.remove_task(image_tasks[chapter_name])
                            del image_tasks[chapter_name]
                        pb.update(
                            main_task,
                            advance=1,
                            description=f"[green]{chapter_name} processed[/green]",
                        )
                        processed_chapters_count += 1
                    elif message["type"] == "error":
                        console.print(
                            f"[red]Error processing {chapter_name}: {message['message']}[/red]"
                        )
                        # Still advance the main task for errors to ensure progress completes
                        pb.update(
                            main_task,
                            advance=1,
                            description=f"[red]{chapter_name} failed[/red]",
                        )
                        processed_chapters_count += 1

                # Ensure all futures are completed (even if errors occurred)
                for future in futures:
                    future.result()  # This will re-raise exceptions from workers if any occurred

    console.print("[green]Clamping complete.[/green]")


# ----- CREATE-CHAPTERS SUBCOMMAND -----
@app.command(
    name="create-chapters",
    help="Faster chapter splitting via batching with multiple target images using AI feature extraction.",
)
def create_chapters_command(
    input_dir: Annotated[
        str,
        typer.Argument(
            ...,
            help="Path to the directory containing comic images.",
            rich_help_panel="Input Options",
        ),
    ],
    chapter_break_images: Annotated[
        list[str],
        typer.Argument(
            ...,
            help="Filenames of images within the input directory that mark chapter breaks.",
            rich_help_panel="Input Options",
        ),
    ],
    output_dir: str | None = typer.Option(
        None,
        help="Directory where the generated CBZ chapter files will be saved. Defaults to 'chapters' subdirectory within input_dir if None, or current directory if input_dir is '.'.",
        rich_help_panel="Output Options",
    ),
    threshold: float = typer.Option(
        0.9,
        min=0.0,
        max=1.0,
        help="Similarity threshold for matching (0.0 to 1.0).",
        rich_help_panel="Processing Options",
    ),
    batch_size: int = typer.Option(
        16,
        min=1,
        help="Batch size for feature extraction.",
        rich_help_panel="Processing Options",
    ),
    num_workers: int = typer.Option(
        8,
        min=1,
        help="Number of worker threads for data loading and CBZ creation.",
        rich_help_panel="Processing Options",
    ),
    plot: bool = typer.Option(
        False,
        "--plot",
        help="Plot similarity values and exit.",
        rich_help_panel="Output Options",
    ),
):
    """
    Identifies chapter breaks in a directory of comic images based on similarity to target images
    and creates CBZ archives for each chapter.
    """
    import numpy as np
    import pandas as pd
    import plotext as plt
    import torch
    import torch.nn as nn
    from PIL import Image
    from rich.console import Console
    from rich.progress import (
        BarColumn,
        MofNCompleteColumn,
        Progress,
        TextColumn,
        TimeRemainingColumn,
    )
    from rich.table import Table
    from torch.utils.data import DataLoader, Dataset
    from torchvision import models, transforms
    from torchvision.models import efficientnet

    class ImageDataset(Dataset):
        def __init__(self, filepaths, transform):
            self.filepaths = filepaths
            self.transform = transform

        def __len__(self):
            return len(self.filepaths)

        def __getitem__(self, idx):
            path = self.filepaths[idx]
            img = Image.open(path).convert("RGB")
            return self.transform(img), os.path.basename(path)

    def extract_features(
        filepaths: list,
        model: nn.Module,
        transform: transforms.Compose,
        device: torch.device,
        batch_size: int,
        num_workers: int,
        console: Console,
    ) -> Tuple[list, np.ndarray]:
        ds = ImageDataset(filepaths, transform)
        loader = DataLoader(
            ds,
            batch_size=batch_size,
            num_workers=num_workers,
            pin_memory=True,
            prefetch_factor=2,
            shuffle=False,
            drop_last=False,
            persistent_workers=True,
        )
        all_feats: list[np.ndarray] = []
        all_names: list[str] = []
        model.eval()
        with torch.no_grad():
            with Progress(
                TextColumn("[progress.description]{task.description}"),
                BarColumn(),
                MofNCompleteColumn(),
                TextColumn("•"),
                TimeRemainingColumn(),
                console=console,
            ) as progress_display:
                feature_task_id = progress_display.add_task(
                    "Computing similarity", total=len(ds)
                )
                for imgs, names_batch in loader:
                    imgs: torch.Tensor = imgs.to(device)
                    feats = model(imgs)
                    feats = feats.view(feats.size(0), -1)
                    feats = feats / feats.norm(dim=1, keepdim=True)
                    all_feats.append(feats.cpu())
                    all_names.extend(names_batch)
                    progress_display.update(feature_task_id, advance=imgs.size(0))
        return all_names, torch.cat(all_feats, dim=0).numpy()

    console = Console()

    # Determine and create output directory
    if output_dir is None:
        if input_dir == ".":
            # If input is current directory, default output to a 'chapters' subdir in current dir
            final_output_dir = os.path.join(os.getcwd(), "chapters")
        else:
            # Default output to 'chapters' subdirectory within input_dir
            final_output_dir = os.path.join(input_dir, "chapters")
    else:
        final_output_dir: str = output_dir

    os.makedirs(final_output_dir, exist_ok=True)
    console.print(
        f"Output directory: [bold green]{os.path.abspath(final_output_dir)}[/bold green]"
    )

    # Check targets
    target_paths: list[str] = []
    for target_image_name in chapter_break_images:
        target_path = os.path.join(input_dir, target_image_name)
        if not os.path.isfile(target_path):
            console.print(
                f"[bold red]Error: Target image not found: {target_path}[/bold red]"
            )
            raise typer.Exit(code=1)
        target_paths.append(target_path)

    console.print(
        f"Using [bold cyan]{len(chapter_break_images)}[/bold cyan] chapter break images: [cyan]{', '.join(chapter_break_images)}[/cyan]"
    )

    # Gather files
    files = sorted(
        [
            f
            for f in os.listdir(input_dir)
            if f.lower().endswith(
                (
                    ".avif",
                    ".bmp",
                    ".gif",
                    ".jpeg",
                    ".jpg",
                    ".jxl",
                    ".pgm",
                    ".png",
                    ".tif",
                    ".tiff",
                    ".webp",
                )
            )
        ],
        key=alphanum_key,
    )
    paths = [os.path.join(input_dir, f) for f in files]

    preprocess = transforms.Compose(
        [
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )

    backbone = models.efficientnet_b0(
        weights=efficientnet.EfficientNet_B0_Weights.DEFAULT
    )
    model = nn.Sequential(
        backbone.features,
        nn.AdaptiveAvgPool2d(1),
        nn.Flatten(),
    )
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    if torch.cuda.device_count() > 1:
        model = nn.DataParallel(model)
    model.to(device)
    console.print(f"Using device [bold green]{device}[/bold green]")

    # Batch feature extraction
    names, feats = extract_features(
        paths, model, preprocess, device, batch_size, num_workers, console
    )

    # Extract target features
    target_feats = []
    for target_image in chapter_break_images:
        target_idx = names.index(target_image)
        target_feats.append(feats[target_idx])

    target_feats = np.array(target_feats)  # Shape: (num_targets, feature_dim)

    # Compute similarities against all targets and take the maximum
    all_sims = feats @ target_feats.T  # Shape: (num_images, num_targets)
    max_sims = np.max(all_sims, axis=1)  # Take max similarity across all targets

    # Find which target each image is most similar to
    best_target_idx = np.argmax(all_sims, axis=1)
    best_target_names = [chapter_break_images[idx] for idx in best_target_idx]

    labels = ["similar" if s >= threshold else "not similar" for s in max_sims]

    # Build DataFrame
    df = pd.DataFrame(
        {
            "filename": names,
            "cosine_similarity": max_sims,
            "best_match_target": best_target_names,
            "label": labels,
        }
    )
    df.sort_values("cosine_similarity", ascending=False, inplace=True)

    # Find matches
    intro_set = set(df[df["label"] == "similar"]["filename"])
    indices = [i for i, f in enumerate(files) if f in intro_set]
    console.print(
        f"Found [bold magenta]{len(indices)}[/bold magenta] matches for threshold [yellow]{threshold}[/yellow]"
    )

    # Show breakdown by target
    similar_df = df[df["label"] == "similar"]
    target_counts = similar_df["best_match_target"].value_counts()

    table = Table(
        title="[bold]Matches per Target Image[/bold]",
        title_style="none",
        show_header=True,
        header_style="bold blue",
    )
    table.add_column("Target Image", style="cyan", no_wrap=True)
    table.add_column("Matches", justify="right", style="magenta")
    for target, count in target_counts.items():
        table.add_row(target, str(count))
    console.print(table)

    if plot:
        # Plotting similarity values
        console.print("\n[bold]Plotting Similarity Values (Highest to Lowest)[/bold]")
        plt.clf()  # Clear previous plot data
        plt.title("Similarity Scores (Highest to Lowest)")
        plt.bar(df["cosine_similarity"].values)
        plt.show()
        return

    if len(indices) < 1:
        console.print("[yellow]No matches found; nothing to split.[/yellow]")
        return

    # Split chapters
    split_points = indices[1:]
    chapters = []
    prev = 0
    for pt in split_points:
        chapters.append(files[prev:pt])
        prev = pt
    chapters.append(files[prev:])

    # Prepare chapter data for parallel processing
    chapter_data = [
        (idx + 1, chap, final_output_dir, input_dir)
        for idx, chap in enumerate(chapters)
    ]  # Pass input_dir for zipping

    # Write CBZs in parallel using ThreadPoolExecutor
    with ThreadPoolExecutor(max_workers=num_workers) as executor:
        with Progress(
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            MofNCompleteColumn(),
            TimeRemainingColumn(),
            console=console,
        ) as progress_display:
            cbz_task_id = progress_display.add_task(
                "Creating CBZ files", total=len(chapter_data)
            )
            for _ in executor.map(create_chapter_zip, chapter_data):
                progress_display.update(cbz_task_id, advance=1)

    console.print(
        f"[bold green]Successfully created {len(chapters)} chapters.[/bold green]"
    )


if __name__ == "__main__":
    app()
