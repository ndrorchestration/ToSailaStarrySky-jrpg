'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const workflowPath = path.join(root, '.github', 'workflows', 'preview-windows.yml');
const workflow = fs.readFileSync(workflowPath, 'utf8');
const builder = fs.readFileSync(path.join(root, 'scripts', 'build-preview-windows.ps1'), 'utf8');

assert(/^\s+pull_request:/m.test(workflow),
  'Preview Windows build must run for pull requests');
assert(/^\s+runs-on:\s*windows-2022\s*$/m.test(workflow),
  'Preview Windows build must execute on Windows');
assert(workflow.includes('github.event.pull_request.head.sha'),
  'Preview Windows build must check out the exact PR head');
assert(workflow.includes('git rev-parse HEAD'),
  'Preview Windows build must verify the checked-out source SHA');
assert(workflow.includes('npm run build:preview:windows'),
  'Preview Windows build must call the existing bounded builder');
assert(builder.includes('npm run test:preview-slice'),
  'Preview Windows build must gate the encounter outcome and authored route regressions');
assert(builder.includes('npm run test:preview-world-presentation'),
  'Preview Windows build must test the tile map and character atlas');
assert(builder.includes('npm run test:combat-visual'),
  'Preview Windows build must test the Sky Predator battle presentation');
assert(workflow.includes('aetherwake-preview-ready.json') &&
  workflow.includes('first-frame-readiness.json'),
  'Preview artifact must retain first-frame readiness evidence');
assert(workflow.includes('SOURCE_SHA.txt'),
  'Preview artifact must record the exact source SHA');
assert(workflow.includes('Aetherwake-Preview-0.1-Windows.zip') &&
  workflow.includes('SHA256SUMS.txt'),
  'Preview artifact must include the ZIP and checksum manifest');
assert(workflow.includes('actions/upload-artifact@v4') &&
  workflow.includes('if-no-files-found: error'),
  'Preview ZIP and evidence must be uploaded as a required workflow artifact');
assert(!workflow.includes('Install NSIS') && !workflow.includes('action-gh-release'),
  'Preview Windows build must stay outside the installer and publication gates');

console.log('Aetherwake Preview Windows CI contract: PASS');
