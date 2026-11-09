# Amazing Maze — technical debt and evidence ledger

Version: v20261108-0001

| Item | Status | Exit evidence |
| --- | --- | --- |
| Original ROM identity | Documented by static scanner; execute locally to confirm | Original members pass CRC32/SHA-1 assertions |
| 17-command vector interpreter | Static signatures established | Full handler ABI and execution trace |
| Full 8080 disassembly | Open | No reachable code hidden in undifferentiated raw bytes; semantics verified |
| Semantic labels and function boundaries | Open | Cross-referenced entry/exit contracts and named callers |
| 8080 assembler and round-trip | Open | Bundled assembler produces exact 4 KB image and both matching SHA-1s |
| MAME execution of generated ROM | Open | Rebuilt set boots and behaves in MAME with recorded test |
| Hardware execution | Open | Separate physical-board test record |
| Zero-command / IRQ scheduler | Open | Native trace from `$0008`, `$030B`, `$03CA` |
| All native command contracts | Open | Each of 17 entries decoded with inline bytes and side effects |
| Maze algorithm | Open | Recover RAM representation, randomness, draw and validation code |
| Gun Fight relationship | Open | Actual machine-code and ABI comparison, including shared-ancestor possibility |
| Hardware memory map | Partial | ROM/RAM/video envelope known; mirrors, ports, owner bytes need driver+schematics audit |
| README bezel artwork | Open | Repository-controlled authentic image with provenance |
| Engineering rule files | Adopted from Gun Fight and reviewed | Continue following root `ENGINEERING-RULES.md` and `AGENTS.md`; obtain approval for deviations |

## Verified versus inferred

**Original-ROM scan:** Two 2 KB ROM members, reset `SP=$2400`, `RST 08h` service entry, command script root `$0D64`, cursor at `$2000`, 17 native vectors at `$0BEE`, and dispatch `$0392–$03C9` are documented in the existing scanner with exact byte assertions.

**Similarity only:** The 9-byte indexed-handler lookup tail matches documented Boot Hill bytes. The index-doubling opcode differs. This is not proof of a common runtime ABI or shared source.

**Unresolved:** The extent of Gun Fight ↔ Amazing Maze software inheritance, historical chronology, handler semantics, dynamic scheduling and maze-generator origin.

## Build integrity policy

The original archive is immutable. The assembler build must use human-maintained 8080 assembly from the original program, then compare generated ROM hashes. A scanner, a self-copying ROM packager, a file of anonymous `DB` bytes, or a synthetic ROM is never counted as an RE build. Build, exact byte equality, MAME and hardware each have their own status.

If a rule requires approval, stop before changing execution architecture.
