// Asset stubs – on the 8-bit version these referred to cartridge bank offsets.
// On STE everything lives in RAM; real data will be loaded from files.
// GFX = pointer to tile/image data, APU = pointer to aplib-compressed data.

type
    TAsset = record
        GFX: word;
        APU: word;
    end;

var
    B0_BIGVIAL:    TAsset;
    B0_BIGFORMULA: TAsset;
    B0_BIGMAP:     TAsset;
    B0_SKULL:      TAsset;
    B0_FLOB_THEME: TAsset;
    B0_FLOB_TITLE: TAsset;
    B0_CROWN2:     TAsset;
    B0_CHEAT:      TAsset;
    B0_STATBACK:   TAsset;
