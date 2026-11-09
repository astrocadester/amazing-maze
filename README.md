# Amazing Maze (1976)

**Amazing Maze**, released by Midway in 1976, is an Intel 8080 black-and-white arcade maze game associated with Dave Nutting Associates' early game-development period. Players race through newly generated mazes. This project studies the original arcade ROM rather than the later Bally Astrocade cartridge adaptation.

**Reverse-engineering status:** original ROM identity and a 17-command native-handler interpreter have been identified; source reconstruction, exact assembly round-trip, complete command semantics, and maze-engine analysis remain to be completed. See [the original-ROM runtime scan](docs/ORIGINAL-ROM-RUNTIME-SCAN.md), [sprint plan](docs/SPRINT-PLAN.md), and [technical debt](docs/TECHNICAL-DEBT.md).

Unlike later Z80 TERSE, the arcade's observed dispatcher uses **one-byte command tokens** and 16-bit native handler vectors. The key lineage question is whether Amazing Maze and Gun Fight inherited a common 8080 command framework, shared selected routines, or evolved independently. Similar opcodes alone cannot answer that question.

The original dedicated cabinet appears to have used the title on the monitor bezel rather than a separate illuminated marquee. We will use an original bezel photograph in this README when a repository-controlled source image is available; a modern invented marquee would not represent the arcade cabinet. Historical cabinet information: [Arcade History](https://www.arcade-history.com/?id=75&n=amazing-maze&page=detail).

## Project layout

| Path | Purpose |
| --- | --- |
| `roms/original/maze.zip` | Immutable two-device original MAME ROM archive |
| `tools/scan-runtime.mjs` | Node.js structural scanner; validates original ROM members and interpreter signatures |
| `tools/zmac`, `tools/zmac.exe` | Bundled native assembler executables for Linux and Windows |
| `docs/ORIGINAL-ROM-RUNTIME-SCAN.md` | Verified static evidence and provisional runtime classification |
| `docs/SPRINT-PLAN.md` | RE and source-reconstruction gates |
| `docs/TECHNICAL-DEBT.md` | Unresolved tasks and verification status |
| `images/amazing-maze-memory-map.svg` | Hardware address-space diagram with distinct ROM, RAM, and video areas |

## Original ROM organization

| Device | Address | Size | CRC32 | SHA-1 |
| --- | --- | ---: | --- | --- |
| `maze.h` | `$0000–$07FF` | 2 KB | `f2860cff` | `62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c` |
| `maze.g` | `$0800–$0FFF` | 2 KB | `65fad839` | `893f0a7621e7df19f777be991faff0db4a9ad571` |

Original image is 4 KB, addresses `$0000–$0FFF`. The broader Midway 8080 address space has an 8 KB ROM window, of which the Amazing Maze game occupies the lower half. The known RAM/video layout is shown separately below; individual variable ownership is still under investigation.

![Amazing Maze Intel 8080 memory map](images/amazing-maze-memory-map.svg)

## Native execution architecture

| Component | Observed location | Meaning |
| --- | --- | --- |
| Reset | `$0000` | Initializes `SP=$2400` and jumps to `$0017` |
| Interrupt/service entry | `$0008` | Saves PSW, BC, DE, HL and jumps to `$030B` |
| Initial script root | `$0D64` | Saved to RAM `$2002` |
| Script cursor | RAM `$2000` | Read by interpreter |
| Interpreter | `$0392–$03C9` | Validates one-byte command and loads native handler vector |
| Zero-command path | `$03CA` | Separate control path, not native vector slot zero |
| Vector table | `$0BEE–$0C0F` | 17 little-endian native target addresses |

The nine-byte vector lookup tail at `$03C1` matches a corresponding documented pattern in Boot Hill. Amazing Maze precedes that tail with `ADD A,A` (`87`); the Boot Hill example uses `RLC` (`07`). This is an **observed code-pattern relationship**, not proof of common source or identical run-time ABI.

The 17 original command targets, exact signature assertions, and scope of current verification are in [the runtime scan](docs/ORIGINAL-ROM-RUNTIME-SCAN.md).

## Build and verification

**Current gate: ROM structural scan only.** Execute:

```sh
node tools/scan-runtime.mjs
```

This verifies both original ROM hashes, reset and dispatcher signatures, vector table, and each in-ROM handler target. It **does not assemble reconstructed source** and **does not demonstrate a byte-for-byte rebuild**.

Native build entry points are provided for Linux (`./build.sh`) and Windows (`build.bat`). Both invoke the appropriate assembler in `tools/`, check the 4096-byte image length, split into `maze.h` and `maze.g`, verify both original SHA-1 hashes, and only then package `roms/maze.zip`. **Both currently stop with an explicit BLOCKED message** because `src/maze.asm` has not yet been recovered. The scripts do not copy original ROM bytes into a simulated build. Neither uses Python.

When the exact rebuild exists, the game can be checked separately in MAME:

```sh
mame maze -rompath roms
```

MAME boot and gameplay tests are separate from byte equality. Hardware testing is another independent gate.

## Gun Fight and DNA lineage

Compare the Gun Fight 21-handler indexed interpreter at `$03A7`, script pointer `$2000`, and table `$09AE` with Amazing Maze's 17-handler dispatcher `$0392–$03C9`, script pointer `$2000`, and table `$0BEE`. Verify the calling ABI, script semantics, handler bodies, IRQ interaction, and full binary overlaps before assigning a relationship class.

[Gun Fight](https://github.com/lizard43/gunfight) · [Sea Wolf II style reference](https://github.com/lizard43/SeaWolf2) · [RE sprint plan](docs/SPRINT-PLAN.md) and [Gun Fight comparison](docs/GUNFIGHT-COMPARISON.md)

## Sources and evidence

The game-specific ROM hashes and code addresses above derive from the repository's original-ROM structural scanner. Hardware context can be cross-checked against the MAME Midway 8080 driver (`src/mame/midw8080/mw8080bw.cpp`) and original documentation. Historical leads include the [original 1976 sales flyer](https://flyers.arcade-museum.com/videogames/show/35), [arcade cabinet overview](https://www.arcade-history.com/?id=75&n=amazing-maze&page=detail), and [Midway 8080 board study](https://hackaday.io/project/204138-up-to-eleven/log/243972-development-details); modern derivative code is not evidence of the original ROM's software architecture.
