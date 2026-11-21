# Amazing Maze — Engineering and reverse-engineering plan

Version: v20261121-0002
Status: **PR #3 release complete; active RE work concluded by project decision (2026-11-21)**

## Original software and build contract

The two original 2 KB Intel 8080 devices in `roms/original/maze.zip` are authoritative: `maze.h` ($0000–$07FF) and `maze.g` ($0800–$0FFF). `src/maze.asm` reconstructs the native game, interpreter, graphics, font, data and original command stream. Bundled zmac v1.3 assembles the game; `./build.sh` verifies the original ROM identities and packages `roms/maze.zip`. [Engineering rules](../ENGINEERING-RULES.md) remain in force.

## Completed project deliverables

- [x] Reconstruct and label all **4,096** native ROM bytes as Intel 8080 instructions and original data.
- [x] Decode the **17 original command handlers**, dispatcher at $0392–$03C9, special command zero at $03CA and 17-entry vector table at $0BEE.
- [x] Decode all **190 original command records** in the 668-byte script, with original operands and aligned branch targets. AM-RE-002's structural interpreter work is complete and integrated into AM-RE-004.
- [x] Recover original 37 ten-row glyphs, encoded game messages, indicators and native drawing routines; preserve original graphics in native source.
- [x] Document 22 contiguous ROM code/data regions and conservative reachability of **1,551/1,551 native instruction statements** without unresolved direct JP/CALL targets. [Native code/data map](NATIVE-CODE-DATA-MAP.md).
- [x] Trace original maze-generating routines, four-byte random state, direction mask, 26×24 cells and native scoring/movement logic. Correct the earlier 880-byte interpretation: separate B/C counters process **624** maze cells.
- [x] Independently verify a user-supplied **624-byte original MAME RAM grid** at $2066–$22D5, SHA-256 `a4f6f85ac9e60a7551de1c4de6fe1cce76fb9a1ca97a089c453889af52d52124`. [Grid evidence](AM-RE-004-MAME-GRID-SNAPSHOT.md).
- [x] Analyze real MAME debugger log: **4,359** native events, including 21 generator entries, 3,964 generator completion checks, one pre-shift capture and 25 packed-BCD score increments. [Execution evidence](AM-RE-004-MAME-EXECUTION-LOG.md).
- [x] Add passive debugger trace commands, source contract tests and Node analyzers. Preserve native program logic.
- [x] User confirmed byte-exact native builds and successful MAME execution; latest code annotations did not change native instructions or data.

## Archived unfinished research — no active sprint

The project is being **closed as-is**, not falsely represented as having proven every research hypothesis. These permanent tracking IDs remain available if RE is reopened. They do not block the completed release.

| Tracking ID | Deferred evidence / investigation |
| --- | --- |
| AM-RE-001 | Indirect branch/restart-vector behavior and possible consumers of isolated ROM bytes; static image classification is complete |
| AM-RE-003 | Interrupt/frame/script-cursor ownership and stack continuation through $0008, $030B, $02FC, $03CA/$03D4 |
| AM-RE-004 | Controlled movement/collision and round-transition events; generator and score-increment execution **already observed** |
| AM-RE-005 | Exhaustive graphics command behavior ($03/$04/$07/$0A/$10/$11), bitmap consumers and RAM ownership |
| AM-RE-006 | Detailed physical hardware I/O, memory mirrors, raster mapping and timing |
| AM-RE-007 | Byte-level Gun Fight interpreter ABI and shared-source lineage comparison |
| AM-RE-008 | Extended one/two-player gameplay input, collision and round-completion tests |
| AM-RE-009 | Windows build.bat and physical-board execution |
| AM-RE-010 | Cabinet artwork provenance and standalone maze-generator test history |
| AM-RE-011 | Cross-game DNA interpreter handler ancestry and master-document research |

AM-RE-002: **completed and consolidated into AM-RE-004; not in the deferred inventory**.

## Evidence boundaries and release decision

Original ROM integrity, native build and MAME launch are separate successful verification gates. Debugger recordings demonstrate actual generator and score execution, but **zero movement/collision breakpoint hits and zero $04DB round-breakpoint hits** were recorded. Windows and physical-hardware tests were not reported. These limitations are preserved rather than rewritten as PASS.

**Decision 2026-11-21:** project owner concludes this RE phase and authorizes merging PR #3. Deferred investigations are archived above for future work, with no active sprint. The implementation, build workflow and native ROMs remain unchanged by this closeout.
