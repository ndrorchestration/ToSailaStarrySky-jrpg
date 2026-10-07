'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'scripts', 'prepare-visual-acceptance-protocol.js'), 'utf8');

for (const required of [
  "git', ['rev-parse', 'HEAD']",
  "git', ['status', '--porcelain']",
  'working tree must be clean',
  'exactly three --decoy files are required',
  'protocol.aetherwakeFrames.length !== 7',
  'protocol.candidate.packageSha256',
  'protocol.candidate.evidenceManifestSha256',
  'protocol.aetherwakeFrameSha256',
  'protocol.presentation.orderSeed',
  'protocol.presentation.order = deterministicOrder',
  'protocol.frozenBeforeFirstSession = true',
  'AETHERWAKE_VISUAL_ACCEPTANCE_PROTOCOL_SHA256'
]) {
  assert(source.includes(required), 'visual acceptance protocol preparer missing control: ' + required);
}

console.log('Aetherwake visual acceptance protocol preparer contract: PASS');
