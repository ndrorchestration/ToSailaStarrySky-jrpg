const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const runtime = fs.readFileSync(path.resolve(__dirname, '..', 'aetherwake.js'), 'utf8');

assert(runtime.includes('function getQuestObjectiveText()'),
  'quest guidance helper is missing');
assert(runtime.includes('objective: getQuestObjectiveText()'),
  'quest state snapshot must expose the current objective');
assert(runtime.includes('Talk to marked:'),
  'Signal objective must direct the player to marked contacts');
assert(runtime.includes('Resolve orange hazard zones ('),
  'Crossing objective must explain how to find hazards');
assert(runtime.includes('Talk to marked:'),
  'Contact objective must identify remaining contacts');
assert(runtime.includes('Choose: press 1, 2, or 3 (or click a path).'),
  'Choice objective must teach the actual input');
assert(runtime.includes('Chapter I complete. Press R'),
  'completed objective must explain restart control');
assert(runtime.includes("text('NEXT: ' + getQuestObjectiveText()"),
  'world HUD must show the next action');
assert(runtime.includes("text('NEXT: ' + qs.objective"),
  'Quest Log must show the next action');

const scanlineDefinitions = runtime.match(/function drawScanlines\(\)/g) || [];
assert(scanlineDefinitions.length === 1,
  'runtime must have one authoritative scanline implementation');
assert(runtime.includes('scanlines: false'),
  'modern player presentation must keep CRT scanlines disabled by default');
assert(runtime.includes('if (!VIS.scanlines) return;'),
  'scanline renderer must fail closed when the effect is disabled');
assert(runtime.includes('scanShadow.setAlpha(24)'),
  'optional scanline mode must use an explicit low-alpha color');
assert(!runtime.includes('fill(color(PAL.TEAL), 6)'),
  'opaque-teal scanline regression path must not return');

console.log('Aetherwake First Wake guidance contract: PASS');
