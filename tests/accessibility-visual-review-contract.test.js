'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const matrix = fs.readFileSync(
  path.join(repo, 'tests', 'accessibility-visual-matrix-playwright.js'),
  'utf8'
);
const validator = fs.readFileSync(
  path.join(repo, 'scripts', 'validate-m0-accessibility-review.js'),
  'utf8'
);
const template = JSON.parse(fs.readFileSync(
  path.join(repo, 'docs', 'm0-accessibility-visual-review.template.json'),
  'utf8'
));

assert(matrix.includes('schemaVersion: 2'),
  'visual matrix manifest must use provenance schema v2');
assert(matrix.includes("git', ['rev-parse', 'HEAD']"),
  'visual matrix must bind exact Git HEAD');
assert(matrix.includes("crypto.createHash('sha256')"),
  'visual matrix must fingerprint screenshots');
assert(matrix.includes('bytes: bytes.length'),
  'visual matrix must record screenshot byte counts');

assert(validator.includes('record.candidate.commitSha, manifest.gitHead'),
  'review validator must bind review to exact source commit');
assert(validator.includes('record.candidate.visualManifestSha256, manifestSha256'),
  'review validator must bind review to exact manifest bytes');
assert(validator.includes('Reviewed visual capture hash drifted'),
  'review validator must detect capture replacement/regeneration');
assert(validator.includes("record.result, 'PASS'"),
  'review validator must require explicit human PASS');
assert(validator.includes('record.defects.length, 0'),
  'review validator must reject PASS with blocking defects');

assert.strictEqual(template.result, 'NOT_RUN',
  'review template must remain fail-closed before human review');
assert.strictEqual(template.candidate.captureCount, 58,
  'review template must bind expected matrix cardinality');

console.log('Aetherwake accessibility visual-review evidence contract: PASS');
