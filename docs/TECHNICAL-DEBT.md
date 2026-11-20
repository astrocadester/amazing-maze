# Amazing Maze — technical debt and verification blockers

## RE-001 — Complete original Intel 8080 source

The November 8 RE branch already contained a substantial 54 KB `src/maze.asm` source reconstruction, now carried forward. Native zmac assembly and both SHA-1 matches were verified by the user on commit `10d4e72`. Further code/data classification, labels and command-contract auditing remain.

**Resolution:** Build the existing source using zmac v1.3, correct any actual assembler/ROM mismatches without changing original behavior, and continue semantic refinement.

## RE-002 — Interpreted command semantics

Seventeen native handler vector entry addresses are verified at `$0BEE–$0C0F`; the meaning and argument widths of individual script commands still require native-code audit.

**Resolution:** Trace handler reads and cursor advances, label the handler routines and script operands, and document evidence for each command.

## RE-003 — Display, sound and memory semantics

Working RAM, video RAM and interpreter program addresses are documented. Precise game-specific RAM variables, hardware I/O operations, glyphs and graphic tables remain to be annotated from original machine code.

**Resolution:** Name locations and tables only after verifying all reads/writes or use sites.

## RE-004 — Build and execution verification

The Checkmate-style build harness is committed. User's native zmac build on commit `10d4e72` matched the original two ROM hashes and produced `roms/maze.zip`. The newest ASM presentation changes still require their own native build. MAME execution has not been reported.

**Resolution:** Assemble full source, verify both SHA-1 hashes, then run MAME and record the outcome.

## Build policy

No Python, secondary compiler, surrogate gameplay code or generated stand-in ROM. Keep `roms/original/maze.zip` unchanged. Document every test as executed, pending, or failed.

## Source-style review — November 20, 2026

The previous byte-exact build was reported by the user on the source carried forward from the November 8 hard-RE branch. The follow-on source-style commits revise headers, routine spacing, 56 local/native labels, and long byte-data presentation without changing documented opcodes or DB operands. **Re-run the native build and ROM hashes after the formatting and symbol changes.**

The latest source-style pass resolved all 54 remaining `NATIVE_xxxx` label definitions, symbolicized 217 branch/call operands, converted 37 fonts and 49 indicator graphics bytes to Checkmate-style inline rows, formatted original encoded text as quoted runs, and decoded all 190 command records over 668 bytes at `$0D64–$0FFF`. Remaining work is native compilation verification after these changes, gameplay semantics, and documentation of additional raw-data regions. The final Checkmate-style source gate requires meaningful per-routine comments, independently identifiable tables and well-spaced, correctly classified data.

## Verified source-style build — November 20, 2026

User executed `git pull --ff-only` and `./build.sh` on commit `10d4e72` (source-format and label cleanup). Native zmac v1.3 assembly succeeded; split ROM hashes matched the original archive:

- `maze.h` — SHA-1 `62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c` — PASS
- `maze.g` — SHA-1 `893f0a7621e7df19f777be991faff0db4a9ad571` — PASS
- `roms/maze.zip` packaging — PASS

This verifies byte-exact output after the source-style pass. MAME execution and further source-label/data cleanup remain separate tasks.

## Latest source presentation and script audit — November 20, 2026

- All 54 remaining `NATIVE_xxxx` labels replaced with instruction-grounded function/local path names.
- All 217 numeric direct JP/CALL operands replaced with existing named labels; static 8080 source-address layout remains exactly 4,096 bytes with fonts at `$0170`, native vectors at `$0BEE`, text at `$0C10` and script at `$0D64`.
- The original 37 ten-row font glyphs and 49 indicator bitmap bytes are presented with one `DB` per row and an inline 8-pixel preview.
- Encoded text uses quoted ASCII runs for original uppercase letter bytes; `$40` blanks and native cursor control bytes remain numeric.
- The full 668-byte command program is expressed as 190 typed `DB`/`DW` records. The command $03/$0A no-operand paths and $04 eight-byte packet were audited against native handlers. Eighteen script branch destinations are aligned to named packet entries.
- These formatting and operand transformations passed **independent source-byte and address-layout audits**. Native assembler verification of this latest version is pending; the prior commit `10d4e72` is byte-exact according to the user's build output. MAME and Windows build checks remain separate verification tasks.

## Source readability pass — 2026-11-20

The original 291-byte text stream is now displayed as 20 separate, descriptive, labeled message/control sequences with quoted uppercase strings and preserved numeric screen-control codes. The original 17 native vectors no longer repeat their command numbers in comments. All 17 numeric `SCRIPT_xxxx` branch labels now describe observable command sequences, and 190 game commands have preceding comments with consistent record spacing. Duplicate stream documentation was consolidated.

**Independent source comparison:** compared the latest 4,096-byte source layout against commit `b9b148c` (previous user-verified byte-exact build); both contain 2,323 executable/data statements and 2,980 canonical opcode/data entries. All 2,980 normalized entries match, with no differences. Original font, vector, text, bitmap and script addresses are unchanged. Native zmac and ROM SHA-1 verification are still required for the latest edits; MAME execution remains separately pending.
