# Amazing Maze — Intel 8080 hard RE, native control flow

Version: v20261108-0002

## Scope and provenance

This pass decodes original Intel 8080 instructions and the existing original-ROM structural scan, rather than guessing from game genre. Exact native bytes examined from `maze.h` and `maze.g` are recorded below. The decoded blocks establish additional register and memory effects; the whole-image source and complete handler catalog remain in progress. None of the working names are claimed as original DNA source names.

## Verified reset and interrupt entry

```asm
; $0000: reset
NOP
NOP
LXI SP,$2400        ; native hardware stack starts at upper edge of work RAM
JMP $0017

; $0008: interrupt/service entry
PUSH PSW
PUSH B
PUSH D
PUSH H
JMP $030B           ; saves CPU state before shared service code
```

The entry at `$0008` is not a TERSE colon call. Full exit and interrupt-enable behavior must be traced through service code before its register-preservation contract is considered complete.

## Frame service at $030B

Native bytes beginning `3E 10 CD 02 03 77 CD 1E 06 CD A2 05 CD F9 05 ...` decode into:

```asm
FRAME_SERVICE_ENTRY:             ; $030B
    MVI A,$10
    CALL $0302
    MOV M,A
    CALL $061E
    CALL $05A2
    CALL $05F9
    LDA $2030
    DCR A
    JNZ $0338
    LDA $2020
    ANA A
    JZ $02FC
    LXI H,$2033
    INR M
    LDA $2013
    CMP M
    JNZ $02FC
    MVI M,0
    CALL $0A32
    LXI H,$2044
    CALL $0962
    JMP $02FC
```

**Observed state:** work RAM `$2030`, `$2020`, `$2033`, `$2013`, and `$2044` participate in periodic service/conditional work; the branch to `$02FC` is shared. A high-level role for each cell is not yet claimed. `$0302` returns an `HL`-addressed location for the immediate `MOV M,A` write; its own inputs/outputs remain to be decoded.

## Timed event service $0341–$0375

These bytes expose an actual countdown mechanism, not merely a presumed timer:

```asm
; $0341: timer-service entry, called from frame/periodic control
    LXI H,$2035
    MOV A,M
    ANA A
    RNZ
    MOV B,A
    LXI H,$200A
    DCR M
    JNZ $0357
    MVI M,$3C
    LXI H,$200B
    CALL $0369
    LXI H,$200C
    CALL $0369
    INX H
    CALL $0369
    INX H
    CALL $0369
    STA $2035
    RET

; $0369: one byte countdown/expiry helper
TIMER_DECREMENT:                 ; $0369
    MOV A,M
    ANA A
    JZ $0373
    DCR M
    JNZ $0373
    STC
    MOV A,B
    RAL
    MOV B,A
    RET
```

**Contract, `$0369`:** `HL` points to a byte counter; if nonzero it is decremented. When that decrement reaches zero, carry is set and incorporated into `B` by `RAL`, with resulting `B` returned. The complete bit-aggregation convention across the four calls requires checking intervening code and entry `B`. This helper changes `A, F`, and possibly `B` and memory `(HL)`; it does not increment `HL`. Its caller explicitly advances `HL` for later counters.

**Contract, `$0341`:** if `[$2035]` is nonzero it returns immediately. Otherwise it decrements `[$200A]`; when that reaches zero it reloads `$3C`, processes timer counters at `$200B–$200E`, then stores the resulting event value to `$2035`. This is consistent with a periodic timer service; exact wall-clock rate requires interrupt-frequency evidence.

## Initial native script setup $0377–$038E

```asm
    MVI A,$10                 ; $0377
    CALL $08EE
    LXI H,$0D64               ; root command stream
    SHLD $2002                ; script root or next-start pointer
    LXI H,$FFFF
    SHLD $2004
    SHLD $2006
    EI
    LXI H,$038B
    PUSH H
    OUT $02
```

**Observed state:** `$2002` stores initial script address `$0D64`; `$2004` and `$2006` are initialized to `$FFFF`. `OUT $02` is a hardware interaction that requires independent I/O interpretation. The self-referencing `$038B` stack continuation and final code need a control-flow trace rather than a conventional caller/return assumption.

## One-byte command dispatcher $0392–$03C9

