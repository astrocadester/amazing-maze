# amazing-maze
Amazing Maze ザ・アメージング・メーズ・ゲーム Arcade Disassembly 

## Original ROM runtime scan

The 1976 Intel 8080 arcade game has a **17-command indexed native-handler interpreter**, not a Z80 TERSE runtime. The original `maze.h` and `maze.g` ROM members, handler vector table at `$0BEE`, command dispatch at `$0392–$03C9`, and shared nine-byte 8080 lookup pattern are documented in [Original ROM runtime scan](docs/ORIGINAL-ROM-RUNTIME-SCAN.md).

Run `node tools/scan-runtime.mjs` to verify the original archived ROM hashes, command dispatch signature, and all 17 native vectors without changing `roms/original/maze.zip`.
