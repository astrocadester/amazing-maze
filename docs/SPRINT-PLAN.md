# Amazing Maze — Engineering and reverse-engineering plan

Version: v20261121-0001

## Original software and build contract

The original two 2 KB Intel 8080 ROMs in `roms/original/maze.zip` are the executable authority. `src/maze.asm` contains the reconstructed native game, interpreter, original command script, font and graphics. The project builds with bundled zmac v1.3, verifies both original SHA-1 hashes and packages `roms/maze.zip`. The root [engineering rules](../ENGINEERING-RULES.md) and [agent instructions](../AGENTS.md) govern changes.

## Completed and verified

- [x] Identify and preserve `maze.h` (`$0000–$07FF`) and `maze.g` (`$0800–$0FFF`), including their hashes and original ROM identity.
- [x] Reconstruct all 4 KB as native Intel 8080 source and original data in `src/maze.asm`.
- [x] Identify the interpreter at `$0392–$03C9`, zero-command event path at `$03CA`, RAM script cursor `$2000`, and the 17-entry vector table at `$0BEE`.
- [x] Recover the original 37 ten-row font glyphs, indicator graphics, encoded game text, maze-cell addressing and movement boundaries.
- [x] Classify the 668-byte game command stream as 190 original commands; describe operand sizes and label 18 script targets.
- [x] Replace the 54 remaining `NATIVE_xxxx` labels and 217 numeric direct JP/CALL destinations; present graphics inline, decoded text as named records, and commands as annotated DB/DW.
- [x] Build the native source with bundled zmac and confirm original SHA-1 values for both 2 KB devices (user-reported PASS on the current source).
- [x] Run the rebuilt `roms/maze.zip` in MAME (user-reported PASS).
- [x] Preserve the original game architecture and source, documentary evidence, scanner, ROMs, artwork, and toolchain from the earlier hard-RE work.

## Authoritative remaining research inventory

Priorities are ranked within the current work program. Completed work above is omitted from the open-task inventory.

| Task | Priority | Scope and acceptance evidence |
| --- | --- | --- |
| AM-RE-001 | P1 | **Static classification complete:** the [4 KB native code/data ledger](NATIVE-CODE-DATA-MAP.md) now accounts for every ROM byte and names the original checksum tables and inter-routine spans. **Remaining:** verify indirect branch/interrupt reachability and indexed consumers of the explicitly inventoried bytes |
| AM-RE-003 | P1 | Trace the interrupt/frame path through `$0008`, `$030B`, exit at `$02FC`, event path `$03CA/$03D4`, and script-root transitions; establish frame and script cursor ownership |
| AM-RE-004 | P1 | **Combined with completed AM-RE-002:** [original interpreter and maze-generator audit](MAZE-GENERATION-AND-INTERPRETER.md) establishes the command-to-generator path, four-byte random state, $2066 cell layout, candidate direction mask, maze-cell marking and movement tests. **Remaining:** trace concrete generated mazes, verify generator completion, and complete controlled movement/collision/score/round effects. The apparent 880-byte shift discrepancy is resolved (separate B/C countdowns visit exactly 624 cells) |
| AM-RE-005 | P1 | Audit the graphics/display pipeline, all decoded bitmap/data consumers, and exact behavior of display commands `$03`, `$04`, `$07`, `$0A`, `$10`, `$11`; maintain a native routine index and RAM ownership ledger |
| AM-RE-006 | P2 | Verify hardware decoding, possible mirrors, input/output ports, interrupt timing, monochrome raster mapping and device assignments against the MAME driver and original hardware documentation |
| AM-RE-007 | P2 | Compare the original Gun Fight and Amazing Maze interpreter instructions, command operand records and return ABI at the machine-byte level; classify exact reuse, ABI compatibility, related implementations or independent code; evaluate a shared ancestor and contemporary DNA interpreter lineage |
| AM-RE-008 | P2 | Record MAME gameplay cases beyond launch: attract/start, one- and two-player input, generated maze navigation, maze boundaries, timing, scoring and round completion |
| AM-RE-009 | P2 | Verify the Windows `build.bat` pipeline and, separately, original-board operation if hardware becomes available |
| AM-RE-010 | P3 | Identify original cabinet-artwork provenance, distinguish marquee/bezel/flyer assets, and review any documented standalone maze-generation test against original code and archival evidence |
| AM-RE-011 | P3 | Compare other early DNA indexed handlers and lookup tails byte by byte, distinguish common code from similar algorithms, and update corresponding game and master interpreter research when findings are verified |

