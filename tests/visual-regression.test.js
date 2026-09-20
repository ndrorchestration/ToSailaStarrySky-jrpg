const assert = require('assert');
const fs = require('fs');

// Quick syntax check before running tests
const syntax = require('child_process').execSync('node --check aetherwake.js 2>&1').toString().trim();
if (syntax) {
  console.error('Syntax check failed:', syntax);
  process.exit(1);
}

// Regression tests for Cluster 6: Visual fixes (D24-D25)
// D24: Vignette uses isNight() instead of window._isNight
// D25: Grass wind sets visible stroke before drawing lines

const aetherwakeSrc = fs.readFileSync('aetherwake.js', 'utf-8');

function test(name, fn) {
  try {
    fn();
    console.log(`PASS ${name}`);
  } catch (error) {
    console.error(`FAIL ${name}: ${error.message}`);
    throw error;
  }
}

// D24: Verify vignette uses isNight() not window._isNight
test('D24: drawVignette uses isNight() not window._isNight', () => {
  const vignetteMatch = aetherwakeSrc.match(/function drawVignette\(\) \{([\s\S]*?)^\}/m);
  assert(vignetteMatch, 'drawVignette function should exist');
  const body = vignetteMatch[1];
  
  // Should use isNight() function
  assert(body.includes('isNight()'), 'drawVignette should call isNight()');
  
  // Should NOT use window._isNight
  assert(!body.includes('window._isNight'), 
    'drawVignette should NOT use window._isNight (undefined global)');
});

// D25: Verify grass wind sets stroke before drawing lines
test('D25: drawGrassWind sets visible stroke before drawing lines', () => {
  const grassMatch = aetherwakeSrc.match(/function drawGrassWind\(\) \{([\s\S]*?)^\}/m);
  assert(grassMatch, 'drawGrassWind function should exist');
  const body = grassMatch[1];
  
  // Should set stroke before the loop that draws lines
  const strokeIdx = body.indexOf('stroke(');
  const lineIdx = body.indexOf('line(');
  
  assert(strokeIdx !== -1, 'drawGrassWind should call stroke()');
  assert(lineIdx !== -1, 'drawGrassWind should call line()');
  assert(strokeIdx < lineIdx, 
    'stroke() must be called BEFORE line() in drawGrassWind');
  
  // Should NOT have noStroke() before lines (the bug was noStroke immediately before line primitives)
  const noStrokeBeforeLines = body.indexOf('noStroke()');
  if (noStrokeBeforeLines !== -1 && noStrokeBeforeLines < lineIdx) {
    assert(false, 'Should NOT call noStroke() before drawing lines (visual bug)');
  }
  
  // Should restore noStroke after drawing
  assert(body.includes('noStroke();') && body.lastIndexOf('noStroke();') > body.indexOf('line('),
    'Should call noStroke() after drawing lines to restore state');
});

test('D26: rendering helpers do not shadow p5 text()', () => {
  assert(aetherwakeSrc.includes('function wrapText(content, x, y, maxWidth)'),
    'wrapText should not name its string parameter text');
  assert(!aetherwakeSrc.includes('function wrapText(text, x, y, maxWidth)'),
    'wrapText parameter must not shadow p5 text()');
  assert(aetherwakeSrc.includes('function drawNPCDialogue(npc, content)'),
    'dialogue renderer should use a non-shadowing content parameter');
});

console.log('\nAll Cluster 6 regression tests passed!');
