#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "torch",
#     "torchvision",
#     "pandas",
#     "pillow",
#     "rich",
#     "matplotlib",
#     "typer",
# ]
# ///

import os
import re
import zipfile
from concurrent.futures import ThreadPoolExecutor
from typing import List, Optional, Tuple

import typer


def alphanum_key(s: str) -> list:
    # Natural sort key
    return [int(text) if text.isdigit() else text for text in re.split(r"([0-9]+)", s)]


def create_chapter_zip(chapter_data: Tuple[int, str, str, str]) -> str:
    """Create a single chapter ZIP file"""
    idx, chapter_files, current_output_dir, input_dir_for_zip = chapter_data
    out_file = os.path.join(current_output_dir, f"Chapter {idx:03d}.cbz")

    with zipfile.ZipFile(out_file, "w", compression=zipfile.ZIP_STORED) as zf:
        for fname in chapter_files:
            full_path = os.path.join(input_dir_for_zip, fname)
            zf.write(full_path, arcname=fname)

    return out_file


app = typer.Typer(
    name="comic-create-chapters",
    help="Faster chapter splitting via batching with multiple target images using AI feature extraction.",
    add_completion=True,
)


@app.command()
def main(
    input_dir: str = typer.Argument(
        ...,
        help="Path to the directory containing comic images.",
        rich_help_panel="Input Options",
    ),
    chapter_break_images: List[str] = typer.Argument(
        ...,
        help="Filenames of images within the input directory that mark chapter breaks.",
        rich_help_panel="Input Options",
    ),
    output_dir: Optional[str] = typer.Option(
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
):
    """
    Identifies chapter breaks in a directory of comic images based on similarity to target images
    and creates CBZ archives for each chapter.
    """
    import numpy as np
    import pandas as pd
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

    # Model & Transforms
    # Moved imports and model initialization here to speed up Typer completion
    preprocess = transforms.Compose(
        [
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )

    backbone = models.efficientnet_b0(
        weights=models.efficientnet.EfficientNet_B0_Weights.DEFAULT
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
