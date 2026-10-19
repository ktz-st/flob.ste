# Building and packaging Flob ST/STE

Run project commands from flob-ste. This is the canonical repository;
../flob-files is generated. Keep ../flob available for original world data
and import tools. Do not reimport artwork over the edited PNGs.

## Free Pascal toolchain

Recipe source: local ../atari-st-builder/Dockerfile and fpc.cfg, inspected
2026-10-19. These instructions document that recipe; installation was not
repeated as part of this documentation update. The builder uses Linux/amd64
Debian Bookworm, FPC 3.2.2 to bootstrap FPCSource, VASM and VLINK.

The complete container can be built from the workspace root:

```sh
docker build --platform linux/amd64 -t atari-st-builder ./atari-st-builder
```

It includes unrelated C/AGT/GodLib tools too. Packaging dependencies below are
not all installed by that Dockerfile. Its Linux .deb is not a native macOS
installer. Native macOS needs a host FPC bootstrap and matching host tools.

### VASM and VLINK

Download and extract the source archives used by the builder:

- VASM: http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
- VLINK: http://sun.hasenbraten.de/vlink/release/vlink.tar.gz

With a host C compiler and make installed:

```sh
# In extracted vasm/:
make CPU=m68k SYNTAX=mot
make CPU=m68k SYNTAX=std
sudo install -m 0755 vasmm68k_mot vasmm68k_std /usr/local/bin/
sudo ln -s /usr/local/bin/vasmm68k_std /usr/local/bin/m68k-atari-vasmm68k_std
# In extracted vlink/:
make
sudo install -m 0755 vlink /usr/local/bin/
```

Do not replace an existing tool/symlink blindly. Use a private prefix if needed,
then add its bin directory to PATH.

### Compiler and Atari RTL

On Linux/amd64, install git, make, wget, certificates and the host build tools.
The builder's Free Pascal steps are:

```sh
wget -O fpc-bootstrap.deb 'https://sourceforge.net/projects/lazarus/files/Lazarus%20Linux%20amd64%20DEB/Lazarus%204.6/fpc-laz_3.2.2-210709_amd64.deb/download'
sudo dpkg -i fpc-bootstrap.deb
git clone https://github.com/fpc/FPCSource
cd FPCSource
make clean crossall crossinstall OS_TARGET=atari CPU_TARGET=m68k \
  CROSSOPT="-Avasm -Cp68000" INSTALL_PREFIX="/opt/fpc"
```

The installation prefix must be writable (the builder runs in a container).
Record the FPCSource revision: the Dockerfile clones an unpinned branch, so a
future checkout can produce a version other than the current 3.3.1.
Copy ../atari-st-builder/fpc.cfg to /opt/fpc/lib/fpc/etc/fpc.cfg; its contents:

```text
#IFDEF CPUM68K
-Fu/opt/fpc/lib/fpc/3.3.1/units/atari/rtl
-Fu/opt/fpc/lib/fpc/3.3.1/units/atari/rtl/*
-Fu/opt/fpc/lib/fpc/3.3.1/units/m68k-atari
-Fu/opt/fpc/lib/fpc/3.3.1/units/m68k-atari/*
#IFDEF ATARI
-FD/usr/bin
-Cp68000
-XV
#ENDIF
#ENDIF
```

Add /usr/local/bin and /opt/fpc/lib/fpc/3.3.1 to PATH. Adapt version/unit/tool
paths on other installations. Check configuration lookup with compiler verbose
output if needed. `ppcross68k -iV` and a project build verify the cross toolchain;
the host `fpc -iV` alone does not check the Atari RTL.

## Packaging tools: sources and compilation

These are HOST programs, not Atari binaries. Use a host C/C++ compiler, not
m68k GCC. Put installed tools on PATH. The examples use $HOME/.local/bin to
avoid system changes. Pin revisions/releases for repeatable release builds.

### Apultra: resource compression

