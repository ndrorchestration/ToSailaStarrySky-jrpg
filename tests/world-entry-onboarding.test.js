'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

assert(runtime.includes("showToast('T // QUEST LOG   E // TALK   R // CHARACTER'"),
  'world-entry controls onboarding missing');
assert(runtime.includes("FOLLOW THE TEAL SIGNAL MARKERS // FIND 3 HOOKS"),
  'world-entry first objective onboarding missing');
assert(runtime.includes("if (keysPressed[84])"),
  'T quest-log input binding missing');
assert(runtime.includes('openState(STATE.QUESTLOG)'),
  'T key must route to quest log overlay');
assert(runtime.includes('function drawQuestLogOverlay()'),
  'quest log overlay renderer missing');

console.log('Aetherwake world-entry onboarding contract: PASS');
