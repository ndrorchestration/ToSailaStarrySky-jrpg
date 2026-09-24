'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'tests', 'capture-visual-evidence.js'), 'utf8');

for (const id of [
  '00-title-screen',
  '01-first-wake-dock-walk',
  '02-dragonfly-dusk-dock',
  '03-dialogue-ionia',
  '04-combat-sky-predator',
  '05-dragonfly-flight',
  '06-sky-combat-crosswind',
]) {
  assert(source.includes(id), 'visual evidence capture missing scene: ' + id);
}

assert(source.includes('AETHERWAKE_VISUAL_EVIDENCE_V1'),
  'visual evidence manifest contract missing');
assert(source.includes('CAPTURE_ONLY_NOT_VISUAL_PASS'),
  'capture harness must not self-promote screenshots to visual PASS');
assert(source.includes("sourceSha: process.env.AETHERWAKE_SOURCE_SHA || process.env.GITHUB_SHA || 'LOCAL_UNBOUND'"),
  'visual evidence must prefer the exact PR-head SHA over the synthetic merge SHA');
assert(source.includes("sha256(file)"),
  'visual evidence screenshots must be hashed');
assert(source.includes("viewport: { width: 1440, height: 960 }"),
  'visual evidence viewport must match desktop presentation target');
assert(source.includes("logicalCanvas: { width: 960, height: 640 }"),
  'visual evidence must preserve logical canvas authority');

console.log('Aetherwake visual evidence capture contract: PASS');
