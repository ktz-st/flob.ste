"""Host checks for independent per-world sprite bundles and shared payloads."""
import hashlib
import json
from pathlib import Path
import re
import tempfile
import unittest
import zlib

from build_file_version import ROOT, CORE_SPRITES, prepare, sprite_groups, sprite_world_usage
from file_bundle import HEADER_BYTES, decode


class SpriteBundles(unittest.TestCase):
    def test_complete_partition(self):
        usage = sprite_world_usage((ROOT / 'generated/world_sprite_atlas_map.inc').read_text())
        with tempfile.TemporaryDirectory(prefix='flob-sprite-groups-') as tmp:
            output = Path(tmp)
            prepare(output)
            manifest = json.loads((output / 'manifest.json').read_text())
            groups = {g['path']: g for g in manifest['groups']}
            self.assertEqual(manifest['stage'], 'dynamic-group-storage')
            self.assertEqual({e['symbol'] for e in groups['COMMON/WORLDINF.BIN']['assets']},
                             {f'WORLD_{w:02d}_DATA_APL' for w in range(6)})
            source = output / 'src'
            all_pascal = '\n'.join(p.read_text() for p in source.rglob('*.inc'))
            for group in groups.values():
                for entry in group['assets']:
                    name = entry['symbol']
                    if name == 'FlobFont':
                        continue
                    self.assertEqual(all_pascal.count(f'var {name}: ^TFile_{name};'), 1)
                    self.assertNotRegex(all_pascal, rf'var {name}: array')
            core = groups['COMMON/SPRITES.BIN']['assets']
            self.assertEqual({re.sub(r'_(WORDS|EMS_OFFSETS|EMS_MASKS)$', '', e['symbol'])
                              for e in core}, CORE_SPRITES)
            seen = {}
            count = 0
            stored = 0
            for path, group in groups.items():
                data = (output / 'disk' / path).read_bytes()
                self.assertEqual(len(data), group['bytes'])
                unpacked = decode(data)
                self.assertEqual(zlib.crc32(unpacked), group['crc32'])
                for entry in group['assets']:
                    offset, size = entry['offset'], entry['size']
                    self.assertEqual(offset % 2, 0)
                    payload = unpacked[offset-HEADER_BYTES:offset-HEADER_BYTES + size]
                    self.assertEqual(hashlib.sha256(payload).hexdigest(), entry['sha256'])
                    self.assertEqual(zlib.crc32(payload), entry['crc32'])
                    self.assertEqual(seen.setdefault(entry['symbol'], payload), payload)
                    count += 1
                    stored += size
            for world in range(6):
                entries = groups[f'WORLD{world}/SPRITES.BIN']['assets']
                self.assertEqual({e['symbol'] for e in entries},
                                 {name + '_WORDS' for name, users in usage.items() if world in users})
                self.assertTrue(all(world in e['worlds'] for e in entries))
            self.assertEqual(len(seen), manifest['asset_count'])
            self.assertEqual(sum(map(len, seen.values())), manifest['payload_bytes'])
            self.assertEqual(count, manifest['stored_entry_count'])
            self.assertEqual(stored, manifest['stored_payload_bytes'])

    def test_unknown_sprite_fails(self):
        with self.assertRaises(ValueError):
            sprite_groups('SPR_UNKNOWN_WORDS', {})

    def test_incomplete_mapping_fails(self):
        with self.assertRaises(ValueError):
            sprite_world_usage('0: case addr of')


if __name__ == '__main__':
    unittest.main()
