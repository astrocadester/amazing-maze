# Amazing Maze — Technical debt and release verification ledger

Version: v20261121-0002
Status: **Release accepted; residual RE archived, not active**

## Release gates

| Gate | Evidence | Status |
| --- | --- | --- |
| Original ROM identity | `roms/original/maze.zip`; two 2 KB devices | PASS |
| Original `maze.h` SHA-1 | `62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c` | PASS — previously user-reported native build |
| Original `maze.g` SHA-1 | `893f0a7621e7df19f777be991faff0db4a9ad571` | PASS — previously user-reported native build |
| Native reconstruction | `src/maze.asm`; complete original 4 KB | PASS |
| Build and MAME | `./build.sh` and `mame maze -rompath roms -window -skip_gameinfo` | PASS — user-reported |
| Original pre-shift maze RAM | 624 bytes, $2066–$22D5; SHA-256 `a4f6f85ac9e60a7551de1c4de6fe1cce76fb9a1ca97a089c453889af52d52124` | PASS — attached original MAME capture verified |
| Native debugger events | 4,359 recorded; generator, choice, writes, completion checks, BCD increments | PASS for observed breakpoint entries |
| Controlled player movement and wall collisions | No move/wall breakpoint hits | NOT OBSERVED — deferred |
| Round-transition breakpoint $04DB | No breakpoint hit | NOT OBSERVED — deferred |
| Windows build and physical board | No execution evidence | NOT TESTED — deferred |

## Established architecture

The original 8080 game and data occupy ROM $0000–$0FFF. The source includes 17 original interpreter vectors at $0BEE, special zero-command processing at $03CA and 190 original script records occupying $0D64–$0FFF. The maze uses **26 × 24 = 624** cell bytes at $2066–$22D5. Command-$06 initializes BC=$0370, but decrements **C and B separately**, processing 112+256+256 = 624 cells, not 880. The previously claimed 256-byte overrun was an analysis error and is corrected in source and supporting documents.

The [native code/data map](NATIVE-CODE-DATA-MAP.md) classifies all 4,096 ROM bytes and records two native computed `JP (HL)` sites ($03C9 and $0902). Static analysis reaches 1,551 native instruction statements; dynamic reachability into each isolated byte is not established.

The [MAME maze snapshot](AM-RE-004-MAME-GRID-SNAPSHOT.md) and [execution log audit](AM-RE-004-MAME-EXECUTION-LOG.md) preserve actual original-data evidence, including 21 generation entries, 3,964 completion-test entries, 25 packed-BCD score increments and two end-state entries. These do not prove controlled movement or round completion.

## Residual research disposition

**No active blocking technical debt for this accepted RE release.** Unfinished research is **deferred by project decision**, not marked experimentally completed.

The single authoritative list of permanent AM-RE IDs and archived research scopes is maintained in [SPRINT-PLAN.md](SPRINT-PLAN.md). It covers: AM-RE-001, 003–011. AM-RE-002 is completed and integrated with AM-RE-004.

Keep ROM originals unchanged, use bundled `tools/zmac` v1.3, preserve original DNA code/data and the root [engineering rules](../ENGINEERING-RULES.md). Retain this archive and all evidence for future optional RE.

## Closeout — 2026-11-21

The project owner accepted the native rebuild, MAME execution and documented RE depth as sufficient to conclude PR #3. This closeout updates **documentation only**. Original assembly, ROMs, shaders, gameplay, native toolchain and debug artifacts are not altered.
