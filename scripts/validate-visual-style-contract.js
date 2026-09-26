'use strict';
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const contractPath = path.join(root, 'docs', 'visual-style-contract.json');
const c = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
function assert(ok, msg) { if (!ok) throw new Error('VISUAL_CONTRACT_FAIL: ' + msg); }

assert(c.schema === 'AETHERWAKE_VISUAL_STYLE_CONTRACT_V1', 'schema mismatch');
assert(Array.isArray(c.authority.logicalCanvas) && c.authority.logicalCanvas[0] === 960 && c.authority.logicalCanvas[1] === 640, 'logical canvas drift');
assert(Array.isArray(c.authority.evidenceViewport) && c.authority.evidenceViewport[0] === 1440 && c.authority.evidenceViewport[1] === 960, 'evidence viewport drift');

const palette = Object.values(c.palette || {});
assert(palette.length >= 12 && palette.length <= 16, 'palette must contain 12-16 role colors');
for (const value of palette) assert(/^#[0-9A-F]{6}$/i.test(value), 'invalid hex color ' + value);

assert(c.ui.gridPx === 8, 'UI grid must remain 8px');
assert(c.ui.minBodyContrast >= 4.5, 'body contrast budget below 4.5:1');
assert(c.ui.maxPrimaryPanelsAtOnce <= 2, 'too many simultaneous primary panels');
assert(c.performance.targetFps >= 60, 'target FPS below 60');
assert(c.performance.minimumFps >= 30, 'minimum FPS below 30');
assert(c.performance.p95FrameMsHardLimit <= 33.4, 'p95 frame-time hard limit above 33.4ms');
assert(c.performance.singleFrameSpikeHardLimitMs <= 50, 'single-frame spike hard limit above 50ms');
assert(c.performance.atlasMaxPx[0] <= 2048 && c.performance.atlasMaxPx[1] <= 2048, 'atlas exceeds 2048x2048');
assert(c.scale.combatDragonflyMaxScreenWidthRatio <= 0.25, 'combat Dragonfly width budget exceeds 25%');

const cats = c.acceptance.categories;
let weight = 0;
for (const [name, spec] of Object.entries(cats)) {
  assert(spec.weight > 0 && spec.weight <= 1, 'invalid weight for ' + name);
  assert(spec.minimum >= 1 && spec.minimum <= 5, 'invalid minimum for ' + name);
  weight += spec.weight;
}
assert(Math.abs(weight - 1) < 1e-9, 'acceptance weights must sum to 1.0');
assert(c.acceptance.weightedMinimum >= 4.0, 'weighted visual threshold below 4.0');
assert(c.acceptance.playtesters >= 5, 'fewer than five playtesters');
assert(c.acceptance.sameGameBlindTestMinimum >= 0.8, 'same-game blind threshold below 80%');
assert(c.acceptance.dragonflyRecallMinimum >= 0.8, 'Dragonfly recall threshold below 80%');

const expectedGates = ['G0_BASELINE_AUDITED','G1_STYLE_CONTRACT_LOCKED','G2_CHARACTER_DRAGONFLY_IDENTITY_LOCKED','G3_WORLD_UI_SYSTEM_LOCKED','G4_POLISH_QA_ACCEPTED'];
assert(JSON.stringify(c.gates) === JSON.stringify(expectedGates), 'gate order drift');

console.log('AETHERWAKE_VISUAL_STYLE_CONTRACT=PASS');
