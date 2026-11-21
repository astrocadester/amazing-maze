import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const source = readFileSync(new URL('../src/maze.asm', import.meta.url), 'utf8');
const section = (start, end) => {
  const from = source.indexOf('\n' + start + ':');
  const to = source.indexOf('\n' + end + ':', from + 1);
  assert.ok(from >= 0 && to > from, 'missing original label boundary ' + start + ' / ' + end);
  return source.slice(from, to).replace(/;[^\n]*/g, '');
};

test('AM-RE-004: original maze grid is 26 rows x 24 columns', () => {
  const clear = section('CLEAR_MAZE_CELL_LOW_NIBBLES', 'MAZE_FIELD_EXTRA_RET_BYTE');
  assert.match(clear, /LD DE,\$2066/);
  assert.match(clear, /LD B,\$1A/);
  assert.match(clear, /LD C,\$18/);
  assert.match(clear, /AND \$F0/);
  assert.equal(0x1a * 0x18, 624);
  assert.equal(0x2066 + 624 - 1, 0x22d5);
});

test('AM-RE-004: BC=$0370 is a pair of nested byte counters, NOT an 880-byte transfer', () => {
  const shift = section('SHIFT_MAZE_CELLS_LEFT_FOUR', 'UPDATE_MAZE_STATE_IF_IDLE');
  assert.match(shift, /LD BC,\$0370/);
  assert.match(shift, /SHIFT_NEXT_MAZE_CELL_NIBBLE:[\s\S]*DEC C\s+JP NZ,SHIFT_NEXT_MAZE_CELL_NIBBLE\s+DEC B\s+JP NZ,SHIFT_NEXT_MAZE_CELL_NIBBLE/);
  let b = 3, c = 0x70, steps = 0;
  do {
    do { c = (c - 1) & 255; steps++; } while (c !== 0);
    b = (b - 1) & 255;
  } while (b !== 0);
  assert.equal(steps, 624);
});

test('AM-RE-004: command zero conditionally enters the original generator', () => {
  assert.match(section('ZERO_COMMAND', 'ZERO_COMMAND_ENTRY_GAP'), /LD A,\(\$201F\)\s+AND A\s+CALL Z,ZERO_COMMAND_EVENT/);
  assert.match(section('ZERO_COMMAND_EVENT', 'RUN_ZERO_COMMAND_MAZE_EVENTS'), /CALL CLEAR_MAZE_CELL_LOW_NIBBLES[\s\S]*LD \(\$201C\),A[\s\S]*CALL MAZE_RECALCULATE_RANDOM_STATE[\s\S]*CALL SELECT_MAZE_RANDOM_VALUE/);
});

test('AM-RE-004: random state and initial maze column use original RAM and mask', () => {
  const random = section('READ_GAME_RANDOM_STATE', 'MAZE_CELL_ADDRESS');
  assert.match(random, /LD HL,\$2004/);
  assert.match(random, /LD B,\$08/);
  const seed = section('SELECT_MAZE_RANDOM_VALUE', 'MAZE_INSPECT_NEIGHBOR_WALLS');
  assert.match(seed, /LD E,\$18/);
  assert.match(seed, /LD \(\$2025\),A/);
  assert.match(seed, /LD \(\$2040\),A/);
  assert.match(seed, /OR \$09/);
});

test('AM-RE-004: maze generator tests each neighbor and counts four direction bits', () => {
  const inspect = section('MAZE_INSPECT_NEIGHBOR_WALLS', 'ADVANCE_MAZE_GENERATION_COUNT');
  for (const bit of ['01', '02', '04', '08'])
    assert.match(inspect, new RegExp('OR \\$' + bit + '\\b'));
  assert.match(inspect, /COUNT_OPEN_DIRECTIONS_LOOP:[\s\S]*RRA[\s\S]*INC E/);
});

test('AM-RE-004: native collision checks use wall bits 20/40', () => {
  const move = section('UPDATE_MAZE_MOVEMENT', 'CMD_02_SET_MODE_0E');
  for (const name of ['CHECK_MAZE_LEFT_BOUNDARY', 'CHECK_MAZE_UP_BOUNDARY', 'CHECK_MAZE_RIGHT_BOUNDARY', 'CHECK_MAZE_DOWN_BOUNDARY'])
    assert.ok(move.includes(name + ':'), name);
  assert.match(move, /AND \$20/);
  assert.match(move, /AND \$40/);
  assert.match(move, /STORE_MAZE_POSITION_AND_WALL_STATE:[\s\S]*LD \(HL\),C[\s\S]*LD \(HL\),B/);
});

test('AM-RE-004: original score uses decimal adjust and carry into next packed byte', () => {
  const score = section('INCREMENT_PACKED_SCORE', 'NORMALIZE_DISPLAY_GLYPH_SPACE');
  assert.match(score, /LD HL,\$2019\s+LD A,\(HL\)\s+INC A\s+DAA\s+LD \(HL\),A/);
  assert.match(score, /CP \$60[\s\S]*LD \(HL\),\$00\s+DEC HL\s+LD A,\(HL\)\s+INC A\s+DAA/);
  const round = section('UPDATE_ROUND_COUNTER_AND_SCORE', 'DISPLAY_SCORE_AND_INCREMENT');
  assert.match(round, /LD A,\(\$202C\)[\s\S]*LD HL,\$202B[\s\S]*ADD A,\$99\s+DAA/);
});

test('AM-RE-004: neither test nor tracer supplies replacement gameplay or ROM bytes', () => {
  const trace = readFileSync(new URL('../tools/am-re-004-trace.cmd', import.meta.url), 'utf8');
  assert.match(trace, /bp 03d4/);
  assert.match(trace, /bp 0a32/);
  assert.match(trace, /bp 0554/);
  assert.doesNotMatch(trace, /\b(?:b@(?:[a-f0-9]+)\s*=|do\s+(?:pc|a|b|c|d|e|hl|sp)\s*=)/i);
});
