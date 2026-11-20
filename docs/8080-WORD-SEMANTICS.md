# Amazing Maze — 17-command native dictionary (hard RE pass 2)

Version: v20261108-0003

## Provenance and boundaries

Decoded directly from the original two 2,048-byte 8080 ROM devices, `maze.h` at `$0000` and `maze.g` at `$0800`. The command table is at `$0BEE` and the dispatcher at `$0392`. Names below are **working semantic descriptions**, not historical DNA source spellings. "Inline bytes" means bytes *following* the single-byte command. H = clear machine-state effect and width, M = native effect clear but gameplay meaning not fully established, L = incomplete implementation/packet interpretation. Handler presence does not mean full semantic recovery.

| Token | Native address | Working name | Inline bytes | Confirmed effects | Confidence |
| --- | --- | --- | --- | --- | --- |
| `01` | `$04BD` | RETURN_FROM_SCRIPT_HANDLER | 0 | `RET` at entry; actual stack continuation requires trace | H (opcode only) |
| `02` | `$0B12` | SET_MODE_0E | 0 | `MVI A,$0E; JMP $08EE` | H (native entry), M (purpose) |
| `03` | `$0835` | UPDATE_DISPLAY_OR_GAME_STATE | Unknown | Complex native work at `$0835`; accesses `$3E02` and `$2026`; requires full graph | L |
| `04` | `$0B17` | WRITE_COMPUTED_DISPLAY_DATA | Unknown | Disables interrupts, consumes pointer/word fields from script, performs memory writes, updates `$2000` | M |
| `05` | `$0B4B` | POLL_INPUT_BIT_40 | 0 | `IN $01; ANI $40`, selects a working value, stores `$202A`, complements/stores `$202C` | H (native state), M (game meaning) |
| `06` | `$0419` | INITIALIZE_GAME_FIELDS | 0 | Calls `$043D`; clears `$2015–$2021` (13 bytes), copies selected bytes into adjacent state, updates `$2040` region | H (partial effects), M (meaning) |
| `07` | `$0B90` | DRAW_OR_COPY_INLINE_RECORD | 5 | Reads a byte and two pointer16 operands, saves cursor at `$2000`, then jumps to native routine `$0129` | M |
| `08` | `$0B5F` | SET_RAM_200C | 1 | Reads inline byte, stores at `$200C`, advances `$2000` | H |
| `09` | `$0B69` | SET_RAM_200B_AND_2008 | 3 | Reads byte into `$200B`, then address16 into `$2008`, advances cursor | H |
| `0A` | `$08AC` | GAME_CONTROL_NATIVE | Unknown | Native entry located; full effects not yet traced | L |
| `0B` | `$0B7B` | GOTO_SCRIPT | 2 | Reads little-endian target16 from inline stream and stores at `$2000` | H |
| `0C` | `$0B84` | STORE_INLINE_BYTE_AT_ADDRESS | 3 | Reads byte8 and target address16; `STAX D` writes the byte, advances `$2000` | H |
| `0D` | `$0BA3` | CONDITIONAL_DECREMENT_2013 | 0 | `LXI D,$2013; LDAX D; DCR A; CPI 1; RZ; STAX D; RET`. Does not store when original byte is 2 | H (native effect) |
| `0E` | `$0BB9` | BRANCH_IF_BYTE_ZERO | 4 | Shared condition helper reads address16 and target16; when pointed byte is zero, replaces `$2000` with target | H |
| `0F` | `$0BC4` | BRANCH_IF_BYTE_NONZERO | 4 | Shared condition helper reads address16 and target16; when pointed byte is nonzero, replaces `$2000` with target | H |
| `10` | `$0BCF` | PROCESS_INLINE_NATIVE_RECORD | 4 | Reads pointer16, calls `$0634` with `BC=$2036`, reads further operand and calls `$058C`, transfers to `$0129` | M |
| `11` | `$05D9` | UPDATE_END_OR_DISPLAY_STATE | 0 | Tests/decrements `$2027`, initializes `$202E` and `$202D`, writes `$2002` and calls through display routine `$0129` | M |

**Note on command 07:** The explicit `$0B90` stream contains one byte plus *two* 16-bit values (five operand bytes). The continuation through `$0129` determines how these affect graphics. Do not equate this word with a generic byte copy before analyzing that routine.

## Native handler snippets and contracts

### Token $08 — SET_RAM_200C (entry $0B5F)

```asm
WORD_SET_200C:         ; $0B5F, original bytes EB 7E 23 22 00 20 32 0C 20 C9
    XCHG               ; HL = script cursor passed in DE
    MOV A,M             ; inline byte
    INX H
    SHLD $2000          ; cursor after byte
    STA $200C
    RET
```

Input: `DE` = first inline operand; `SP` contains interpreter continuation. Output: `A` = immediate value, `HL` = advanced source pointer; `DE` receives the displaced handler-side `HL`; writes `$2000` and `$200C`. Flags unchanged by the load/store operations (except any preceding context).

