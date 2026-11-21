# AM-RE-004 — Original MAME-generated maze RAM snapshot

Evidence recorded: 2026-11-21. This document transcribes the **user-supplied binary RAM snapshot** from MAME, not a generated or synthetic maze. Source build: original Intel 8080 `maze` game; uploaded assembler listing `amazing-maze.lst` accompanies the snapshot.

## Acquisition and integrity

- Capture: `tools/am-re-004-trace.cmd` breakpoint at native `$043D` (`SHIFT_MAZE_CELLS_LEFT_FOUR`), before the shift routine executes
- Original RAM: `$2066–$22D5`, 26 rows × 24 columns = **624 bytes**
- Original capture file: `build/am-re-004-grid.bin`
- Exact SHA-256: `a4f6f85ac9e60a7551de1c4de6fe1cce76fb9a1ca97a089c453889af52d52124`
- Bytes verified independently from the uploaded 624-byte file, and listing addresses checked against the uploaded zmac listing
- This snapshot is **one actual observed maze state** at the pre-shift breakpoint, not a set of post-shift or gameplay frames

## Observed bytes

| Cell value | Number of cells |
| --- | ---: |
| `$01` | 113 |
| `$03` | 144 |
| `$05` | 188 |
| `$07` | 101 |
| `$09` | 8 |
| `$0B` | 27 |
| `$0D` | 23 |
| `$0F` | 20 |

All 624 values are odd and belong to `$01/$03/$05/$07/$09/$0B/$0D/$0F`; bit `$01` is set in 624 cells, bit `$02` in 292, bit `$04` in 332, bit `$08` in 78, and bits `$10/$20/$40/$80` in zero cells. These measurements are properties of **this captured run**; they are not asserted as invariants for every possible random seed or generated maze.

## Exact original RAM transcription (row-major hexadecimal)

Each line corresponds to 24 consecutive original RAM bytes. Row zero begins at `$2066`; row 25 ends at `$22D5`.

```text
00 07 03 03 03 03 05 07 07 01 07 07 03 05 07 01 07 05 0F 0B 0B 0B 0B 0D 0D
01 07 05 07 03 05 03 01 05 07 01 05 03 01 07 03 01 05 0B 0B 0D 0F 0D 0D 0D
02 01 05 03 05 05 07 03 03 01 07 01 07 05 03 05 07 01 0F 0B 09 0D 0B 09 0D
03 07 01 07 01 05 05 07 05 03 05 07 01 03 05 01 03 05 0F 03 05 0B 0B 0B 09
04 03 03 01 07 01 03 01 03 05 01 07 05 05 05 07 05 05 0B 0D 03 07 03 03 05
05 07 05 05 03 05 07 03 07 01 07 01 05 05 03 01 03 01 05 0F 05 05 07 03 01
06 05 03 01 07 01 03 05 03 05 05 05 07 01 07 03 05 05 0F 0D 05 01 05 07 05
07 05 07 05 05 03 05 05 07 01 03 05 03 03 03 01 07 01 0D 01 03 05 03 01 05
08 03 01 05 05 07 01 05 03 03 07 01 07 05 07 05 01 0F 0B 03 05 05 03 03 01
09 07 05 05 05 07 05 05 07 05 05 05 05 05 01 07 05 0F 05 05 05 03 03 03 05
10 05 01 05 07 01 05 05 05 05 01 07 01 03 03 01 05 0D 01 07 01 07 03 01 05
11 07 03 01 05 05 05 03 01 07 05 05 07 05 03 07 01 0B 0D 03 01 03 03 05 05
12 07 01 07 01 03 01 07 03 01 05 03 05 03 05 05 05 0F 0B 05 07 03 07 01 05
13 03 05 05 07 03 03 01 07 01 07 05 01 07 01 05 05 0B 0D 05 07 05 03 01 05
14 03 03 01 07 03 03 01 05 07 05 05 07 01 05 07 01 0F 09 05 05 03 03 03 01
15 07 03 01 07 03 07 05 03 01 05 03 01 05 05 05 0F 0B 01 05 05 07 05 07 05
16 07 03 05 03 05 01 05 07 05 01 07 03 05 05 05 0B 0D 07 01 03 01 03 01 01
17 05 07 07 01 03 05 03 01 03 05 05 07 01 05 05 0F 09 03 03 03 03 03 03 05
18 05 05 03 05 05 03 07 03 01 03 01 03 03 01 05 0D 0F 0F 0B 0D 0F 0B 0D 01
19 01 05 05 05 07 07 03 01 07 05 03 07 05 05 05 0F 09 03 01 0B 0B 01 0B 0D
20 07 03 01 05 05 05 07 03 01 03 05 01 05 07 01 03 03 03 05 05 0F 0F 01 0D
21 05 07 03 03 01 05 03 05 07 01 07 05 03 01 07 03 03 01 05 05 0D 0B 0B 09
22 05 05 07 05 07 01 07 01 03 05 05 05 07 01 07 05 07 05 03 01 0B 0B 0D 05
23 05 03 01 05 05 05 03 05 07 01 01 07 05 07 01 01 05 03 05 07 03 03 0D 05
24 03 03 05 05 03 03 03 01 05 07 05 01 03 03 03 05 05 05 05 07 05 0F 09 05
25 03 03 01 03 03 03 03 03 03 01 03 03 03 03 01 03 03 01 03 01 01 0F 03 01
```

## Cross-check against actual assembled listing

The user's uploaded zmac listing locates:

- `$03CA`: command-zero event test; `$03CE`: `CALL Z,$03D4`
- `$03D4`: original `ZERO_COMMAND_EVENT`
- `$03E1`: native maze generation neighbor-selection loop
- `$0403`: 26×24 low-nibble clearing routine
- `$0419`: command-$06 handler calls `$043D`
- `$043D`: original maze nibble-shift entry
- `$0440`: `LD BC,$0370`; `$044A`: `DEC C`; `$044E`: `DEC B`
- `$070E`: native neighbor inspection; `$0804`: maze cell direction-bit writer

The split B/C loop gives **112 + 256 + 256 = 624** bytes, confirming the same RAM window as the captured data. The snapshot itself is recorded at the **entry** of that routine, so it does not independently prove the loop has finished.

## Evidence boundaries and AM-RE-004 status

**Observed:** one real MAME native maze RAM capture exists at the command-$06 shift entry; its size, SHA-256, row contents and bit distribution are verified.

**Source-proven:** the original generator and its directional marking instructions use the low-nibble flags; this snapshot is consistent with a populated low-nibble maze. The trace does not establish which specific sequence of random calls generated it.

**Not supplied:** an `error.log` containing the tagged G1/G2, M1/M2 and S1/S2 native breakpoints, a second maze snapshot for reproducibility, or a full input/gameplay trace. Do **not** mark movement, wall collisions, or scoring dynamically verified from this file alone. See [controlled trace protocol](AM-RE-004-CONTROLLED-TRACES.md).
