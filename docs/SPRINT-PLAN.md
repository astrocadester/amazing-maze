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
| AM-RE-001 | P1 | Complete native reachability and code/data classification, including padding and hardware-dependent table uses; document each unresolved span against its original read/write sites |
| AM-RE-002 | P1 | Audit the 17 command handlers and interpreter continuation contract: registers, flags, stack, RAM side effects, read widths, caller/return behavior and branch semantics; add confirmed contracts to [command semantics](8080-WORD-SEMANTICS.md) |
| AM-RE-003 | P1 | Trace the interrupt/frame path through `$0008`, `$030B`, exit at `$02FC`, event path `$03CA/$03D4`, and script-root transitions; establish frame and script cursor ownership |
| AM-RE-004 | P1 | Recover maze generation, random-state seed, storage, traversability, boundary and collision checks, movement, score/round progression and player input from original native routines |
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
