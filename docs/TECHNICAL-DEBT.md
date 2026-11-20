# Amazing Maze — technical debt and verification blockers

## RE-001 — Complete original Intel 8080 source

The source tree does not yet contain `src/amazing-maze.asm`. The original archive and existing runtime scan identify the ROM boundaries and 17-entry interpreter table, but completing the disassembly requires individual code/data classification and handler analysis. The new build scripts deliberately fail at this stage.

**Resolution:** Reconstruct and verify original instructions and data, then build with zmac v1.3.

## RE-002 — Interpreted command semantics

Seventeen native handler vector entry addresses are verified at `$0BEE–$0C0F`; the meaning and argument widths of individual script commands still require native-code audit.

**Resolution:** Trace handler reads and cursor advances, label the handler routines and script operands, and document evidence for each command.

## RE-003 — Display, sound and memory semantics

Working RAM, video RAM and interpreter program addresses are documented. Precise game-specific RAM variables, hardware I/O operations, glyphs and graphic tables remain to be annotated from original machine code.

**Resolution:** Name locations and tables only after verifying all reads/writes or use sites.

## RE-004 — Build and execution verification

The Checkmate-style build harness is committed. No byte-identical zmac build of Amazing Maze has yet been executed; no MAME run of a newly built ROM has been performed.

**Resolution:** Assemble full source, verify both SHA-1 hashes, then run MAME and record the outcome.

## Build policy

No Python, secondary compiler, surrogate gameplay code or generated stand-in ROM. Keep `roms/original/maze.zip` unchanged. Document every test as executed, pending, or failed.
