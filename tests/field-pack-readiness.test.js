'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const root = path.resolve(__dirname, '..');
const script = path.join(root, 'scripts', 'verify-field-pack-readiness.js');
const source = fs.readFileSync(script, 'utf8');

assert(source.includes("['ender', 'ionia']"), 'default admission targets must remain Ender + Ionia');
assert(source.includes('FIELD_CELL') && source.includes('EXPECTED_ACTIONS'),
  'validator must bind canonical 64x96 cells and action frame counts independently of manifest claims');
assert(source.includes('manifestContractValid'), 'validator must report manifest contract drift explicitly');
assert(source.includes("require('crypto')") && source.includes('sha256File'),
  'validator must hash production strips before admission');
assert(source.includes('hashesMatch') && source.includes('assetSha256'),
  'admission evidence must bind the reviewed receipt to exact strip SHA-256 values');
assert(source.includes('transparentCapable') && source.includes('transparentCapable &&'),
  'validator must require an alpha-capable PNG before a strip can be admitted');
assert(source.includes('ADMISSION_SCHEMA') && source.includes('inspectAdmissionEvidence'),
  'validator must bind a separate evidence receipt for post-promotion admission');
assert(source.includes('rawParticipants.length >= 5') && source.includes('silhouetteRate >= 0.80'),
  'human silhouette evidence must derive the minimum participant count and recognition threshold from raw observations');
assert(source.includes('participant.independentOfImplementation !== true') &&
       source.includes("typeof participant.correct !== 'boolean'"),
  'silhouette evidence must require independent participants and raw correctness booleans');
assert(source.includes("runtime.status === 'PASS'") && source.includes('runtime.exactHead'),
  'admission evidence must bind a passing runtime review to an exact head');
for (const gate of ['visualSuite', 'browserRouteReplay', 'exactHeadEvidenceCapture', 'visualPerformance', 'beforeAfterCohesion']) {
  assert(source.includes("runtime." + gate + " === 'PASS'"),
    'admission evidence must explicitly require runtime gate ' + gate);
}
assert(source.includes('actualEvidenceManifestSha256') && source.includes('evidenceManifestMatches'),
  'runtime evidence must compare the recorded evidence-manifest hash to the actual manifest bytes');
assert(source.includes('admissionTransitionMatches') && source.includes('BOUNDED_ADMISSION_CHILD'),
  'runtime evidence must allow only the exact reviewed head or one bounded admission child commit');
assert(source.includes("'assets/characters/v1/manifest.json'") &&
       source.includes("'assets/characters/v1/admission/ender.json'") &&
       source.includes("'assets/characters/v1/admission/ionia.json'"),
  'bounded admission commit must restrict changed files to manifest + Ender/Ionia admission receipts');
assert(source.includes("gitText(['status', '--porcelain'])"),
  'admission transition must inspect worktree cleanliness/content');
assert(source.includes('UNBOUNDED_REVIEWED_WORKTREE'),
  'reviewed-head pre-commit state must reject unrelated dirty paths');
assert(source.includes('/^[0-9a-f]{40}$/i.test(runtime.exactHead)'),
  'runtime evidence must bind a full 40-character exact commit SHA');
assert(source.includes('--require-complete') && source.includes('--require-ready') && source.includes('--require-evidence'),
  'validator must separate pre-promotion completeness from post-promotion admission');
assert(source.includes('AETHERWAKE_FIELD_PACK_READINESS=BLOCKED'),
  'validator must fail closed when a required gate is unmet');

const run = cp.spawnSync(process.execPath, [script], { cwd: root, encoding: 'utf8' });
assert.strictEqual(run.status, 0, run.stderr);
assert(run.stdout.includes('AETHERWAKE_FIELD_PACK_READINESS=NOT_READY'),
  'planned packs should report NOT_READY without failing ordinary development');
assert(run.stdout.includes('"manifestContractValid":true'),
  'current Ender/Ionia manifest declarations must match the canonical strip contract');
assert(run.stdout.includes('"transparentCapable":false'),
  'missing production strips must not be represented as transparency-capable');

const complete = cp.spawnSync(process.execPath, [script, '--require-complete'], { cwd: root, encoding: 'utf8' });
assert.notStrictEqual(complete.status, 0, 'pre-promotion completeness must block while production strips are absent');
assert(complete.stderr.includes('AETHERWAKE_FIELD_PACK_READINESS=BLOCKED'));

const admission = cp.spawnSync(
  process.execPath,
  [script, '--require-ready', '--require-evidence'],
  { cwd: root, encoding: 'utf8' }
);
assert.notStrictEqual(admission.status, 0, 'post-promotion admission must block without ready packs and evidence receipts');
assert(admission.stderr.includes('AETHERWAKE_FIELD_PACK_READINESS=BLOCKED'));

console.log('Aetherwake field-pack readiness gate: PASS');
