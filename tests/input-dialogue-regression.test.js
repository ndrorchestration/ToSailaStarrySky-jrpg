const assert = require('assert');
const fs = require('fs');

// Quick syntax check before running tests
const syntax = require('child_process').execSync('node --check aetherwake.js 2>&1').toString().trim();
if (syntax) {
  console.error('Syntax check failed:', syntax);
  process.exit(1);
}

// Regression tests for Cluster 2: Input/Dialogue (D5-D10)
// D5: Input ordering - interactionKey set before handleInput
// D6: Immediate movement on keydown
// D7: Dialogue first-contact - intro shown before met flag set
// D8: Dialogue API exports - nextDialogueLine, closeDialogue exported
// D9: openDialogue transitions to STATE.DIALOGUE
// D10: Overlay routing - M key uses world.openShop()

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

// D5: Verify interactionKey is set BEFORE handleInput() in keyPressed
test('D5: interactionKey set before handleInput in keyPressed', () => {
  // Find the keyPressed function
  const keyPressedMatch = aetherwakeSrc.match(/function keyPressed\(\) \{([\s\S]*?)^\}/m);
  assert(keyPressedMatch, 'keyPressed function should exist');
  const body = keyPressedMatch[1];
  
  const setInteractionIdx = body.indexOf('window.interactionKey =');
  const handleInputIdx = body.indexOf('handleInput();');
  
  assert(setInteractionIdx !== -1, 'window.interactionKey should be set in keyPressed');
  assert(handleInputIdx !== -1, 'handleInput() should be called in keyPressed');
  assert(setInteractionIdx < handleInputIdx, 
    'interactionKey must be set BEFORE handleInput() is called');
});

// D6: Verify immediate movement in handleWorldInput
test('D6: Immediate first move in handleWorldInput', () => {
  const handleWorldMatch = aetherwakeSrc.match(/function handleWorldInput\(\) \{([\s\S]*?)^\}/m);
  assert(handleWorldMatch, 'handleWorldInput function should exist');
  const body = handleWorldMatch[1];
  
  // Check that doMove is called when keyRepeat is first set (immediate move)
  const keyRepeatSection = body.substring(body.indexOf('if (!keyRepeat[code])'), body.indexOf('} else if'));
  assert(body.includes('doMove(code);'), 'doMove should be called in handleWorldInput');
  // The immediate move should happen right after setting keyRepeat
  const immediateMoveIdx = body.indexOf('doMove(code);');
  const keyRepeatSetIdx = body.indexOf('keyRepeat[code] = now;');
  assert(immediateMoveIdx > keyRepeatSetIdx, 'doMove should be called after keyRepeat is set');
});

// D7: Verify doTalk opens dialogue before setting met flag
test('D7: doTalk opens dialogue before setting met flag', () => {
  const doTalkMatch = aetherwakeSrc.match(/function doTalk\(\) \{([\s\S]*?)^\}/m);
  assert(doTalkMatch, 'doTalk function should exist');
  const body = doTalkMatch[1];
  
  const openDialogueIdx = body.indexOf('openDialogue(nearest);');
  const metFlagIdx = body.indexOf('nearest.flags.met = true;');
  
  assert(openDialogueIdx !== -1, 'openDialogue should be called in doTalk');
  assert(metFlagIdx !== -1, 'met flag should be set in doTalk');
  assert(openDialogueIdx < metFlagIdx, 
    'openDialogue must be called BEFORE setting met flag');
});

// D8: Verify nextDialogueLine and closeDialogue are exported via World
test('D8: nextDialogueLine and closeDialogue exported in World', () => {
  const worldExportMatch = aetherwakeSrc.match(/const World = \{([\s\S]*?)\};/m);
  assert(worldExportMatch, 'World export object should exist');
  const exports = worldExportMatch[1];
  
  assert(exports.includes('openDialogue'), 'openDialogue should be exported');
  assert(exports.includes('nextDialogueLine'), 'nextDialogueLine should be exported');
  assert(exports.includes('closeDialogue'), 'closeDialogue should be exported');
});

// D9: Verify openDialogue returns a structured result; core owns STATE.DIALOGUE
test('D9: openDialogue returns structured result; core owns state transition', () => {
  const openDialogueMatch = aetherwakeSrc.match(/function openDialogue\(npc\) \{([\\s\\S]*?)^\}/m);
  assert(openDialogueMatch, 'openDialogue function should exist');
  const body = openDialogueMatch[1];

  assert(body.includes('window.UI.dialogueOpen = true'),
    'openDialogue should prepare the dialogue UI state');
  assert(/return \{\\s*ok: true,\\s*kind: 'dialogue'/.test(body),
    'openDialogue should return a structured dialogue result');
  assert(!body.includes('gameState = STATE.DIALOGUE'),
    'openDialogue should not own the global state transition');

  const handleWorldMatch = aetherwakeSrc.match(/function handleWorldInput\(\) \{([\\s\\S]*?)^\}/m);
  assert(handleWorldMatch, 'handleWorldInput function should exist');
  assert(handleWorldMatch[1].includes('openState(STATE.DIALOGUE)'),
    'core should enter STATE.DIALOGUE after a successful interaction');
});

// D10: Verify M key routes through world.openShop() 
test('D10: M key routes through world.openShop() in handleWorldInput', () => {
  // Find the handleWorldInput function
  const handleWorldMatch = aetherwakeSrc.match(/function handleWorldInput\(\) \{([\s\S]*?)^\}/m);
  assert(handleWorldMatch, 'handleWorldInput function should exist');
  const body = handleWorldMatch[1];
  
  // Check for M key (77) handling
  const mKeyStart = body.indexOf('if (keysPressed[77])');
  assert(mKeyStart !== -1, 'M key handling should exist in handleWorldInput');
  
  // Extract the M key block - find the closing brace
  let depth = 0;
  let mKeyEnd = mKeyStart;
  let foundOpen = false;
  for (let i = mKeyStart; i < body.length; i++) {
    if (body[i] === '{') { depth++; foundOpen = true; }
    if (body[i] === '}') { depth--; if (foundOpen && depth === 0) { mKeyEnd = i; break; } }
  }
  const mKeyBlock = body.substring(mKeyStart, mKeyEnd + 1);
  
  assert(mKeyBlock.includes('world.openShop()') || mKeyBlock.includes('world && typeof world.openShop'), 
    'M key should call world.openShop()');
  // After fix, should NOT have direct openState(STATE.SHOP) without world.openShop() check
  const hasDirectOpenState = mKeyBlock.includes('openState(STATE.SHOP)') && 
    !mKeyBlock.includes('world.openShop()');
  assert(!hasDirectOpenState, 
    'M key should NOT directly call openState(STATE.SHOP) — should route through world.openShop()');
});

console.log('\nAll Cluster 2 regression tests passed!');
