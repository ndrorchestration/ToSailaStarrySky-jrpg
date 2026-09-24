'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

const start = runtime.indexOf('function drawCharSheet(px, py, pw, ph)');
const end = runtime.indexOf('function drawWorldHUD()', start);
assert(start >= 0 && end > start, 'canonical character sheet renderer missing');
const sheet = runtime.slice(start, end);

assert(sheet.includes('const livePlayer = world && world.player ? world.player : null;'),
  'character sheet must read the live player');
assert(sheet.includes('livePlayer.productionStats'),
  'character sheet must read production stats');
for (const stat of ['wits','presence','spirit','might','grace']) {
  assert(sheet.includes('production.' + stat),
    'character sheet must render production stat: ' + stat);
}
assert(sheet.includes('const gy = sheet.gearY + 22 + i * 42;'),
  'gear rows must calculate their own y-coordinate');
assert(sheet.includes('abilitiesY: py + 220') && sheet.includes('resourcesY: py + 360'),
  'character sheet must leave room for all production stats before abilities/resources');
for (const liveResource of ['liveAether','liveAetherMax','liveHeat','liveHeatMax','liveCharge']) {
  assert(sheet.includes(liveResource),
    'character sheet must render live resource state: ' + liveResource);
}
assert(!sheet.includes('Mycelial tattoos'),
  'Ender portrait fallback must not retain superseded tattoo prototype');
assert(!sheet.includes('Trimmed beard'),
  'Ender portrait fallback must not retain superseded beard prototype');
assert(sheet.includes('copper hair') && sheet.includes('Brass goggles'),
  'Ender portrait fallback must match current visual canon');

assert(!runtime.includes("text('ENDER — Rift Scholar', px + 20, py + 24);"),
  'character-sheet fallback must not hard-code a stale class label');


const hudStart = runtime.indexOf('function drawWorldHUD()');
const hudEnd = runtime.indexOf('// ─────────────────────────────────────────────\n// COMBAT UI PANEL', hudStart);
assert(hudStart >= 0 && hudEnd > hudStart, 'compact world HUD renderer missing');
const hud = runtime.slice(hudStart, hudEnd);
for (const liveField of ['livePlayer','liveEchoes','liveAether','liveHeat','world.getQuestState']) {
  assert(hud.includes(liveField), 'compact HUD must use live state: ' + liveField);
}
assert(hud.includes("qs.state === 'signal'") &&
       hud.includes("qs.state === 'crossing'") &&
       hud.includes("qs.state === 'contact'"),
  'compact HUD must render live Chapter 1 quest progress');
assert(!hud.includes("text('Rift Scholar  Lv.1'"),
  'compact HUD must not hard-code Ender class/level');
assert(!hud.includes("text('Signal 0/3'"),
  'compact HUD must not hard-code initial quest progress');

console.log('Aetherwake Chapter 1 character-sheet presentation: PASS');
