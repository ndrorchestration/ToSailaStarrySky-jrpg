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
assert(smoke.includes('pull_request:\n'),
  'pull-request smoke trigger must remain present');
assert(!smoke.includes('pull_request:\n    paths-ignore:'),
  'pull-request smoke must remain unconditional while required-check protection is unknown');
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


assert(desktop.includes('pull_request:\n'),
  'Windows packaging must run a read-only contract lane on relevant pull requests');
assert(desktop.includes('verify-package-contract:') &&
       desktop.includes("if: github.event_name == 'pull_request'"),
  'desktop PR workflow must isolate the packaging-contract verification job');
assert(desktop.includes('runs-on: ubuntu-24.04'),
  'desktop PR package-contract verification must use the pinned Ubuntu runner family');
assert(desktop.includes('actions/checkout@11d5960a326750d5838078e36cf38b85af677262'),
  'desktop workflow checkout action must remain immutable-pinned');
assert(desktop.includes('actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020'),
  'desktop workflow setup-node action must remain immutable-pinned');
assert(desktop.includes('softprops/action-gh-release@3bb12739c298aeb8a4eeaf626c5b8d85266b0e65'),
  'desktop release action must remain immutable-pinned');
assert(/permissions:\s*\n\s+contents: read/.test(desktop),
  'desktop workflow default permission must remain contents:read');
assert(/verify-windows:[\s\S]*?if: github\.event_name != 'pull_request'[\s\S]*?permissions:\s*\n\s+contents: write/.test(desktop),
  'release-only Windows job must own the contents:write escalation');
assert(desktop.includes('npm run test:desktop-package') &&
       desktop.includes('npm run test:ci-trigger-hygiene'),
  'desktop PR job must execute package and trigger-hygiene contracts');
