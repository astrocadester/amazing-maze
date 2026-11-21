# Amazing Maze — Technical debt and verification ledger

Version: v20261121-0001

## Verified software

The original source is reconstructed as `src/maze.asm` and assembled with bundled zmac v1.3. The user confirmed the latest source builds, that both original 2 KB ROM SHA-1 hashes match, and that the resulting ROM runs in MAME.

| Verification | Evidence | Status |
| --- | --- | --- |
| Original ROM identity | `roms/original/maze.zip`: `maze.h` and `maze.g`, 2 KB each | PASS |
| Native 4 KB Intel 8080 source | `src/maze.asm` with complete original 4 KB source/data layout | PASS |
| Native build / exact hashes | `./build.sh`; `maze.h` `62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c`, `maze.g` `893f0a7621e7df19f777be991faff0db4a9ad571` | PASS — user-reported |
| Generated MAME ROM | `roms/maze.zip` containing the two split devices | PASS — user-reported |
| MAME execution | `mame maze -rompath roms -window -skip_gameinfo` | PASS — user-reported |
| Extended gameplay coverage | Two-player, collision, timing, progression, scoring | Open — AM-RE-008 |
| Windows build | `build.bat` | Open — AM-RE-009 |
| Original hardware | Physical board execution | Open — AM-RE-009 |

## Open technical research

The [sprint plan](SPRINT-PLAN.md) contains the single authoritative numbered task inventory and priority order. Current technical areas are: native routine and data reachability (AM-RE-001); command, interrupt and execution ABI (AM-RE-002/003); maze generation and gameplay logic (AM-RE-004); renderer, bitmap and RAM ownership (AM-RE-005); hardware map and I/O verification (AM-RE-006); interpreter lineage with Gun Fight and other DNA games (AM-RE-007/011); expanded MAME coverage and Windows/hardware verification (AM-RE-008/009); and archival image/test provenance (AM-RE-010).

Specific evidence boundaries:

- The 17 native command vectors are identified and the 668-byte stream is decoded as 190 records. Complete native register/flag/stack and behavioral contracts still require targeted runtime tracing.
- `$03CA` is the zero-command event path; exact timing/continuation through `$03D4` and the interrupt exit are separate audit items.
- RAM at `$2066` holds the maze data and `$2400–$3FFF` is framebuffer memory. Complete hardware decoding, including any higher-address mirrors, requires original driver/schematic verification.
- The [Gun Fight comparison](GUNFIGHT-COMPARISON.md) already records the common `$2000` script cursor, corresponding `GOTO_SCRIPT` operands and different 8080 entry conventions. Shared function does not, by itself, prove exact byte reuse or a common source module.
- Original graphics are expressed inline with byte-accurate rows, game text with named control/string spans, and script commands in original DB/DW order. The functional names are analytical descriptions grounded in original code.

## Source integrity

Keep `roms/original/maze.zip` unchanged. Assemble original Intel 8080 code with bundled zmac and verify both device hashes after source edits. Record build results and MAME gameplay observations separately. Additional research changes should retain meaningful labels, formatted original data, complete routine documentation and reproducible executable verification.

## AM-RE-001 static source audit — 2026-11-21

[Native ROM code/data map](NATIVE-CODE-DATA-MAP.md) now partitions all **4,096 bytes** of the original ROM into 22 contiguous classified regions, including native startup/restart vectors, ROM diagnostics, named checksum and failure-glyph tables, native renderer and fonts, frame/interpreter code, maze/game code, dispatch vectors, messages, graphics, and original command script. The source names previously anonymous bytes at `$000F`, `$0120–$0128`, `$03D2–$03D3`, `$0418`, `$07F1–$07F2` and `$0BEC–$0BED`, and documents their known native readers or outstanding evidence.

**Static PASS:** 4 KB source address layout and **2,980 normalized instruction/data entries** match source commit `dd17820`; zero code/data differences. Native assembler and hash verification of these new source symbols is **pending**. The user previously verified the underlying source ROM hashes and MAME boot.

**Remaining AM-RE-001 work:** computed/indirect branches, potential secondary restart entry, possible data reads through indexed pointers, isolated `$C9` at `$0418`, and the identified inter-routine bytes. The research task remains open for those dynamic proofs.
