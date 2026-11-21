# AM-RE-004 — Controlled generator, movement, collision and scoring traces

Version: v20261121-0002

Authority: original Intel 8080 source in [src/maze.asm](../src/maze.asm). Related [maze analysis](MAZE-GENERATION-AND-INTERPRETER.md) and [17-command dictionary](8080-WORD-SEMANTICS.md).

## Execution boundary

Only the original Intel 8080 game running in MAME generates mazes, moves players, detects walls, or changes scores. The [MAME debugger command file](../tools/am-re-004-trace.cmd) observes native routine entries and RAM without modifying gameplay state. The [Node trace analyzer](../tools/analyze-am-re-004-trace.mjs) summarizes observed MAME log events. Neither implements a game, synthesizes command output, or replaces native routines.

MAME is not installed in the assistant's environment. The source analysis is executed; the new MAME debugger recipe remains unexecuted here. Previous ordinary native build and MAME gameplay launch were user-confirmed successful.

## Reproducible MAME run

From the repository root:

~~~sh
node --test test/am-re-004-native-contracts.test.mjs
./build.sh
mame maze -rompath roms -window -skip_gameinfo -debug -log -debugscript tools/am-re-004-trace.cmd
node tools/analyze-am-re-004-trace.mjs error.log
node tools/analyze-am-re-004-grid.mjs build/am-re-004-grid.bin
~~~

The debugger script also saves the **actual native 624-byte maze RAM region** at the command-$06 shift entry to build/am-re-004-grid.bin. The grid analyzer reads the captured bytes, reports bit frequencies and lists all 26 original 24-cell rows. Neither tool generates cells or simulates maze gameplay.

The debugger script uses documented MAME breakpoint, logging, memory-expression, binary save and continuation commands. It writes AM004-prefixed events to the MAME error log, normally error.log. The first 64 visits for several high-frequency maze operations are captured to limit output volume. No RAM or CPU register mutation is performed. Preserve each error.log and the rebuilt ROM hashes together for comparison.

## Seven controlled cases

| Case | Game action | Native PC | Expected evidence |
| --- | --- | --- | --- |
| G1 Initial generation | Start a new game | $03D4, $06F5 | Random-state bytes $2004–$2007 and initial seed-column selection |
| G2 Generate maze | Continue until maze is built | $070E, $078B, $0804, $03F1 | Neighbor candidates, randomized selection, cell writes, completion tests |
| G3 Initialize grid | Advance to maze game fields | $043D | Original 624-cell shift entry, with boundaries $2066–$22D5 |
| M1 Movement | Move through an open corridor | $0A32, $0ABE/$0ACE/$0ADD/$0AF0, $0AB1 | Movement gate, wall tests, committed row and column |
| M2 Collision | Attempt to move into a wall | Same movement routines | Compare position before/after, wall bit $20 or $40, D/carry result |
| S1 Score | Play through a score-changing event | $0514, $0554 | Packed score values $2018/$2019 before the original DAA increment |
| S2 Round | Play through round/result transition | $04DB, $05D9 | State $2029/$2027/$202D and script root $2002 |

A breakpoint hit is evidence of entering a native routine; it is not by itself evidence that a game event had the expected outcome.

## Original generator and maze layout — source proven

Original maze grid: 26 rows x 24 columns, RAM $2066 through $22D5 inclusive. The code at $0403 clears exactly 624 low nibbles. Code at $043D loads BC=$0370, then decrements **C** until zero before decrementing **B**. The actual iterations are 112 + 256 + 256 = **624**. Earlier notes claiming an 880-byte transformation and 256-byte overrun were incorrect and have been corrected throughout the research.

The four-byte random-state routine at $0919 updates $2004–$2007 with rotate/XOR/carry operations. The seed selector at $06F5 samples with E=$18 and saves the selected column to $2025/$2040. It marks the first-row cell with bits $09. Neighbor inspection at $070E builds D bits $01 previous row, $02 next row, $04 previous column, and $08 next column. Candidate count and random choice lead to native wall writes at $0804. The generator invokes native completion checks at $03F1; command $00 only enters a new generation pass while $201F is zero.

## Original movement and collision — source proven

The movement entry at $0A32 checks ($2046 & 7) == 3 and ($2045 & 7) == 7 before loading current row/column from $2043/$2042 and route bits from $2044. Boundary handlers at $0ABE, $0ACE, $0ADD and $0AF0 test horizontal wall bit $20 or vertical wall bit $40, with directional status values $C4, $C1, $C8 and $C2. The commit routine at $0AB1 writes row/column back to $2043/$2042 and merges D into $2044. Cases M1/M2 must confirm whether the same position is preserved or moved for particular real maze-cell states.

## Packed score, rounds, game end — source proven

At $0554 the original score update increments [$2019], applies DAA, then checks $60. The rollover path clears [$2019] and increments adjacent [$2018], also with DAA. These **source-derived** examples follow the original 8080 instruction sequence:

| Score byte before | After |
| --- | --- |
| $08 | $09 |
| $09 | $10 (DAA) |
| $58 | $59 |
| $59 | $00, with increment of $2018 |

At $0514, a round/score update reloads [$200D]=$3C and branches on [$202C]. The other path performs ADD A,$99; DAA on packed state [$202B]. If the countdown is exhausted it restores script $0D64 to [$2002], clears [$200B–$200F], and resets [$2044]/[$2055].

At $04DB the code decrements [$2029] and chooses another round-display update or results-display path. Command $11 at $05D9 checks/decrements [$2027], sets [$202E]/[$202D]=$03 and stores script root $0E27 at [$2002].

## Verification gates

- PASS — source: generator, direction mask, movement, wall and packed-score/round routines are identified and documented at native 8080 instruction addresses.
- PASS — source: original 624-cell grid and separate B/C countdown confirmed. Previous 880-byte claim corrected.
- PASS — static: native source contracts checked against the original ASM and test script added.
- NOT EXECUTED HERE — new Node test file and MAME debugger command file. Reproducible commands are provided above.
- NOT YET RECORDED — actual G1–G3, M1–M2, S1–S2 original MAME debugger observations and their outcome comparisons.

**Disposition: AM-RE-004 source analysis complete; controlled runtime evidence outstanding.** No fabricated trace logs or game outcomes are claimed.
