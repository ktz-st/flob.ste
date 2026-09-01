#!/usr/bin/env python3
"""Render Flob's original Atari 8-bit RMT sound effects to WAV files."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import tempfile
import wave
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_A8_DIR = SCRIPT_DIR.parent / "flob"
DEFAULT_OUTPUT_DIR = SCRIPT_DIR / "audio" / "a8_sfx_wav"
DEFAULT_STE_OUTPUT_DIR = SCRIPT_DIR / "audio" / "ste_sfx_wav"

RMT_MODULE_ADDRESS = 0xE000
RMT_PLAYER_START = 0x0682
RMT_PLAYER_END = 0x0D93
RMT_INIT = 0x0903
RMT_UPDATE_INSTRUMENTS = 0x0906
RMT_WRITE_POKEY = 0x090C
RMT_SFX = 0x090F
HARNESS_ADDRESS = 0x2000

SAMPLE_RATE = 25033
STE_SAMPLE_RATE = 12517
RENDER_SECONDS = 4.0
TRAILING_SILENCE_SECONDS = 0.1

# Values are the constants passed to FSfx. FSfx adds $10 before calling RMT.
EFFECTS = (
    ("flip", 0x00),
    ("slime_pick", 0x01),
    ("dead", 0x02),
    ("pick_all", 0x03),
    ("pick_goal", 0x04),
    ("reveal", 0x05),
    ("big_slime", 0x06),
    ("console", 0x07),
    ("water_drop", 0x10),
    ("lever", 0x11),
    ("siren", 0x12),
    ("circuit", 0x13),
    ("gear", 0x14),
    ("valve", 0x15),
    ("bell", 0x16),
    ("gas", 0x17),
    ("insect", 0x18),
)

ALIASES = {
    "beep": "console",
    "teleport": "reveal",
    "scrape": "gas",
}


def read_xex_segments(path: Path) -> list[tuple[int, bytes]]:
    data = path.read_bytes()
    offset = 0
    if data[:2] == b"\xff\xff":
        offset = 2

    segments: list[tuple[int, bytes]] = []
    while offset < len(data):
        while data[offset : offset + 2] == b"\xff\xff":
            offset += 2
        if offset == len(data):
            break
        if offset + 4 > len(data):
            raise ValueError(f"Truncated XEX header in {path}")

        start = data[offset] | (data[offset + 1] << 8)
        end = data[offset + 2] | (data[offset + 3] << 8)
        offset += 4
        size = end - start + 1
        payload = data[offset : offset + size]
        if len(payload) != size:
            raise ValueError(f"Truncated XEX segment ${start:04X}-${end:04X} in {path}")
        segments.append((start, payload))
        offset += size
    return segments


def find_segment(path: Path, start: int, end: int | None = None) -> bytes:
    for segment_start, payload in read_xex_segments(path):
        if segment_start == start and (end is None or start + len(payload) - 1 == end):
            return payload
    expected = f"${start:04X}" if end is None else f"${start:04X}-${end:04X}"
    raise ValueError(f"Segment {expected} not found in {path}")


def xex_segment(start: int, payload: bytes) -> bytes:
    end = start + len(payload) - 1
    return bytes((start & 0xFF, start >> 8, end & 0xFF, end >> 8)) + payload


def make_harness(instrument: int) -> tuple[bytes, int]:
    instrument_x2 = instrument * 2
    if instrument_x2 > 0xFF:
        raise ValueError(f"RMT instrument index out of range: {instrument}")

    # Init RMT, discard all song voices, then start the SFX on both POKEYs.
    init = bytes(
        (
            0xA9, 0x00,                    # lda #0 (song line)
            0xA2, 0x00,                    # ldx #<$e000
            0xA0, 0xE0,                    # ldy #>$e000
            0x20, RMT_INIT & 0xFF, RMT_INIT >> 8,
            0xA2, 0x07,                    # ldx #7
            0xA9, 0x00,                    # lda #0
            0x9D, 0x90, 0x05,              # clear trackn_instrhb,x
            0x9D, 0x30, 0x06,              # clear trackn_audc,x
            0xCA,                          # dex
            0x10, 0xF7,                    # bpl clear loop
            0xA9, 0x01,                    # lda #1 (same note as FSfx)
            0xA2, 0x00,                    # ldx #0
            0xA0, instrument_x2,
            0x20, RMT_SFX & 0xFF, RMT_SFX >> 8,
            0xA9, 0x01,
            0xA2, 0x04,                    # ldx #4 (second POKEY)
            0xA0, instrument_x2,
            0x20, RMT_SFX & 0xFF, RMT_SFX >> 8,
            0x20, RMT_UPDATE_INSTRUMENTS & 0xFF, RMT_UPDATE_INSTRUMENTS >> 8,
            0x20, RMT_WRITE_POKEY & 0xFF, RMT_WRITE_POKEY >> 8,
            0x60,                          # rts
        )
    )
    player_address = HARNESS_ADDRESS + len(init)
    player = bytes(
        (
            0x20, RMT_WRITE_POKEY & 0xFF, RMT_WRITE_POKEY >> 8,
            0x4C, RMT_UPDATE_INSTRUMENTS & 0xFF, RMT_UPDATE_INSTRUMENTS >> 8,
        )
    )
    return init + player, player_address


def make_sap(module: bytes, rmt_player: bytes, instrument: int, name: str) -> bytes:
    harness, player_address = make_harness(instrument)
    header = (
        "SAP\r\n"
        'AUTHOR "Flob"\r\n'
        f'NAME "Flob SFX: {name}"\r\n'
        "STEREO\r\n"
        "TYPE B\r\n"
        f"INIT {HARNESS_ADDRESS:04X}\r\n"
        f"PLAYER {player_address:04X}\r\n"
        "FASTPLAY 312\r\n"
        "\r\n"
    ).encode("ascii")
    return (
        header
        + b"\xff\xff"
        + xex_segment(RMT_MODULE_ADDRESS, module)
        + xex_segment(RMT_PLAYER_START, rmt_player)
        + xex_segment(HARNESS_ADDRESS, harness)
    )


def trim_trailing_silence(path: Path) -> tuple[int, int, bool]:
    with wave.open(str(path), "rb") as source:
        params = source.getparams()
        frames = source.readframes(source.getnframes())

    bytes_per_frame = params.nchannels * params.sampwidth
    last_nonzero_frame = -1
    for frame_index in range(params.nframes - 1, -1, -1):
        begin = frame_index * bytes_per_frame
        if any(frames[begin : begin + bytes_per_frame]):
            last_nonzero_frame = frame_index
            break

    if last_nonzero_frame < 0:
        return params.nframes, params.framerate, True

    tail = round(TRAILING_SILENCE_SECONDS * params.framerate)
    kept_frames = min(params.nframes, last_nonzero_frame + 1 + tail)
    with wave.open(str(path), "wb") as target:
        target.setparams(params)
        target.writeframes(frames[: kept_frames * bytes_per_frame])
    return kept_frames, params.framerate, False


def render_effect(
    asapconv: str,
    temp_dir: Path,
    output_path: Path,
    module: bytes,
    rmt_player: bytes,
    effect_name: str,
    effect_value: int,
) -> dict[str, object]:
    instrument = effect_value + 0x10
    sap_path = temp_dir / f"{effect_name}.sap"
    sap_path.write_bytes(make_sap(module, rmt_player, instrument, effect_name))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        (
            asapconv,
            "-t", f"00:{RENDER_SECONDS:06.3f}",
            "-R", str(SAMPLE_RATE),
            "-w",
            "-o", str(output_path),
            str(sap_path),
        ),
        check=True,
    )
    frames, rate, silent = trim_trailing_silence(output_path)
    return {
        "constant_value": effect_value,
        "rmt_instrument": instrument,
        "note": 1,
        "stereo_channels": [0, 4],
        "sample_rate": rate,
        "frames": frames,
        "duration_seconds": round(frames / rate, 6),
        "silent": silent,
        "sha256": hashlib.sha256(output_path.read_bytes()).hexdigest(),
    }


def convert_to_ste(ffmpeg: str, source: Path, target: Path) -> dict[str, object]:
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        (
            ffmpeg,
            "-v", "error",
            "-y",
            "-i", str(source),
            "-ac", "1",
            "-ar", str(STE_SAMPLE_RATE),
            "-c:a", "pcm_u8",
            str(target),
        ),
        check=True,
    )
    with wave.open(str(target), "rb") as wav:
        if wav.getnchannels() != 1 or wav.getsampwidth() != 1 or wav.getframerate() != STE_SAMPLE_RATE:
            raise ValueError(f"Unexpected STE WAV format in {target}")
        frames = wav.getnframes()
        unsigned_samples = wav.readframes(frames)

    raw_path = target.with_suffix(".raw")
    raw_path.write_bytes(bytes(sample ^ 0x80 for sample in unsigned_samples))
    return {
        "file": target.name,
        "raw_file": raw_path.name,
        "sample_rate": STE_SAMPLE_RATE,
        "channels": 1,
        "sample_width_bits": 8,
        "raw_sample_format": "signed 8-bit PCM",
        "raw_header_bytes": 0,
        "frames": frames,
        "duration_seconds": round(frames / STE_SAMPLE_RATE, 6),
        "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
        "raw_sha256": hashlib.sha256(raw_path.read_bytes()).hexdigest(),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--a8-dir", type=Path, default=DEFAULT_A8_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--ste-output-dir", type=Path, default=DEFAULT_STE_OUTPUT_DIR)
    args = parser.parse_args()

    asapconv = shutil.which("asapconv")
    if asapconv is None:
        raise SystemExit("asapconv not found in PATH")
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        raise SystemExit("ffmpeg not found in PATH")

    a8_dir = args.a8_dir.resolve()
    output_dir = args.output_dir.resolve()
    ste_output_dir = args.ste_output_dir.resolve()
    xex_path = a8_dir / "flob.xex"
    world_modules = sorted((a8_dir / "worlds").glob("*/_flob_ingame.rmt"))
    if not xex_path.is_file():
        raise SystemExit(f"Original executable not found: {xex_path}")
    if not world_modules:
        raise SystemExit(f"No original world RMT modules found below {a8_dir / 'worlds'}")

    # The first world contains the shared gameplay SFX bank used by FSfx.
    module_path = world_modules[0]
    module = find_segment(module_path, RMT_MODULE_ADDRESS)
    rmt_player = find_segment(xex_path, RMT_PLAYER_START, RMT_PLAYER_END)

    manifest: dict[str, object] = {
        "description": "Original Flob Atari 8-bit RMT SFX rendered through ASAP's POKEY emulator.",
        "source_module": str(module_path.relative_to(a8_dir)),
        "source_player": "flob.xex:$0682-$0D93",
        "render_seconds": RENDER_SECONDS,
        "trailing_silence_seconds": TRAILING_SILENCE_SECONDS,
        "effects": {},
        "aliases": ALIASES,
    }
    ste_manifest: dict[str, object] = {
        "description": "Flob SFX converted for Atari STE DMA playback.",
        "source": str(output_dir),
        "sample_rate": STE_SAMPLE_RATE,
        "channels": 1,
        "sample_width_bits": 8,
        "effects": {},
        "aliases": ALIASES,
    }

    with tempfile.TemporaryDirectory(prefix="flob_sfx_") as temp_name:
        temp_dir = Path(temp_name)
        effects_manifest = manifest["effects"]
        assert isinstance(effects_manifest, dict)
        for effect_name, effect_value in EFFECTS:
            wav_path = output_dir / f"{effect_name}.wav"
            metadata = render_effect(
                asapconv,
                temp_dir,
                wav_path,
                module,
                rmt_player,
                effect_name,
                effect_value,
            )
            metadata["file"] = wav_path.name
            effects_manifest[effect_name] = metadata
            ste_effects_manifest = ste_manifest["effects"]
            assert isinstance(ste_effects_manifest, dict)
            ste_effects_manifest[effect_name] = convert_to_ste(
                ffmpeg,
                wav_path,
                ste_output_dir / f"{effect_name}.wav",
            )
            print(f"{effect_name:12s} {metadata['duration_seconds']:>8.3f} s  instrument {metadata['rmt_instrument']}")

    for alias, target in ALIASES.items():
        shutil.copyfile(output_dir / f"{target}.wav", output_dir / f"{alias}.wav")
        shutil.copyfile(ste_output_dir / f"{target}.wav", ste_output_dir / f"{alias}.wav")
        shutil.copyfile(ste_output_dir / f"{target}.raw", ste_output_dir / f"{alias}.raw")

    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="ascii"
    )
    (ste_output_dir / "manifest.json").write_text(
        json.dumps(ste_manifest, indent=2) + "\n", encoding="ascii"
    )
    print(f"Generated {len(EFFECTS)} effects and {len(ALIASES)} aliases in {output_dir}")
    print(f"Generated Atari STE 12517 Hz mono copies in {ste_output_dir}")


if __name__ == "__main__":
    main()