## Evidence and status policy

Native build equality, MAME launch, extended gameplay tests and physical hardware are independently reported. The user has confirmed byte-exact zmac builds and successful MAME execution; extended gameplay and Windows/hardware tests remain separate research tasks. Names in the reconstructed source describe established instruction behavior and are not represented as original DNA source spellings.

Detailed supporting findings remain in [native RE](NATIVE-RE-PASS.md), [word semantics](8080-WORD-SEMANTICS.md), [graphics and maze](GRAPHICS-AND-MAZE-RE.md), [original ROM scan](ORIGINAL-ROM-RUNTIME-SCAN.md), and [Gun Fight comparison](GUNFIGHT-COMPARISON.md).

## AM-RE-002 consolidation — 2026-11-21

- [x] Previously completed: all 17 original native command addresses and inline packet widths; 190 decoded command records and aligned script branches; documented native cursor and basic handler contracts.
- [x] Fold existing command-to-game and control-flow research into [AM-RE-004's native maze algorithm audit](MAZE-GENERATION-AND-INTERPRETER.md). Do not redo the structural interpreter work.
- [ ] Continue game-specific handler state/flags with AM-RE-004, display semantics with AM-RE-005, scheduler/stack with AM-RE-003.

## AM-RE-001 progress — 2026-11-21

- [x] Create a gap-free, 22-region classification of all `$0000–$0FFF` original ROM bytes.
- [x] Name original ROM-page checksum constants at `$0120`, separate the intervening `$0124` byte, and name the diagnostic glyph table at `$0125` using its native lookup instructions.
- [x] Identify the second restart-vector entry at `$0010` and preserve byte-alignment and inter-routine spans with source labels.
- [x] Compare 2,980 normalized native instruction/data entries and original source addresses against the previous byte-exact build: zero differences.
- [ ] Prove computed/indirect native entry reachability and all unclassified span consumers; see [native ROM code/data map](NATIVE-CODE-DATA-MAP.md).
- [x] Rebuild the AM-RE-001 source with `./build.sh` and launch the resulting ROM in MAME — user-confirmed PASS on 2026-11-21 (hash values not separately supplied for this run).

Task remains open until the remaining reachability evidence is resolved.

- [x] Conservative native reachability audit: **1,551 of 1,551 original instruction statements** reachable from reset/restart/handler roots, no unresolved direct targets; the only two `JP (HL)` sites are `$03C9` (17-vector dispatch) and `$0902` (stack-supplied continuation).
- [x] Identify the two native entry paths into the `$0902` continuation: `CALL` at `INIT_SCRIPT_ROOT` and `JP` at command `$02`; distinguish their stack sources.

## AM-RE-004 build verification — 2026-11-21

- [x] User confirmed `./build.sh` succeeds on the combined AM-RE-002/004 source.
- [x] User confirmed the rebuilt ROM launches and runs successfully in MAME.
- [ ] Controlled maze-generation, movement, collision and scoring traces remain separate research tasks.

## AM-RE-004 original MAME trace instrumentation — 2026-11-21

- [x] Source-check native generator, random state, 624-cell transformation, movement/collision and packed-BCD score/round effects.
- [x] Add passive MAME debugger script at `tools/am-re-004-trace.cmd` for real game execution, including binary capture of original maze RAM before shift.
- [x] Add Node-only trace and 26×24 RAM grid analyzers; add source-contract tests (`test/am-re-004-native-contracts.test.mjs`).
- [ ] Execute the new debugger script against the rebuilt ROM; capture G1–G3, M1–M2, S1–S2 and verify outcomes using [controlled trace protocol](AM-RE-004-CONTROLLED-TRACES.md).

Do not close AM-RE-004 until these native MAME debugger cases are observed and recorded. Source analysis and tracing tools are not substituted for executed gameplay traces.
