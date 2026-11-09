# Amazing Maze — hard RE sprint plan

Version: v20261108-0001

## Rules and scope

Original Intel 8080 ROM and original program architecture are authoritative. No synthetic gameplay, JavaScript/Python gameplay reimplementation, invented command semantics, raw-byte `DB` stand-in presented as a recovered disassembly, or substituted interpreter. Use the bundled assembler in `tools/` for native builds. No Python in build scripts. Stop for approval before architectural deviations.

The mandatory `ENGINEERING-RULES.md` and `AGENTS.md` were copied verbatim from `lizard43/gunfight` into this repository. Read both before any implementation change. The original-software-first policy, approval gates, and separate verification gates apply throughout this sprint.

## Gate 0 — Original evidence

- [x] Identify two original 2 KB devices `maze.h`, `maze.g`, SHA-1 and CRC32 recorded in `ORIGINAL-ROM-RUNTIME-SCAN.md`.
- [x] Static signatures for reset, interrupt entry, interpreter, vector table and all 17 targets documented.
- [ ] Confirm actual ZIP member decoding using the scanner on the development machine; keep this test distinct from source round-trip.
- [x] Reuse the repository's existing `images/amazing-maze-21054-marquee.jpg` in the README.
- [ ] Audit original MAME driver, manuals, electrical schematics, input ports, raster/video map, interrupt vectors, and device-specific ROM assignments.
- [ ] Determine original cabinet image provenance and distinguish bezel, flyer, and marquee terminology without changing repository artwork.

## Gate 1 — Hard 8080 source RE

- [ ] Recover a readable `src/maze.asm` from both original ROMs.
- [ ] Establish executable boundaries via control-flow reachability; distinguish code, script streams, tables, display graphics, fonts, and padding.
- [ ] Replace generic labels with semantic labels supported by cross-references and behavior.
- [ ] Define function boundaries, documented inputs/outputs, register/flag effects, stack and RAM effects, I/O effects, and callers.
- [ ] Decode important graphics and game constants inline.
- [ ] Keep source annotations aligned with the actual instruction bytes. Retain exact original data.
- [ ] Maintain a routine index and RAM ownership ledger.

## Gate 2 — Native exact assembly

- [ ] Assemble exclusively with a verified bundled `tools/` 8080-capable assembler.
- [ ] Generate exactly 4096 bytes, split into 2048-byte `maze.h` and `maze.g`.
- [ ] Fail on source-assembly error, incorrect size, or any original ROM SHA-1 mismatch.
- [ ] Package generated `roms/maze.zip` for MAME, separate from immutable `roms/original/maze.zip`.
- [ ] Establish source -> ROM -> source cross-reference and verify hash-equivalent round-trip.

## Gate 3 — VM and command dictionary

- [x] Static identification of a 17-command native vector dispatcher.
- [x] Decode the dispatcher `$0392–$03C9`, zero-command branch `$03CA`, script root initialization and RAM cursor `$2000` at the instruction level; record exact original bytes in `NATIVE-RE-PASS.md`.
- [ ] Complete dynamic traces and analyze `$03D4` plus all script-root transitions.
- [ ] Audit all 17 handlers for parameter width, registers, stack, flags, side effects, and dispatcher continuation contract.
- [ ] Decode real scripts with token names, source offsets, and actual handler behaviors.
- [ ] Test malformed token handling, branches, literals, loops, copies, zero command, and interrupt preemption without conjecture.

## Gate 4 — Maze engine and gameplay

- [ ] Recover maze storage and generation algorithm, seed/randomness, and generation entrypoints.
- [ ] Recover drawing, collision, path traversability, joystick handling, timers, scoring, attract/start and completion logic.
- [ ] Determine whether the originally described maze-generation test remains a self-contained unit or was integrated into the commercial game.

## Gate 5 — Gun Fight and lineage

- [ ] Diff original Gun Fight/Amazing Maze ROM byte sequences and algorithm graphs, not simply mnemonics.
- [ ] Compare script ABI, vector indexing, zero-command behavior, RAM records, IRQ architecture and hardware services.
- [ ] Classify each candidate correspondence: exact binary reuse, ABI-compatible, related implementation, or independent.
- [ ] Test the alternative shared-ancestor hypothesis.
- [ ] Compare later five-game identical lookup sequence against Amazing Maze's observed nine-byte tail without conflating complete runtimes.
- [ ] Separate dated archival testimony from executable-derived deductions; record attribution confidence.

## Gate 6 — Runtime and distribution

- [ ] Source and rebuilt ROM verified independently.
- [ ] Launch `mame maze -rompath roms` and validate attract, two-player play, maze generation, collision, timing and scoring.
- [ ] Hardware verification is separately recorded, not inferred from MAME.
- [ ] Update README, graphics/map, native routine contracts, original scripts, historical research and honest technical debt.
- [ ] Prepare corresponding Gun Fight/WB changes as separately reviewed, bidirectional updates; avoid private dependency links in public source docs.

## Current verdict

**Static ROM interpreter identification: documented. Full hard RE, native assembly, generated game ROM, MAME and hardware: not yet verified.** This is a sprint plan, not a completion claim.
