"""Explicit selector mappings verified against the original cartridge bitmap."""
# These rooms omit PF1. Sorting their three-colour GIF palettes loses the
# missing selector and can turn solid PF0 into a lethal collision colour.
SOURCE_TO_A8 = {
    (2, 22): {0: 3, 1: 0, 2: 1},
    (3, 12): {0: 3, 1: 1, 2: 0},
}
A8_TO_ST = {0: 0, 1: 2, 2: 1, 3: 3}
A8_TO_COLLISION = {0: 0, 1: 2, 2: 3, 3: 1}
ST_PREVIEW_PALETTE = [0, 0, 0, 255, 255, 255, 170, 170, 170, 85, 85, 85] + [0] * 756


def remap_source(image, key, collision=False):
    mapping = A8_TO_COLLISION if collision else A8_TO_ST
    result = image.copy()
    result.putdata([mapping[SOURCE_TO_A8[key][int(p)]] for p in image.getdata()])
    result.putpalette(ST_PREVIEW_PALETTE)
    result.info.pop('transparency', None)
    return result
