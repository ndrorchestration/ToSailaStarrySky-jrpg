'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'tests', 'capture-visual-evidence.js'), 'utf8');

for (const id of [
  '00-title-screen',
  '01-first-wake-dock-walk',
  '01c-first-wake-lyra-family',
  '02-dragonfly-dusk-dock',
  '03-dialogue-ionia',
  '04-combat-sky-predator',
  '05-dragonfly-flight',
  '05a-rootline-west-assist',
  '05b-rootline-west-upper-trace',
  '05c-rootline-west-shifted',
  '06-sky-combat-crosswind',
]) {
  assert(source.includes(id), 'visual evidence capture missing scene: ' + id);
}

assert(source.includes('AETHERWAKE_VISUAL_EVIDENCE_V1'),
  'visual evidence manifest contract missing');
assert(source.includes('01c-first-wake-lyra-family'), 'visual evidence must retain Lyra family/interior identity coverage');
assert(source.includes('CAPTURE_ONLY_NOT_VISUAL_PASS'),
  'capture harness must not self-promote screenshots to visual PASS');
assert(source.includes('function resolveSourceBinding()'),
  'visual evidence must resolve a concrete local or CI source binding');
assert(source.includes("execFileSync('git', ['rev-parse', 'HEAD']"),
  'local visual evidence must bind to git HEAD when CI SHA is unavailable');
assert(source.includes('workingTreeClean'),
  'local evidence binding must record working-tree cleanliness');
assert(source.includes("sha256(file)"),
  'visual evidence screenshots must be hashed');
assert(source.includes("viewport: { width: 1440, height: 960 }"),
  'visual evidence viewport must match desktop presentation target');
assert(source.includes("logicalCanvas: { width: 960, height: 640 }"),
  'visual evidence must preserve logical canvas authority');

console.log('Aetherwake visual evidence capture contract: PASS');
