'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const script = fs.readFileSync(
  path.join(repo, 'scripts', 'write-release-evidence.js'),
  'utf8'
);
const localRelease = fs.readFileSync(
  path.join(repo, 'scripts', 'build-windows-release.ps1'),
  'utf8'
);
const workflow = fs.readFileSync(
  path.join(repo, '.github', 'workflows', 'desktop-package.yml'),
  'utf8'
);
const packageJson = require('../package.json');

assert(script.includes("git', ['rev-parse', 'HEAD']"),
  'release evidence must bind exact Git HEAD');
assert(script.includes("['diff', '--quiet', 'HEAD', '--']") &&
       script.includes("['diff', '--cached', '--quiet', '--']"),
  'release evidence must reject tracked or staged source mutation while allowing generated artifacts');
assert(script.includes("repositoryStatus === 'admitted'") &&
       script.includes('runtimeRegistration === true'),
  'release evidence must require admitted governed title audio');
assert(script.includes('title.sourceVerification.bytes') &&
       script.includes('title.sourceVerification.sha256'),
  'release evidence must bind governed title-audio fingerprint');
assert(script.includes('sha256(installer)') &&
       script.includes('sha256(portableZip)'),
  'release evidence must fingerprint both release artifacts');
assert(script.includes("trackedSource: 'unchanged-from-head'"),
  'release evidence must record that tracked source remained unchanged from HEAD');
assert(script.includes('AETHERWAKE_RELEASE_DESKTOP_SAVE_RESTART') &&
       script.includes('AETHERWAKE_RELEASE_DESKTOP_SAVE_BACKUP_ONLY_RECOVERY'),
  'release evidence must require explicit persistence verification inputs');
assert(script.includes('persistenceVerification') &&
       script.includes('desktopSaveRestart') &&
       script.includes('desktopSaveBackupOnlyRecovery'),
  'release evidence must record restart and backup-only recovery proof');

assert.strictEqual(
  packageJson.scripts['write:release-evidence'],
  'node scripts/write-release-evidence.js',
  'release evidence writer must have a stable package command'
);

assert(localRelease.includes('SOURCE_COMMIT=$gitHead'),
  'local release must expose exact source commit');
assert(localRelease.includes('RELEASE_EVIDENCE.json') &&
       localRelease.includes('npm run write:release-evidence'),
  'local release must generate machine-readable release evidence');
assert(localRelease.includes("$env:AETHERWAKE_RELEASE_DESKTOP_SAVE_RESTART = 'PASS'") &&
       localRelease.includes("$env:AETHERWAKE_RELEASE_DESKTOP_SAVE_BACKUP_ONLY_RECOVERY = 'PASS'"),
  'local release must export verified persistence results before provenance generation');
assert(workflow.includes('Verify clean source checkout') &&
       workflow.includes('Release source checkout is not clean'),
  'hosted release must verify a clean source checkout before build');
assert(workflow.includes('Write release provenance evidence') &&
       workflow.includes('npm run write:release-evidence'),
  'hosted Windows release must generate release evidence');
assert(workflow.includes('AETHERWAKE_RELEASE_DESKTOP_SAVE_RESTART=PASS') &&
       workflow.includes('AETHERWAKE_RELEASE_DESKTOP_SAVE_BACKUP_ONLY_RECOVERY=PASS'),
  'hosted Windows release must carry persistence verification into release evidence');
assert(workflow.includes('RELEASE_EVIDENCE.json'),
  'hosted release publication must include release evidence');
assert(
  workflow.indexOf('Write release provenance evidence') <
  workflow.indexOf('Publish verified Windows release'),
  'release evidence must be generated before publication'
);

console.log('Aetherwake release evidence contract: PASS');
