'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const root = path.resolve(__dirname, '..');
const script = path.join(root, 'scripts', 'verify-field-pack-readiness.js');
const source = fs.readFileSync(script, 'utf8');

assert(source.includes("['ender', 'ionia']"), 'default admission targets must remain Ender + Ionia');
assert(source.includes('spec.frameWidth * spec.frames'), 'validator must derive strip width from frame contract');
assert(source.includes("AETHERWAKE_FIELD_PACK_READINESS=BLOCKED"), 'validator must fail closed for invalid ready packs');

const run = cp.spawnSync(process.execPath, [script], { cwd: root, encoding: 'utf8' });
assert.strictEqual(run.status, 0, run.stderr);
assert(run.stdout.includes('AETHERWAKE_FIELD_PACK_READINESS=NOT_READY'),
  'planned packs should report NOT_READY without failing ordinary development');

const strict = cp.spawnSync(process.execPath, [script, '--require-ready'], { cwd: root, encoding: 'utf8' });
assert.notStrictEqual(strict.status, 0, 'strict admission mode must block incomplete packs');
assert(strict.stderr.includes('AETHERWAKE_FIELD_PACK_READINESS=BLOCKED'));

console.log('Aetherwake field-pack readiness gate: PASS');
