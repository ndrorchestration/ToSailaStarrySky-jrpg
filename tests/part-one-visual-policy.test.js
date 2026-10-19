const assert = require('assert');
const fs = require('fs');

const runtime = fs.readFileSync('aetherwake.js', 'utf8');
const core = fs.readFileSync('modules/core.js', 'utf8');
const evidence = fs.readFileSync('scripts/capture-player-evidence.js', 'utf8');
const html = fs.readFileSync('index-embedded.html', 'utf8');

for (const [name, source] of [['runtime', runtime], ['core', core]]) {
  assert(source.includes('scanlines: false'), name + ' must default CRT scanlines off');
  assert(!/^[ \t]*drawScanlines\(\);/m.test(source),
    name + ' still contains an unconditional scanline draw call');
  assert(source.includes('if (VIS.scanlines) drawScanlines();'),
    name + ' must guard scanlines behind VIS.scanlines');
}

assert(evidence.includes("window.__awLoadingDone === true"),
  'evidence capture must wait for the HTML preloader to leave');
assert(evidence.includes("window.gameState === 'menu'"),
  'title-ready capture must wait for the authored title/menu state');

assert(html.includes('aetherwake-preview-world-pixelart-v2.png'),
  'embedded preloader must use Aetherwake visual material');
assert(html.includes('PREPARING THE WAKE'),
  'embedded preloader must use Aetherwake-specific copy');
assert(!html.includes('initializing the weave...'),
  'legacy preloader copy remains active');

console.log('Aetherwake Part One visual policy gate: PASS');
