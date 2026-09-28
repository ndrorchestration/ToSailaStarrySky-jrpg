'use strict';
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'assets', 'characters', 'v1', 'manifest.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const requireReady = process.argv.includes('--require-ready');
const ids = process.argv.slice(2).filter(v => !v.startsWith('--'));
const targets = ids.length ? ids : ['ender', 'ionia'];

const FIELD_CELL = Object.freeze({ width: 64, height: 96 });
const EXPECTED_ACTIONS = Object.freeze({
  idle: 8,
  walk: 6,
  talk: 4,
  focus: 6,
  attack: 8,
});
const ACTION_NAMES = Object.freeze(Object.keys(EXPECTED_ACTIONS));

function pngInfo(file) {
  if (!fs.existsSync(file)) return { exists: false };
  const buf = fs.readFileSync(file);
  const signature = buf.subarray(0, 8).toString('hex');
  if (signature !== '89504e470d0a1a0a' || buf.length < 26) {
    return { exists: true, png: false };
  }
  return {
    exists: true,
    png: true,
    width: buf.readUInt32BE(16),
    height: buf.readUInt32BE(20),
    colorType: buf[25],
    bytes: buf.length,
  };
}

function sameActions(fieldStrips) {
  const names = Object.keys(fieldStrips || {}).sort();
  return names.length === ACTION_NAMES.length &&
    names.every((name, index) => name === [...ACTION_NAMES].sort()[index]);
}

function inspect(id) {
  const record = manifest.characters && manifest.characters[id];
  if (!record) return { id, status: 'MISSING_RECORD', valid: false, strips: [] };

  const fieldStrips = record.fieldStrips || {};
  const actionsMatch = sameActions(fieldStrips);
  const strips = ACTION_NAMES.map(action => {
    const spec = fieldStrips[action] || null;
    const expectedFrames = EXPECTED_ACTIONS[action];
    const expectedWidth = FIELD_CELL.width * expectedFrames;
    const contractValid = Boolean(
      spec &&
      spec.frameWidth === FIELD_CELL.width &&
      spec.frameHeight === FIELD_CELL.height &&
      spec.frames === expectedFrames &&
      typeof spec.path === 'string' &&
      spec.path.length > 0
    );
    const file = contractValid ? path.join(root, spec.path) : null;
    const info = file ? pngInfo(file) : { exists: false };
    const transparentCapable = Boolean(info.png && [4, 6].includes(info.colorType));
    const valid = Boolean(
      contractValid &&
      info.exists && info.png &&
      transparentCapable &&
      info.width === expectedWidth &&
      info.height === FIELD_CELL.height
    );
    return {
      action,
      path: spec && spec.path ? spec.path : null,
      expected: [expectedWidth, FIELD_CELL.height],
      expectedFrames,
      manifestContractValid: contractValid,
      actual: info.exists && info.png ? [info.width, info.height] : null,
      transparentCapable,
      valid,
    };
  });

  const complete = actionsMatch && strips.every(s => s.valid);
  const declaredReady = record.status === 'ready' || record.status === 'field-ready';
  return {
    id,
    manifestStatus: record.status,
    actionsMatch,
    complete,
    declaredReady,
    valid: declaredReady ? complete : !requireReady,
    strips,
  };
}

const results = targets.map(inspect);
for (const result of results) console.log(JSON.stringify(result));

const invalidDeclaredReady = results.some(r => r.declaredReady && !r.complete);
const unmetRequiredReady = requireReady && results.some(r => !r.declaredReady || !r.complete);
if (invalidDeclaredReady || unmetRequiredReady) {
  console.error('AETHERWAKE_FIELD_PACK_READINESS=BLOCKED');
  process.exit(1);
}
const allReady = results.every(r => r.declaredReady && r.complete);
console.log('AETHERWAKE_FIELD_PACK_READINESS=' + (allReady ? 'READY' : 'NOT_READY'));
process.exit(0);
