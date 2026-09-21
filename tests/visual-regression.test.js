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

test('D27: character sheet uses canonical live view-model and defined row variables', () => {
  assert(aetherwakeSrc.includes('function getCharacterSheetViewModel()'),
    'character sheet view-model helper should exist');
  assert(aetherwakeSrc.includes('window.getCharacterSheetViewModel = getCharacterSheetViewModel'),
    'character sheet view-model should be exposed for integration verification');
  assert(aetherwakeSrc.includes("mastery.getNativeJobStatus(actor.id)"),
    'character sheet should read native-job facts from mastery definitions');
  assert(aetherwakeSrc.includes("mastery.getAuthoredAffinities(actor.id)"),
    'character sheet should read authored affinities from mastery definitions');
  assert(aetherwakeSrc.includes("abilityDefs.getEligibleActionIds(actor)"),
    'character sheet should derive eligible actions from the canonical ability registry');
  assert(!aetherwakeSrc.includes('abilities.forEach((a, i)'),
    'legacy undefined abilities iterator must not return');
  assert(aetherwakeSrc.includes('const gy = sheet.gearY + 22 + i * 32'),
    'gear renderer must define its row position before use');
  assert(!aetherwakeSrc.includes("text('Rift Scholar / Dreamwright', sheet.classX"),
    'character sheet must not hardcode the legacy class as canonical native job');
});

test('D28: character sheet roster browser is read-only and uncertainty-preserving', () => {
  assert(aetherwakeSrc.includes('let charSheetRosterIndex = 0'),
    'character sheet roster selection state is missing');
  assert(aetherwakeSrc.includes('charSheetRosterIndex = selectedCode - 49'),
    'number keys 1-5 should select a roster record for viewing');
  assert(aetherwakeSrc.includes('const actor = roster[index]'),
    'character sheet view-model should read the selected canonical roster record');
  assert(aetherwakeSrc.includes("actor.runtimeImplemented === false"),
    'unimplemented roster shells should suppress inherited action claims');
  assert(aetherwakeSrc.includes("Field role (temporary):"),
    'temporary mechanics templates should be labeled as non-canonical field roles');
  assert(aetherwakeSrc.includes("view.runtimeImplemented ? 'PORTRAIT PENDING' : 'NOT IMPLEMENTED'"),
    'unresolved companion portraits should not fabricate appearance');
  assert(!aetherwakeSrc.includes('ACTIVE_PARTY.splice', aetherwakeSrc.indexOf('function drawCharSheet')),
    'character sheet renderer must not mutate active-party formation');
});

console.log('\nAll Cluster 6 regression tests passed!');
