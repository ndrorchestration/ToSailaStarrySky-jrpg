'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

assert(runtime.includes('function getDialogueSpriteId(npc)'),
  'dialogue sprite resolver missing');
assert(runtime.includes("npc.id === 'elder_farmer'") && runtime.includes("return 'ionia'"),
  'Ionia dialogue portrait binding missing');
assert(runtime.includes("npc.id === 'child_prophet'") && runtime.includes("return 'lyra'"),
  'Lyra dialogue portrait binding missing');
assert(runtime.includes("return 'engineSpirit'"),
  'Core dialogue portrait binding missing');
assert(runtime.includes("return 'corporateSalvager'"),
  'Verrick dialogue portrait binding missing');
assert(runtime.includes('function drawDialoguePortrait('),
  'dialogue portrait renderer missing');
assert(runtime.includes('const scale = Math.max(1, Math.floor(size / 16));') &&
       runtime.includes("anchor: 'bottom-center'") &&
       runtime.includes('    scale\n  });'),
  'dialogue portrait must use integer-scaled shared sprite authority');
assert(runtime.includes('const bw = Math.min(820, width - 64)'),
  'cinematic dialogue stage width contract missing');
assert(runtime.includes('const bh = 126'),
  'cinematic dialogue stage height contract missing');
assert(runtime.includes('wrapText(window.UI.dialogueText'),
  'dialogue text flow must remain live');
assert(runtime.includes("text('E / ENTER  CONTINUE'"),
  'dialogue continue interaction cue missing');

console.log('Aetherwake representative dialogue visual gate: PASS');
