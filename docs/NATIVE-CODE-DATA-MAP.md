# Amazing Maze — original 8080 ROM code/data classification

Version: v20261121-0001  
Task: **AM-RE-001**  
Authority: [original native source](../src/maze.asm) and the two ROMs in `roms/original/maze.zip`.

## Scope

All **4,096 original ROM bytes** are accounted for in the source-ledger below. Classification of an instruction encoding or a table is separate from proof that the CPU actually reaches the instruction or reads the data in each gameplay mode. Dynamic indirect-branch and hardware-entry audits are explicitly tracked below.

## Contiguous ROM address map

All ranges inclusive; the entries partition $0000–$0FFF without overlap.

| Range | Size | Classification and native source evidence |
| --- | ---: | --- |
| `$0000–$0007` | 8 | Reset instructions: `RESET` |
| `$0008–$000E` | 7 | First restart/interrupt vector: `INTERRUPT_ENTRY` |
| `$000F` | 1 | Original restart-slot alignment byte: `RST_08_VECTOR_FILL` |
| `$0010–$0016` | 7 | Second restart-vector entry: `RST_10_ENTRY`; actual invocation still to be traced |
| `$0017–$011F` | 265 | Native startup and RAM/ROM diagnostics: `RESET_START`, `CHECK_ROM_PAGE_SUMS` |
| `$0120–$0123` | 4 | Expected ROM page-check bytes: `ROM_CHECKSUM_EXPECTED_BYTES` |
| `$0124` | 1 | Original intervening `$58`: `ROM_CHECKSUM_INTERVENING_BYTE` |
| `$0125–$0128` | 4 | Diagnostic failure-display codes: `ROM_CHECKSUM_FAILURE_GLYPHS` |
| `$0129–$016F` | 71 | Native text renderer: `DRAW_TEXT_GLYPH_STREAM` |
| `$0170–$02E1` | 370 | 37 original glyphs × 10 rows: `FONT_37_GLYPHS_10_ROWS` |
| `$02E2–$03D1` | 240 | Native frame/interrupt services, interpreter setup and dispatch, zero-command entry |
| `$03D2–$03D3` | 2 | Original bytes `00 00`: `ZERO_COMMAND_ENTRY_GAP` |
| `$03D4–$0417` | 68 | Zero-command event and native maze-state services: `ZERO_COMMAND_EVENT` |
| `$0418` | 1 | Original `C9` (8080 RET opcode): `MAZE_FIELD_EXTRA_RET_BYTE` |
| `$0419–$07F0` | 984 | Native game-state, input, score, maze generation and movement |
| `$07F1–$07F2` | 2 | Original bytes `00 00`: `MAZE_DIRECTION_ENTRY_GAP` |
| `$07F3–$0BEB` | 1017 | Native maze/display/gameplay logic and native command handlers |
| `$0BEC–$0BED` | 2 | Original bytes `00 00`: `COMMAND_VECTOR_ENTRY_GAP` |
| `$0BEE–$0C0F` | 34 | 17 little-endian handler addresses: `NATIVE_COMMAND_VECTORS` |
| `$0C10–$0D32` | 291 | Original game text and position-control bytes: `GAME_TEXT_STREAM` |
| `$0D33–$0D63` | 49 | Original indicator/graphics bytes: `GAME_INDICATOR_BITMAPS` |
| `$0D64–$0FFF` | 668 | Interpreted program: `INITIAL_GAME_SCRIPT`, 190 command records |

**Total: 4,096 bytes.** The script area includes three final `$00` records after a self-loop; executing those records has not been established.

## Recovered ROM diagnostic tables at $0120

The original checksum code uses two different indexed addresses:

```asm
        LD HL,ROM_CHECKSUM_EXPECTED_BYTES
        ADD HL,DE
        CP (HL)                         ; compare current page checksum

        LD HL,ROM_CHECKSUM_FAILURE_GLYPHS
        ADD HL,DE
        LD A,(HL)                       ; load page-specific failure code
```

The original 9 bytes are now separated in the assembly:

```asm
ROM_CHECKSUM_EXPECTED_BYTES:           ; $0120-$0123
        DB $00,$A1,$C1,$EE

ROM_CHECKSUM_INTERVENING_BYTE:         ; $0124
        DB $58

ROM_CHECKSUM_FAILURE_GLYPHS:          ; $0125-$0128
        DB $48,$48,$47,$47
```

`DE` is initialized to zero and incremented for each page of the ROM diagnostic loop, so these are **four-entry page tables**. The isolated `$58` has no identified direct consumer; it remains independently labeled and unchanged.

## Native execution and interpreter roots

| Address | Source of execution |
| --- | --- |
| `$0000` | Hardware reset |
| `$0008` | Native RST 08h slot leading to `FRAME_SERVICE` |
| `$0010` | Native RST 10h slot leading to `INITIALIZE_FRAME_STATE`; actual runtime caller awaits confirmation |
| `$0017` | Reset branch to `RESET_START` |
| `$0392` | Script startup / initial cursor setup |
| `$03AA` | Fetch command via cursor RAM `$2000` |
| `$03CA` | Special command-zero processing |
| `$03D4` | Conditional zero-event helper |
| `$0BEE` | Seventeen native command handler vectors |
| `$0D64` | Initial game script address stored through RAM `$2002` |

Original nonzero command $01–$11 indexes the vector table; the handlers return to the native execution continuation. Command $00 follows the distinct event path. The [word dictionary](8080-WORD-SEMANTICS.md) documents each vector and its original packet width.

## Indirect reachability still to establish

| Address | Original byte(s) | Required evidence |
| --- | --- | --- |
| `$000F` | `00` | RST 08h/RST 10h hardware/control-flow traces |
| `$0124` | `58` | Read-site search extending beyond the four page-code table entries |
| `$03D2–$03D3` | `00 00` | Indirect/computed branch and call target tracing |
| `$0418` | `C9` | Verify any indirect entry into the extra RET opcode before treating it as padding |
| `$07F1–$07F2` | `00 00` | Trace movement routine entry/continuation paths |
| `$0BEC–$0BED` | `00 00` | Check readers/branchers adjacent to the native vector table |

The reconstructed source has no **direct symbolic JP/CALL** to these inter-routine bytes. That finding alone does not establish dynamic unreachability. Native indirect jumps, interrupt entries and indexed reads must be audited independently.

## Verification performed on this pass

- **PASS, static:** Source address calculation reaches exactly `$1000` and all established data/handler anchor labels remain at their original ROM addresses.
- **PASS, static:** Comparison against source commit `dd17820` confirms identical normalized native instruction/data entries (**2,980 entries; zero differences**) after names and comments were updated.
- **Pending, native:** Repeat `./build.sh` on the current branch to confirm original ROM SHA-1 hashes after these changes.
- **Previously user-verified:** Byte-exact native assembly and MAME launch before this classification pass.

## Task disposition

**AM-RE-001 remains OPEN (static classification substantially complete).** The original full-image ledger and diagnostic-data classification are complete. Finish indirect code-entry reachability and data-consumer tracing before closing the task.
