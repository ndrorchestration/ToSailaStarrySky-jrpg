const assert = require('assert');
const fs = require('fs');

const runtime = fs.readFileSync('aetherwake.js','utf8');
const core = fs.readFileSync('modules/core.js','utf8');
const evidence = fs.readFileSync('scripts/capture-player-evidence.js','utf8');
const html = fs.readFileSync('index-embedded.html','utf8');

for (const [label, source] of [['runtime', runtime], ['core', core]]) {
  assert(source.includes('scanlines: false'), label + ' must disable CRT scanlines by default');
  assert(!/^[ \t]*drawScanlines\(\);/m.test(source), label + ' contains an unconditional scanline call');
  assert(source.includes('if (VIS.scanlines) drawScanlines();'), label + ' must keep scanlines opt-in');
}

assert(html.includes("aetherwake-preview-world-pixelart-v2.png"), 'preloader must use an Aetherwake visual plate');
assert(html.includes('PREPARING THE WAKE'), 'preloader copy must be Aetherwake-specific');
assert(!html.includes('initializing the weave...'), 'legacy preloader copy must not remain');
assert(evidence.includes("window.__awLoadingDone === true"), 'evidence must wait for preloader dismissal');
assert(evidence.includes("window.gameState === 'menu'"), 'title-ready evidence must wait for authored menu state');

console.log('Aetherwake visual presentation defaults gate: PASS');
