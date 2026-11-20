# Gun Fight → Amazing Maze — original Intel 8080 command lineage

Version: v20261108-0004

## Core finding

Gun Fight (1975) and Amazing Maze (1976) both implement a one-byte, indexed native-command architecture. Their interpreters fetch a command from an original ROM script, look up an Intel 8080 handler, and maintain the script pointer in RAM at **$2000**. Their games use different ROM layouts and command numbers while carrying forward recognizable **command functions**.

The most direct common command function is **GOTO_SCRIPT**: each program consumes a 16-bit little-endian script target and replaces the interpreter cursor at `$2000`. RAM-state writes, conditional execution, and graphics-related commands form additional shared functional families.

The relationship categories are useful at the **word level**: same operation, compatible operand record, matching native sequence, or a game-specific implementation of a shared function.

## Shared command functions

| Function | Gun Fight (1975) | Amazing Maze (1976) | What carries forward |
| --- | --- | --- | --- |
| **GOTO_SCRIPT** | `$09 → $0682` | `$0B → $0B7B` | Script supplies `address16` and the handler replaces RAM `$2000` with it; matching high-level word function and inline address format |
| **Set a RAM byte** | `$02 → $063D` sets `$2003`; `$03 → $0649` sets `$2015` | `$08 → $0B5F` sets `$200C`; `$0C → $0B84` writes byte to inline `address16` | Immediate-byte state mutation; Amazing Maze includes a general addressed-store form |
| **Conditional command transfer** | `$05 → $068D`, `$06 → $069D` test through helper `$0372`; `$10 → $0807` tests `$2008` | `$0E → $0BB9`, `$0F → $0BC4` test a RAM byte through helper `$0BAD` | Predicate-driven script control; predicate operands and return behavior follow each game's implementation |
| **Formatted graphics / memory operations** | `$01 → $05E9` formatted data; `$0E → $0785` fill; `$0F → $07AB` expand graphics table | `$04 → $0B17` uses native memory writes; `$07 → $0B90` reads inline data for `$0129`; `$10 → $0BCF` uses native record helpers | Shared *functional category* of inline-driven graphics and memory services; direct routine comparison follows native control-flow recovery |
| **Frame and event control** | `$00 → $0813` repeats based on counter `$20C5`; `$14 → $03C9` samples ports and events | Token zero enters `$03CA` and tests `$201F`; services include `$030B` and timed counters | Command-driven gameplay coupled to native frame/input servicing |

All names are descriptive RE names. They identify actual native effects and provide a common vocabulary for comparing two original 8080 games.

## The common GOTO word

**Gun Fight** `$09` at `$0682` consumes `address16` and stores that address into `$2000`. Its recovered entry bytes begin `2A 00 20 5E 23 56 EB 22`: `LHLD $2000; MOV E,M; INX H; MOV D,M; XCHG; SHLD ...`. It fetches the operand directly from the saved script pointer.

**Amazing Maze** `$0B` at `$0B7B` performs:

```asm
WORD_GOTO_SCRIPT:       ; Amazing Maze $0B7B
    XCHG
    MOV E,M
    INX H
    MOV D,M
    XCHG
    SHLD $2000
    RET
```

The word moves the next ROM-script address into `$2000`. The same **operation and 16-bit operand record** appear in Gun Fight's `$09` word. **The native entries use different machine instructions:** Gun Fight begins with `LHLD $2000`, while Amazing Maze begins with `XCHG` and receives the advanced command pointer in `DE`. This identifies a shared command **implemented through two distinct entry conventions**. It also gives us a concrete architectural change to trace through the dispatcher and handler return paths.

## Shared interpreter architecture

| Native property | Gun Fight | Amazing Maze |
| --- | --- | --- |
| CPU | Intel 8080 | Intel 8080 |
| Interpreter entry | `$03A7` | `$0392` |
| Script cursor | `$2000` | `$2000` |
| Native vector base | `$09AE` | `$0BEE` |
| Handler count | 21 entries, tokens `$00–$14` | 17 entries, tokens `$01–$11`, plus the token-zero event path |
| First recovered script | `$0821` | `$0D64` |
| Dispatch | Index → 16-bit native address → indirect transfer | Decrement one-based token → range check → index → indirect transfer |
| Zero token | Counter-based handler `WAIT_OR_REPEAT` | Event path `$03CA` reading `$201F` |
| Word return | Dispatcher creates a native continuation for `RET` | Native handlers use `RET`; initialization/interrupt context supplies the continuation |
| Operand handling | Fixed state updates, `address16`, and mixed graphics packets | Fixed state updates, `address16`, `byte8 + address16`, conditional records and graphics packets |

### Amazing Maze changes to the design

Amazing Maze's interpreter applies a one-based command mapping, bounds the native vector lookup to 17 entries, and routes zero to a separate event path. It retains the shared `$2000` script cursor and address-indexed native dispatch. Its command `$0C` provides a general `byte8 + address16` RAM store, which appears four times at the beginning of its initial command stream:

```text
$0D64: 0C 00 2C 20     [$202C] = $00
$0D68: 0C 00 31 20     [$2031] = $00
$0D6C: 0C 00 32 20     [$2032] = $00
$0D70: 0C 00 2D 20     [$202D] = $00
$0D74: 11              native command $11
$0D75: 09 0A 94 0D     store $0A at $200B and $0D94 at $2008
```

The sequence demonstrates actual source-level usage of the newer store and state-configuration operations.

## Engineering interpretation

The **reusable framework** consists of command-script fetching, an indexed table of native Intel 8080 routines, script-pointer ownership at `$2000`, and recurring script-level words for jumps, state mutation and conditional control. Amazing Maze customizes its command set and event control for maze gameplay.

For precise lineage classification, compare each corresponding native routine under four labels:

- **Exact binary reuse:** identical machine bytes, allowing an explicitly documented relocation comparison where relevant.
- **ABI-compatible reuse:** same operand representation and entry/exit effects across both programs.
- **Related implementation:** shared operation with distinct code or native state conventions.
- **Game-specific implementation:** behavior tied to each game's own objects, graphics, input, or timers.

`GOTO_SCRIPT` supports **matching word semantics and inline operand format, with distinct native entry implementations**. The first Gun Fight bytes are recorded in its original-word inventory; the Amazing Maze bytes come from its original ROM. The other rows identify concrete functional families. Continued original-ROM instruction comparison will assign reuse classes to the individual routines.

## Evidence and next RE work

Amazing Maze: `docs/8080-WORD-SEMANTICS.md`, `docs/NATIVE-RE-PASS.md`, `tools/scan-runtime.mjs`, and original `maze.h`/`maze.g` ROMs.

Gun Fight: `lizard43/gunfight/docs/8080-WORD-SEMANTICS.md` with its 21 native command entries and interpreter description.

Next native pass: compare `GOTO_SCRIPT` machine bytes side by side, trace both interpreters' return continuations, compare RAM-store and branch word operand contracts, then trace shared graphics helper instruction sequences. Record any machine-code reuse in both corresponding original-game source files and reference dictionaries.