```asm
SCRIPT_DISPATCH_START:             ; $0392
    LHLD $2002
    MOV A,H
    ORA L
    JZ $03AA
    XRA A
    STA $200B
    STA $200C
    SHLD $2000                   ; active command cursor = saved root
    LXI H,0
    SHLD $2002                   ; consume/reset root
SCRIPT_FETCH:                    ; $03AA
    LHLD $2000
    MOV A,M                     ; read one-byte command
    ANA A
    JZ $03CA                    ; zero is special, no normal cursor increment
    INX H
    SHLD $2000                   ; advance active cursor past token
    XCHG                        ; DE = cursor
    LXI H,$0BEE                 ; native vector base
    DCR A                       ; 1-based token -> 0-based index
    CPI $11
    JNC $0377                   ; out of range restarts initialization
    ADD A                       ; native vector index * 2
    MOV C,A
    MVI B,0
    DAD B
    MOV A,M
    INX H
    MOV H,M
    MOV L,A
    PCHL                        ; indirect jump to native handler
```

**Register effects:** The lookup actively overwrites `A, B, C, D, E, H, L` and flags; the current saved script cursor is authoritative at `$2000`. Handlers cannot assume the dispatcher preserved their incoming general registers. Because the dispatch uses `PCHL` rather than `CALL`, the native continuation contract is established by the surrounding stack and handler return paths, not by `PCHL` itself. The complete 17-handler audit must trace those paths.

**Important correction to simplistic opcode diagrams:** the zero token branches to `$03CA` **before** the normal `INX H / SHLD $2000` sequence. Its behavior cannot be modeled as the normal handler `$00` or presumed to consume one byte.

## Zero-command event path $03CA

```asm
ZERO_COMMAND_EVENT:              ; $03CA
    LDA $201F
    ANA A
    CZ $03D4                   ; conditional call when zero
    RET
```

Original bytes `3A 1F 20 A7 CC D4 03 C9`. This is a conditional event path, not an indexed-table slot. It is conditional on work RAM `$201F`, and the callee at `$03D4` requires separate analysis. The original scan's phrase "event/scheduler path" is provisional until that routine is decoded.

## Initial command-stream bytes

The stream beginning at `$0D64` starts:

```text
$0D64: 0C 00 2C 20   0C 00 31 20   0C 00 32 20   0C 00 2D 20
$0D74: 11 09 0A 94 0D 07 10 10 0C 08 24 07 09 22 0D 0B
$0D84: 24 08 1E 00 07 09 10 0C 0B 24 08 1E 00 ...
```

The first repeated `0C` followed by three bytes suggests a structured packet, but the exact operand contract and any immediate byte interpretation **must be determined from handler `$0B84`**. These bytes are deliberately displayed as a ROM stream rather than mislabelled executable 8080 instructions. Likewise, `0B`, `07`, `11`, and other tokens must be decoded through their handlers before giving a high-level maze script.

## Command table

| Command | Native address | Command | Native address |
| --- | --- | --- | --- |
| `01` | `$04BD` | `0A` | `$08AC` |
| `02` | `$0B12` | `0B` | `$0B7B` |
| `03` | `$0835` | `0C` | `$0B84` |
| `04` | `$0B17` | `0D` | `$0BA3` |
| `05` | `$0B4B` | `0E` | `$0BB9` |
| `06` | `$0419` | `0F` | `$0BC4` |
| `07` | `$0B90` | `10` | `$0BCF` |
| `08` | `$0B5F` | `11` | `$05D9` |
| `09` | `$0B69` | | |

### New hard-RE findings

1. Dispatcher root initialization clears `$200B` and `$200C` while activating `$2002` as the current `$2000` script cursor; the two cells also participate in a separate timer path. This shared ownership must be explained by runtime sequencing.
2. Zero commands do **not** advance the cursor via the normal fetch path; they perform an `$201F`-conditioned call and return.
3. Invalid nonzero command values (`$12` or above, after one-based correction) transfer to `$0377`, not an assumed no-op handler.
4. The native timing subsystem at `$0341` uses a `$3C` reload and four consecutive work-RAM counters to aggregate expiry bits.
5. Actual initial stream bytes at `$0D64` establish a concrete packet-decoding starting point for the 17-handler dictionary.

## Open RE and verification gates

- Recover the full native source and complete control-flow graph; eliminate generic names based on verified semantics, not guesswork.
- Inspect `$03D4`, `$0377` continuation, `$02FC` interrupt exit and handler return mechanism in detail.
- Identify the 17 command operand formats and parse every reachable script using the **actual** byte-consumption contracts.
- Establish accurate register flags/stack contracts and RAM ownership including counters used across stages.
- Recover maze generation, drawing, randomness, collision, timing, graphics and I/O.
- Independently cross-diff Gun Fight instruction sequences and handler semantics before claiming direct reuse.
- Assemble with native zmac and prove 4096-byte exact identity. MAME and hardware remain separate gates.

**Verification performed for this pass:** extracted original ZIP member bytes and inspected the displayed ROM address ranges directly in the connected repository's original archive. No native assembler execution, full ROM diff, MAME or hardware test was executed.
