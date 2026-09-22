'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

assert(runtime.includes('function drawWakeResolutionScreen()'),
  'WAKE resolution screen missing');
assert(runtime.includes("text('THE WAKE ANSWERS'"),
  'WAKE transition title missing');
assert(runtime.includes('ENTER / SPACE — SEE THE CONSEQUENCE'),
  'WAKE transition input cue missing');
assert(runtime.includes("currentQuest.state === 'wake'"),
  'world input must detect WAKE state');
assert(runtime.includes('keysPressed[13] || keysPressed[32]'),
  'WAKE transition must accept Enter/Space');
assert(runtime.includes("typeof world.advanceQuest === 'function'"),
  'WAKE transition must route through quest authority');
assert(runtime.includes('  advanceQuest,\n  getQuestState,'),
  'world public API must expose advanceQuest for deterministic WAKE progression');
assert(runtime.includes('if (quest.state === QUEST_STATES.WAKE)'),
  'quest overlay must render WAKE transition before standard HUD');

console.log('Aetherwake WAKE transition pacing contract: PASS');
