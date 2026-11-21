# Amazing Maze — interpreter-driven maze generation and gameplay

Version: v20261121-0001  
Combined scope: **AM-RE-002** (completed structural 17-command interpreter inventory) + **AM-RE-004** (native maze algorithm and game state).

## Existing interpreter work reconciled

The complete command dictionary is in [8080-WORD-SEMANTICS.md](8080-WORD-SEMANTICS.md), and the actual 668-byte stream is represented in [src/maze.asm](../src/maze.asm) as **190 original typed records**. The one-byte codes `$01–$11` dispatch via the original 17 vectors at `$0BEE`; `$00` follows a separate native event path at `$03CA`. All 17 handler entry addresses and operand counts are established. This is already significant AM-RE-002 work, so its structural portion is **complete**. Specific unresolved register/flag/stack effects and handler display behavior belong to the connected native/gameplay investigations, not to another blanket decoder task.

The following source-visible command-to-game bridges are critical:

| Command | Native entry | Inline bytes | Maze/game effect |
| --- | --- | ---: | --- |
| `$00` | `$03CA` | 0 | If `[$201F]` is zero, call `ZERO_COMMAND_EVENT` and run the maze event/generation path |
| `$03` | `$0835` | 0 | Draw the maze boundaries/playfield from RAM cell flags |
| `$05` | `$0B4B` | 0 | Sample I/O port $01 bit $40 and store resulting state at `$202A/$202C` |
| `$06` | `$0419` | 0 | Transform 0x370 bytes of maze state, reset 13 game-state bytes, and copy game-state fields |
| `$07` | `$0B90` | 5 | Draw text record: count8, source16, framebuffer destination16 |
| `$08` | `$0B5F` | 1 | Set timer/state byte `$200C` |
| `$09` | `$0B69` | 3 | Set `$200B` and pointer `$2008` |
| `$0A` | `$08AC` | 0 | Draw maze-cell array from `$2066` into the framebuffer |
| `$0B` | `$0B7B` | 2 | Transfer interpreter script cursor to new address |
| `$0C` | `$0B84` | 3 | Store immediate value into addressed RAM |
| `$0E/$0F` | `$0BB9/$0BC4` | 4 each | Test RAM byte and branch to an inline script address, or advance sequentially |
| `$10` | `$0BCF` | 4 | Format a packed game value as two display characters and render it |
| `$11` | `$05D9` | 0 | Update end/display state, round counters and saved script root |

Command `$04` writes an eight-byte inline display record, `$0D` conditionally updates `$2013`, and `$01/$02` control native continuation/mode. These commands remain in the complete dictionary; no command was removed or synthesized.

## 1. Maze storage layout

`MAZE_CELL_ADDRESS` (`$0940`) computes the maze byte address using row in `B`, column in `C`:

```text
cell_address = $2066 + 24 * row + column
```

Native drawing and clearing loops process **26 rows × 24 columns = 624 cell bytes**, occupying `$2066–$22D5`. Maze rows are numbered `0..25`, columns `0..23`; loop counters are `$1A` and `$18`. Do not infer that all bits of each byte represent the same information. Native consumers distinguish at least:

- bit `$01`: tested via `RRCA` to decide whether neighboring cells can be considered in maze generation;
- bits `$20/$40`: checked by native left/right and up/down wall/boundary handlers;
- bit `$80`: influences the `$0A` rendering path;
- high and low nibbles: processed independently by the `$0403` and `$043D` transformations.

The **generation/clear window** and **nibble-shift window are not the same size**: `CLEAR_MAZE_CELL_LOW_NIBBLES` visits 624 bytes, while `SHIFT_MAZE_CELLS_LEFT_FOUR` visits `$0370 = 880` bytes from `$2066` (ending at `$23D5`). The latter extends **256 bytes past** the standard 26×24 cell region. This is an original native loop bound and should not be silently corrected to 624; the trailing 256-byte region needs its own ownership/consumer audit.

## 2. The command-zero maze-generation path

The original control chain is:

```text
SCRIPT_FETCH ($03AA)
  └─ command $00 → ZERO_COMMAND ($03CA)
      └─ if [$201F] == 0:
          ZERO_COMMAND_EVENT ($03D4)
            ├─ clear 624 low-nibble maze cells
            ├─ [$201C] = 0
            ├─ advance random state using [$200A] as iteration count
            ├─ choose a random column and mark first maze byte
            └─ RUN_ZERO_COMMAND_MAZE_EVENTS
                ├─ inspect neighboring maze cells / form candidate mask in D
                ├─ if E != 0: count/choose direction and write cell flags
                └─ if E == 0: test [$201D], scan/advance cell position
                    ├─ repeat generation path if not complete
                    └─ increment [$201F] and return when complete
```

This is the original native code, not a host implementation. At `ZERO_COMMAND` the test is literal: `LD A,($201F); AND A; CALL Z,ZERO_COMMAND_EVENT; RET`. `$201F` therefore suppresses a subsequent generator call once set, until game state resets it. Exact event timing needs the frame-service and script-return trace.

## 3. Random state and initial maze selection

`READ_GAME_RANDOM_STATE` reads four consecutive bytes `$2004–$2007`. It performs eight iterations of rotate/XOR/carry operations and writes state back to those four bytes. This is an original state-mixing / pseudo-random update **routine**, not evidence for a particular named LFSR polynomial or statistical distribution.

