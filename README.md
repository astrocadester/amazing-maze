# Amazing Maze

Amazing Maze is a 1976 arcade maze game developed by Dave Nutting Associates (DNA) and released by Midway. Built for Intel 8080 arcade hardware, the game generates mazes, draws the playfield, processes player movement, and runs its game logic through a 17-command interpreter.

![Amazing Maze marquee](images/amazing-maze-21054-marquee.jpg)

The original program occupies 4 KB of ROM across two 2 KB devices. A native Intel 8080 interpreter reads one-byte game commands from a script stream, selects their corresponding routine addresses from a 17-entry table, and transfers execution to the game handlers.

## Project layout

| Path | Contents |
| --- | --- |
| `src/maze.asm` | Intel 8080 assembly reconstruction, game routines, interpreter, graphics and command scripts |
| `roms/original/maze.zip` | Original arcade ROM reference archive |
| `build.sh`, `build.bat` | Linux and Windows assembly, ROM verification and packaging |
| `tools/zmac`, `tools/zmac.exe` | Bundled zmac v1.3 assemblers |
| `tools/scan-runtime.mjs` | Original ROM identity and interpreter inspection |
| `build/` | Generated assembly image, listing and ROM devices |
| `roms/maze.zip` | Assembled MAME ROM set |
| `docs/` | Native routine, game command, graphics and memory research |
| `images/` | Arcade artwork and memory-map SVG |

## Build

Linux:

```sh
./build.sh
```

Windows:

```bat
build.bat
```

The build assembles `src/maze.asm` with zmac v1.3, produces a 4 KB program image, splits it into `maze.h` and `maze.g`, verifies each device against the original SHA-1, and packages `roms/maze.zip`.

Run the assembled game in MAME:

```sh
mame maze -rompath roms -window -skip_gameinfo
```

## ROM organization

| ROM | CPU address | Size | SHA-1 |
| --- | --- | --- | --- |
| `maze.h` | `$0000–$07FF` | 2 KB | `62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c` |
| `maze.g` | `$0800–$0FFF` | 2 KB | `893f0a7621e7df19f777be991faff0db4a9ad571` |

![Amazing Maze Intel 8080 memory map](images/amazing-maze-memory-map.svg)

The lower 4 KB contains the program ROM. The board uses 1 KB of working RAM at `$2000–$23FF` and 7 KB of bitmap video RAM at `$2400–$3FFF`. [Memory-map details](docs/memory-map.md) identify the original ROM devices and key routines.

## Architecture

Amazing Maze combines native Intel 8080 routines with an interpreted game-command stream. The 8080 executes the interpreter and each command handler directly; the script provides the sequence of game operations.

| Component | Address | Function |
| --- | --- | --- |
| Reset | `$0000` | Initializes `SP=$2400` and branches to startup at `$0017` |
| Interrupt entry | `$0008` | Preserves registers and enters the frame-service routine |
| Script initialization | `$037C` | Loads the script root from `$0D64` into game state |
| Script cursor | RAM `$2000` | Tracks the next game-command byte |
| Command dispatch | `$0392–$03C9` | Fetches, validates and dispatches game commands |
| Zero-command service | `$03CA` | Handles the command-zero control path |
| Handler vectors | `$0BEE–$0C0F` | Stores 17 native command-handler addresses |
| Opening script | `$0D64` | Game initialization and presentation command stream |

### Game-command interpreter

Commands `$01–$11` index 17 native handlers. The dispatcher subtracts one from the command, checks its range, doubles the resulting index to select a two-byte address, and branches to the handler using `PCHL`. Command `$00` enters the scheduler/control path at `$03CA`.

The original handler table includes game-state updates, script-pointer changes, conditional execution and drawing services. The command `$0B` handler at `$0B7B`, for example, reads an inline 16-bit address and updates the script cursor at `$2000`.

See [8080 word semantics](docs/8080-WORD-SEMANTICS.md), [original ROM command vectors](docs/ORIGINAL-ROM-RUNTIME-SCAN.md), and [native program analysis](docs/NATIVE-RE-PASS.md).

## Maze engine and game state

The game maintains maze cell data in working RAM beginning at `$2066`. Native routines calculate cell addresses, extract and modify packed cell information, and test directional boundaries used for movement through the maze.

| Address | Use |
| --- | --- |
| `$2000–$2001` | Game-command cursor |
| `$2002–$2003` | Initial script root/state pointer |
| `$200A–$200E` | Timer and frame-service counters |
| `$2066` onward | Maze cell storage |
| `$2400–$3FFF` | Monochrome framebuffer |

The [native RE documentation](docs/NATIVE-RE-PASS.md) traces the interpreter, event services and game-state routines.

## Graphics and text

The text renderer at `$0129` draws characters into video RAM using ten-row glyphs. The ROM contains **37 original glyphs** beginning at `$0170`: digits, a space and uppercase letters. Each glyph occupies ten bytes, with one byte per eight-pixel row.

Encoded game text begins at `$0C10`; additional indicator graphics begin at `$0D33`. The assembly presents font bitmaps with inline pixel patterns and keeps encoded messages in their original ROM order.

[Graphics and maze analysis](docs/GRAPHICS-AND-MAZE-RE.md)

## Sound and timing

Native interrupt and frame-service routines maintain game timers and coordinate hardware output. The periodic service at `$0341` updates work-RAM counters; the routine at `$0369` processes adjacent countdown bytes and reports expiry information to its caller.

## References

- [Original ROM runtime and interpreter](docs/ORIGINAL-ROM-RUNTIME-SCAN.md)
- [8080 game-command semantics](docs/8080-WORD-SEMANTICS.md)
- [Native execution analysis](docs/NATIVE-RE-PASS.md)
- [Graphics and maze routines](docs/GRAPHICS-AND-MAZE-RE.md)
- [Memory map](docs/memory-map.md)
- [MAME Midway Intel 8080 hardware driver](https://github.com/mamedev/mame/blob/master/src/mame/midway/8080bw.cpp)
