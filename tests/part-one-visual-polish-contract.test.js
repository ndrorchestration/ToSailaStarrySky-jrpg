const assert = require('assert');
const fs = require('fs');

const bundle = fs.readFileSync('aetherwake.js', 'utf8');
const core = fs.readFileSync('modules/core.js', 'utf8');
const html = fs.readFileSync('index-embedded.html', 'utf8');
const capture = fs.readFileSync('scripts/capture-player-evidence.js', 'utf8');

for (const [name, source] of [['bundle', bundle], ['core', core]]) {
  assert(/scanlines:\s*false/.test(source),
    name + ' must disable CRT scanlines by default');
  const unconditional = source
    .split(/\r?\n/)
    .filter(line => /^\s*drawScanlines\(\);\s*$/.test(line));
  assert.strictEqual(unconditional.length, 0,
    name + ' must not apply full-screen scanlines unconditionally');
  assert(source.includes('if (VIS.scanlines) drawScanlines();'),
    name + ' must retain scanlines only as an explicit opt-in effect');
}

assert(html.includes("aetherwake-preview-world-pixelart-v2.png"),
  'preloader must use an Aetherwake-authored atmospheric plate');
assert(html.includes('PREPARING THE WAKE'),
  'preloader must use Aetherwake-specific copy');
assert(!html.includes('initializing the weave...'),
  'legacy technical loading copy must not remain active');
assert(/\.loading-ref-img\s*\{[\s\S]*?display:\s*none;/.test(html),
  'reference loading sprite must not be visible');

assert(capture.includes('window.__awLoadingDone === true'),
  'evidence capture must wait for the HTML loading cover to clear');
assert(capture.includes("window.gameState === 'menu'"),
  'title-ready evidence must wait for the authored title/menu state');

console.log('Aetherwake Part One visual polish contract: PASS');
