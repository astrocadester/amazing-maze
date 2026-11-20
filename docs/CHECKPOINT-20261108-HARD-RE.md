# Amazing Maze — hard RE checkpoint

**Date:** 2026-11-08  
**PR:** #2 — `feature/hard-re-v20261108-0001`  
**Next priority:** Execute native zmac build, verify two byte-exact ROMs, then continue source RE against the generated machine code.

## State carried into the next thread

- `src/maze.asm` is the active original-ROM-derived Intel 8080 source (4 KB address layout; 1,551 decoded instruction entries and original byte-preserving code/data regions).
- The 17-command indexed native interpreter has its vector table, dispatcher, zero-command event entry and initial script identified.
- Graphic source includes the 37 original ten-row text glyphs with inline pixels, original messages and small game bitmaps.
- Recognized original native routines include text rendering, maze cell address calculation, nibble transforms, movement/boundary checks, input service, interrupt handling and periodic timer service.
- README is the game/project/architecture reference, modeled after the Sea Wolf II presentation. Sprint status and technical debt belong in `docs/`, not in the README or memory-map SVG.
- The memory map uses a maze emblem, multiline address definitions and no status/evidence footer boxes.

**Verification ledger:** original two 2 KB ROM members extracted and inspected; source address/label audit reaches 4,096 bytes with symbol references resolved. The native assembler build, generated-ROM SHA-1 comparison, MAME execution and hardware tests remain **unexecuted**. The address audit is not a substitute for byte-exact equality.

## Remaining sprint priorities

| Priority | Sprint gate | Work to complete | Exit condition |
| --- | --- | --- | --- |
| **P0** | 2 — Native exact assembly | Execute bundled `tools/zmac` / `tools/zmac.exe` on `src/maze.asm`; correct assembly problems; build a 4,096-byte ROM and split `maze.h` / `maze.g` | Both generated devices match original SHA-1; source-built MAME ZIP produced; assembler output and checks recorded |
| **P1** | 1 — Hard 8080 source RE | Classify remaining code/data, replace generic labels with verified routine/function and branch names, document register/flag/stack/RAM/I/O contracts and callers, build routine/RAM ledger | Original native source is readable, complete, and aligned with ROM bytes; native build remains exact |
| **P1** | 3 — Command dictionary | Trace `$03D4` and script transitions; complete all 17 command operand/continuation contracts; decode original command scripts and test branches, loops, zero-command and IRQ interactions | Command definitions match native handlers and actual script usage |
| **P1** | 4 — Maze engine | Recover full generation algorithm, seed/randomness, maze storage and boundaries, drawing, collision, inputs, timers, scoring and game progression | Named, documented original routines with reproducible behavioral checks |
| **P2** | 5 — Gun Fight lineage | Compare original Gun Fight and Amazing Maze machine-code sequences and operand ABIs; classify actual command reuse vs related implementations; test common-ancestor hypothesis and chronology | Source-backed comparison of specific shared command words, especially GOTO_SCRIPT, RAM store, branching and graphics |
| **P2** | 0 — Hardware/source context | Review original MAME driver, schematics, board/port mappings, IRQs, ROM assignment and marquee provenance | Correct memory map and hardware contracts |
| **P2** | 6 — Runtime/distribution | Execute source-built ROM in MAME; test attract, player controls, maze generation, collision, timing and scores; record hardware test separately; propagate reviewed changes to Gun Fight/WB where relevant | Distinct ROM equality, MAME and hardware test records |

## Remaining technical debt

1. **Native build verification:** The committed source has passed a static layout/symbol audit; run the real bundled assembler and fix errors until both ROMs are byte-identical. No pass is recorded for this gate.
2. **Unresolved native labels and contracts:** Approximately 110 remaining generic local `NATIVE_xxxx` labels at the last counted source checkpoint. Audit actual current count before citing a new number. Resolve function boundaries and input/output/flag/stack contracts without speculative labels.
3. **Data/graphics ownership:** Classify remaining ROM data tables, native command streams, gameplay records and graphics; retain inline pixel previews for identified graphics.
4. **Command ABI:** Complete unknown parameters and continuation behavior for all 17 commands and the zero-event/IRQ scheduler.
5. **Maze algorithm:** Complete generation/randomness and maze-cell representation, collision and scoring behaviors from native instructions.
6. **DNA lineage:** Follow the specific Gun Fight → Amazing Maze 8080 command-word progression, including original machine-code and register/operand comparisons.
7. **Hardware mapping:** Confirm high-memory mirrors, RAM ownership, input/output ports and interrupt details against the board/MAME.
8. **Runtime checks:** Execute generated ROM in MAME and separately on physical hardware; record outcomes and any variations.
9. **Historical and project context:** Research Jeff Frederiksen's early maze-generation experiments and game chronology, while keeping README focused on actual game architecture.

## Mandatory engineering rules

Read `ENGINEERING-RULES.md` and `AGENTS.md` before any new edits. The original ROM, native Intel 8080 software and original execution behavior are authoritative. Use the bundled native assembler. Do not add synthetic gameplay, substitute parsers/interpreters, per-word host token rewriting or Python build scripts. Discuss and obtain explicit user approval **before** any architectural substitution. Changes to assembly and documentation must remain synchronized. Record actual test execution; distinguish source audit, native ROM build/equality, MAME and physical hardware.

## Resume instruction

**Start at P0:** run the native source build, inspect zmac errors or output, correct source and verify `maze.h` and `maze.g` by original SHA-1. Then resume native 8080 routine cleanup, maze algorithm and command vocabulary. Update the sprint/debt files and this checkpoint when a gate changes; keep README free of sprint status.
