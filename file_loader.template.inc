{ Generated distribution loader runs before video, input and audio takeover. }
var
    assetFile: file;
    assetPath: string;
    assetOpen: boolean = false;

procedure AssetFailure(const reason: string);
{$ifdef VERIFY_FILE_ASSETS}
var report: text;
{$endif}
begin
    if assetOpen then begin
        {$I-} Close(assetFile); {$I+}
        if IOResult <> 0 then;
    end;
    Writeln('Flob resource error: ', assetPath);
    Writeln(reason);
{$ifdef VERIFY_FILE_ASSETS}
    Assign(report, 'FILE.ERR');
    Rewrite(report);
    Writeln(report, assetPath, ': ', reason);
    Close(report);
{$endif}
    Halt(1);
end;

procedure ReadAssetBytes(dst: pointer; count: longint);
var got: longint;
    status: word;
begin
    {$I-} BlockRead(assetFile, PByte(dst)^, count, got); {$I+}
    status := IOResult;
    if (status <> 0) or (got <> count) then AssetFailure('Read failed or truncated file');
end;

procedure OpenAssetGroup(const path: string; expectedSize, expectedCrc: longword; entries: word);
var header: packed record
        magic: array[0..3] of char;
        version, count: word;
        bytes, crc: longword;
    end;
    actualSize: longint;
    status: word;
begin
    assetPath := path;
    Assign(assetFile, path);
    FileMode := 0;
    {$I-} Reset(assetFile, 1); {$I+}
    status := IOResult;
    if status <> 0 then AssetFailure('Cannot open file');
    assetOpen := true;
    {$I-} actualSize := FileSize(assetFile); {$I+}
    status := IOResult;
    if (status <> 0) or (actualSize <> longint(expectedSize)) then AssetFailure('Wrong file size');
    ReadAssetBytes(@header, SizeOf(header));
    if (header.magic[0] <> 'F') or (header.magic[1] <> 'L') or
       (header.magic[2] <> 'B') or (header.magic[3] <> '1') or
       (header.version <> 1) or (header.count <> entries) or
       (header.bytes <> expectedSize - 16) or (header.crc <> expectedCrc) then
        AssetFailure('Wrong resource version; rebuild the complete disk folder');
end;

procedure ReadAsset(dst: pointer; actualSize, expectedSize, expectedCrc: longword);
var pad: byte;
{$ifdef VERIFY_FILE_ASSETS}
    crc, i: longword;
    bit: byte;
{$endif}
begin
    if actualSize <> expectedSize then AssetFailure('Pascal resource size mismatch');
    ReadAssetBytes(dst, actualSize);
    if (actualSize and 1) <> 0 then ReadAssetBytes(@pad, 1);
{$ifdef VERIFY_FILE_ASSETS}
    crc := $FFFFFFFF;
    for i := 0 to actualSize - 1 do begin
        crc := crc xor PByte(dst)[i];
        for bit := 0 to 7 do
            if (crc and 1) <> 0 then crc := (crc shr 1) xor $EDB88320
            else crc := crc shr 1;
    end;
    if (crc xor $FFFFFFFF) <> expectedCrc then AssetFailure('Payload checksum mismatch');
{$endif}
end;

procedure CloseAssetGroup;
var status: word;
begin
    {$I-} Close(assetFile); {$I+}
    status := IOResult;
    assetOpen := false;
    if status <> 0 then AssetFailure('Close failed');
end;

procedure LoadFileAssets;
var savedMode: byte;
begin
    savedMode := FileMode;
{ LOAD_ASSET_GROUPS }
    FileMode := savedMode;
end;

{$ifdef VERIFY_FILE_ASSETS}
procedure WriteFileAssetsVerified;
var report: text;
begin
    Assign(report, 'LOAD.OK');
    Rewrite(report);
    Writeln(report, 'PASS all resource sizes and CRC32 checks');
    Close(report);
end;
{$endif}
