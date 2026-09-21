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

  // M remains a compatibility alias, but it must still respect World.openShop().
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
