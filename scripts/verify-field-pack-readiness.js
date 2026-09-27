'use strict';
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'assets', 'characters', 'v1', 'manifest.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const requireReady = process.argv.includes('--require-ready');
const ids = process.argv.slice(2).filter(v => !v.startsWith('--'));
const targets = ids.length ? ids : ['ender', 'ionia'];

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

function inspect(id) {
  const record = manifest.characters && manifest.characters[id];
  if (!record) return { id, status: 'MISSING_RECORD', valid: false, strips: [] };
  const strips = Object.entries(record.fieldStrips || {}).map(([action, spec]) => {
    const file = path.join(root, spec.path);
    const info = pngInfo(file);
    const expectedWidth = spec.frameWidth * spec.frames;
    const valid = Boolean(
      info.exists && info.png &&
      info.width === expectedWidth &&
      info.height === spec.frameHeight
    );
    return {
      action,
      path: spec.path,
      expected: [expectedWidth, spec.frameHeight],
      actual: info.exists && info.png ? [info.width, info.height] : null,
      transparentCapable: info.png ? [4, 6].includes(info.colorType) : false,
      valid,
    };
  });
  const complete = strips.length === 5 && strips.every(s => s.valid);
  const declaredReady = record.status === 'ready' || record.status === 'field-ready';
  return {
    id,
    manifestStatus: record.status,
    complete,
    declaredReady,
    valid: declaredReady ? complete : !requireReady,
    strips,
  };
}

const results = targets.map(inspect);
for (const result of results) {
  console.log(JSON.stringify(result));
}
const invalidDeclaredReady = results.some(r => r.declaredReady && !r.complete);
const unmetRequiredReady = requireReady && results.some(r => !r.declaredReady || !r.complete);
if (invalidDeclaredReady || unmetRequiredReady) {
  console.error('AETHERWAKE_FIELD_PACK_READINESS=BLOCKED');
  process.exit(1);
}
const allReady = results.every(r => r.declaredReady && r.complete);
console.log('AETHERWAKE_FIELD_PACK_READINESS=' + (allReady ? 'READY' : 'NOT_READY'));
process.exit(0);
