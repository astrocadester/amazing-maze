#!/usr/bin/env node
// Summarize actual MAME debugger evidence. Does not generate gameplay or alter ROM.
// Usage: node tools/analyze-am-re-004-trace.mjs error.log
import { readFileSync } from 'node:fs';

const filename = process.argv[2] ?? 'error.log';
let data;
try { data = readFileSync(filename, 'utf8'); }
catch (error) { console.error('Cannot read trace:', error.message); process.exit(2); }

const names = [
  'GEN_BEGIN', 'SEED_COLUMN', 'GEN_CELL', 'GEN_CHOOSE',
  'GEN_WRITE', 'GEN_FINISH_TEST', 'SHIFT_624',
  'MOVE_BEGIN', 'MOVE_LEFT', 'MOVE_UP', 'MOVE_RIGHT', 'MOVE_DOWN',
  'MOVE_COMMIT', 'SCORE_ENTRY', 'SCORE_INC', 'ROUND', 'END_STATE',
];
const counts = Object.fromEntries(names.map(name => [name, 0]));
const samples = Object.fromEntries(names.map(name => [name, []]));
// MAME logerror can concatenate events without physical newlines.
const raw = data.split(/(?=AM004\s+[A-Z0-9_]+\b)/).filter(segment => segment.startsWith('AM004 '));
for (const event of raw) {
  const m = event.match(/^AM004\s+([A-Z0-9_]+)\b/);
  if (!m || !Object.hasOwn(counts, m[1])) continue;
  counts[m[1]]++;
  if (samples[m[1]].length < 4) samples[m[1]].push(event.trim().split(/\r?\n/)[0]);
}

console.log('AM-RE-004 MAME native execution evidence: ' + filename);
console.log('Observed tagged debugger events: ' + raw.length);
for (const name of names)
  console.log(name.padEnd(17) + String(counts[name]).padStart(7));

console.log('\nEvidence gates (observed, not inferred):');
for (const [label, keys] of [
  ['Generator invocation', ['GEN_BEGIN']],
  ['Randomized starting column', ['SEED_COLUMN']],
  ['Candidate/selection/write path', ['GEN_CELL','GEN_CHOOSE','GEN_WRITE']],
  ['Generator completion check', ['GEN_FINISH_TEST']],
  ['Original 624-cell shift entry', ['SHIFT_624']],
  ['Player movement check', ['MOVE_BEGIN']],
  ['Boundary/collision processing', ['MOVE_LEFT','MOVE_UP','MOVE_RIGHT','MOVE_DOWN']],
  ['Movement commit', ['MOVE_COMMIT']],
  ['Score update', ['SCORE_INC']],
  ['Round update', ['ROUND']],
]) {
  const ok = keys.every(key => counts[key] > 0);
  console.log((ok ? 'OBSERVED ' : 'NOT SEEN ').padEnd(10) + label);
}

const scores = raw.filter(event => event.startsWith('AM004 SCORE_ENTRY '))
  .map(event => event.match(/\bpacked=([0-9A-F]{4})\b/))
  .filter(Boolean).map(match => match[1]);
if (scores.length) console.log('\nObserved score-entry packed values: ' + scores.join(', '));

console.log('\nRepresentative original events:');
for (const name of names) if (samples[name].length)
  console.log(samples[name][0]);
console.log('\nNOTE: A breakpoint hit proves execution of that source address. It does not by itself prove correct gameplay outcomes.');
