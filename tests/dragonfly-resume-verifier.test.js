'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const scriptPath = path.join(root, 'scripts', 'verify-visual-v46-dragonfly.ps1');
const source = fs.readFileSync(scriptPath, 'utf8');

for (const required of [
  'git rev-parse HEAD',
  'git status --porcelain',
  'tests/dragonfly-visual-authority.test.js',
  'tests/flight-visual-gate.test.js',
  'tests/title-visual-stage.test.js',
  'tests/first-wake-visual-stage.test.js',
  'npm run test:chapter1-visual',
  'npm run test:chapter1-browser',
  'npm run capture:visual-evidence',
  'npm run verify:visual-performance',
  'git diff --check',
  'Get-FileHash -Algorithm SHA256',
  'AETHERWAKE_DRAGONFLY_RENDER_REVIEW=PENDING_HUMAN',
  'AETHERWAKE_DRAGONFLY_VERIFY=PASS'
]) {
  assert(source.includes(required), 'Dragonfly resume verifier missing required gate: ' + required);
}

assert(source.includes("Working tree is not clean"),
  'exact-head verifier must reject a dirty worktree');
assert(source.includes("^[0-9a-f]{40}$"),
  'exact-head verifier must require a full 40-character Git SHA');

console.log('Aetherwake Dragonfly exact-head resume verifier contract: PASS');
