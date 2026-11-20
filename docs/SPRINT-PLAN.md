# Amazing Maze — reverse-engineering sprint plan

## Goal

Produce a fully annotated original Intel 8080 source reconstruction, assemble it with the repository's zmac v1.3 and verify both 2 KB ROM devices byte-for-byte against `roms/original/maze.zip`. Retain Checkmate's project organization and presentation conventions.

## Source and authority

- Original ROM: `roms/original/maze.zip`, members `maze.h` and `maze.g`; do not alter original bytes.
- Native CPU and language: Intel 8080; use zmac v1.3's supported syntax as in Checkmate.
- Verified interpreter landmarks and 17 entry vectors: [original ROM runtime scan](ORIGINAL-ROM-RUNTIME-SCAN.md).
- Styling/build reference: [Checkmate](https://github.com/astrocadester/checkmate).

## Tasks

- [x] Preserve original ROM and identify two device boundaries and SHA-1 values.
- [x] Inspect Checkmate's build, README and SVG conventions.
- [x] Add Linux/Windows zmac v1.3 build scripts without Python.
- [x] Create memory map and README with Amazing Maze-specific contents.
- [x] Carry forward `src/maze.asm` (native instruction reconstruction, glyphs, vectors and scripts) from the November 8 hard-RE branch.
- [ ] Complete semantic cleanup of existing `src/maze.asm` and resolve remaining generic labels and unclassified regions.
- [ ] Audit interrupt paths and all 17 original command handlers; establish inline operand formats and script boundaries.
- [ ] Replace unclassified data ranges with verified graphics, strings, pointer tables or control data and add appropriate inline comments.
- [ ] Run native zmac v1.3 assembly and require exact SHA-1 matches for both ROM devices.
- [ ] Run `mame maze -rompath roms -window -skip_gameinfo` and record actual result.
- [ ] Review generated ASM headers, routine separation, blank lines, comments and graphics formatting against Checkmate.
- [ ] Confirm Linux and Windows build scripts and mark the PR ready only after verification.

## Acceptance

`./build.sh` creates `roms/maze.zip` with members `maze.h` and `maze.g` whose SHA-1 hashes match the original archive. All behavior descriptions must be supported by original ROM evidence and reviewed native source. A successful build and a successful MAME run are separate acceptance checks.
