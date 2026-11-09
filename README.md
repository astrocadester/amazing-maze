# Amazing Maze

![Amazing Maze marquee](images/amazing-maze-21054-marquee.jpg)

Amazing Maze (1976) is an Intel 8080 arcade maze game by Dave Nutting Associates (DNA) / Midway. It challenges players to navigate generated mazes and is one of the company's earliest 8080 arcade programs. This project reconstructs the **original 4 KB executable** as readable native 8080 assembly, with every produced ROM chip verified against the original bytes.

**Amazing Maze contains a 17-command indexed native-handler interpreter.** Gun Fight (1975) contains 21 native command entries. Both games use one-byte commands, Intel 8080 handler vectors, and a script cursor at RAM `$2000`. Their command dictionaries share recognizable operations, including jumps, RAM updates, and conditional control flow. This RE traces DNA's engineering choices from Gun Fight into Amazing Maze.

The game runs on the Midway 8080 black-and-white platform with 4 KB of program ROM, 1 KB of work RAM, and a 7 KB monochrome framebuffer.

## Project layout

| Path | Contents |
| --- | --- |
| `roms/original/maze.zip` | Original reference MAME ROM archive |
| `src/maze.asm` | Reconstructed Intel 8080 assembly, game commands, graphics, and tables |
| `build.sh`, `build.bat` | Linux and Windows assembly, ROM splitting, verification, and packaging |
| `tools/zmac`, `tools/zmac.exe` | Bundled native assembler binaries |
| `tools/scan-runtime.mjs` | ROM identity and interpreter inspection |
| `images/amazing-maze-21054-marquee.jpg` | Amazing Maze marquee artwork |
| `images/amazing-maze-memory-map.svg` | Intel 8080 memory map |
| `docs/NATIVE-RE-PASS.md` | Native execution and control flow |
| `docs/GRAPHICS-AND-MAZE-RE.md` | Character graphics, game text, and maze routines |
| `docs/ORIGINAL-ROM-RUNTIME-SCAN.md` | ROM structure and native vectors |
| `docs/8080-WORD-SEMANTICS.md` | Indexed command dictionary |
| `docs/GUNFIGHT-COMPARISON.md` | Gun Fight and Amazing Maze command comparison |
| `docs/SPRINT-PLAN.md`, `docs/TECHNICAL-DEBT.md` | Engineering work plan and technical debt |

## Build

The Linux and Windows scripts assemble the Intel 8080 source with the bundled zmac assembler, split the image into the original ROM devices, and verify the resulting ROMs.

Linux:
```sh
./build.sh
```

Assembler command:
```sh
./tools/zmac -o src/maze.bin src/maze.asm
```

Windows 10/11:
```bat
build.bat
```

Assembler command:
```bat
tools\zmac.exe -o src\maze.bin src\maze.asm
```

The build assembles `src/maze.asm` into a 4 KB image, produces `maze.h` and `maze.g`, checks their SHA-1 hashes, and packages `roms/maze.zip`.

## Run in MAME

```sh
mame maze -window -skip_gameinfo -rompath roms
```

## ROM organization

The original 4 KB program occupies two 2 KB devices in the lower half of the Midway 8080 ROM window.

| ROM | CPU address | CRC32 | SHA-1 |
| --- | --- | --- | --- |
| `maze.h` | `$0000–$07FF` | `f2860cff` | `62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c` |
| `maze.g` | `$0800–$0FFF` | `65fad839` | `893f0a7621e7df19f777be991faff0db4a9ad571` |

The memory map shows the two ROM devices, the upper program ROM window, work RAM, and bitmap video RAM.

![Amazing Maze 8080 address-space map](images/amazing-maze-memory-map.svg)

## Indexed 8080 execution architecture

Amazing Maze uses one-byte game commands to select little-endian Intel 8080 native handler addresses. Gun Fight uses the same overall command-dispatch architecture. Amazing Maze adds explicit nonzero command bounds checking and a dedicated zero-command event path.

| Component | Address | Function |
| --- | --- | --- |
| Reset | `$0000` | Initializes `SP=$2400` and branches to `$0017` |
| Interrupt entry | `$0008` | Saves PSW, BC, DE, HL and enters service at `$030B` |
| Script root | `$0D64` | Initially stored at RAM `$2002` |
| Script cursor | RAM `$2000` | Current game command pointer |
| Interpreter | `$0392–$03C9` | Loads, bounds-checks and dispatches one-byte tokens |
| Zero-command path | `$03CA` | Conditional event call rather than normal native slot |
| Vector table | `$0BEE–$0C0F` | 17 little-endian handler addresses |

### Native command dispatch

