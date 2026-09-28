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
assert(source.includes('transparentCapable') && source.includes('transparentCapable &&'),
  'validator must require an alpha-capable PNG before a strip can be admitted');
assert(source.includes('ADMISSION_SCHEMA') && source.includes('inspectAdmissionEvidence'),
  'validator must bind a separate evidence receipt for post-promotion admission');
assert(source.includes('silhouette.participants >= 5') && source.includes('Number(silhouette.correctRate) >= 0.80'),
  'human silhouette evidence must enforce the minimum participant count and recognition threshold');
assert(source.includes("runtime.status === 'PASS'") && source.includes('runtime.exactHead'),
  'admission evidence must bind a passing runtime review to an exact head');
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
