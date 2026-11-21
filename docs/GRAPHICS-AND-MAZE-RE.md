# Amazing Maze — recovered graphics and maze native routines

Version: v20261121-0001

## Source of truth

The reconstructed 8080 source is [`src/maze.asm`](../src/maze.asm). The original video/game data remains in ROM address order and is represented by native instructions, named glyphs, named data tables and original command bytes. ROM addresses below refer to the original machine program.

## Original ten-row character font ($0170–$02E1)

`DRAW_TEXT_GLYPH_STREAM` at **$0129** indexes a 37-entry font at **$0170**, with **ten bytes per character** and a **32-byte vertical framebuffer stride**. The source names each of the 37 characters individually and displays its original pixel bitmap directly above the ten bytes.

Example of the original glyph **0**:

```asm
FONT_DIGIT_0:
;     ####
;   ########
;   ##    ##
;   ##    ##
;   ##    ##
;   ##    ##
;   ##    ##
;   ##    ##
;   ########
;     ####
    DB $3C,$7E,$66,$66,$66,$66,$66,$66,$7E,$3C
```

A lit pixel (`##`) corresponds to a set bit; a space corresponds to a clear bit. The 37 glyphs contain digits 0–9, blank, and letters A–Z. The renderer uses the original ten-row glyph storage directly.

### Native text renderer ($0129)

- **Input:** `HL` addresses encoded text bytes; `DE` is framebuffer destination; `A` is the item count.
- **Code selection:** encoded text bytes below `$30` act as position commands, while character values select ten-byte entries from the original font table.
- **Output:** for each selected glyph, ten bitmap rows are copied into framebuffer memory, advancing `HL` by `$20` bytes per row.
- **Stack/register behavior:** `AF` is saved at entry; the glyph path also saves/restores the text and screen pointers while copying rows.
- **Script integration:** command `$07` at `$0B90` consumes `byte8, pointer16, destination16`, updates script pointer `$2000`, then jumps into the native text renderer.

The startup script beginning at `$0D64` includes an invocation using font/text pointer `$0C10` and framebuffer destination `$2408`.

## Original game message stream ($0C10–$0D32)

`GAME_TEXT_STREAM` is an original encoded message array. The source displays readable characters beside its `DB` data. For example, its early bytes spell **THE AMAZING MAZE** and subsequent text includes **MAZES WON**, **SELECT**, **SINGLE PLAYER**, **TWO PLAYER**, **INSERT COIN**, and **GAME OVER**. Control values are shown as periods in the source preview while retaining their numeric operands.

The data is consumed by the original renderer and related native routines, preserving its native spacing and positioning conventions.

## Original small indicator bitmaps ($0D33–$0D63)

`GAME_INDICATOR_BITMAPS` contains 49 bytes of game graphics and indicator data adjacent to the text stream. Each original byte is accompanied by a binary pixel illustration in the source. Its consumers determine each sprite's screen-space role.

## Maze cell representation and movement

### Maze buffer transformations ($0403, $043D)

`CLEAR_MAZE_CELL_LOW_NIBBLES` at **$0403** visits **26 rows × 24 columns** starting at RAM **$2066**. It masks every cell with `$F0`, leaving the high nibble.

`SHIFT_MAZE_CELLS_LEFT_FOUR` at **$043D** processes **$0370 bytes** beginning at RAM **$2066**. It shifts each byte left four bits, preserving its former low nibble as the new high nibble.

These are separate native operations over the original maze representation. Importantly, **26 × 24 = 624 bytes**, but **$0370 = 880 bytes**, so the second loop also processes 256 bytes beyond the displayed/cleared maze cells, ending at `$23D5`. This is an original native instruction count, not a typo to correct. The ownership of the trailing 256 bytes requires further audit. See [maze generation and interpreter](MAZE-GENERATION-AND-INTERPRETER.md) for the native random-state, direction-selection, and completion logic.

### Directional boundary checks ($0A32–$0B0F)

`UPDATE_MAZE_MOVEMENT` at **$0A32** reads state from **$2042–$2046**, selects a sequence of neighboring cell tests, and updates current column, row, and wall-state fields through `STORE_MAZE_POSITION_AND_WALL_STATE`.

- `CHECK_MAZE_LEFT_BOUNDARY` at `$0ABE` decrements column `C` and tests cell bit `$20`.
- `CHECK_MAZE_UP_BOUNDARY` at `$0ACE` decrements row `B` and tests cell bit `$40`.
- `CHECK_MAZE_RIGHT_BOUNDARY` at `$0ADD` increments column `C` and tests cell bit `$20`.
- `CHECK_MAZE_DOWN_BOUNDARY` at `$0AF0` increments row `B` and tests cell bit `$40`.

The routines use the native cell-address resolver at **$0940**, communicate direction/boundary results in `D` and carry, and converge to an update at `$0AB1` for position and wall state.

## Source organization

The source groups callable native routines and internal branch labels while retaining meaningful byte-exact data constructs. Routine comments describe actual input registers, RAM access and control flow. Glyphs and indicators are shown inline as pixel patterns. Instructions are written as assembly rather than repeating each instruction's ROM hex bytes in comments.

## Verification

The source-layout audit after this pass walks the native instruction mnemonics and `DB`/`DW` records, reaches exactly **4096 bytes**, and finds no duplicate labels. Key fixed addresses are `$0170` (font), `$0C10` (messages), `$0D33` (small graphics), `$0D64` (command script), and `$0A32` (movement).

The user has verified the native build and MAME operation; the new comment-only ASM changes require their own rebuild. Independent physical hardware testing remains a separate gate.
