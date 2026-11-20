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
- [x] Resolve all `NATIVE_xxxx` label definitions and replace 217 numeric JP/CALL operands with verified source symbols.
- [x] Convert 37 font glyphs and 49 indicator bytes to inline bitmap rows; render message glyph data using quoted character runs and original control bytes.
- [x] Decode 190 command packets spanning the original 668-byte script, label 18 original script branch destinations and represent typed inline operands with DB/DW.
- [ ] Finish instruction-level review of gameplay effects, graphics ownership, I/O and CPU register contracts.
- [ ] Audit interrupt paths and all 17 original command handlers; establish inline operand formats and script boundaries.
- [x] Reformat documented font, indicator graphics, encoded text and the 17 native handler pointers; retain original command/data order.
- [ ] Review other unclassified native tables, remaining raw DB spans and individual routine contracts.
- [x] Native zmac v1.3 assembly and exact SHA-1 matches on previous source-style commit `10d4e72`, verified by the user.
- [ ] Rerun native assembly and both ROM SHA-1 checks after the latest inline graphics, text, branch-label and command-script edits.
- [ ] Run `mame maze -rompath roms -window -skip_gameinfo` and record actual result.
- [x] Review Checkmate's source patterns for headers, routine comments, inline bitmaps, quoted text, pointer vectors and script data; apply them to Amazing Maze.
- [ ] Review final formatting and native-assembly verification after the latest edits.
- [ ] Confirm Linux and Windows build scripts and mark the PR ready only after verification.

## Acceptance

`./build.sh` creates `roms/maze.zip` with members `maze.h` and `maze.g` whose SHA-1 hashes match the original archive. All behavior descriptions must be supported by original ROM evidence and reviewed native source. A successful build and a successful MAME run are separate acceptance checks.

## Readability pass — 2026-11-20

- [x] Remove duplicate command-index comments from all 17 native vectors.
- [x] Segment the 291-byte game text into 20 descriptively labeled original messages and control sequences with quoted string runs.
- [x] Replace 17 numeric script-entry names with functional names based on their native game-command sequences.
- [x] Use preceding comments and spacing for all 190 original game command records.
- [x] Compare normalized instructions and DB/DW contents against the previously byte-exact source: all 2,980 canonical opcode/data entries match; 4,096-byte layout matches.
- [ ] Execute `./build.sh` and run the newly rebuilt ROM in MAME.
