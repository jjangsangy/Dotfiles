#!/usr/bin/env -S uv run --extra-index-url https://download.pytorch.org/whl/cu124
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "torch",
#     "faster-whisper>=1.1.1",
#     "pysrt",
#     "rich",
#     "typer",
# ]
# ///

from __future__ import annotations

import os
import sys

if "UV_ENV_SET" not in os.environ:
    from importlib.metadata import distribution

    try:
        cublas_dist = distribution("nvidia-cublas-cu12")
        cudnn_dist = distribution("nvidia-cudnn-cu12")

        cublas_lib_path = os.path.join(cublas_dist.locate_file("nvidia/cublas/lib"))
        cudnn_lib_path = os.path.join(cudnn_dist.locate_file("nvidia/cudnn/lib"))

        new_ld_library_path = f"{cublas_lib_path}:{cudnn_lib_path}"

        if "LD_LIBRARY_PATH" in os.environ:
            new_ld_library_path = (
                f"{new_ld_library_path}:{os.environ['LD_LIBRARY_PATH']}"
            )

        # Set the environment for the re-executed script
        os.environ["LD_LIBRARY_PATH"] = new_ld_library_path
        os.environ["UV_ENV_SET"] = "1"

        # Re-execute the script with the correct environment
        os.execv(sys.executable, ["python"] + sys.argv)
        sys.exit()  # Should not be reached

    except Exception as e:
        print(f"Error setting up environment: {e}")
        sys.exit(1)


import pathlib
from enum import Enum
from typing import TYPE_CHECKING, Annotated, List

import pysrt
import typer

if TYPE_CHECKING:
    from faster_whisper.transcribe import Segment
from rich.console import Console
from rich.panel import Panel
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
from rich.text import Text

console = Console()
app = typer.Typer(
    help="Generate subtitles from media files using Faster Whisper",
    pretty_exceptions_show_locals=False,
)


class Task(str, Enum):
    TRANSCRIBE = "transcribe"
    TRANSLATE = "translate"


class Device(str, Enum):
    GPU = "cuda"
    CPU = "cpu"


class ComputeType(str, Enum):
    FLOAT16 = "float16"
    INT8 = "int8"
    INT8_FLOAT16 = "int8_float16"
    INT16 = "int16"
    FLOAT32 = "float32"


def get_available_models_for_completion() -> list[str]:
    """
    Returns a list of available models for autocompletion.
    Avoids importing faster_whisper if only generating completions.
    """
    if os.environ.get("_TYPER_COMPLETE_ARGS"):
        # Return a static list for fast autocompletion
        return ["tiny", "base", "small", "medium", "large", "large-v2", "large-v3"]
    else:
        # Only import and call available_models if not in completion context
        from faster_whisper.utils import available_models

        return available_models()


def get_supported_languages() -> list[str]:
    """
    Returns a list of supported languages for autocompletion.
    """
    return [
        "ab",
        "af",
        "ak",
        "am",
        "an",
        "ar",
        "as",
        "av",
        "ay",
        "az",
        "ba",
        "be",
        "bg",
        "bi",
        "bn",
        "br",
        "ca",
        "ce",
        "ch",
        "co",
        "cr",
        "cs",
        "cu",
        "cv",
        "cy",
        "da",
        "de",
        "dz",
        "ee",
        "el",
        "en",
        "eo",
        "es",
        "et",
        "eu",
        "fa",
        "fi",
        "fj",
        "fo",
        "fr",
        "fy",
        "ga",
        "gd",
        "gl",
        "gn",
        "gu",
        "gv",
        "ha",
        "he",
        "hi",
        "ho",
        "hr",
        "ht",
        "hu",
        "hy",
        "id",
        "ig",
        "ik",
        "io",
        "iu",
        "ja",
        "jv",
        "ka",
        "kg",
        "ki",
        "kj",
        "kk",
        "km",
        "kn",
        "ko",
        "ku",
        "kv",
        "kw",
        "ky",
        "la",
        "lb",
        "lg",
        "li",
        "ln",
        "lo",
        "lt",
        "lu",
        "lv",
        "mg",
        "mh",
        "mi",
        "mk",
        "ml",
        "mn",
        "ms",
        "mt",
        "my",
        "na",
        "nd",
        "ne",
        "ng",
        "nl",
        "no",
        "nr",
        "nv",
        "ny",
        "oc",
        "om",
        "os",
        "pa",
        "pi",
        "pl",
        "ps",
        "pt",
        "qu",
        "rm",
        "rn",
        "ro",
        "ru",
        "rw",
        "sa",
        "sc",
        "sd",
        "sg",
        "sh",
        "si",
        "si",
        "sk",
        "sl",
        "sm",
        "sn",
        "so",
        "sq",
        "sr",
        "ss",
        "st",
        "su",
        "sv",
        "sw",
        "ta",
        "te",
        "tg",
        "th",
        "tk",
        "tl",
        "tr",
        "tt",
        "ty",
        "ug",
        "uk",
        "ur",
        "uz",
        "vi",
        "wa",
        "wo",
        "xh",
        "yi",
        "yo",
        "za",
        "zh-Hans",
        "zh-Hant",
        "zh",
        "zu",
    ]


