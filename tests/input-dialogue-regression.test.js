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
// D9: openDialogue returns a structured result; core owns STATE.DIALOGUE
// D10: Contextual JRPG OK is the primary shop/interaction path

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

  const firstRepeatIdx = body.indexOf('if (!keyRepeat[repeatCode])');
  const repeatSetIdx = body.indexOf('keyRepeat[repeatCode] = now;', firstRepeatIdx);
  const immediateMoveIdx = body.indexOf('world.movePlayer(dir.dx, dir.dy);', repeatSetIdx);
  assert(firstRepeatIdx !== -1 && repeatSetIdx > firstRepeatIdx,
    'first movement repeat state should initialize on keydown');
  assert(immediateMoveIdx > repeatSetIdx,
    'first directional press should move immediately after repeat initialization');
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
  const openDialogueMatch = aetherwakeSrc.match(/function openDialogue\(npc\) \{([\s\S]*?)^\}/m);
  assert(openDialogueMatch, 'openDialogue function should exist');
  const body = openDialogueMatch[1];

  assert(body.includes('window.UI.dialogueOpen = true'),
    'openDialogue should prepare the dialogue UI state');
  assert(/return \{\s*ok: true,\s*kind: 'dialogue'/.test(body),
    'openDialogue should return a structured dialogue result');
  assert(!body.includes('gameState = STATE.DIALOGUE'),
    'openDialogue should not own the global state transition');

  const handleWorldMatch = aetherwakeSrc.match(/function handleWorldInput\(\) \{([\s\S]*?)^\}/m);
  assert(handleWorldMatch, 'handleWorldInput function should exist');
  assert(handleWorldMatch[1].includes('openState(STATE.DIALOGUE)'),
    'core should enter STATE.DIALOGUE after a successful interaction');
});

test('D9b: contextual OK boards the airship through the World contract', () => {
  const boardMatch = aetherwakeSrc.match(/function boardShip\(\) \{([\s\S]*?)^\}/m);
  assert(boardMatch, 'boardShip function should exist');
  const boardBody = boardMatch[1];

  assert(boardBody.includes("return { ok: false, kind: 'airship'"),
    'boardShip should return structured failure results');
  assert(boardBody.includes("return { ok: true, kind: 'airship' }"),
    'boardShip should return a structured success result');
  assert(!boardBody.includes('openState(STATE.AIRSHIP)'),
    'World.boardShip must not own the global AIRSHIP transition');

  const handleWorldMatch = aetherwakeSrc.match(/function handleWorldInput\(\) \{([\s\S]*?)^\}/m);
  assert(handleWorldMatch, 'handleWorldInput function should exist');
  const inputBody = handleWorldMatch[1];

  assert(inputBody.includes('inputPressed(api.ACTION.OK)'),
    'world interaction should be reachable from semantic OK');
  assert(inputBody.includes('const result = world.interact();'),
    'semantic OK should route through World.interact()');
  assert(inputBody.includes("result.kind === 'airship'") &&
    inputBody.includes('openState(STATE.AIRSHIP)'),
    'core should own AIRSHIP transition after contextual interaction');
});

test('D9c: dialogue typewriter cannot freeze after an empty first frame', () => {
  const typeInRender = aetherwakeSrc.match(/if \(dialogueTypeIn\.active && gameState === STATE\.DIALOGUE\) \{([\s\S]*?)\n  \}/);
  assert(typeInRender, 'dialogue type-in render block should exist');
  const body = typeInRender[1];

  assert(body.includes('window.UI.dialogueText = dialogueTypeIn.displayText'),
    'active typewriter should always publish its displayText');
  assert(!body.includes('if (window.UI.dialogueText)'),
    'typewriter must not stop updating when its first displayed frame is empty');
});

// D9d: semantic Cancel dismisses dialogue while OK/E advances it.
test('D9d: dialogue Cancel closes while OK/E advances', () => {
  const handleInputMatch = aetherwakeSrc.match(/function handleInput\(\) \{([\s\S]*?)^\}/m);
  assert(handleInputMatch, 'handleInput function should exist');
  const body = handleInputMatch[1];
  const dialogueStart = body.indexOf('if (gameState === STATE.DIALOGUE)');
  const shopStart = body.indexOf('if (gameState === STATE.SHOP)', dialogueStart);
  assert(dialogueStart !== -1 && shopStart > dialogueStart,
    'dialogue input block should exist');
  const dialogueBlock = body.substring(dialogueStart, shopStart);

  const cancelIdx = dialogueBlock.indexOf('if (cancel)');
  const closeIdx = dialogueBlock.indexOf('closeOverlay();', cancelIdx);
  const advanceIdx = dialogueBlock.indexOf('if (ok || keysPressed[69])');
  const nextLineIdx = dialogueBlock.indexOf('world.nextDialogueLine()', advanceIdx);

  assert(cancelIdx !== -1 && closeIdx > cancelIdx,
    'Cancel should dismiss dialogue through closeOverlay');
  assert(advanceIdx > closeIdx,
    'OK/E advance handling should be separate from Cancel');
  assert(nextLineIdx > advanceIdx,
    'OK/E should advance through World.nextDialogueLine');
});

// D10: Verify shop access uses contextual World interaction as the primary path.
test('D10: contextual OK can open shop through World interaction', () => {
  const handleWorldMatch = aetherwakeSrc.match(/function handleWorldInput\(\) \{([\s\S]*?)^\}/m);
  assert(handleWorldMatch, 'handleWorldInput function should exist');
  const body = handleWorldMatch[1];

  assert(body.includes('inputPressed(api.ACTION.OK)'),
    'semantic OK handling should exist in WORLD');
  assert(body.includes('const result = world.interact();'),
    'semantic OK should call World.interact()');
  assert(body.includes("result.kind === 'shop'") &&
    body.includes('openState(STATE.SHOP)'),
    'contextual shop interaction should route through the core state transition');

  const mKeyStart = body.indexOf('if (keysPressed[77]');
  assert(mKeyStart !== -1, 'legacy M compatibility alias should still exist during migration');
  const mBlock = body.slice(mKeyStart, body.indexOf('if (keysPressed[86]', mKeyStart));
  assert(mBlock.includes('world.openShop()'),
    'legacy M alias must still respect the World shop contract');
});

// D11: Optional prerecorded dialogue TTS must not request absent assets by default
test('D11: prerecorded dialogue TTS is opt-in', () => {
  assert(aetherwakeSrc.includes('window.AETHER_DIALOGUE_TTS_ENABLED = false'),
    'dialogue TTS should default to disabled when the voice asset pack is absent');

  const playMatch = aetherwakeSrc.match(/function playDialogueAudioLine\(\) \{([\s\S]*?)^\}/m);
  assert(playMatch, 'playDialogueAudioLine should exist');
  const body = playMatch[1];
  const guardIdx = body.indexOf('window.AETHER_DIALOGUE_TTS_ENABLED !== true');
  const srcIdx = body.indexOf("const src = 'tts/'");

  assert(guardIdx !== -1, 'dialogue audio should have an explicit opt-in guard');
  assert(srcIdx !== -1 && guardIdx < srcIdx,
    'dialogue TTS guard must run before constructing/requesting an MP3 resource');
});

console.log('\nAll Cluster 2 regression tests passed!');
