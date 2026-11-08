# Amazing Maze (1976) — Original ROM runtime scan

**Classification: non-TERSE.** The original **Intel 8080** arcade game executes a **one-byte indexed game-command interpreter**, with 17 native handler vectors. This is a genuine pre-TERSE DNA game language, **not** the Z80 TERSE BC/IX/IY / RST $08 architecture.

## Original-ROM evidence

This scan uses the existing, unchanged `roms/original/maze.zip` and its **two 2,048-byte** members, assembled as the 4 KB 8080 program space. The SHA-1s identify the known original MAME set (not a rewritten cartridge):

| File | CPU address | CRC32 | SHA-1 |
|---|---|---|---|
| `maze.h` | `$0000–$07FF` | `f2860cff` | `62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c` |
| `maze.g` | `$0800–$0FFF` | `65fad839` | `893f0a7621e7df19f777be991faff0db4a9ad571` |

Run `node tools/scan-runtime.mjs` to extract both ROMs, validate CRC32 and SHA-1, assert the instruction sequences below, and print all 17 vector targets. No Python, external packages, generated stand-in ROM, or changes to original bytes.

## Native execution contract

| Component | Original address | Observed code/behavior |
|---|---|---|
| Reset | `$0000` | `NOP; NOP; LXI SP,$2400; JMP $0017` |
| `$0008` entry | `$0008` | `PUSH PSW; PUSH B; PUSH D; PUSH H; JMP $030B` — interrupt/service prologue, **not TERSE colon entry** |
| Initial script root | `$037C` | `LXI H,$0D64; SHLD $2002` |
| Script cursor | RAM `$2000` | Game-program PC, loaded and advanced while fetching command bytes |
| Interpreter | `$0392–$03C9` | Loop loads/initializes script PC, reads a command, handles zero separately, checks command range, selects a native vector, then `PCHL` |
| Zero-command path | `$03CA` | Separate event/scheduler path; **not** vector-table slot zero |
| Native command table | `$0BEE–$0C0F` | **17** 16-bit little-endian native handler addresses |
| Dispatch tail | `$03C0–$03C9` | `87 4F 06 00 09 7E 23 66 6F E9` = `ADD A,A; MOV C,A; MVI B,0; DAD B; MOV A,M; INX H; MOV H,M; MOV L,A; PCHL` |

### Interpreter packet format

A **nonzero command 1–17** is decremented to a zero-based index. The dispatcher compares the result against `$11`, doubles the index, adds it to table base `$0BEE`, reads a 16-bit handler address and branches with `PCHL`. **Command zero** takes a distinct control path rather than indexing the native table. Other command-specific inline operand forms still require a word-by-word handler audit; this document does not invent those contracts.

### Original native handler vectors

| Command | Target | Command | Target | Command | Target |
|---|---|---|---|---|---|
| `$01` | `$04BD` | `$02` | `$0B12` | `$03` | `$0835` |
| `$04` | `$0B17` | `$05` | `$0B4B` | `$06` | `$0419` |
| `$07` | `$0B90` | `$08` | `$0B5F` | `$09` | `$0B69` |
| `$0A` | `$08AC` | `$0B` | `$0B7B` | `$0C` | `$0B84` |
| `$0D` | `$0BA3` | `$0E` | `$0BB9` | `$0F` | `$0BC4` |
| `$10` | `$0BCF` | `$11` | `$05D9` | | |

All 17 vector addresses are within the 4 KB ROM. These are command-handler entry addresses, **not** TERSE named words.

## DNA runtime evolution finding

The last **nine bytes** of Amazing Maze's command-vector lookup (`4F 06 00 09 7E 23 66 6F E9` at `$03C1`) are byte-identical to the tail in [Boot Hill's documented 8080 interpreter](https://github.com/lizard43/boothill/blob/main/docs/interpreter-lineage-audit.md). The preceding index-doubling opcode differs:

| Game | Double command index | Following lookup sequence |
|---|---|---|
| Amazing Maze | `87` — `ADD A,A` | `4F 06 00 09 7E 23 66 6F E9` |
| Boot Hill | `07` — `RLC` | `4F 06 00 09 7E 23 66 6F E9` |

Both operations double an 8-bit index, but their flag/carry behavior differs. This is **precise code-pattern reuse or a very closely related implementation**, not proof the entire runtimes or source modules are identical. It strengthens the early indexed-8080 family connection.

**Important distinction:** The later **Astrocade Z80 cartridge** `Amazing Maze / Tic-Tac-Toe` is a *different implementation* using the numbered **Bally BIOS system-service interpreter** (`SYSTEM INTPC`, `DO RECTAN`), documented in [the actual cartridge-to-BIOS trace](https://github.com/lizard43/TERSE/blob/main/02-AMAZING-MAZE-WORKED-TRACE.md). The historical architectural contrast is therefore **arcade 8080 indexed native game commands ↔ cartridge Z80 BIOS service commands**, without asserting unproven shared machine code.

## Follow-up reverse engineering

1. Decode each of the 17 native handlers and their exact inline operand widths.
2. Recover the complete interpreted script boundaries starting at `$0D64`; distinguish executable scripts from graphics, messages and other data.
3. Compare the nine-byte native handler lookup against Gun Fight, Sea Wolf, Boot Hill, Tornado Baseball, Double Play, Extra Inning and Desert Gun at the **byte** level; determine where the differing doubling opcode changes effective semantics.
4. Trace the `$0008` interrupt path and zero-command scheduler with a native 8080 emulator; do not assume they are TERSE control flow.
5. Compare actual program structure and ABI with the distinct 1979 Astrocade cartridge implementation.

**Status:** Original program bytes and the enumerated interpreter signatures/vector targets were inspected directly. This is an **original ROM structural scan**, not a full dynamic emulator trace or complete semantic RE of every command.
