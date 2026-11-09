# Gun Fight ↔ Amazing Maze: initial ROM-level interpreter comparison

Version: v20261108-0001

## Scope and evidence

This is a **static architecture comparison**, not a complete byte-diff or dynamic trace. Amazing Maze evidence is from `tools/scan-runtime.mjs` and `docs/ORIGINAL-ROM-RUNTIME-SCAN.md` in this repository. Gun Fight evidence is from `lizard43/gunfight/docs/8080-WORD-SEMANTICS.md` and `README.md`. Original ROM bytes were not directly cross-diffed in this document. Do not use this as proof of shared source.

| Feature | Gun Fight (1975) | Amazing Maze (1976) | Implication |
| --- | --- | --- | --- |
| Processor | 8080 | 8080 | Shared target ISA, no lineage inference |
| Script cursor | RAM `$2000` | RAM `$2000` | Shared address convention; may reflect platform RAM choices or common design |
| Default script | `$0821` | `$0D64` | Different game program |
| Alternative script | `$089B` | Not yet established | Audit needed |
| Dispatcher | `$03A7` | `$0392–$03C9` | Both indexed-native interpreters |
| Handler vector base | `$09AE` | `$0BEE` | Different layout |
| Defensible commands | 21 indexed slots, `$00–$14` | 17 native handlers for `$01–$11`; zero separate | Different token indexing/zero behavior |
| Index validation | No obvious bound check in reported Gun Fight dispatch | Compares adjusted index against 17 | Different fault/control contracts |
| Handler continuation | Pushes `$03A6` then `PCHL`; handlers can `RET` | Indirect `PCHL`; entry/exit and return continuation require audit | **Do not classify ABI compatibility yet** |
| Zero token | Gun Fight handler `$0813`: wait or repeat | Separate control path at `$03CA` | Material difference in control flow |
| Handler packet widths | Mixed; some verified immediates and pointer operands | Not audited individually | Dictionary comparison premature |
| Hardware | Midway 8080 platform | Midway 8080 platform | Shared I/O constraints alone do not prove reused code |

## Evidence already recovered

Gun Fight's command `$00` is a valid handler that may decrement the stored script pointer. Amazing Maze tests zero before the normal 1-based native-vector lookup. Therefore the same opcode number **cannot** be assumed to mean the same operation in both games.

Gun Fight has proven handlers that set RAM bytes, redirect script execution, clear the display, update scores, and handle I/O. These categories are candidates for functional comparisons against Amazing Maze, but **no Amazing Maze handler has been assigned those functions** without tracing its native implementation.

Amazing Maze's lookup tail `4F 06 00 09 7E 23 66 6F E9` is reported as matching the later Boot Hill implementation. Its index doubling uses `87` (`ADD A,A`) whereas the documented Boot Hill uses `07` (`RLC`). This observation identifies a related lookup idiom, not identical complete binaries.

## Open comparison questions

1. Is Gun Fight's vector fetch identical or only logically equivalent to the Amazing Maze vector fetch? Extract and byte-compare the **entire** instruction sequences and register effects.
2. Do both dispatchers retain their script PCs in RAM `$2000` with identical update/advance timing?
3. Does Amazing Maze preserve the same native `RET` continuation mechanism as Gun Fight, or use a different return path?
4. Is Amazing Maze's zero handler a frame/event scheduler more like later 8080 games than Gun Fight's `WAIT_OR_REPEAT`?
5. Which native routines, if any, share byte-identical bodies after accounting for relocation or different port addresses?
6. Which common graphics/I/O operations are dictated solely by the shared board?
7. Could a pre-Gun Fight common 8080 library explain parts of both games without either directly inheriting from the other?

## Classification status

- **Exact binary reuse:** not established.
- **ABI-compatible:** not established; zero-token treatment and index validation differ.
- **Related implementation:** supported as a **preliminary architectural classification** for the concept of one-byte interpreted native commands and cursor storage at `$2000`; this is not yet a proven direct lineage.
- **Independent implementation:** cannot be excluded.

## Required next evidence

Compare the original 4 KB ROMs directly; recover and annotate Amazing Maze's 17 handlers, script packet boundaries and zero-command scheduler; then record the ABI in both original assembly sources and their respective dictionaries. Avoid duplicating a stale Gun Fight word inventory: `docs/interpreter.md` lists an obsolete 30-slot extraction; `docs/8080-WORD-SEMANTICS.md` corrects the defensible count to **21**. Changes affecting Gun Fight must round-trip in the Gun Fight repository rather than changing only this comparison.