### Token $09 — SET_RAM_200B_AND_2008 (entry $0B69)

```asm
WORD_SET_200B_AND_2008:
    XCHG
    MOV A,M
    STA $200B
    INX H
    MOV E,M
    INX H
    MOV D,M
    INX H
    SHLD $2000          ; skip byte8 + little-endian word16
    XCHG
    SHLD $2008
    RET
```

Input `DE` = cursor. Output `$200B` = byte8, `$2008` = word16, `$2000` advanced by three operand bytes. This supports an explicit byte + address immediate packet.

### Token $0B — GOTO_SCRIPT (entry $0B7B)

```asm
WORD_GOTO_SCRIPT:
    XCHG
    MOV E,M
    INX H
    MOV D,M
    XCHG
    SHLD $2000
    RET
```

No sequential fall-through: script pointer is replaced with target16. Inputs: `DE` cursor. Outputs: `HL` target16, `$2000` target16; `A` and flags unchanged.

### Token $0C — STORE_INLINE_BYTE_AT_ADDRESS (entry $0B84)

```asm
WORD_STORE_INLINE_BYTE:
    XCHG
    MOV A,M
    INX H
    MOV E,M
    INX H
    MOV D,M
    INX H
    SHLD $2000
    STAX D
    RET
```

Packet: `0C value8 target_lo target_hi`. Input `DE` cursor. Output: `[target16] = value8`, `$2000` advances three bytes. `A` retains value8. Flag results unchanged by this handler.

Actual verified script packets from `$0D64`:

```text
$0D64: 0C 00 2C 20    STORE_INLINE_BYTE [$202C] = $00
$0D68: 0C 00 31 20    STORE_INLINE_BYTE [$2031] = $00
$0D6C: 0C 00 32 20    STORE_INLINE_BYTE [$2032] = $00
$0D70: 0C 00 2D 20    STORE_INLINE_BYTE [$202D] = $00
$0D74: 11             UPDATE_END_OR_DISPLAY_STATE
$0D75: 09 0A 94 0D    SET_RAM_200B_AND_2008 byte=$0A, address=$0D94
```

The next byte at `$0D79` is command `07`, whose handler consumes five operand bytes: byte8, pointer16, pointer16. The native drawing helper at `$0129` determines its screen effect.

### Token $0E/$0F — conditional branches (helper $0BAD)

```asm
WORD_BRANCH_IF_ZERO:       ; $0BB9
    CALL READ_BRANCH_RECORD
    JNZ NO_BRANCH_ZERO
    XCHG
    SHLD $2000
NO_BRANCH_ZERO:
    RET

WORD_BRANCH_IF_NONZERO:    ; $0BC4
    CALL READ_BRANCH_RECORD
    JZ NO_BRANCH_NONZERO
    XCHG
    SHLD $2000
NO_BRANCH_NONZERO:
    RET

READ_BRANCH_RECORD:       ; $0BAD
    XCHG
    MOV C,M
    INX H
    MOV B,M
    INX H
    MOV E,M
    INX H
    MOV D,M
    INX H
    LDAX B
    ANA A
    RET
```

Packet: `[token][test_address_lo][test_address_hi][jump_target_lo][jump_target_hi]`. The common helper loads the test address into `BC`, the branch target into `DE`, and leaves `HL` pointing to the next sequential command. It tests the byte at `(BC)` with `ANA A`.

**Every path writes the next script cursor to RAM `$2000`.** When the condition is met, `XCHG` moves the branch target from `DE` into `HL` before the store. When the condition is false, the conditional `JP` skips `XCHG` and stores the already-advanced sequential pointer in `HL`. This original native code establishes both taken and fall-through behavior, so the two words have complete four-byte immediate records and functioning two-way script branches.

The [recovered assembly](../src/maze.asm) labels the common helper `READ_CONDITION_RECORD` at `$0BAD` and annotates the register/flag contract inline.

## Corrected host-analysis issue

The earlier off-repository in-memory ZIP/DEFLATE analysis failed in a temporary custom decoder. This was **not an error in `roms/original/maze.zip`**. Repeating the byte extraction with the corrected canonical DEFLATE code-length order recovered `maze.h` and `maze.g` at 2048 bytes each (4096 total), and reproduced the `$03C0` dispatcher bytes exactly. The repository's `tools/scan-runtime.mjs` uses Node's `inflateRawSync`, which does not have this custom code-length ordering issue.

## Work still required

Native handler details above are a second **structural hard-RE pass**, not a finished emulator trace, not a reconstructed complete `src/maze.asm`, and not a byte-exact assembled ROM. Additional decoding must resolve command `03/04/07/0A/10/11` graphics/service behavior, remaining packet lengths and the screen effects of the native drawing helpers, then assemble and compare both devices with bundled zmac. No replacement gameplay implementation or synthetic interpreter is authorized.
