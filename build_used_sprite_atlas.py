#!/usr/bin/env python3
"""
Build an editable STE sprite atlas containing only sprites used by the port.

This intentionally does not overwrite images/sprite_atlas/all_sprites.png.
It emits:
  images/sprite_atlas/used_sprites.png
  images/sprite_atlas/used_sprites.json

Included rows:
  - direct STE renderer sprites: flob, slime
  - all original world sprite labels referenced by PUT_SPRITES in world data
"""

from __future__ import annotations

import json

import build_full_sprite_atlas as atlas


OUT_PNG = atlas.OUT_DIR / "used_sprites.png"
OUT_JSON = atlas.OUT_DIR / "used_sprites.json"
DIRECT_STE_SPRITES = {"flob", "slime"}


def main() -> None:
    atlas.OUT_DIR.mkdir(parents=True, exist_ok=True)

    constants = atlas.load_constants()
    entries = [
        entry
        for entry in atlas.load_sheet_entries()
        if entry.name in DIRECT_STE_SPRITES
    ]
    seen = {entry.name for entry in entries}

    sources = atlas.find_world_sprite_sources()
    duplicate_labels = atlas.labels_with_different_sources(sources)
    for world_idx, label, path in sources:
        atlas_label = atlas.atlas_label_for_source(world_idx, label, duplicate_labels)
        for entry in atlas.sprite_entries_from_a65(atlas_label, path, constants):
            if entry.name not in seen:
                entries.append(entry)
                seen.add(entry.name)

    entries.sort(key=lambda item: item.name)
    atlas_rgba, meta = atlas.build_rgba_atlas(entries)
    sprite_palette = atlas.quantize_opaque_colors(atlas_rgba)
    indexed, full_palette = atlas.build_indexed_atlas(atlas_rgba, sprite_palette)

    meta["name"] = "used_sprites"
    meta["image"] = str(OUT_PNG.relative_to(atlas.FLOB_STE))
    meta["palette_rgb"] = [list(rgb) for rgb in full_palette]
    meta["sprite_color_count"] = len(sprite_palette)
    meta["quantized_from_unique_colors"] = len(
        {(r, g, b) for (r, g, b, a) in atlas_rgba.getdata() if a}
    )
    meta["atlas_size"] = {"w": atlas_rgba.width, "h": atlas_rgba.height}
    meta["direct_ste_sprites"] = sorted(DIRECT_STE_SPRITES)
    meta["world_sprite_sources"] = len(sources)

    indexed.save(OUT_PNG, transparency=0)
    OUT_JSON.write_text(json.dumps(meta, indent=2))

    print(f"wrote {OUT_PNG}")
    print(f"wrote {OUT_JSON}")
    print(f"sprite rows: {len(entries)}")
    print(f"sprite colors used: {len(sprite_palette)} / {atlas.SPRITE_COLOR_COUNT}")


if __name__ == "__main__":
    main()
