#!/usr/bin/env python3

import argparse
import json
import logging
import operator
import os
import pathlib
import re
from typing import Any, Callable, Dict, Iterable, List, Union

from pymkv import MKVFile, MKVTrack

ShiftCheckerType = Callable[[MKVTrack], bool]

LOGLEVEL = os.environ.get("LOGLEVEL", "INFO").upper()

try:
    import coloredlogs

    coloredlogs.install(level=LOGLEVEL, fmt="[%(levelname)s] %(message)s")
except ImportError:
    logging.basicConfig(level=LOGLEVEL)


def audio_is_jpn(track: MKVTrack) -> bool:
    """
    determine if language is japanese
    """
    return (track.language or "") == "jpn"


def audio_is_eng(track: MKVTrack) -> bool:
    """
    determine if language is english
    """
    return (track.language or "") == "eng"


def sub_not_signs(track: MKVTrack) -> bool:
    """
    determine if a track is english and
    not (signs and songs) by inspecting the title
    """
    match = re.search(
        pattern=r"(signs|songs)",
        string=(track.track_name or ""),
        flags=re.RegexFlag.IGNORECASE,
    )
    return not match and track.language == "eng"


def sub_is_signs(track: MKVTrack) -> bool:
    """
    determine if a track is english and
    (signs and songs) by inspecting the title
    """
    match = re.search(
        pattern=r"(signs|songs)",
        string=(track.track_name or ""),
        flags=re.RegexFlag.IGNORECASE,
    )
    return bool(match) and track.language == "eng"


class MKVTrackEditor:
    """
    A class that changes the ordering of mkv audio and subtitle tracks.

    Ther ordering is determined by shifting tracks until a suitable
    track is found determined by checker functions.

    Checker functions can be provided which take in a `pymkv.MKVTrack`
    and returns a boolean response based on some criteria.
    When returning `True`, the track is marked as the default track if not set
    and shifting halts. When returning `False`, the track is moved to the bottom
    of the stack and shifting proceeds to the next track, any default
    track label is removed if set.
    """

    def __init__(
        self,
        file_path: Union[str, pathlib.Path],
        audio_shift_checker: ShiftCheckerType = audio_is_jpn,
        sub_shift_checker: ShiftCheckerType = sub_not_signs,
    ) -> None:
        self.mkv = MKVFile(str(file_path))
        self.shift_checker_funcs: Dict[str, ShiftCheckerType] = {
            "subtitles": sub_shift_checker,
            "audio": audio_shift_checker,
        }
        self.original_tracks = [track.__dict__.copy() for track in self.mkv.tracks]

    def __repr__(self) -> str:
        return json.dumps([i.__dict__ for i in self.mkv.tracks], indent=4)

    @staticmethod
    def groupby(iterable: Iterable, key: str) -> Dict[str, List[Any]]:
        """
        group iterable based on object attribute
        """
        getter = operator.attrgetter(key)
        items = {}
        for item in iterable:
            items.setdefault(getter(item), []).append(item)
        return items

    @property
    def edited(self) -> bool:
        """
        check if mkv track order has been modified
        """
        for original, track in zip(self.original_tracks, self.mkv.tracks):
            if original != track.__dict__:
                return True
        return False

    def print_track_order(self) -> None:
        """
        print out a table containing fields
            id, lang, type, default, name
        """
        logging.debug("id  lang  type       default name")
        for t in self.mkv.tracks:
            logging.debug(
                f"{t.track_id}   {t.language}   {t.track_type:10} {str(t.default_track):7} {t.track_name}"
            )

    def filter_tracks(self, **filters) -> List[MKVTrack]:
        tracks = self.mkv.tracks
        for key, value in filters.items():
            groups = self.groupby(tracks, key)
            tracks = groups.get(value, [])
            if not tracks:
                break
        return tracks

    def rearrange(self, track: MKVTrack) -> None:
        track_groups = self.groupby(self.mkv.tracks, key="track_type")
        track_type: str = track.track_type or ""
        group = track_groups.get(track_type, [])

        group.pop(group.index(track))
        group.append(track)

        self.mkv.tracks = self.mkv.flatten(
            [
                track_groups["video"],
                track_groups["audio"],
                track_groups["subtitles"],
                *[
                    v
                    for k, v in track_groups.items()
                    if k not in {"video", "audio", "subtitles"}
                ],
            ]
        )

    def shift_tracks(self, track_type: str = "subtitles") -> None:
        """
        recursively shift track
        """
        check = self.shift_checker_funcs[track_type]
        tracks = self.filter_tracks(track_type=track_type)

        if len(tracks) <= 1:
            logging.info(f"Only one '{track_type}' track exists. Will not shift")
            return

        if not any(map(check, tracks)):
            logging.info(f"No '{track_type}' track return true for '{check.__name__}'")
            return

        track = tracks[0]
        if check(track) is False:
            logging.debug(
                f'moving  {track.language} {track_type:3.3} track {track.track_id} "{track.track_name}"'
            )

            # shifted track should no longer be default
            if track.default_track:
                logging.debug(
                    f"setting off {track.track_type:3.3} track {track.track_id} as default"
                )
                track.default_track = False

            self.rearrange(track)
            self.shift_tracks(track_type=track_type)

        # break out condition track should be set to default
        elif not track.default_track:
            logging.debug(
                f"setting on  {track.track_type:3.3} track {track.track_id} as default"
            )
            track.default_track = True

    def shift_audio(self) -> bool:
        """
        shift only audio tracks
        """
        self.shift_tracks(track_type="audio")
        return self.edited

    def shift_subtitles(self) -> bool:
        """
        shift only subtitle tracks
        """
        self.shift_tracks(track_type="subtitles")
        return self.edited

    def shift_all(self) -> bool:
        """
        shift both audio and subtitle tracks
        """
        self.shift_tracks(track_type="subtitles")
        self.shift_tracks(track_type="audio")
        return self.edited


