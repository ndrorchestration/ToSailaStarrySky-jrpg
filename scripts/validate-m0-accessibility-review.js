'use strict';

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
function arg(name) {
  const i = args.indexOf(name);
  assert(i >= 0 && args[i + 1], 'Missing required argument: ' + name);
  return path.resolve(args[i + 1]);
}

const recordPath = arg('--record');
const matrixDir = arg('--matrix-dir');
const manifestPath = path.join(matrixDir, 'manifest.json');

assert(fs.existsSync(recordPath), 'Accessibility review record missing');
assert(fs.existsSync(manifestPath), 'Accessibility visual manifest missing');

const record = JSON.parse(fs.readFileSync(recordPath, 'utf8'));
const manifestBytes = fs.readFileSync(manifestPath);
const manifest = JSON.parse(manifestBytes.toString('utf8'));
const manifestSha256 = crypto.createHash('sha256').update(manifestBytes).digest('hex');

assert.strictEqual(manifest.schemaVersion, 2,
  'Accessibility visual manifest must use provenance schema v2');
assert(typeof manifest.gitHead === 'string' && /^[0-9a-f]{40}$/.test(manifest.gitHead),
  'Accessibility visual manifest must bind exact Git HEAD');
assert.strictEqual(manifest.captureCount, 58,
  'Accessibility visual manifest must contain exactly 58 captures');
assert(Array.isArray(manifest.captures) && manifest.captures.length === 58,
  'Accessibility visual manifest capture list must contain 58 records');

for (const capture of manifest.captures) {
  assert(capture && typeof capture.file === 'string' && capture.file.length > 0,
    'Visual capture record missing file');
  assert(Number.isInteger(capture.bytes) && capture.bytes > 0,
    'Visual capture record missing byte size: ' + capture.file);
  assert(typeof capture.sha256 === 'string' && /^[0-9a-f]{64}$/.test(capture.sha256),
    'Visual capture record missing SHA-256: ' + capture.file);

  const file = path.join(matrixDir, capture.file);
  assert(fs.existsSync(file), 'Reviewed visual capture missing: ' + capture.file);
  const bytes = fs.readFileSync(file);
  assert.strictEqual(bytes.length, capture.bytes,
    'Reviewed visual capture byte count drifted: ' + capture.file);
  assert.strictEqual(
    crypto.createHash('sha256').update(bytes).digest('hex'),
    capture.sha256,
    'Reviewed visual capture hash drifted: ' + capture.file
  );
}

assert(record.candidate, 'Review record candidate binding missing');
assert.strictEqual(record.candidate.commitSha, manifest.gitHead,
  'Review record commit does not match visual manifest Git HEAD');
assert.strictEqual(record.candidate.visualManifestSha256, manifestSha256,
  'Review record manifest hash does not match reviewed manifest');
assert.strictEqual(record.candidate.captureCount, manifest.captureCount,
  'Review record capture count does not match manifest');

assert(record.reviewer && typeof record.reviewer.id === 'string' && record.reviewer.id.trim(),
  'Human reviewer identity/label is required');
assert(record.reviewer.reviewedAt,
  'Human review timestamp is required');

for (const [key, value] of Object.entries(record.coverage || {})) {
  assert.strictEqual(value, true, 'Review coverage incomplete: ' + key);
}
assert(Object.keys(record.coverage || {}).length >= 4,
  'Review coverage declaration is incomplete');

for (const [key, value] of Object.entries(record.criteria || {})) {
  assert.strictEqual(value, true, 'Accessibility review criterion did not pass: ' + key);
}
assert(Object.keys(record.criteria || {}).length >= 9,
  'Accessibility review criteria declaration is incomplete');

assert(Array.isArray(record.defects), 'Review defects must be an array');
assert.strictEqual(record.defects.length, 0,
  'A PASS review cannot retain blocking defects');
assert.strictEqual(record.result, 'PASS',
  'Accessibility review evidence is not PASS');

console.log(JSON.stringify({
  status: 'PASS',
  commitSha: manifest.gitHead,
  manifestSha256,
  captureCount: manifest.captureCount,
  reviewer: record.reviewer.id,
  reviewedAt: record.reviewer.reviewedAt
}));
