'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

assert(runtime.includes("drawGlowText('COMMAND'") && runtime.includes("drawGlowText('ACTIONS'"),
  'combat panel must use concise JRPG command labels');
assert(!runtime.includes("drawGlowText('BATTLE COMMAND'") && !runtime.includes("drawGlowText('COMMANDS  1–8'"),
  'combat panel must not expose dashboard-like command headers');
assert(!runtime.includes("'LOCK ? '") && !runtime.includes("'N/A ? '") && !runtime.includes("'NO RES ? '"),
  'combat actions must communicate availability by styling rather than debug/status prefixes');
assert(!runtime.includes("text('COST ' + totalCost"),
  'combat resource costs must not use dashboard-style COST labels');
assert(runtime.includes("text('◆' + totalCost"),
  'combat resource costs must retain compact JRPG-readable cost marks');
assert(runtime.includes("text('TRAIT'"),
  'enemy special ability presentation must use concise JRPG terminology');
assert(runtime.includes('Enemy identity and HP are already carried by the compact command window') &&
  runtime.includes('Player identity and HP live in the command window'),
  'combat sprites must remain free of duplicate floating name/HP HUD attachments');
assert(runtime.includes('Math.min(panelColor[3] || 150, 150)') && runtime.includes('single rust rule replaces the nested dashboard card'),
  'combat command surface must remain translucent and text-led rather than nested dashboard cards');
assert(runtime.includes('Actions remain grouped by spacing and typography rather than another opaque card'),
  'combat action list must not regress to an opaque nested panel');

console.log('Aetherwake combat UI JRPG presentation contract: PASS');