def cli() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="transforms mkv files with reordered audio and subtitle tracks",
    )
    parser.add_argument(
        "files",
        type=pathlib.Path,
        nargs="+",
        help="relative or absolute path to the mkv files to mux",
    )
    parser.add_argument(
        "-d",
        "--destdir",
        default=pathlib.Path("muxed"),
        type=pathlib.Path,
        help="output directory to place muxed files",
    )
    parser.add_argument(
        "-r",
        "--replace",
        action="store_true",
        help="replaces the original files with muxed files",
    )

    sub_dub_group = parser.add_mutually_exclusive_group()
    sub_dub_group.add_argument(
        "--sub",
        action="store_true",
        help="set ordering with japanese audio and full english subtitles [default]",
    )
    sub_dub_group.add_argument(
        "--dub",
        action="store_true",
        help="set ordering with english audio and signs and songs english subtitles",
    )
    return parser.parse_args()


def main():
    args = cli()
    args.destdir.mkdir(parents=True, exist_ok=True)

    for file in args.files:
        if not file.exists() or not file.match("*.mkv"):
            logging.warning(f"skipping '{file}', is not an mkv")
            continue

        if args.dub:
            mkv = MKVTrackEditor(
                file_path=file,
                audio_shift_checker=audio_is_eng,
                sub_shift_checker=sub_is_signs,
            )
        # assume it is sub if not dub
        else:
            mkv = MKVTrackEditor(
                file_path=file,
                audio_shift_checker=audio_is_jpn,
                sub_shift_checker=sub_not_signs,
            )

        if mkv.shift_all():
            logging.info(f"muxing '{file}'")
            mkv.print_track_order()
            mkv.mkv.mux(str(args.destdir / file.name), silent=True)
            if args.replace:
                (args.destdir / file.name).replace(file)
        else:
            logging.warning(f"skipping '{file}', tracks are already in correct order")
    if args.replace:
        args.destdir.rmdir()


if __name__ == "__main__":
    main()
