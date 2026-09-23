'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const validator = fs.readFileSync(
  path.join(repo, 'scripts', 'validate-m0-external-playtest.js'),
  'utf8'
);
const protocol = fs.readFileSync(
  path.join(repo, 'docs', 'M0_EXTERNAL_PLAYTEST.md'),
  'utf8'
);
const template = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'm0-external-playtest-record.template.json'),
  'utf8'
));

assert(validator.includes('release.source.gitHead'),
  'external playtest validator must bind exact release source commit');
assert(validator.includes('releaseEvidenceSha256'),
  'external playtest validator must bind exact release evidence bytes');
assert(validator.includes('release.artifacts.installer.sha256'),
  'external playtest validator must bind installer hash');
assert(validator.includes('playerVerifiedStandalone, true'),
  'external playtest validator must require standalone verification');
assert(validator.includes('persistenceVerification') &&
       validator.includes('desktopSaveRestart') &&
       validator.includes('desktopSaveBackupOnlyRecovery'),
  'external playtest validator must require installed persistence/recovery proof');
assert(validator.includes('record.interventions.length, 0'),
  'external playtest validator must reject coached/intervened PASS');
assert(validator.includes('combatDecisionReasoning.length > 0'),
  'external playtest validator must require observed combat reasoning');
assert(validator.includes("record.result, 'PASS'"),
  'external playtest validator must require explicit PASS');

assert(protocol.includes('do not explain objectives, controls, combat strategy'),
  'external playtest protocol must preserve no-coaching boundary');
assert.strictEqual(template.result, 'NOT_RUN',
  'external playtest template must fail closed');
assert.strictEqual(template.candidate.playerVerifiedStandalone, false,
  'external playtest template must not preclaim standalone verification');
assert.strictEqual(template.candidate.releaseEvidencePath, 'RELEASE_EVIDENCE.json',
  'external playtest template must reference release provenance evidence');

console.log('Aetherwake external playtest evidence contract: PASS');
