#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
echo "Amazing Maze native ROM build"
echo "Source: src/maze.asm"
echo

if [[ ! -f src/maze.asm ]]; then
    echo "BLOCKED: src/maze.asm has not yet been reconstructed from the original Intel 8080 ROMs." >&2
    echo "The existing tools/scan-runtime.mjs is a structural scan, not a source build." >&2
    exit 2
fi
if [[ ! -x tools/zmac ]]; then
    echo "ERROR: bundled tools/zmac executable missing or not executable." >&2
    exit 2
fi
for cmd in dd sha1sum zip wc; do
    command -v "$cmd" >/dev/null || { echo "ERROR: required command $cmd is not installed." >&2; exit 2; }
done
mkdir -p roms

echo "[1/4] Assemble native 8080 source with bundled tools/zmac"
./tools/zmac -o src/maze.bin src/maze.asm
size="$(wc -c < src/maze.bin | tr -d ' ')"
if [[ "$size" != 4096 ]]; then
    echo "FAIL: assembled image is $size bytes; expected exactly 4096." >&2
    exit 1
fi

echo "[2/4] Split 4 KB image into original 2 KB ROM devices"
dd if=src/maze.bin of=roms/maze.h bs=2048 count=1 status=none
dd if=src/maze.bin of=roms/maze.g bs=2048 skip=1 count=1 status=none

echo "[3/4] Verify each generated ROM against original SHA-1"
verify() {
    local filename="$1" expected="$2" actual
    actual="$(sha1sum "$filename")"
    actual="${actual%% *}"
    printf '%s  %s\n' "$actual" "$filename"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: original SHA-1 mismatch: $filename" >&2
        echo "Expected: $expected" >&2
        exit 1
    fi
}
verify roms/maze.h 62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c
verify roms/maze.g 893f0a7621e7df19f777be991faff0db4a9ad571

echo "[4/4] Package source-built MAME set (never the original archive)"
rm -f roms/maze.zip
zip -jq roms/maze.zip roms/maze.h roms/maze.g
echo "PASS: source-assembled Amazing Maze ROM exactly matches both original devices."
echo "MAME and hardware execution remain separate verification gates."
