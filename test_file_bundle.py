import random
import unittest

from file_bundle import HEADER, HEADER_BYTES, encode, decode


class Bundles(unittest.TestCase):
    def test_raw_and_packed_roundtrip(self):
        for payload, compressed in [(random.Random(123).randbytes(4096), False),
                                    (b'Flob sprite data\0' * 8000, True)]:
            blob = encode(payload, 3)
            fields = HEADER.unpack_from(blob)
            self.assertEqual(fields[:3], (b'FLB2', 2, 3))
            self.assertEqual(fields[5] < fields[3], compressed)
            self.assertEqual(decode(blob), payload)

    def test_damage_rejected_before_decompression(self):
        blob = bytearray(encode(b'\0' * 8192, 1))
        blob[HEADER_BYTES] ^= 0x80
        with self.assertRaisesRegex(ValueError, 'Stored checksum'):
            decode(blob)

    def test_truncation(self):
        blob = encode(b'\0' * 8192, 1)
        with self.assertRaisesRegex(ValueError, 'header/size'):
            decode(blob[:-1])


if __name__ == '__main__':
    unittest.main()
