const assert = require('assert');
const fs = require('fs');

const runtime = fs.readFileSync('aetherwake.js', 'utf8');
const html = fs.readFileSync('index-embedded.html', 'utf8');
const source = fs.readFileSync('modules/ship-interior-visual-stage.js', 'utf8');

assert(html.includes('modules/ship-interior-visual-stage.js'),
  'live ship interior visual module is not loaded');
assert(html.indexOf('modules/ship-interior-visual-stage.js') < html.indexOf('aetherwake.js'),
  'live ship interior authority must load before runtime');
assert(source.includes('aetherwake-preview-interior-pixelart-v1.png'),
  'live interior does not use the authored painted interior plate');
assert(source.includes('AetherAuthoredCharacterArt'),
  'live interior does not use authored character presentation');
assert(source.includes('drawProvisionalFieldCharacter'),
  'live interior does not expose the candidate/fallback crew presentation path');
assert(source.includes('AetherUIVisualSystem'),
  'live interior does not share the current UI presentation system');

const start = runtime.indexOf('function drawShipInterior()');
const end = runtime.indexOf('\n// --- Ground Layer', start);
assert(start >= 0 && end > start, 'live ship interior function missing');
const body = runtime.slice(start, end);
assert(body.includes('window.AetherShipInteriorVisual'),
  'live ship interior does not delegate to the visual authority');
assert(body.includes('visual.draw({'),
  'live ship interior does not call the visual authority');
assert(body.includes('window.ACTIVE_PARTY'),
  'live ship interior does not pass the actual active party');
assert(body.includes('if (rendered) return;'),
  'legacy procedural interior is not retained strictly as fallback');

console.log('Aetherwake live Dragonfly interior visual gate: PASS');
