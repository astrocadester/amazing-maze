# Amazing Maze

Amazing Maze was developed by Dave Nutting Associates (DNA) and released by Midway in 1976. The arcade game runs on Intel 8080 hardware and uses a one-byte indexed command interpreter to execute game scripts through 17 native command handlers.

![Amazing Maze arcade marquee](images/amazing-maze-21054-marquee.jpg)

Unlike Checkmate's native language-selection routines, Amazing Maze's command engine advances through a stream of game commands. A nonzero command in the range 1–17 selects a 16-bit native handler address; command zero enters the separate scheduler path.

| | |
| --- | --- |
| [Native execution](#architecture) | Reset, interrupt service, command interpreter and indexed native handlers. |
| [Command scripts](#command-interpreter) | Script cursor, dispatch, 17-word handler vector table. |
| [RAM and I/O](#ram-and-io) | Script cursor and game-state storage. |
| [ROM organization](#rom-organization) | Two original 2 KB 8080 program devices. |

## Project layout

`src/maze.asm`  
Original-ROM-derived Intel 8080 reconstruction with native routines, original graphics, interpreter vectors and command scripts.

`tools/zmac`, `tools/zmac.exe`  
zmac v1.3 assemblers for Linux and Windows.

`build/`  
Assembled image, listing and split 2 KB ROM devices.

`roms/original/maze.zip`  
Original MAME ROM set, preserved unchanged.

`roms/maze.zip`  
ROM set produced by a verified build.

`build.sh`, `build.bat`  
Native ROM build scripts; no Python.

`docs/`  
Runtime scan and memory-map documentation.

`images/`  
Arcade artwork and memory map.

## Build

Linux:

```sh
./build.sh
```

Windows:

```bat
build.bat
```

The scripts assemble `src/maze.asm` using zmac v1.3, split the 4 KB result into two 2 KB devices, compare each device's SHA-1 against the original ROM, and package `roms/maze.zip`. The original-ROM-derived assembly is present in `src/maze.asm`. The full source has not yet passed native zmac compilation or byte-exact device verification; both checks are required before treating the build as verified. Original bytes can also be inspected with `node tools/scan-runtime.mjs`.

MAME:

```sh
mame maze -rompath roms -window -skip_gameinfo
```

## ROM organization

| ROM | CPU address | SHA-1 |
| --- | --- | --- |
| `maze.h` | `$0000–$07FF` | `62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c` |
| `maze.g` | `$0800–$0FFF` | `893f0a7621e7df19f777be991faff0db4a9ad571` |

![Amazing Maze Intel 8080 memory map](images/amazing-maze-memory-map.svg)

The original archive is retained at `roms/original/maze.zip`. The byte-level runtime scan includes both ROMs and their address ranges. See [memory-map details](docs/memory-map.md).

## RAM and I/O

| Address | Use |
| --- | --- |
| `$2000` | Game-command stream cursor |
| `$2002–$2003` | Startup script-root state, written with `SHLD` |
| `$2000–$23FF` | Working RAM |
| `$2400–$3FFF` | Display RAM |

## Architecture

The reset entry at `$0000` initializes the stack and transfers control to `$0017`. The service entry at `$0008` saves processor registers before entering the interrupt path. The game-command dispatcher at `$0392–$03C9` fetches from the script cursor, checks the command number, computes a vector-table offset and transfers to the selected native handler with `PCHL`.

### Command interpreter

| Component | Address | Function |
| --- | --- | --- |
| Startup script root | `$037C` | Initializes script state from `$0D64` |
| Command dispatcher | `$0392` | Fetch and dispatch one-byte commands |
| Zero-command path | `$03CA` | Scheduler/control path |
| Handler vectors | `$0BEE–$0C0F` | 17 little-endian native routine addresses |

The dispatcher subtracts one from a nonzero command, bounds-checks the resulting index against `$11`, doubles it, and indexes the 16-bit vector table. The indexed table lookup ends in `PCHL`; this transfers execution to native 8080 code.

The 17 original targets are documented in [Original ROM runtime scan](docs/ORIGINAL-ROM-RUNTIME-SCAN.md). The initial native-code audit and interpreted command analysis are documented in [8080 word semantics](docs/8080-WORD-SEMANTICS.md), [native RE pass](docs/NATIVE-RE-PASS.md), and [graphics and maze RE](docs/GRAPHICS-AND-MAZE-RE.md). Further operand and continuation tracing remains open.

## Graphics and text

Screen graphics and message tables will be annotated at their verified original addresses in the complete disassembly; avoid assigning semantic names from byte-pattern appearance alone.

## Sound

Sound and timing services are native 8080 routines and hardware I/O interactions. Their source-level and port-level annotation is part of the full RE.

## References

- [Amazing Maze original-ROM interpreter audit](docs/ORIGINAL-ROM-RUNTIME-SCAN.md)
- [Memory map](docs/memory-map.md)
- [MAME Midway Intel 8080 driver](https://github.com/mamedev/mame/blob/master/src/mame/midway/8080bw.cpp)