def create_srt(
    chunks: list["Segment"], text_cutoff_length: int = 400
) -> "pysrt.SubRipFile":
    """
    Take chunks from the output of the whisper model and convert it into a SRT time.

    Args:
        chunks: List of Segment objects containing timing and text information
        text_cutoff_length: Maximum length of text per subtitle (default: 400)

    Returns:
        pysrt.SubRipFile: SRT file object containing the subtitles
    """
    subtitles = pysrt.SubRipFile()
    for idx, item in enumerate(chunks, start=1):
        start_time, end_time = item.start, item.end

        if not (start_time and end_time):
            continue

        if len(item.text) >= text_cutoff_length:
            continue

        start_time = pysrt.SubRipTime.from_ordinal(start_time * 1000)
        end_time = pysrt.SubRipTime.from_ordinal(end_time * 1000)

        subtitle_item = pysrt.SubRipItem(
            index=idx, start=start_time, end=end_time, text=item.text
        )

        subtitles.append(subtitle_item)
    return subtitles


def is_media_file(path: pathlib.Path) -> bool:
    extensions: set[str] = {
        ".m4a",
        ".mp3",
        ".flac",
        ".ogg",
        ".wav",
        ".wma",
        ".aac",
        ".alac",
        ".opus",
        ".webm",
        ".ac3",
        ".mkv",
        ".mp4",
        ".wmv",
        ".m4v",
        ".avi",
        ".flv",
        ".mov",
        ".amv",
        ".mpg",
        ".mpeg",
        ".f4v",
    }
    return path.suffix in extensions


def find_media_files(
    path: pathlib.Path, skip_exists: bool = True
) -> list[pathlib.Path]:
    """
    Iterate over a directory and find all files with media extension types.

    Args:
        path: Directory path to search for media files
        skip_exists: Skip files that already have corresponding .srt files

    Returns:
        list[pathlib.Path]: List of paths to media files
    """
    files = [f for f in path.iterdir() if is_media_file(f)]
    if skip_exists:
        return list(filter(lambda f: not f.with_suffix(".srt").exists(), files))
    return files