Source: [emmanuel-marty/apultra](https://github.com/emmanuel-marty/apultra).
The local ../apultra/Makefile builds libdivsufsort as part of the library;
no separately installed libdivsufsort is needed.

```sh
git clone https://github.com/emmanuel-marty/apultra.git
cd apultra
make CC=cc
mkdir -p "$HOME/.local/bin"
install -m 0755 apultra "$HOME/.local/bin/apultra"
export PATH="$HOME/.local/bin:$PATH"
```

Used by graphics/world converters and file_bundle.py. FLB2 compresses entire
bundles only if smaller; it retains existing inner compression. The game
validates packed CRC before UnApl, then expanded CRC before binding pointers.

### UPX: PRG compression

Source: [upx/upx](https://github.com/upx/upx), build instructions:
[README.SRC](https://github.com/upx/upx/blob/devel/README.SRC).
The upstream instructions require a C++17 compiler, GNU make and CMake >=3.13.
Use a recursive checkout for bundled dependencies; normal packer builds use
prebuilt decompressor stubs, so no Atari cross tools are needed for UPX itself.

```sh
git clone --recursive https://github.com/upx/upx.git
cd upx
# Select the desired release, then synchronize its submodules:
git submodule update --init --recursive
make
mkdir -p "$HOME/.local/bin"
install -m 0755 build/release/upx "$HOME/.local/bin/upx"
upx --version
```

The current release was packed using UPX 5.2.1. After changing UPX versions,
check Atari/TOS support and retest on ST and STE, including startup RAM use:

```sh
upx --best /path/to/fresh/FLOB.PRG
upx -t /path/to/fresh/FLOB.PRG
```

Do not repack an already packed PRG. The project builder compiles fresh files
before packing them. Another packer version can change the floppy size budget.

### mtools: FAT12 floppy images

Source and release downloads: [GNU mtools](https://www.gnu.org/software/mtools/),
[release archives](https://ftp.gnu.org/gnu/mtools/).
Use an official release tarball (includes configure), extract it and build:

```sh
# In the extracted mtools release directory:
./configure --prefix="$HOME/.local"
make
make install
mformat -V
mcopy -V
```

Requires a host C compiler and make. Follow that release's INSTALL for optional
platform dependencies. Flob uses mformat, mmd and mcopy on regular image files,
not raw device access; no root privileges or custom drive config are needed.
build_floppy.py checks geometry, free FAT space and byte-for-byte readback.

### ZIP, Python and optional tools

Install zip/unzip through the host package manager; they only package the HDD
release, and do not perform the game's runtime decompression. Upstream source
is [Info-ZIP](https://infozip.sourceforge.net/). For the traditional Zip 3.0 and
UnZip 6.0 source trees on Unix, their documented build targets are:

```sh
# In zip30/:
make -f unix/Makefile generic
# In unzip60/:
make -f unix/Makefile generic
```

Prefer maintained OS packages for these older projects and platform patches.
The resulting zip/unzip executables can be installed into $HOME/.local/bin.
Python 3 plus Pillow is needed for artwork/export/tests; use a virtualenv:

```sh
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install Pillow
```

Legacy image import paths may additionally use Netpbm (including ppmtopi1).
Audio regeneration and A8 captures have their own emulator/conversion tools;
they are not required to package existing generated assets. Hatari plus a
legally supplied TOS ROM is needed for target tests. Inspect hardcoded local
headless-Hatari paths in test scripts when moving to another workstation.

## Project commands

```sh
make                            # Embedded flob.prg, auto ST/STE rendering
make st                         # Embedded CPU-only test edition
make sprite-atlas-assets-only   # Compile existing edited sprite PNG
make files                      # ../flob-files/disk: external assets + PRGs
make files-floppy               # Also FLOB720.ST and FLOB720.json budget/hash
```

Default audio is PSG; DMA synthesis is optional and excluded from the release.
The normal Makefile permits `make PPC=/path/to/ppcross68k`; Python build/test
scripts currently hardcode /opt/fpc/lib/fpc/3.3.1/ppcross68k. Change those paths
explicitly on another installation. Run builds serially. Do not run atlas or
original-art initialization targets over edited art for a normal build.

FLOB.PRG selects ST CPU / STE blitter automatically; FLOBST.PRG is diagnostic.
The file-backed edition is the 1 MiB release, not the embedded PRG. See
FILE_VERSION.md for memory ownership, FLB2 format and validation. The current
720 KiB image has 13312 bytes free before saves; future artwork may change this.

## HDD ZIP

Canonical tester instructions live in TESTERZY.TXT here. After exporting:

```sh
cp TESTERZY.TXT ../flob-files/disk/TESTERZY.TXT
cd ../flob-files
# If absent: ln -s disk flob
# Ensure flob-release-new.zip does not already exist.
zip -r -9 flob-release-new.zip flob \
  -x 'flob/flob.sav' 'flob/FLOB.SAV' 'flob/FLOBST.PRG' '*/.DS_Store'
unzip -t flob-release-new.zip
mv flob-release-new.zip flob.zip
```

Create a fresh archive to avoid retaining obsolete entries. Follow the flob ->
disk symlink (do not use zip -y). Never package or overwrite the user's save.
The floppy builder has a manifest whitelist, so TESTERZY.TXT is HDD-ZIP only.

## Verification

```sh
python3 -m unittest test_file_bundle.py test_file_sprite_groups.py
python3 verify_file_version.py --gameplay --lifetime
python3 verify_floppy.py --no-build
git diff --check
```

The floppy test uses private images, no HDD, ST and STE with 1 MiB/68000/8 MHz,
configured TOS (currently 2.06) and normal FDC timing. Several seconds of black
screen during loading are expected. Automated regressions are not a full
manual playthrough or physical-hardware test. See TESTERZY.TXT for A8 comparison.