`MAZE_RECALCULATE_RANDOM_STATE` calls that routine as many times as the byte at `$200A` specifies.

`SAMPLE_RANDOM_RANGE` saves BC, calls `READ_GAME_RANDOM_STATE`, then uses a carry/accumulation loop controlled by the caller's `E` value. A bounded result is returned in `A`, with BC restored. Determining its complete numeric distribution requires tracing flags and doing controlled input/output experiments.

`SELECT_MAZE_RANDOM_VALUE` initializes `E=$18` (24), calls that sampler, writes the result to `$2025` and `$2040`, copies it to column `C`, sets row `B=0` and `$2041=0`, finds the maze cell at `$2066+C`, and ORs `$09` into that cell.

This provides a source-grounded starting location: a sample-selected column in the first row, with original marker bits `$09`. It does not alone prove the game always produces a unique full maze or specify a maze-generation family.

## 4. Neighbor tests, candidate mask and direction selection

`MAZE_INSPECT_NEIGHBOR_WALLS` begins with `D=0` and tests four adjacent cells. For each candidate it excludes the outer array boundary and checks bit 0 of the neighboring cell (via `RRCA`). It ORs the following bits into `D` when the corresponding test succeeds:

| Candidate | Added bit in D | Key bound |
| --- | --- | --- |
| Previous row | `$01` | row B must not be 0 |
| Next row | `$02` | row B must not be `$19`, except for special `$201C/$201D` handling |
| Previous column | `$04` | column C must not be 0 |
| Next column | `$08` | column C must not be `$17` |

`MAZE_COUNT_DIRECTION_FLAGS` then rotates the four-bit mask and counts set bits in `E`. A nonzero count causes `RUN_ZERO_COMMAND_MAZE_EVENTS` to call `ADVANCE_MAZE_GENERATION_COUNT`, which conditionally increments `$201C`, sets `$2022=1`, calls `SAMPLE_RANDOM_RANGE`, and selects one of the mask's candidate directions.

Direction-writing routines `MARK_MAZE_PREVIOUS_ROW`, `MARK_MAZE_NEXT_ROW`, `MARK_MAZE_PREVIOUS_COLUMN` and `MARK_MAZE_NEXT_COLUMN` update neighbor/current cells. `WRITE_MAZE_DIRECTION_BITS` combines the previous cell bits with `D` and `([$201D] XOR $08)` before storing the result.

The special bottom-row case (`B=$19`) consults `$201D` and the `$201C >= $46` condition. `SAVE_MAZE_COLUMN_AND_DIRECTION` can store `$08` into `$201D`, save `C` in `$2023`, and resume at row `$19`. These are explicit game-algorithm state transitions, not merely drawing commands.

## 5. Completion and following round

When no candidates remain (`E=0`), `TEST_MAZE_EVENT_COMPLETION` tests `$201D`. A zero value causes a fresh generator pass; otherwise it calls `MAZE_ADVANCE_COLUMN`, which scans cell state, advances across `$18` columns and `$1A` rows and can clear `$2022`. The generator increments `$201F` before returning to the interpreter when the scanner signals completion.

Command `$06` subsequently calls `SHIFT_MAZE_CELLS_LEFT_FOUR`, clears `$2015–$2021`, copies selected state bytes and returns. Commands `$03/$0A` render the maze, while `$05` and the separate movement routines respond to native input/state. The original script, not an invented game loop, controls ordering.

## 6. Movement and collision path

`UPDATE_MAZE_MOVEMENT` (`$0A32`) checks low coordinate bits in `$2046` and `$2045`, loads maze row/column from `$2043/$2042`, and selects one of four sequences of wall tests from bits in `$2044`.

Directional checks are at `$0ABE` (left), `$0ACE` (up), `$0ADD` (right), and `$0AF0` (down). Each uses `MAZE_CELL_ADDRESS` and cell bits `$20` or `$40`; boundary/flag results are delivered through carry and `D`, with code paths assigning `D=$C4,$C1,$C8,$C2`. `STORE_MAZE_POSITION_AND_WALL_STATE` writes the resulting `C` and `B` to `$2042/$2043` and merges `D` into `$2044`. The code is direction- and state-dependent; a complete player-interaction simulation remains distinct from this source trace.

## Remaining work and task ownership

**AM-RE-002 structural inventory: complete, folded into AM-RE-004.** Native handler count, locations, inline packet widths, branches, and the complete original stream have already been decoded. Do not repeat that work.

**AM-RE-004 remains open** for (1) the 880-byte shift window beyond the 624-byte maze grid, (2) a traced end-to-end generated maze with known random-state seed and input, (3) verifying the generator's behavior in its bottom-row `$201D/$201C` special case, (4) movement and collision effects under controlled MAME input, (5) complete scoring/round transitions. Any unresolved display-specific effects of `$03/$04/$07/$0A/$10/$11` belong in AM-RE-005; native scheduler/stack continuation details belong in AM-RE-003.

Static source analysis has not reproduced gameplay in an emulator or independently executed a new build. All descriptions here are grounded in original native instruction sequences and the already decoded script.

## Build and runtime verification — 2026-11-21

After this combined AM-RE-002/004 annotation pass, the user confirmed **native build PASS** and **MAME execution PASS**. The exact per-device SHA-1 output was not provided for this run; both hashes were verified on prior builds. This validates buildability and basic runtime execution, not the still-open controlled gameplay traces.
