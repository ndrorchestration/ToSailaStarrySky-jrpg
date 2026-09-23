'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const generator = fs.readFileSync(
  path.join(repo, 'scripts', 'prepare-m0-accessibility-review.js'),
  'utf8'
);
const local = fs.readFileSync(
  path.join(repo, 'scripts', 'verify-m0-local.ps1'),
  'utf8'
);
const smoke = fs.readFileSync(
  path.join(repo, '.github', 'workflows', 'smoke.yml'),
  'utf8'
);
const packageJson = require('../package.json');

assert.strictEqual(
  packageJson.scripts['prepare:accessibility-review'],
  'node scripts/prepare-m0-accessibility-review.js',
  'accessibility review packet generator must have a stable command'
);
assert(generator.includes('manifest.schemaVersion, 2'),
  'review packet must require provenance manifest schema v2');
assert(generator.includes('manifest.captureCount, 58'),
  'review packet must require exactly 58 captures');
assert(generator.includes('Visual capture hash drifted'),
  'review packet must verify every capture hash');
assert(generator.includes('record.candidate.commitSha = manifest.gitHead'),
  'review record must bind exact source commit');
assert(generator.includes('record.candidate.visualManifestSha256 = manifestSha256'),
  'review record must bind exact manifest bytes');
assert(generator.includes("record.result = 'NOT_RUN'"),
  'generated review record must remain fail-closed before human review');
assert(generator.includes('Human review required.'),
  'review HTML must state that human review is required');
assert(generator.includes('does not pre-approve any criterion'),
  'review HTML must not imply automated acceptance');

assert(local.includes("Invoke-Gate 'prepare:accessibility-review' 'npm run prepare:accessibility-review'"),
  'local M0 lane must generate the review packet after capture');
assert(local.includes('ACCESSIBILITY_REVIEW_HTML=') &&
       local.includes('ACCESSIBILITY_REVIEW_RECORD='),
  'local M0 lane must expose review packet paths');
assert(smoke.includes('Prepare accessibility human-review packet') &&
       smoke.includes('npm run prepare:accessibility-review'),
  'hosted smoke must include the deterministic review packet in uploaded artifacts');

console.log('Aetherwake accessibility review packet contract: PASS');
