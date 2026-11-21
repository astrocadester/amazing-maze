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

The [sprint plan](SPRINT-PLAN.md) contains the single authoritative numbered task inventory and priority order. Current technical areas are: native routine and data reachability (AM-RE-001); interrupt and execution ABI (AM-RE-003); interpreter-driven maze generation and gameplay logic (AM-RE-004, incorporating completed AM-RE-002); renderer, bitmap and RAM ownership (AM-RE-005); hardware map and I/O verification (AM-RE-006); interpreter lineage with Gun Fight and other DNA games (AM-RE-007/011); expanded MAME coverage and Windows/hardware verification (AM-RE-008/009); and archival image/test provenance (AM-RE-010).

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

**Static PASS:** 4 KB source address layout and **2,980 normalized instruction/data entries** match source commit `dd17820`; zero code/data differences. The user confirmed the AM-RE-001 source **builds and runs in MAME** on 2026-11-21. The exact per-device hashes were not pasted for this run; previous builds verified both original SHA-1 values.

**Remaining AM-RE-001 work:** computed/indirect branches, potential secondary restart entry, possible data reads through indexed pointers, isolated `$C9` at `$0418`, and the identified inter-routine bytes. The research task remains open for those dynamic proofs.

### Native reachability follow-up

A conservative native control-flow graph rooted at reset, restart vectors and the original 17 command handlers reaches **all 1,551 native instruction statements**. All direct JP/CALL targets resolve. Two computed jumps exist: `$03C9`, which indexes the original 17-entry command table, and `$0902`, which resumes an address popped from the stack. The latter has two source-visible callers, one via `CALL` and one via `JP`. The [full source and data audit](NATIVE-CODE-DATA-MAP.md) records these edges and the remaining hardware/dynamic reachability questions.

## AM-RE-002 and AM-RE-004 reconciliation — 2026-11-21

The 17 native command handlers, opcode/inline operand widths, script-pointer mechanics, native branch contracts, and all 190 original command records were already reconstructed. AM-RE-002's **structural interpreter audit is complete**; it is consolidated into [AM-RE-004](MAZE-GENERATION-AND-INTERPRETER.md) rather than reopening the same decoding work.

The combined audit now documents the source-visible command-zero generator path, 26×24 cell storage at `$2066–$22D5`, four-byte random state at `$2004–$2007`, direction-mask bits, bottom-row generation transitions, player movement flags and the 624-byte nibble-shift loop covering `$2066–$22D5`. The earlier 880-byte interpretation is corrected: `BC=$0370` is decremented as separate B/C counters, yielding 112+256+256=624 bytes.

**Open evidence:** concrete random-state/generated-maze traces, special generator completion and dynamic movement/collision/score cases. Graphic-handler behavior remains with AM-RE-005 and timing/stack continuation with AM-RE-003. Native rebuild of the new source comments is pending; no ROM bytes were intentionally modified.

## AM-RE-004 user verification — 2026-11-21

User confirmed successful native build and MAME execution after the combined interpreter/maze-generation research pass. These are **PASS — user-reported**. Source changes in that pass were comment-only; exact per-device SHA-1 output was not supplied for this latest run. Native game-state experiments remain open.

## AM-RE-004 controlled runtime evidence gate

The source-level RE of the generator, directions, movement, collision, score/round logic and the correct 624-byte shift count is documented. The repository now contains a passive debugger command file and Node-only log/grid analyzers. The MAME command file automatically captures the real maze's 624 bytes at the pre-shift entry. **Dynamic G1–G3, M1–M2 and S1–S2 evidence is still pending**; this environment could not run MAME. The previous normal MAME run was user-confirmed successful, which is a separate verification gate.

### AM-RE-004 actual MAME RAM capture — 2026-11-21

User supplied a **real 624-byte generated-maze RAM dump** captured at native breakpoint `$043D` (pre-shift), along with the zmac `amazing-maze.lst`. Both files were inspected directly; the snapshot SHA-256 matches `a4f6f85ac9e60a7551de1c4de6fe1cce76fb9a1ca97a089c453889af52d52124`, and the listing agrees with the recorded original generator/shift addresses. Full cell contents, frequencies and evidence limits are preserved in [AM-RE-004-MAME-GRID-SNAPSHOT.md](AM-RE-004-MAME-GRID-SNAPSHOT.md).

**One debugger capture: OBSERVED.** Exact G1/G2 routine order, maze completion, controlled movement/collision and scoring/round outcomes still require a debugger `error.log` and matched actual input observations. Do not close AM-RE-004 on the strength of the RAM snapshot alone.
