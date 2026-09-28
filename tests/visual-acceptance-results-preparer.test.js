'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'scripts', 'prepare-visual-acceptance-results.js'), 'utf8');

for (const required of [
  'visual-acceptance-protocol.json',
  'visual-acceptance-template.json',
  'visual-acceptance-results.json',
  'AETHERWAKE_VISUAL_ACCEPTANCE_PROTOCOL_V1',
  'protocol.frozenBeforeFirstSession !== true',
  'protocol.aetherwakeFrames.length !== 7',
  'protocol.decoys.length !== 3',
  'packageSha256',
  'evidenceManifestSha256',
  'protocolSha256',
  'AETHERWAKE_VISUAL_ACCEPTANCE_RESULTS=PREPARED'
]) {
  assert(source.includes(required), 'visual acceptance results preparer missing control: ' + required);
}

assert(source.includes('VISUAL_RESULTS_PREP_FAIL'),
  'results preparer must fail closed with an explicit error family');

console.log('Aetherwake visual acceptance results preparer contract: PASS');
