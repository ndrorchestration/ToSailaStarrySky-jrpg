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
const portraitStart = runtime.indexOf('function drawDialoguePortrait(');
const portraitEnd = runtime.indexOf('function drawDialogueOverlay()', portraitStart);
assert(portraitStart >= 0 && portraitEnd > portraitStart,
  'dialogue portrait renderer boundary missing');
const portrait = runtime.slice(portraitStart, portraitEnd);
assert(portrait.includes('const scale = Math.max(1, Math.floor(size / 16));') &&
       portrait.includes("anchor: 'bottom-center'") &&
       /sprites\.draw\([\s\S]*?\bscale\s*\n?\s*\}\);/.test(portrait),
  'dialogue portrait must use integer-scaled shared sprite authority');
assert(runtime.includes('const dialogueLayout = uiVisual'),
  'dialogue must resolve shared UI layout before panel geometry');
assert(runtime.includes('const bw = dialogueLayout.w') && runtime.includes('const bh = dialogueLayout.h'),
  'dialogue panel dimensions must come from shared UI layout authority');
assert(runtime.includes('wrapText(window.UI.dialogueText'),
  'dialogue text flow must remain live');
assert(runtime.includes("text('E / ENTER   Continue'"),
  'dialogue continue interaction cue missing');

assert(runtime.includes('layoutDialogue(width, height)'),
  'dialogue overlay must use shared UI layout authority');
assert(runtime.includes('uiVisual.panelRGBA'),
  'dialogue overlay must use shared UI panel token');

console.log('Aetherwake representative dialogue visual gate: PASS');