def run_pipeline(
    paths: list[pathlib.Path],
    model_size: str = "large-v2",
    language: str = "ja",
    task: str = "translate",
    device: str = "cuda",
    compute_type: str = "float16",
    min_silence_duration: int = 500,
    text_cutoff_length: int = 400,
    skip_existing: bool = True,
) -> None:
    """
    Run whisper pipeline and save the srt files.

    Args:
        paths: Files or directories containing media files
        model_size: Size of the Whisper model to use
        language: Language code for transcription
        task: Task type ('transcribe' or 'translate')
        device: Device to run model on ('cuda' or 'cpu')
        compute_type: Compute type for model
        min_silence_duration: Minimum silence duration in ms
        text_cutoff_length: Maximum length of text per subtitle
        skip_existing: Skip files that already have .srt files
    """
    from faster_whisper import WhisperModel

    # Print configuration
    config_text = Text()
    config_text.append("Configuration:\n", style="bold cyan")
    config_text.append(f"• Model: {model_size}\n", style="green")
    config_text.append(f"• Device: {device} ({compute_type})\n", style="green")
    config_text.append(f"• Language: {language}\n", style="green")
    config_text.append(f"• Task: {task}\n", style="green")
    config_text.append(f"• Min Silence: {min_silence_duration}ms\n", style="green")
    console.print(Panel(config_text, title="Whisper Subtitles Generator"))

    # Get media files
    files = []
    for path in paths:
        if path.is_dir():
            files.extend(find_media_files(path))
        elif path.is_file() and is_media_file(path):
            files.append(path)
        else:
            console.print(f"[yellow]Filepath {path} does not exist")

    if not files:
        console.print("[yellow]No media files found to process!")
        return

    # Initialize model
    with console.status("[bold green]Loading Whisper model...") as status:
        model = WhisperModel(model_size, device=device, compute_type=compute_type)
        status.update("[bold green]Model loaded successfully!")

    console.print(f"\nFound [cyan]{len(files)}[/cyan] media files to process.\n")

    # Create progress bars
    progress = Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(bar_width=None),
        TaskProgressColumn(),
        MofNCompleteColumn(),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
        console=console,
    )

    # Process each media file
    with progress:
        overall_task = progress.add_task(
            "[cyan]Overall Progress[/cyan]", total=len(files)
        )
        for f in files:
            segments, info = model.transcribe(
                str(f),
                language=language,
                task=task,
                vad_filter=True,
                vad_parameters=dict(min_silence_duration_ms=min_silence_duration),
            )

            # Initialize a progress bar for the current file
            media_task = progress.add_task(
                f"[green]Processing {f.name}[/green]", total=info.duration
            )

            # Forward pass
            chunks = []
            timestamps = 0.0
            for seg in segments:
                chunks.append(seg)
                progress.update(media_task, advance=seg.end - timestamps)
                timestamps = seg.end

            # Handle remaining silence
            if timestamps < info.duration:
                progress.update(media_task, advance=info.duration - timestamps)

            srt_file = create_srt(chunks, text_cutoff_length=text_cutoff_length)
            output_path = f.with_suffix(".srt")
            srt_file.save(str(output_path))
            console.print(f"✓ Saved subtitles to: [cyan]{output_path}[/cyan]")

            # update progress
            progress.update(overall_task, advance=1)
            progress.remove_task(media_task)

    console.print("\n[bold green]✓ All files processed successfully![/bold green]")


@app.command()
def main(
    paths: Annotated[
        List[pathlib.Path],
        typer.Argument(
            help="Files or directories containing media files to process",
        ),
    ],
    model_size: Annotated[
        str,
        typer.Option(
            help="Size of the Whisper model to use",
            rich_help_panel="Configuration",
            autocompletion=get_available_models_for_completion,
        ),
    ] = "large-v2",
    language: Annotated[
        str,
        typer.Option(
            help="Language code for transcription",
            rich_help_panel="Configuration",
            autocompletion=get_supported_languages,
        ),
    ] = "ja",
    task: Annotated[
        Task,
        typer.Option(
            help="Task to perform",
            rich_help_panel="Configuration",
        ),
    ] = Task.TRANSLATE,
    device: Annotated[
        Device,
        typer.Option(
            help="Device to run the model on",
            rich_help_panel="Configuration",
        ),
    ] = Device.GPU,
    compute_type: Annotated[
        ComputeType,
        typer.Option(
            help="Compute type for the model",
            rich_help_panel="Configuration",
        ),
    ] = ComputeType.FLOAT16,
    min_silence_duration: Annotated[
        int,
        typer.Option(
            help="Minimum silence duration in milliseconds",
            rich_help_panel="Configuration",
        ),
    ] = 500,
    text_cutoff_length: Annotated[
        int,
        typer.Option(
            help="Maximum length of text per subtitle",
            rich_help_panel="Configuration",
        ),
    ] = 400,
    skip_existing: Annotated[
        bool,
        typer.Option(
            "--skip-existing/--no-skip-existing",
            help="Skip files that already have corresponding .srt files",
            rich_help_panel="Configuration",
        ),
    ] = True,
):
    """Generate subtitles from media files using Faster Whisper."""
    # Import available_models here to ensure it's only loaded when the script is run, not for autocompletion
    from faster_whisper.utils import available_models

    if model_size not in available_models():
        raise typer.BadParameter(
            f"Invalid model size: {model_size}. Available models are: {', '.join(available_models())}"
        )

    run_pipeline(
        paths=paths,
        model_size=model_size,
        language=language,
        task=task.value,
        device=device.value,
        compute_type=compute_type.value,
        min_silence_duration=min_silence_duration,
        text_cutoff_length=text_cutoff_length,
        skip_existing=skip_existing,
    )


if __name__ == "__main__":
    app()
