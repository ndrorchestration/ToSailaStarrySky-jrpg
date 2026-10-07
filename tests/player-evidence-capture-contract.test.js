const assert = require('assert');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const scriptPath = path.join(ROOT, 'scripts', 'capture-player-evidence.js');
const packagePath = path.join(ROOT, 'package.json');
const smokeWorkflowPath = path.join(ROOT, '.github', 'workflows', 'smoke.yml');
const developmentPath = path.join(ROOT, 'docs', 'DEVELOPMENT.md');
const uiPath = path.join(ROOT, 'modules', 'ui.js');
const integratedRuntimePath = path.join(ROOT, 'aetherwake.js');

assert(fs.existsSync(scriptPath), 'player evidence capture script must exist');

const source = fs.readFileSync(scriptPath, 'utf8');
const pkg = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
const smokeWorkflow = fs.readFileSync(smokeWorkflowPath, 'utf8');
const development = fs.readFileSync(developmentPath, 'utf8');
const uiSource = fs.readFileSync(uiPath, 'utf8');
const integratedRuntime = fs.readFileSync(integratedRuntimePath, 'utf8');

assert.strictEqual(
  pkg.scripts['capture:player-evidence'],
  'node scripts/capture-player-evidence.js',
  'package.json must expose the local player evidence capture command'
);

assert.strictEqual(
  pkg.scripts['test:player-evidence-capture'],
  'node tests/player-evidence-capture-contract.test.js',
  'package.json must expose the player evidence capture contract test'
);

assert(
  smokeWorkflow.includes('npm run test:player-evidence-capture'),
  'smoke workflow must guard the player evidence capture contract'
);

assert(
  development.includes('npm run capture:player-evidence'),
  'development guide must document the local player evidence capture command'
);

for (const required of [
  'AETHERWAKE_PLAYER_EVIDENCE=CAPTURED',
  'AETHERWAKE_PLAYER_EVIDENCE_DIR=',
  'humanAcceptance: \'PENDING\'',
  'visualAcceptance: \'PENDING\'',
  'gameplayCaptureInspected: false',
  'git rev-parse HEAD',
  'index-embedded.html',
  'arrival_horizon',
  'lyra_join',
  'Captain Ionia',
  'Aetherwake.exe',
]) {
  assert(source.includes(required), `capture script must include required authority marker: ${required}`);
}

for (const forbidden of [
  "keyboard.press('KeyN')",
  'VISUAL_ACCEPTANCE=PASS',
  'HUMAN_PLAYER_ACCEPTANCE=PASS',
  'visualApproval: true',
]) {
  assert(!source.includes(forbidden), `capture script must not contain unsafe shortcut/approval marker: ${forbidden}`);
}

for (const [label, runtimeSource] of [
  ['modules/ui.js', uiSource],
  ['aetherwake.js', integratedRuntime],
]) {
  assert(
    !runtimeSource.includes('fill(color(PAL.SHADOW), 40)'),
    `${label} must not rely on ambiguous fill(color, alpha) scanline semantics`
  );
  assert(
    !runtimeSource.includes('fill(color(PAL.TEAL), 6)'),
    `${label} must not rely on ambiguous fill(color, alpha) scanline semantics`
  );
  assert(
    runtimeSource.includes('shadowScanline.setAlpha(40)'),
    `${label} must set dark scanline alpha explicitly`
  );
  assert(
    runtimeSource.includes('tealScanline.setAlpha(6)'),
    `${label} must set teal scanline alpha explicitly`
  );
}

console.log('PLAYER_EVIDENCE_CAPTURE_CONTRACT=PASS');
