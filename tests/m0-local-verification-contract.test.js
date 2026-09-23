'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const script = fs.readFileSync(
  path.join(repo, 'scripts', 'verify-m0-local.ps1'),
  'utf8'
);
const doc = fs.readFileSync(
  path.join(repo, 'docs', 'M0_LOCAL_VERIFICATION.md'),
  'utf8'
);

for (const gate of [
  'test:save-system',
  'test:save-runtime',
  'test:save-payload',
  'test:save-interrupted-write',
  'test:persistence-coverage',
  'test:first-wake-benchmark',
  'test:input-runtime',
  'test:input-accessibility',
  'test:accessibility-rendering',
  'test:audio-assets',
  'test:title-audio-admission',
  'test:title-audio-runtime',
  'test:world-authority',
  'test:smoke',
  'test:first-wake-benchmark-live',
  'test:controller-parity-live',
  'test:accessibility-visual-matrix'
]) {
  assert(script.includes(gate), 'M0 local verifier missing gate: ' + gate);
}

assert(script.includes('captureCount -ne 54'),
  'M0 local verifier must require the 54-frame matrix');
assert(script.includes("reviewStatus -ne 'HUMAN_REVIEW_REQUIRED'"),
  'M0 local verifier must preserve human visual review');
assert(script.includes('build-windows-release.ps1'),
  'M0 local verifier must invoke exact Windows package verification by default');
assert(script.includes('summary.json'),
  'M0 local verifier must emit a machine-readable summary');
assert(script.includes('requires a clean working tree'),
  'M0 local verifier must fail closed on uncommitted working-tree changes');
assert(script.includes('requires readable Git HEAD provenance'),
  'M0 local verifier must fail closed when exact Git HEAD provenance is unavailable');
assert(doc.includes('clean working tree'),
  'documentation must require a clean working tree for exact-head claims');
assert(doc.includes('not the same as final M0 acceptance'),
  'documentation must not overclaim local script success');
assert(doc.includes('admit:title-audio'),
  'documentation must route title audio through governed admission');

console.log('Aetherwake M0 local verification orchestrator: PASS');
