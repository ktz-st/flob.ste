#!/usr/bin/env python3
"""Convert the mono POKEY side of an RMT song into a compact YM stream.

This is an intentionally small first-pass converter for evaluating the music
port. It uses ASAP as the RMT reference player, keeps the three most active
voices from the left POKEY and emits register deltas at PAL VBL frequency.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import struct
import subprocess
import wave
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent
DEFAULT_INPUT = ROOT.parent / "flob" / "assets" / "_flob_theme.rmt"
DEFAULT_OUTPUT = ROOT / "audio" / "ym_music" / "flob_theme"
PAL_FRAME_RATE = 49.860759
WAV_RATE = 22050
YM_CLOCK = 2_000_000
REGISTER_COUNT = 11
NOISE_VOLUME_ATTENUATION = 3
NOISE_PERIOD_NUMERATOR = 5
NOISE_PERIOD_DENOMINATOR = 4

TIME_RE = re.compile(r"TIME\s+(\d+):(\d+\.\d+)(?:\s+(LOOP))?")
DUMP_RE = re.compile(
    r"^\s*(\d+\.\d+):\s+"
    r"((?:[0-9A-F]{2}\s+){8}[0-9A-F]{2})\s+\|\s+"
    r"((?:[0-9A-F]{2}\s+){8}[0-9A-F]{2})",
    re.IGNORECASE,
)

# The STE SFX player uses this mapping too. It compensates for the logarithmic
# YM2149 volume ladder while retaining quiet POKEY envelopes.
YM_VOLUME = (0, 7, 9, 10, 11, 12, 12, 13, 13, 14, 14, 14, 15, 15, 15, 15)

# RMT's distortion-C bass has a dedicated, non-linear note table. These are
# the stable C2 divider values from G1 through F#3, paired with MIDI notes.
C_BASS_NOTES = (
    (0xFB, 31), (0xF2, 32), (0xE3, 33), (0xD7, 34), (0xCB, 35),
    (0xBF, 36), (0xB6, 37), (0xAA, 38), (0xA1, 39), (0x98, 40),
    (0x8F, 41), (0x89, 42), (0x80, 43), (0x7A, 44), (0x71, 45),
    (0x6B, 46), (0x65, 47), (0x5F, 48), (0x5C, 49), (0x56, 50),
    (0x50, 51), (0x4D, 52), (0x47, 53), (0x44, 54),
)


@dataclass(frozen=True)
class PokeyFrame:
    audf: tuple[int, int, int, int, int, int, int, int]
    audc: tuple[int, int, int, int, int, int, int, int]
    audctl: tuple[int, int]


def detect_song_timing(path: Path, song: int) -> tuple[float, bool]:
    output = subprocess.check_output(
        ("asapscan", "-t", "-s", str(song), str(path)), text=True
    )
    match = TIME_RE.search(output)
    if not match:
        raise RuntimeError(f"ASAP did not detect a loop in {path}: {output.strip()}")
    seconds = int(match.group(1)) * 60.0 + float(match.group(2))
    return seconds, match.group(3) == "LOOP"


def detect_loop_seconds(path: Path, song: int) -> float:
    """Backward-compatible helper used by small analysis scripts."""
    return detect_song_timing(path, song)[0]


def dump_left_pokey(path: Path, song: int, loop_seconds: float) -> list[PokeyFrame]:
    process = subprocess.Popen(
        ("asapscan", "-d", "-s", str(song), str(path)),
        stdout=subprocess.PIPE,
        text=True,
    )
    frames: list[PokeyFrame] = []
    assert process.stdout is not None
    try:
        for line in process.stdout:
            match = DUMP_RE.match(line)
            if not match:
                continue
            if float(match.group(1)) >= loop_seconds:
                break
            left = [int(token, 16) for token in match.group(2).split()]
            right = [int(token, 16) for token in match.group(3).split()]
            frames.append(
                PokeyFrame(
                    audf=(
                        left[0], left[2], left[4], left[6],
                        right[0], right[2], right[4], right[6],
                    ),
                    audc=(
                        left[1], left[3], left[5], left[7],
                        right[1], right[3], right[5], right[7],
                    ),
                    audctl=(left[8], right[8]),
                )
            )
    finally:
        process.terminate()
        process.wait()
    if not frames:
        raise RuntimeError(f"ASAP produced no register frames for {path}")
    return frames


def select_channels(
    frames: list[PokeyFrame], candidates: tuple[int, ...]
) -> tuple[int, int, int]:
    activity = [0] * 8
    for frame in frames:
        for channel in candidates:
            audc = frame.audc[channel]
            activity[channel] += audc & 15
    selected = sorted(
        candidates, key=lambda channel: (-activity[channel], channel)
    )[:3]
    # Preserve the original left-to-right voice order after rejecting silence.
    return tuple(sorted(selected))  # type: ignore[return-value]


def effective_volume(frame: PokeyFrame, channel: int) -> int:
    # A joined 16-bit POKEY voice is emitted by the second channel. The first
    # channel's low-byte counter can create ultrasonic artifacts which cannot
    # be represented faithfully by a YM tone channel.
    local_channel = channel & 3
    audctl = frame.audctl[channel >> 2]
    if (local_channel == 0 and (audctl & 0x10)) or (
        local_channel == 2 and (audctl & 0x08)
    ):
        return 0
    return frame.audc[channel] & 15


def pokey_period(frame: PokeyFrame, channel: int) -> int:
    audf = frame.audf[channel]
    side_base = channel & 4
    local_channel = channel & 3
    audctl = frame.audctl[channel >> 2]
    if audctl & ~0x7E:
        raise RuntimeError(
            f"converter does not support AUDCTL ${audctl:02X} on channel {channel + 1}"
        )

    if local_channel == 1 and (audctl & 0x10):
        # Joined channels 1+2 form a 16-bit counter clocked at 1.79 MHz.
        divider = frame.audf[side_base] | (frame.audf[side_base + 1] << 8)
        frequency = 1_789_790.0 / (2.0 * (divider + 7))
    elif local_channel == 3 and (audctl & 0x08):
        divider = frame.audf[side_base + 2] | (frame.audf[side_base + 3] << 8)
        frequency = 1_789_790.0 / (2.0 * (divider + 7))
    elif (local_channel == 0 and (audctl & 0x40)) or (
        local_channel == 2 and (audctl & 0x20)
    ):
        frequency = 1_789_790.0 / (2.0 * (audf + 4))
    else:
        # Default POKEY clock is approximately 31.96 kHz after output toggle.
        frequency = 31_960.0 / (audf + 1)
    return max(1, min(4095, round(YM_CLOCK / (16.0 * frequency))))


def c_bass_period(audf: int) -> int:
    """Map an RMT distortion-C divider to its perceived musical pitch."""
    points = tuple(reversed(C_BASS_NOTES))
    if audf <= points[0][0]:
        midi_note = float(points[0][1])
    elif audf >= points[-1][0]:
        midi_note = float(points[-1][1])
    else:
        midi_note = float(points[0][1])
        for (left_div, left_note), (right_div, right_note) in zip(points, points[1:]):
            if left_div <= audf <= right_div:
                fraction = (audf - left_div) / (right_div - left_div)
                midi_note = left_note + fraction * (right_note - left_note)
                break
    frequency = 440.0 * (2.0 ** ((midi_note - 69.0) / 12.0))
    return max(1, min(4095, round(YM_CLOCK / (16.0 * frequency))))


def pokey_mode(audc: int, distortion_c_noise: bool = False) -> str:
    distortion = audc & 0xF0
    # Distortion C is a pitched, rough bass voice in the Flob title tune.
    # Treating it as unpitched noise loses the double-bass line completely.
    if distortion == 0xC0 and distortion_c_noise:
        return "tone_noise"
    if distortion in (0xA0, 0xC0):
        return "tone"
    if distortion == 0x20:
        return "tone_noise"
    return "noise"


def convert_frame(
    frame: PokeyFrame,
    selected: tuple[int, int, int],
    volume_attenuation: int = 0,
    distortion_c_noise: bool = False,
) -> tuple[int, ...]:
    registers = [0] * REGISTER_COUNT
    mixer = 0x3F
    noise_candidates: list[tuple[int, int]] = []

    for ym_channel, pokey_channel in enumerate(selected):
        audf = frame.audf[pokey_channel]
        audc = frame.audc[pokey_channel]
        mode = pokey_mode(audc, distortion_c_noise)
        volume = max(
            0,
            YM_VOLUME[effective_volume(frame, pokey_channel)]
            - volume_attenuation,
        )
        if mode == "noise":
            volume = max(0, volume - NOISE_VOLUME_ATTENUATION)
        if (audc & 0xF0) == 0xC0:
            period = c_bass_period(audf)
        else:
            period = pokey_period(frame, pokey_channel)
        registers[ym_channel * 2] = period & 0xFF
        registers[ym_channel * 2 + 1] = (period >> 8) & 0x0F
        registers[8 + ym_channel] = volume
        if volume == 0:
            continue

        if mode in ("tone", "tone_noise"):
            mixer &= ~(1 << ym_channel)
        if mode in ("noise", "tone_noise"):
            mixer &= ~(1 << (ym_channel + 3))
            noise_candidates.append((audc & 15, audf))

    if noise_candidates:
        _, noise_audf = max(noise_candidates)
        noise_period = (noise_audf + 1) // 8
        noise_period = (
            noise_period * NOISE_PERIOD_NUMERATOR
            + NOISE_PERIOD_DENOMINATOR // 2
        ) // NOISE_PERIOD_DENOMINATOR
        registers[6] = max(1, min(31, noise_period))
    else:
        registers[6] = 1
    registers[7] = mixer
    return tuple(registers)


def encode_stream(
    frames: list[tuple[int, ...]],
    selected: tuple[int, int, int],
    frame_rate: int,
    loop_frame: int,
) -> bytes:
    body = bytearray()
    previous = (-1,) * REGISTER_COUNT
    for frame in frames:
        mask = 0
        changed: list[int] = []
        for register, value in enumerate(frame):
            if value != previous[register]:
                mask |= 1 << register
                changed.append(value)
        body.extend(struct.pack(">H", mask))
        body.extend(changed)
        previous = frame

    header = struct.pack(
        ">4sHHB3BI",
        b"FYM1",
        len(frames),
        loop_frame,
        frame_rate,
        *(channel + 1 for channel in selected),
        len(body),
    )
    return header + body


def allocate_dynamic_channels(
    frames: list[PokeyFrame],
    candidates: tuple[int, ...],
    deduplicate_stereo: bool = False,
) -> list[tuple[int, int, int]]:
    """Fit four POKEY voices into YM while avoiding needless channel swaps."""
    previous: tuple[int, int, int] = candidates[:3]  # type: ignore[assignment]
    allocations: list[tuple[int, int, int]] = []
    for frame in frames:
        available = list(candidates)
        if deduplicate_stereo:
            unique: list[int] = []
            signatures: set[tuple[int, int, int]] = set()
            for channel in candidates:
                signature = (
                    frame.audf[channel],
                    frame.audc[channel],
                    frame.audctl[channel >> 2],
                )
                if signature not in signatures:
                    signatures.add(signature)
                    unique.append(channel)
            if len(unique) >= 3:
                available = unique
        ranked = sorted(
            available,
            key=lambda channel: (
                -effective_volume(frame, channel),
                channel not in previous,
                channel,
            ),
        )
        chosen = set(ranked[:3])
        current = [-1, -1, -1]
        for ym_channel, pokey_channel in enumerate(previous):
            if pokey_channel in chosen:
                current[ym_channel] = pokey_channel
                chosen.remove(pokey_channel)
        for ym_channel in range(3):
            if current[ym_channel] < 0:
                current[ym_channel] = min(chosen)
                chosen.remove(current[ym_channel])
        previous = tuple(current)  # type: ignore[assignment]
        allocations.append(previous)
    return allocations


def render_wav(
    path: Path, frames: list[tuple[int, ...]], frame_rate: float
) -> None:
    samples_per_frame = WAV_RATE / frame_rate
    tone_phase = [0.0, 0.0, 0.0]
    noise_phase = 0.0
    noise_lfsr = 0x1FFFF
    volume_amp = [0.0] + [10.0 ** ((level - 15) * 1.5 / 20.0) for level in range(1, 16)]
    pcm: list[int] = []
    sample_cursor = 0.0

    for registers in frames:
        next_cursor = sample_cursor + samples_per_frame
        sample_count = round(next_cursor) - round(sample_cursor)
        sample_cursor = next_cursor
        mixer = registers[7]
        noise_period = max(1, registers[6] & 31)
        noise_frequency = YM_CLOCK / (16.0 * noise_period)

        for _ in range(sample_count):
            noise_phase += noise_frequency / WAV_RATE
            while noise_phase >= 1.0:
                noise_phase -= 1.0
                feedback = (noise_lfsr ^ (noise_lfsr >> 3)) & 1
                noise_lfsr = (noise_lfsr >> 1) | (feedback << 16)
            noise_high = noise_lfsr & 1

            mixed = 0.0
            for channel in range(3):
                period = registers[channel * 2] | ((registers[channel * 2 + 1] & 15) << 8)
                frequency = YM_CLOCK / (16.0 * max(1, period))
                tone_phase[channel] = (tone_phase[channel] + frequency / WAV_RATE) % 1.0
                tone_high = tone_phase[channel] < 0.5
                tone_enabled = (mixer & (1 << channel)) == 0
                noise_enabled = (mixer & (1 << (channel + 3))) == 0
                gate = (tone_high if tone_enabled else True) and (
                    bool(noise_high) if noise_enabled else True
                )
                amplitude = volume_amp[registers[8 + channel] & 15]
                mixed += amplitude if gate else -amplitude
            pcm.append(max(-32767, min(32767, round(mixed * 8500.0))))

    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(WAV_RATE)
        output.writeframes(struct.pack("<" + "h" * len(pcm), *pcm))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", nargs="?", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--song", type=int, default=0)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--frame-rate",
        type=int,
        default=50,
        help="FYM playback rate; use 100 for modules played twice per PAL VBL",
    )
    parser.add_argument(
        "--dynamic-channels",
        action="store_true",
        help="dynamically fit the selected POKEY voices into three YM channels",
    )
    parser.add_argument(
        "--pokey-side",
        choices=("left", "right", "stereo"),
        default="left",
        help="POKEY voices used for conversion (default: left)",
    )
    parser.add_argument(
        "--volume-attenuation",
        type=int,
        default=0,
        help="subtract this many YM volume levels from every voice",
    )
    parser.add_argument(
        "--deduplicate-stereo",
        action="store_true",
        help="count identical left/right POKEY voices only once",
    )
    parser.add_argument(
        "--distortion-c-noise",
        action="store_true",
        help="approximate POKEY distortion C with combined YM tone and noise",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    input_path = args.input.resolve()
    output_base = args.output.resolve()
    output_base.parent.mkdir(parents=True, exist_ok=True)

    loop_seconds, looping = detect_song_timing(input_path, args.song)
    pokey_frames = dump_left_pokey(input_path, args.song, loop_seconds)
    if args.pokey_side == "left":
        candidates = (0, 1, 2, 3)
    elif args.pokey_side == "right":
        candidates = (4, 5, 6, 7)
    else:
        candidates = tuple(range(8))
    if not 1 <= args.frame_rate <= 255:
        raise ValueError("frame rate must fit the FYM header (1..255 Hz)")
    if not 0 <= args.volume_attenuation <= 15:
        raise ValueError("volume attenuation must be in range 0..15")

    if args.dynamic_channels:
        allocations = allocate_dynamic_channels(
            pokey_frames, candidates, args.deduplicate_stereo
        )
        ym_frames = [
            convert_frame(
                frame,
                allocation,
                args.volume_attenuation,
                args.distortion_c_noise,
            )
            for frame, allocation in zip(pokey_frames, allocations)
        ]
        selected = (0xFE, 0xFE, 0xFE)
        channel_description: object = f"dynamic {len(candidates)}-to-3"
    else:
        selected = select_channels(pokey_frames, candidates)
        ym_frames = [
            convert_frame(
                frame,
                selected,
                args.volume_attenuation,
                args.distortion_c_noise,
            )
            for frame in pokey_frames
        ]
        channel_description = [channel + 1 for channel in selected]
    stream = encode_stream(
        ym_frames, selected, args.frame_rate, 0 if looping else 0xFFFF
    )

    bin_path = output_base.with_suffix(".fym")
    wav_path = output_base.with_suffix(".wav")
    json_path = output_base.with_suffix(".json")
    bin_path.write_bytes(stream)
    render_wav(wav_path, ym_frames, args.frame_rate)
    playback_seconds = len(ym_frames) / args.frame_rate
    metadata = {
        "source": str(input_path),
        "song": args.song,
        "source_loop_seconds": loop_seconds,
        "loop_seconds": playback_seconds,
        "looping": looping,
        "frame_rate": args.frame_rate,
        "frame_count": len(ym_frames),
        "left_pokey_channels": channel_description,
        "pokey_side": args.pokey_side,
        "format": "FYM1 register delta stream",
        "register_count": REGISTER_COUNT,
        "stream_bytes": len(stream),
        "wav_rate": WAV_RATE,
        "noise_volume_attenuation": NOISE_VOLUME_ATTENUATION,
        "noise_period_scale": NOISE_PERIOD_NUMERATOR / NOISE_PERIOD_DENOMINATOR,
        "volume_attenuation": args.volume_attenuation,
        "deduplicate_stereo": args.deduplicate_stereo,
        "distortion_c_noise": args.distortion_c_noise,
    }
    json_path.write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"selected left POKEY channels: {metadata['left_pokey_channels']}")
    print(f"frames: {len(ym_frames)}, loop: {playback_seconds:.2f} s")
    print(f"wrote {bin_path} ({len(stream)} bytes)")
    print(f"wrote {wav_path}")
    print(f"wrote {json_path}")


if __name__ == "__main__":
    main()
