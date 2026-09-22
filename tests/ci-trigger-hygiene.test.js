'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const smoke = fs.readFileSync(path.join(root, '.github', 'workflows', 'smoke.yml'), 'utf8');
const desktop = fs.readFileSync(path.join(root, '.github', 'workflows', 'desktop-package.yml'), 'utf8');

for (const ignored of ["'docs/**'", "'**/*.md'", "'.github/ISSUE_TEMPLATE/**'"]) {
  assert(smoke.includes(ignored), 'smoke workflow must ignore documentation-only change: ' + ignored);
}
assert(smoke.includes('pull_request:\n    paths-ignore:'),
  'pull-request smoke must skip documentation-only changes');
assert(smoke.includes('npm run test:ci-trigger-hygiene'),
  'smoke workflow must self-check trigger hygiene');

for (const requiredPath of [
  "'aetherwake.js'",
  "'index-embedded.html'",
  "'modules/**'",
  "'assets/**'",
  "'package.json'",
  "'package-lock.json'",
  "'scripts/stage-memories-desktop.js'",
  "'scripts/build-windows-release.ps1'",
  "'tests/desktop-package-contract.test.js'",
  "'.github/workflows/desktop-package.yml'",
]) {
  assert(desktop.includes(requiredPath),
    'Windows packaging trigger missing release-relevant path: ' + requiredPath);
}
assert(desktop.includes('workflow_dispatch:'),
  'Windows packaging must remain manually dispatchable');
assert(desktop.includes('tags:\n      - "v*"'),
  'Windows packaging must preserve release-tag triggering');

console.log('Aetherwake CI trigger hygiene contract: PASS');
