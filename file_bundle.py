"""FLB2: big-endian bundle header followed by raw or Apultra data."""
from pathlib import Path
import struct
import subprocess
import tempfile
import zlib

HEADER = struct.Struct('>4sHHIIII')
HEADER_BYTES = HEADER.size


def apultra(data, decompress=False):
    with tempfile.TemporaryDirectory(prefix='flob-apultra-') as tmp:
        src, dst = Path(tmp) / 'in', Path(tmp) / 'out'
        src.write_bytes(data)
        subprocess.run(['apultra', '-d' if decompress else '-c', str(src), str(dst)],
                       check=True, capture_output=True)
        return dst.read_bytes()


def encode(payload, entries):
    payload = bytes(payload)
    packed = apultra(payload)
    stored = packed if len(packed) < len(payload) else payload
    header = HEADER.pack(b'FLB2', 2, entries, len(payload), zlib.crc32(payload),
                         len(stored), zlib.crc32(stored))
    return header + stored


def decode(data):
    magic, version, count, size, crc, stored_size, stored_crc = HEADER.unpack_from(data)
    if magic != b'FLB2' or version != 2 or stored_size > size or len(data) != HEADER_BYTES + stored_size:
        raise ValueError('Invalid bundle header/size')
    stored = data[HEADER_BYTES:]
    if zlib.crc32(stored) != stored_crc:
        raise ValueError('Stored checksum mismatch')
    payload = apultra(stored, decompress=True) if stored_size < size else stored
    if len(payload) != size or zlib.crc32(payload) != crc:
        raise ValueError('Unpacked checksum/size mismatch')
    return payload
