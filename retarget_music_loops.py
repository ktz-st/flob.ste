#!/usr/bin/env python3
"""Apply the original RMT song-line loops to Flob's tuned FYM streams."""

from __future__ import annotations

import json
import struct
import subprocess
from dataclasses import dataclass
from pathlib import Path

import convert_rmt_to_ym as converter


ROOT = Path(__file__).resolve().parent
A8_ROOT = ROOT.parent / "flob"
REGISTER_COUNT = 11


@dataclass(frozen=True)
class Track:
    world: int
    source: Path
    frame_count: int
    loop_frame: int
    song_start_row: int
    loop_row: int


TRACKS = (
    Track(0, A8_ROOT / "worlds/00_Escape_From_The_Lab/_flob_ingame.rmt", 4256, 896, 2, 4),
    Track(1, A8_ROOT / "worlds/01_Abominable_Sewers/_flob_ingame.rmt", 3072, 0, 2, 2),
    Track(2, A8_ROOT / "worlds/02_Suburbian_Parkour/_flob_ingame.rmt", 4032, 448, 2, 3),
    Track(3, A8_ROOT / "worlds/03_Hazardous_Mudlands/_flob_ingame.rmt", 4608, 0, 2, 2),
    Track(4, A8_ROOT / "worlds/04_Silver_Dust_Mines/_flob_ingame.rmt", 8960, 0, 2, 2),
)


def decode_fym(path: Path) -> tuple[bytes, list[tuple[int, ...]]]:
    data = path.read_bytes()
    if len(data) < 16 or data[:4] != b"FYM1":
        raise ValueError(f"{path}: expected an FYM1 stream")
    frame_count = int.from_bytes(data[4:6], "big")
    body_size = int.from_bytes(data[12:16], "big")
    if len(data) != body_size + 16:
        raise ValueError(f"{path}: invalid FYM1 body size")

    registers = [0] * REGISTER_COUNT
    frames: list[tuple[int, ...]] = []
    offset = 16
    for _ in range(frame_count):
        mask = int.from_bytes(data[offset : offset + 2], "big")
        offset += 2
        for register in range(REGISTER_COUNT):
            if mask & (1 << register):
                registers[register] = data[offset]
                offset += 1
        frames.append(tuple(registers))
    if offset != len(data):
        raise ValueError(f"{path}: trailing FYM1 data")
    return data[:16], frames


def capture_pokey(path: Path, frame_count: int) -> list[converter.PokeyFrame]:
    process = subprocess.Popen(
        ("asapscan", "-d", "-s", "0", str(path)),
        stdout=subprocess.PIPE,
        text=True,
    )
    frames: list[converter.PokeyFrame] = []
    assert process.stdout is not None
    try:
        for line in process.stdout:
            match = converter.DUMP_RE.match(line)
            if not match:
                continue
            left = [int(value, 16) for value in match.group(2).split()]
            right = [int(value, 16) for value in match.group(3).split()]
            frames.append(
                converter.PokeyFrame(
                    audf=tuple(left[0:8:2] + right[0:8:2]),
                    audc=tuple(left[1:8:2] + right[1:8:2]),
                    audctl=(left[8], right[8]),
                )
            )
            if len(frames) == frame_count:
                break
    finally:
        process.terminate()
        process.wait()
    if len(frames) != frame_count:
        raise RuntimeError(f"{path}: ASAP returned only {len(frames)} frames")
    return frames


def source_ym_frames(track: Track, metadata: dict[str, object]) -> list[tuple[int, ...]]:
    # The shipped FYM files were tuned with the original 2 MHz conversion
    # profile. Use it only to recover frames truncated by ASAP's rounded TIME.
    converter.YM_CLOCK = float(metadata.get("ym_clock_hz", 2_000_000.0))
    converter.POKEY_PAL_CLOCK = float(metadata.get("pokey_clock_hz", 1_789_760.0))
    pokey = capture_pokey(track.source, track.frame_count)
    side = metadata.get("pokey_side", "stereo")
    candidates = {"left": (0, 1, 2, 3), "right": (4, 5, 6, 7),
                  "stereo": tuple(range(8))}[side]
    allocations = converter.allocate_dynamic_channels(
        pokey,
        candidates,
        bool(metadata.get("deduplicate_stereo", False)),
    )
    attenuation = int(metadata.get("volume_attenuation", 0))
    distortion_c_noise = bool(metadata.get("distortion_c_noise", False))
    return [
        converter.convert_frame(frame, allocation, attenuation, distortion_c_noise)
        for frame, allocation in zip(pokey, allocations)
    ]


def update_track(track: Track) -> None:
    base = ROOT / "audio/ym_music" / f"flob_world_{track.world:02d}"
    fym_path = base.with_suffix(".fym")
    apl_path = base.with_suffix(".fym.apl")
    json_path = base.with_suffix(".json")
    metadata = json.loads(json_path.read_text(encoding="utf-8"))
    header, tuned_frames = decode_fym(fym_path)
    if len(tuned_frames) > track.frame_count:
        raise ValueError(f"{fym_path}: more frames than the original RMT cycle")

    frames = tuned_frames
    if len(frames) < track.frame_count:
        reference = source_ym_frames(track, metadata)
        if frames != reference[: len(frames)]:
            raise ValueError(f"{fym_path}: tuned data differs from the recoverable source")
        frames = frames + reference[len(frames) :]

    selected = tuple(value - 1 for value in header[9:12])
    stream = converter.encode_stream(frames, selected, header[8], track.loop_frame)
    fym_path.write_bytes(stream)
    subprocess.run(("apultra", "-c", str(fym_path), str(apl_path)), check=True)

    metadata.update(
        {
            "frame_count": track.frame_count,
            "loop_seconds": track.frame_count / header[8],
            "loop_frame": track.loop_frame,
            "playback_loop_seconds": track.loop_frame / header[8],
            "loop_duration_frames": track.frame_count - track.loop_frame,
            "playback_loop_duration_seconds": (track.frame_count - track.loop_frame) / header[8],
            "rmt_song_start_row": track.song_start_row,
            "rmt_loop_row": track.loop_row,
            "stream_bytes": len(stream),
        }
    )
    json_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(
        f"world {track.world:02d}: {track.frame_count} frames, "
        f"loop {track.loop_frame} ({track.loop_frame / header[8]:.2f} s)"
    )


def main() -> None:
    for track in TRACKS:
        update_track(track)


if __name__ == "__main__":
    main()
