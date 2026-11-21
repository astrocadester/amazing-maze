#!/usr/bin/env node
// Read the actual 624-byte maze RAM captured by MAME just before command $06.
// Usage: node tools/analyze-am-re-004-grid.mjs build/am-re-004-grid.bin
// Observations only. No synthetic maze generation.
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';

const file = process.argv[2] ?? 'build/am-re-004-grid.bin';
let bytes;
try { bytes = readFileSync(file); }
catch (err) { console.error('Cannot read original MAME grid dump:', err.message); process.exit(2); }
if (bytes.length !== 26 * 24) {
  console.error('Expected 624 bytes ($270), found ' + bytes.length);
  process.exit(1);
}
const sha = createHash('sha256').update(bytes).digest('hex');
console.log('AM-RE-004 original MAME maze RAM snapshot');
console.log('File:', file);
console.log('Original RAM: $2066-$22D5, 26 rows by 24 columns');
console.log('Length:', bytes.length, 'bytes; SHA-256:', sha);
for (const bit of [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80]) {
  let count = 0;
  for (const b of bytes) if (b & bit) count++;
  console.log('bit $' + bit.toString(16).toUpperCase().padStart(2, '0') +
    ' set in ' + count + ' / 624 cells');
}
console.log('\nNative byte values, one original 24-cell row per line:');
for (let row = 0; row < 26; row++) {
  const cells = bytes.subarray(row * 24, (row + 1) * 24);
  console.log('row ' + row.toString().padStart(2, '0') + ': ' +
    Array.from(cells, n => n.toString(16).toUpperCase().padStart(2, '0')).join(' '));
}
