#!/usr/bin/env bash
# Amazing Maze original Intel 8080 ROM build — zmac v1.3; no Python.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
fail() { echo "ERROR: $*" >&2; exit 1; }
for cmd in dd sha1sum zip stat unzip cmp; do command -v "$cmd" >/dev/null 2>&1 || fail "Missing command: $cmd"; done
if [[ -n "${ZMAC:-}" ]]; then zmac_bin="$ZMAC"
elif [[ -x tools/zmac ]]; then zmac_bin=tools/zmac
else zmac_bin=zmac
fi
command -v "$zmac_bin" >/dev/null 2>&1 || fail 'zmac v1.3 not found (set ZMAC or use tools/zmac)'
[[ -f src/maze.asm ]] || fail 'Missing src/maze.asm'
[[ -f roms/original/maze.zip ]] || fail 'Missing reference roms/original/maze.zip'

rom_names=(maze.h maze.g)
rom_sha1=(62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c 893f0a7621e7df19f777be991faff0db4a9ad571)
echo 'Amazing Maze original ROM build'
echo '[1/4] Prepare output'
mkdir -p build roms
rm -f build/amazing-maze.bin build/amazing-maze.lst roms/maze.zip
for name in "${rom_names[@]}"; do rm -f "build/$name"; done
echo '[2/4] Assemble native Intel 8080 source (zmac v1.3)'
"$zmac_bin" -c -o build/amazing-maze.bin -x build/amazing-maze.lst src/maze.asm || fail 'Assembly failed'
[[ -s build/amazing-maze.bin ]] || fail 'Assembler did not produce a binary image'
size=$(stat -c %s build/amazing-maze.bin)
(( size == 4096 )) || fail "Binary image is $size bytes; expected 4096"
echo '[3/4] Split and verify two 2 KB ROMs'
for i in 0 1; do
    name=${rom_names[i]}
    dd if=build/amazing-maze.bin of="build/$name" bs=2048 skip="$i" count=1 status=none
    size=$(stat -c %s "build/$name")
    (( size == 2048 )) || fail "$name is $size bytes; expected 2048"
    actual=$(sha1sum "build/$name"); actual=${actual%% *}
    if [[ "$actual" != "${rom_sha1[i]}" ]]; then
        echo "ERROR: $name SHA1 mismatch: expected ${rom_sha1[i]}, got $actual" >&2
        echo 'First byte differences (device offset decimal, byte values octal):' >&2
        cmp -l <(unzip -p roms/original/maze.zip "$name") "build/$name" |
            awk 'NR<=30 {printf "  %6d  %8s  %9s\\n", $1-1, $2, $3} END {printf "  Total differing bytes: %d\\n", NR}' >&2 || true
        fail "ROM verification failed; original archive and assembled device are preserved"
    fi
    echo "  $name  OK  $actual"
done
echo '[4/4] Package roms/maze.zip'
(cd build && zip -q -X ../roms/maze.zip "${rom_names[@]}") || fail 'ROM packaging failed'
[[ -s roms/maze.zip ]] || fail 'ROM ZIP not created'
echo 'Build complete: roms/maze.zip'
