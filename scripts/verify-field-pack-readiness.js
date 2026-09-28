'use strict';
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const manifestPath = path.join(root, 'assets', 'characters', 'v1', 'manifest.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const requireComplete = process.argv.includes('--require-complete');
const requireReady = process.argv.includes('--require-ready');
const requireEvidence = process.argv.includes('--require-evidence');
const ids = process.argv.slice(2).filter(v => !v.startsWith('--'));
const targets = ids.length ? ids : ['ender', 'ionia'];

const FIELD_CELL = Object.freeze({ width: 64, height: 96 });
const EXPECTED_ACTIONS = Object.freeze({ idle: 8, walk: 6, talk: 4, focus: 6, attack: 8 });
const ACTION_NAMES = Object.freeze(Object.keys(EXPECTED_ACTIONS));
const ADMISSION_SCHEMA = 'AETHERWAKE_FIELD_ART_ADMISSION_V1';

function pngInfo(file) {
  if (!fs.existsSync(file)) return { exists: false };
  const buf = fs.readFileSync(file);
  const signature = buf.subarray(0, 8).toString('hex');
  if (signature !== '89504e470d0a1a0a' || buf.length < 26) return { exists: true, png: false };
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
  const expected = [...ACTION_NAMES].sort();
  const names = Object.keys(fieldStrips || {}).sort();
  return names.length === expected.length && names.every((name, index) => name === expected[index]);
}

function inspectAdmissionEvidence(id) {
  const relativePath = path.join('assets', 'characters', 'v1', 'admission', id + '.json');
  const file = path.join(root, relativePath);
  if (!fs.existsSync(file)) return { path: relativePath.replace(/\\/g, '/'), exists: false, valid: false };
  try {
    const receipt = JSON.parse(fs.readFileSync(file, 'utf8'));
    const silhouette = receipt.silhouetteRecognition || {};
    const runtime = receipt.runtimeReview || {};
    const valid = Boolean(
      receipt.schema === ADMISSION_SCHEMA &&
      receipt.characterId === id &&
      silhouette.status === 'PASS' &&
      Number.isInteger(silhouette.participants) &&
      silhouette.participants >= 5 &&
      Number(silhouette.correctRate) >= 0.80 &&
      runtime.status === 'PASS' &&
      runtime.visualSuite === 'PASS' &&
      runtime.browserRouteReplay === 'PASS' &&
      runtime.exactHeadEvidenceCapture === 'PASS' &&
      runtime.visualPerformance === 'PASS' &&
      runtime.beforeAfterCohesion === 'PASS' &&
      typeof runtime.exactHead === 'string' &&
      /^[0-9a-f]{40}$/i.test(runtime.exactHead)
    );
    return {
      path: relativePath.replace(/\\/g, '/'),
      exists: true,
      valid,
      silhouetteStatus: silhouette.status || null,
      participants: Number.isInteger(silhouette.participants) ? silhouette.participants : null,
      correctRate: Number.isFinite(Number(silhouette.correctRate)) ? Number(silhouette.correctRate) : null,
      runtimeStatus: runtime.status || null,
      visualSuite: runtime.visualSuite || null,
      browserRouteReplay: runtime.browserRouteReplay || null,
      exactHeadEvidenceCapture: runtime.exactHeadEvidenceCapture || null,
      visualPerformance: runtime.visualPerformance || null,
      beforeAfterCohesion: runtime.beforeAfterCohesion || null,
      exactHead: typeof runtime.exactHead === 'string' ? runtime.exactHead : null,
    };
  } catch (error) {
    return { path: relativePath.replace(/\\/g, '/'), exists: true, valid: false, parseError: true };
  }
}

function inspect(id) {
  const record = manifest.characters && manifest.characters[id];
  if (!record) return { id, status: 'MISSING_RECORD', valid: false, strips: [], evidence: inspectAdmissionEvidence(id) };

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
  const evidence = inspectAdmissionEvidence(id);
  return { id, manifestStatus: record.status, actionsMatch, complete, declaredReady, evidence, strips };
}

const results = targets.map(inspect);
for (const result of results) console.log(JSON.stringify(result));

const invalidDeclaredReady = results.some(r => r.declaredReady && !r.complete);
const unmetComplete = requireComplete && results.some(r => !r.complete);
const unmetReady = requireReady && results.some(r => !r.declaredReady || !r.complete);
const unmetEvidence = requireEvidence && results.some(r => !r.evidence || !r.evidence.valid);
if (invalidDeclaredReady || unmetComplete || unmetReady || unmetEvidence) {
  console.error('AETHERWAKE_FIELD_PACK_READINESS=BLOCKED');
  process.exit(1);
}

const allComplete = results.every(r => r.complete);
const allReady = results.every(r => r.declaredReady && r.complete);
const state = allReady ? 'READY' : (allComplete ? 'COMPLETE_NOT_PROMOTED' : 'NOT_READY');
console.log('AETHERWAKE_FIELD_PACK_READINESS=' + state);
process.exit(0);
