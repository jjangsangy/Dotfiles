#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "faster-whisper",
#     "pysrt",
#     "rich",
# ]
# ///

import argparse
import pathlib
from typing import List

import pysrt
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

from faster_whisper import WhisperModel
from faster_whisper.transcribe import Segment
from faster_whisper.utils import available_models


def create_srt(chunks: list[Segment], text_cutoff_length=400) -> pysrt.SubRipFile:
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


def find_audio_files(
    path: str | pathlib.Path, skip_exists: bool = True
) -> list[pathlib.Path]:
    """
    Iterate over a directory and find all files with audio extension types.

    Args:
        path: Directory path to search for audio files
        skip_exists: Skip files that already have corresponding .srt files

    Returns:
        list[pathlib.Path]: List of paths to audio files
    """
    extensions = {
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
    }
    files = [f for f in pathlib.Path(path).iterdir() if f.suffix in extensions]
    if skip_exists:
        files = list(filter(lambda f: not f.with_suffix(".srt").exists(), files))
    return files


def run_pipeline(
    file_dirs: List[str | pathlib.Path],
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
        file_dir: Directory containing audio files
        model_size: Size of the Whisper model to use
        language: Language code for transcription
        task: Task type ('transcribe' or 'translate')
        device: Device to run model on ('cuda' or 'cpu')
        compute_type: Compute type for model
        min_silence_duration: Minimum silence duration in ms
        text_cutoff_length: Maximum length of text per subtitle
        skip_existing: Skip files that already have .srt files
    """
    # Print configuration
    config_text = Text()
    config_text.append("Configuration:\n", style="bold cyan")
    config_text.append(f"• Model: {model_size}\n", style="green")
    config_text.append(f"• Device: {device} ({compute_type})\n", style="green")
    config_text.append(f"• Language: {language}\n", style="green")
    config_text.append(f"• Task: {task}\n", style="green")
    config_text.append(f"• Min Silence: {min_silence_duration}ms\n", style="green")
    console.print(Panel(config_text, title="Whisper Subtitles Generator"))

    # Initialize model
    with console.status("[bold green]Loading Whisper model...") as status:
        model = WhisperModel(model_size, device=device, compute_type=compute_type)
        status.update("[bold green]Model loaded successfully!")

    # Get audio files
    files = sum([find_audio_files(f, skip_exists=skip_existing) for f in file_dirs], [])
    if not files:
        console.print("[yellow]No audio files found to process!")
        return

    console.print(f"\nFound [cyan]{len(files)}[/cyan] audio files to process.\n")

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

    # Process each audio file
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
            audio_task = progress.add_task(
                f"[green]Processing {f.name}[/green]", total=info.duration
            )

            # Forward pass
            chunks = []
            timestamps = 0.0
            for seg in segments:
                chunks.append(seg)
                progress.update(audio_task, advance=seg.end - timestamps)
                timestamps = seg.end

            # Handle remaining silence
            if timestamps < info.duration:
                progress.update(audio_task, advance=info.duration - timestamps)

            srt_file = create_srt(chunks, text_cutoff_length=text_cutoff_length)
            output_path = f.with_suffix(".srt")
            srt_file.save(str(output_path))
            console.print(f"✓ Saved subtitles to: [cyan]{output_path}[/cyan]")

            # update progress
            progress.update(overall_task, advance=1)
            progress.remove_task(audio_task)

    console.print("\n[bold green]✓ All files processed successfully![/bold green]")


def main():
    parser = argparse.ArgumentParser(
        description="Generate subtitles from audio files using Faster Whisper"
    )

    # Required arguments
    parser.add_argument(
        "directories",
        type=str,
        nargs="+",
        help="Directories containing audio files to process",
    )

    # Optional arguments
    parser.add_argument(
        "--model-size",
        type=str,
        default="large-v2",
        choices=available_models(),
        help="Size of the Whisper model to use (default: large-v2)",
    )
    parser.add_argument(
        "--language",
        type=str,
        default="ja",
        help="Language code for transcription (default: ja)",
    )
    parser.add_argument(
        "--task",
        type=str,
        default="translate",
        choices=["transcribe", "translate"],
        help="Task to perform (default: translate)",
    )
    parser.add_argument(
        "--device",
        type=str,
        default="cuda",
        choices=["cuda", "cpu"],
        help="Device to run the model on (default: cuda)",
    )
    parser.add_argument(
        "--compute-type",
        type=str,
        default="float16",
        choices=["float16", "int8"],
        help="Compute type for the model (default: float16)",
    )
    parser.add_argument(
        "--min-silence",
        type=int,
        default=500,
        help="Minimum silence duration in milliseconds (default: 500)",
    )
    parser.add_argument(
        "--text-cutoff",
        type=int,
        default=400,
        help="Maximum length of text per subtitle (default: 400)",
    )
    parser.add_argument(
        "--no-skip-existing",
        action="store_false",
        dest="skip_existing",
        help="Process files even if .srt already exists",
    )
    args = parser.parse_args()

    # Run the pipeline with parsed arguments
    run_pipeline(
        file_dirs=args.directories,
        model_size=args.model_size,
        language=args.language,
        task=args.task,
        device=args.device,
        compute_type=args.compute_type,
        min_silence_duration=args.min_silence,
        text_cutoff_length=args.text_cutoff,
        skip_existing=args.skip_existing,
    )


if __name__ == "__main__":
    main()
