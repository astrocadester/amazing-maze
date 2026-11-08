#!/usr/bin/env node
// Scan the two original Intel 8080 Amazing Maze ROM devices.
// Uses only Node.js built-ins; leaves roms/original/maze.zip unchanged.
import { readFileSync } from 'node:fs';
import { inflateRawSync } from 'node:zlib';
import { createHash } from 'node:crypto';

const archive = readFileSync(new URL('../roms/original/maze.zip', import.meta.url));
const expected = {
  'maze.h': { crc: 0xf2860cff, sha1: '62b3fd3d04bf9c5dd9b50964374fb884dc0ab79c' },
  'maze.g': { crc: 0x65fad839, sha1: '893f0a7621e7df19f777be991faff0db4a9ad571' },
};
function crc32(data) {
  let c = 0xffffffff;
  for (const byte of data) {
    c ^= byte;
    for (let j = 0; j < 8; j++) c = (c >>> 1) ^ ((c & 1) ? 0xedb88320 : 0);
  }
  return (c ^ 0xffffffff) >>> 0;
}
function assert(ok, message) { if (!ok) throw new Error(message); }
function hex(value, digits = 4) { return value.toString(16).toUpperCase().padStart(digits, '0'); }
function assertBytes(rom, address, bytes, description) {
  assert(bytes.every((b, index) => rom[address + index] === b), `ROM mismatch at $${hex(address)}: ${description}`);
}
const members = new Map();
for (let offset = 0; offset < archive.length;) {
  if (archive.readUInt32LE(offset) !== 0x04034b50) break; // central directory
  const flags = archive.readUInt16LE(offset + 6);
  const method = archive.readUInt16LE(offset + 8);
  const size = archive.readUInt32LE(offset + 18);
  const expandedSize = archive.readUInt32LE(offset + 22);
  const nameSize = archive.readUInt16LE(offset + 26);
  const extraSize = archive.readUInt16LE(offset + 28);
  assert(!(flags & 8), 'ZIP data descriptors not supported');
  const name = archive.toString('utf8', offset + 30, offset + 30 + nameSize);
  const start = offset + 30 + nameSize + extraSize;
  const compressed = archive.subarray(start, start + size);
  const data = method === 8 ? inflateRawSync(compressed) : method === 0 ? compressed : null;
  assert(data && data.length === expandedSize, `Unexpected member length: ${name}`);
  assert(crc32(data) === archive.readUInt32LE(offset + 14), `ZIP CRC mismatch: ${name}`);
  members.set(name, data);
  offset = start + size;
}
assert(members.size === 2, 'Expected precisely two original 2 KB devices');
const rom = Buffer.alloc(0x1000);
for (const [name, offset] of [['maze.h', 0x0000], ['maze.g', 0x0800]]) {
  const data = members.get(name);
  assert(data?.length === 0x800, `Unexpected ROM size: ${name}`);
  assert(crc32(data) === expected[name].crc, `Original CRC differs: ${name}`);
  assert(createHash('sha1').update(data).digest('hex') === expected[name].sha1, `Original SHA-1 differs: ${name}`);
  data.copy(rom, offset);
}
// 8080 reset, interrupt entry, command engine, script startup, and dispatch.
assertBytes(rom, 0x0000, [0x00, 0x00, 0x31, 0x00, 0x24, 0xc3, 0x17, 0x00], 'reset initializes SP=$2400');
assertBytes(rom, 0x0008, [0xf5, 0xc5, 0xd5, 0xe5, 0xc3, 0x0b, 0x03], 'interrupt saves registers, jumps $030B');
assertBytes(rom, 0x037c, [0x21, 0x64, 0x0d, 0x22, 0x02, 0x20], 'source-script root $0D64');
assertBytes(rom, 0x0392, [0x2a, 0x02, 0x20], 'fetch saved script root');
assertBytes(rom, 0x03aa, [0x2a, 0x00, 0x20, 0x7e, 0xa7], 'read script pointer from RAM $2000');
assertBytes(rom, 0x03b7, [0x21, 0xee, 0x0b], 'vector-table base $0BEE');
assertBytes(rom, 0x03ba, [0x3d, 0xfe, 0x11, 0xd2, 0x77, 0x03], 'one-based opcode and upper bound 17');
assertBytes(rom, 0x03c0, [0x87, 0x4f, 0x06, 0x00, 0x09, 0x7e, 0x23, 0x66, 0x6f, 0xe9], '8080 indexed command lookup');
const nativeTargets = Array.from({length: 17}, (_, n) => rom.readUInt16LE(0x0bee + 2 * n));
assert(nativeTargets.every(x => x < rom.length), 'Out-of-ROM interpreter vector');
const sharedTail = [0x4f, 0x06, 0x00, 0x09, 0x7e, 0x23, 0x66, 0x6f, 0xe9];
assertBytes(rom, 0x03c1, sharedTail, 'nine-byte native vector tail');
// A naked RST $08 byte outside a decoded instruction does not prove TERSE.
// Here the actual $0008 code is an IRQ/service prologue, and command threads
// are 8080 1-byte indexed tokens rather than 16-bit TERSE execution addresses.
console.log('PASS Amazing Maze original ROM runtime scan');
for (const [name, offset] of [['maze.h', 0], ['maze.g', 0x800]])
  console.log(`  ${name}  $${hex(offset)}-$${hex(offset + 0x7ff)}  CRC32 ${hex(expected[name].crc,8)}  SHA1 ${expected[name].sha1}`);
console.log('  Reset SP=$2400; interrupt $0008 -> $030B');
console.log('  Initial script $0D64; script PC RAM $2000; dispatch $0392-$03C9');
console.log('  Indexed 8080 command table: $0BEE-$0C0F, 17 native vectors');
for (const [index, target] of nativeTargets.entries()) console.log(`    command $${hex(index + 1,2)} -> $${hex(target)}`);
console.log('  Shared native lookup tail at $03C1: 4F 06 00 09 7E 23 66 6F E9');
console.log('  Classification: non-TERSE, one-byte indexed 8080 native-handler VM');
