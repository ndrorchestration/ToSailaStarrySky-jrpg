'use strict';

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const base = require('../modules/save-system.js');

const stages = [
  'before-temp-write',
  'after-temp-fsync',
  'after-backup-promote',
  'before-primary-promote',
  'after-primary-promote',
];

for (const stage of stages) {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'aetherwake-save-crash-'));
  let failStage = null;
  const root = {
    nw: { App: { dataPath: temp } },
    require(name) {
      if (name === 'fs') return fs;
      if (name === 'path') return path;
      if (name === 'process') return process;
      throw new Error('unexpected module: ' + name);
    },
    __AETHERWAKE_SAVE_TEST_HOOK__(current) {
      if (current === failStage) throw new Error('SIMULATED_CRASH:' + current);
    },
  };

  const save = base._createForTesting(root);
  save.save('manual-1', { value: 1 }, { gameVersion: '0.2.0' });
  failStage = stage;

  assert.throws(
    () => save.save('manual-1', { value: 2 }, { gameVersion: '0.2.0' }),
    new RegExp('SIMULATED_CRASH:' + stage)
  );

  failStage = null;
  const loaded = save.load('manual-1');
  assert(loaded && loaded.envelope, 'no recoverable save after stage ' + stage);
  assert([1,2].includes(loaded.envelope.payload.value),
    'stage ' + stage + ' left neither old nor new save valid');

  const saveDir = path.join(temp, 'saves');
  const target = path.join(saveDir, 'manual-1.json');
  assert(fs.existsSync(target), 'primary missing after recovery at stage ' + stage);
  assert.strictEqual(base.validateEnvelope(JSON.parse(fs.readFileSync(target, 'utf8'))), true,
    'primary invalid after recovery at stage ' + stage);

  fs.rmSync(temp, { recursive: true, force: true });
}

console.log('Aetherwake interrupted-write save recovery: PASS');
