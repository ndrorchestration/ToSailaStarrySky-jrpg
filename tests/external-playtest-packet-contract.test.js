'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const generator = fs.readFileSync(
  path.join(repo, 'scripts', 'prepare-m0-external-playtest.js'),
  'utf8'
);
const local = fs.readFileSync(
  path.join(repo, 'scripts', 'verify-m0-local.ps1'),
  'utf8'
);
const packageJson = require('../package.json');

assert.strictEqual(
  packageJson.scripts['prepare:external-playtest'],
  'node scripts/prepare-m0-external-playtest.js',
  'external playtest packet generator must have a stable command'
);
assert(generator.includes('release.source.gitHead'),
  'external playtest packet must bind release source commit');
assert(generator.includes('release.artifacts.installer.sha256'),
  'external playtest packet must bind installer hash');
assert(generator.includes('releaseEvidenceSha256'),
  'external playtest packet must bind exact release-evidence bytes');
assert(generator.includes('currentHead') &&
       generator.includes('Release evidence source commit does not match current checkout HEAD'),
  'external playtest packet must reject release evidence from another checkout head');
assert(generator.includes('record.candidate.playerVerifiedStandalone = false'),
  'packet generation must not preclaim participant standalone verification');
assert(generator.includes("record.result = 'NOT_RUN'"),
  'packet generation must remain fail-closed before the human session');
assert(generator.includes('Do not coach the participant.'),
  'observer guide must preserve the no-coaching boundary');

assert(local.includes("Invoke-Gate 'prepare:external-playtest' 'npm run prepare:external-playtest'"),
  'local M0 must prepare the playtest packet only after Windows verification');
assert(
  local.indexOf("Windows release verification failed") <
  local.indexOf("prepare:external-playtest"),
  'external playtest preparation must occur after successful Windows verification'
);
assert(local.includes("status = 'PREPARED_NOT_RUN'"),
  'local M0 summary must report prepared playtest as not run');
assert(local.includes('EXTERNAL_PLAYTEST_GUIDE=') &&
       local.includes('EXTERNAL_PLAYTEST_RECORD='),
  'local M0 must expose exact playtest packet paths');

console.log('Aetherwake external playtest packet contract: PASS');