The normal token path advances the pointer at RAM `$2000`, changes the one-based command number into a zero-based vector index, checks the 17-entry limit, and indirectly jumps to the native code.

```asm
; Actual original instruction sequence at $03C0.
; HL initially holds $0BEE; A contains the zero-based token.
ADD A           ; $87: vector index * 2
MOV C,A         ; $4F
MVI B,0         ; $06 $00
DAD B           ; $09: HL += BC
MOV A,M         ; $7E: low native target byte
INX H           ; $23
MOV H,M         ; $66: high target byte
MOV L,A         ; $6F
PCHL            ; $E9: jump to original native handler
```

Command `$00` enters the event path at `$03CA`, where RAM `$201F` controls a conditional call to `$03D4`. Nonzero commands `$01–$11` select the 17 native vectors. Higher command values enter initialization at `$0377`. 

[17-command native dictionary](docs/8080-WORD-SEMANTICS.md) · [Original command vectors and ROM signatures](docs/ORIGINAL-ROM-RUNTIME-SCAN.md) · [Native assembly analysis](docs/NATIVE-RE-PASS.md)

## Interrupt and timer services

The `$0008` entry saves the primary 8080 registers before transferring to native frame service. A timed event service beginning at `$0341` operates on work-RAM counters: `$200A` reloads with `$3C`, and the helper at `$0369` decrements four neighboring bytes at `$200B–$200E`. The helper aggregates expiry information into register `B`.

The [native execution documentation](docs/NATIVE-RE-PASS.md) describes the service routines and their RAM interactions.

## Maze engine and gameplay

The game maintains its maze cells in RAM beginning at `$2066`. Native routines mask and shift cell-state nibbles, convert maze row and column coordinates into cell addresses, and test the four directional boundaries during movement.

At `$0129`, the native text renderer draws characters from 37 ten-row glyphs stored at `$0170`. The game text begins at `$0C10`, followed by indicator graphics at `$0D33`. The initial command stream at `$0D64` configures game state and displays text through the indexed native commands.

[Graphics, maze data, and movement routines](docs/GRAPHICS-AND-MAZE-RE.md)

## Gun Fight and DNA lineage

Gun Fight (1975) provides the earlier recovered DNA Intel 8080 indexed-command architecture. Its interpreter runs at `$03A7`, uses a 21-entry native command table at `$09AE`, and reads scripts through RAM `$2000`. Amazing Maze (1976) uses a 17-entry native table at `$0BEE`, dispatcher `$0392–$03C9`, and the **same script cursor address `$2000`**.

### Shared command functions

The two games contain corresponding native command operations with different command numbers:

| Command function | Gun Fight command / handler | Amazing Maze command / handler | Common operation |
| --- | --- | --- | --- |
| **GOTO_SCRIPT** | `$09 / $0682` | `$0B / $0B7B` | Read a 16-bit command-stream address and store it at `$2000` |
| **Set RAM byte** | `$02 / $063D`, `$03 / $0649` | `$08 / $0B5F`, `$0C / $0B84` | Read an immediate byte and update game state in RAM |
| **Conditional execution** | `$05 / $068D`, `$06 / $069D`, `$10 / $0807` | `$0E / $0BB9`, `$0F / $0BC4` | Test game state and conditionally change execution |
| **Display/graphics services** | `$01 / $05E9`, `$0E / $0785`, `$0F / $07AB` | `$04 / $0B17`, `$07 / $0B90`, `$10 / $0BCF` | Work with inline data, memory addresses and native drawing-related services |

**The strongest common word is `GOTO_SCRIPT`.** Both implementations use a little-endian 16-bit target and replace the command pointer at `$2000`. RAM-store and conditional commands demonstrate shared command families with game-specific operands and handlers. Graphics commands use the games' respective drawing services.

### How the interpreter evolved

| Feature | Gun Fight | Amazing Maze |
| --- | --- | --- |
| Native command slots | 21 (`$00–$14`) | 17 (`$01–$11`) plus zero event |
| Script cursor | RAM `$2000` | RAM `$2000` |
| Command vector base | `$09AE` | `$0BEE` |
| Script starting point | `$0821` | `$0D64` |
| Zero-command operation | Counter-based wait/repeat handler | Separate `$03CA` event path |
| Indexed native dispatch | Address table and indirect transfer | Address table, range check and indirect transfer |

DNA carried forward the indexed-command design and common command functions while adapting command numbers, state operations, and event handling for Amazing Maze. The [native comparison](docs/GUNFIGHT-COMPARISON.md) details these routines.

[Gun Fight ↔ Amazing Maze command comparison](docs/GUNFIGHT-COMPARISON.md) · [Amazing Maze word dictionary](docs/8080-WORD-SEMANTICS.md)

