const assert = require('assert');
const fs = require('fs');
const path = require('path');

// Regression tests for Cluster 1: Boot/Entrypoints (D1-D4)
// These tests verify the fixes for:
// D1: Fail-open timeout removed - loading screen stays up on init failure
// D2: Audio module loaded in both entrypoints
// D3: index.html loads all required modules
// D4: Debug overlay hidden by default

const BASE = path.resolve(__dirname, '..');

function readFile(filename) {
  return fs.readFileSync(path.join(BASE, filename), 'utf-8');
}

function test(name, fn) {
  try {
    fn();
    console.log(`PASS ${name}`);
  } catch (error) {
    console.error(`FAIL ${name}: ${error.message}`);
    throw error;
  }
}

// D1: Verify REF_MAX_WAIT is removed from index-embedded.html
test('D1: REF_MAX_WAIT timeout removed from index-embedded.html', () => {
  const html = readFile('index-embedded.html');
  assert(!html.includes('REF_MAX_WAIT'), 'REF_MAX_WAIT constant should be removed');
  assert(!html.includes('force-revealing after'), 'Force-reveal timeout logic should be removed');
});

// D1b: Verify initialization error state is implemented
test('D1b: Initialization error state implemented in index-embedded.html', () => {
  const html = readFile('index-embedded.html');
  assert(html.includes('showInitError'), 'showInitError function should exist');
  assert(html.includes('INITIALIZATION FAILED'), 'Error message template should exist');
});

// D2: Verify audio.js is loaded in index-embedded.html
test('D2: audio.js loaded in index-embedded.html', () => {
  const html = readFile('index-embedded.html');
  assert(html.includes('<script src="modules/audio.js"></script>'), 
    'audio.js script tag should be present in index-embedded.html');
  // Verify it's in the correct position (before aetherwake.js)
  const audioPos = html.indexOf('<script src="modules/audio.js"></script>');
  const awPos = html.indexOf('<script src="aetherwake.js"></script>');
  assert(audioPos < awPos, 'audio.js should load before aetherwake.js');
});

// D2b: Verify audio.js is loaded in index.html
test('D2b: audio.js loaded in index.html', () => {
  const html = readFile('index.html');
  assert(html.includes('<script src="modules/audio.js"></script>'), 
    'audio.js script tag should be present in index.html');
});

// D3: Verify index.html loads all required modules (same set as index-embedded.html)
test('D3: index.html loads all required modules', () => {
  const embedded = readFile('index-embedded.html');
  const legacy = readFile('index.html');
  
  const requiredModules = [
    'modules/effect-vocabulary.js',
    'modules/effect-resolver.js',
    'modules/ability-defs.js',
    'modules/progression-defs.js',
    'modules/party-state.js',
    'modules/airship-state.js',
    'modules/airship-combat-bridge.js',
    'modules/airship-ui.js',
    'modules/audio.js',
  ];
  
  for (const mod of requiredModules) {
    const scriptTag = `<script src="${mod}"></script>`;
    const embeddedHas = embedded.includes(scriptTag);
    const legacyHas = legacy.includes(scriptTag);
    assert(embeddedHas, `${mod} should be in index-embedded.html`);
    assert(legacyHas, `${mod} should be in index.html`);
  }
});

// D3b: Verify aetherwake.js and char-create.js loading order is preserved
test('D3b: aetherwake.js loads before char-create.js in both entrypoints', () => {
  const embedded = readFile('index-embedded.html');
  const legacy = readFile('index.html');
  
  const checkOrder = (html, name) => {
    const awPos = html.indexOf('<script src="aetherwake.js"></script>');
    const ccPos = html.indexOf('<script src="modules/char-create.js"></script>');
    assert(awPos < ccPos, `${name}: aetherwake.js must load before char-create.js`);
  };
  
  checkOrder(embedded, 'index-embedded.html');
  checkOrder(legacy, 'index.html');
});

// D4: Verify debug overlay is hidden by default in index.html
test('D4: Debug overlay hidden by default in index.html', () => {
  const html = readFile('index.html');
  // Check for the debug query param check
  assert(html.includes('debug') && html.includes('get(\'debug\')'), 
    'Debug overlay should be controlled by query parameter');
  // The overlay should be hidden unless debug=1
  assert(html.includes("db.style.display = 'none'"), 
    'Debug overlay should be explicitly hidden when debug param is not set');
});

// D4b: Verify debug overlay in index-embedded.html is also controlled by query param
test('D4b: Debug overlay in index-embedded.html is opt-in only', () => {
  const html = readFile('index-embedded.html');
  assert(html.includes('__awDebugEnabled'), 'Debug flag variable should exist');
  assert(html.includes('get(\'debug\') === \'1\''), 'Debug should require explicit query param');
  // The debug-overlay div should have display:none by default
  assert(html.includes('id="debug-overlay" style="display:none"'), 
    'Debug overlay element should be hidden by default');
});

console.log('\nAll Cluster 1 regression tests passed!');
