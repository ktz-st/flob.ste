"""Classification shared by the STE sprite asset and address-map generators."""

from __future__ import annotations


# True PMG overlays used with SPRITE_COMBINED and gap=0. The value is the
# atlas row basename; world-specific names match build_full_sprite_atlas.py.
MERGED_OVERLAY_BY_WORLD_LABEL: dict[tuple[int, str], str] = {
    (0, "sprite_map"): "sprite_map",
    (0, "sprite_flame"): "sprite_flame",
    (0, "sprite_fireext"): "sprite_fireext",
    (0, "sprite_bigslime"): "sprite_bigslime",
    (1, "sprite_lever2"): "sprite_lever2",
    (1, "sprite_vial"): "sprite_vial_w01",
    (1, "sprite_bigslime"): "sprite_bigslime",
    (2, "sprite_vial"): "sprite_vial_w02",
    (2, "sprite_bigslime"): "sprite_bigslime",
    (3, "sprite_lever"): "sprite_lever_w03",
    (3, "sprite_drop"): "sprite_drop",
    (3, "sprite_button"): "sprite_button",
    (3, "sprite_vial"): "sprite_vial_w03",
    (3, "sprite_bigslime"): "sprite_bigslime",
    (4, "sprite_vial"): "sprite_vial_w04",
    (4, "sprite_bigslime"): "sprite_bigslime",
    (5, "sprite_drop"): "sprite_drop",
    (5, "sprite_bigslime"): "sprite_bigslime",
}

MERGED_OVERLAY_ATLAS_NAMES = frozenset(MERGED_OVERLAY_BY_WORLD_LABEL.values())


# SPRITE_COMBINED objects whose P1 player is horizontally displaced.  Gap is
# expressed in original A8 pixels; atlas pixels are scaled 2x horizontally.
MERGED_COMPOUND_BY_WORLD_LABEL: dict[tuple[int, str], tuple[str, int]] = {
    (0, "sprite_phone"): ("sprite_phone", 2),
    (3, "sprite_gear"): ("sprite_gear", 8),
    (3, "sprite_spiderjump"): ("sprite_spiderjump", 7),
    (3, "sprite_bat"): ("sprite_bat", 8),
    (4, "sprite_bat"): ("sprite_bat", 8),
}

MERGED_COMPOUND_ATLAS_GAPS = {
    atlas_name: gap
    for atlas_name, gap in MERGED_COMPOUND_BY_WORLD_LABEL.values()
}
