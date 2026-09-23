'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const source = fs.readFileSync(
  path.join(repo, 'scripts', 'validate-m0-acceptance.js'),
  'utf8'
);

assert.doesNotThrow(() => new Function(source),
  'final M0 acceptance validator must parse as JavaScript');

for (const required of [
  'PASS_WITH_MANUAL_ACCEPTANCE_PENDING',
  'summary.evidenceBindings.visualManifestSha256',
  'summary.evidenceBindings.releaseEvidenceSha256',
  'summary.evidenceBindings.installerSha256',
  'summary.evidenceBindings.portableZipSha256',
  'validate-m0-accessibility-review.js',
  'validate-m0-external-playtest.js',
  "accessibilityReview.result, 'PASS'",
  "externalPlaytest.result, 'PASS'",
  "status: 'PASS'",
  'M0_ACCEPTANCE.json'
]) {
  assert(source.includes(required),
    'final M0 acceptance validator missing contract element: ' + required);
}

assert(source.includes('visualManifest.gitHead, commitSha'),
  'final acceptance must bind visual evidence to exact candidate');
assert(source.includes('releaseEvidence.source.gitHead, commitSha'),
  'final acceptance must bind release evidence to exact candidate');
assert(source.includes('externalPlaytest.candidate.commitSha, commitSha'),
  'final acceptance must bind external-player evidence to exact candidate');
assert(source.includes('accessibilityReview.candidate.commitSha, commitSha'),
  'final acceptance must bind human visual review to exact candidate');
assert(source.includes("git', ['rev-parse', 'HEAD']"),
  'final acceptance must bind current checkout HEAD');
assert(source.includes("git', ['diff', '--quiet', 'HEAD', '--']"),
  'final acceptance must reject tracked source drift');
assert(source.includes("git', ['diff', '--cached', '--quiet', '--']"),
  'final acceptance must reject staged source drift');
assert(source.includes('Final M0 acceptance must run from the exact candidate checkout'),
  'final acceptance must reject stale-candidate checkout use');
assert(source.includes('technicalSummarySha256'),
  'final acceptance must fingerprint technical evidence');
assert(source.includes('accessibilityReviewSha256'),
  'final acceptance must fingerprint human visual-review evidence');
assert(source.includes('externalPlaytestSha256'),
  'final acceptance must fingerprint human player evidence');
assert(source.includes('releaseEvidenceSha256'),
  'final acceptance must fingerprint release evidence');
assert(source.includes('installer') && source.includes('portableZip'),
  'final acceptance must bind player artifact identities');

console.log('Aetherwake final M0 acceptance contract: PASS');
