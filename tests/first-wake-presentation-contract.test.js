const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const runtime = fs.readFileSync(path.resolve(__dirname, '..', 'aetherwake.js'), 'utf8');

const titleStart = runtime.indexOf('function drawTitleScreen()');
const titleEnd = runtime.indexOf('function drawDialogueOverlay()', titleStart);
assert(titleStart >= 0 && titleEnd > titleStart, 'title screen block missing');
const title = runtime.slice(titleStart, titleEnd);
assert(title.includes("text('FIRST WAKE'"), 'title screen must identify First Wake');
assert(title.includes("text('START FIRST WAKE'"), 'title screen must present a clear primary action');
assert(title.includes('Aureate Wake silhouette') && title.includes('triangle('),
  'title must retain the authored ship silhouette composition');

const openingStart = runtime.indexOf('function drawFirstWakeOpening()');
const openingEnd = runtime.indexOf('// ── Open-sky flight ──', openingStart);
assert(openingStart >= 0 && openingEnd > openingStart, 'opening renderer missing');
const opening = runtime.slice(openingStart, openingEnd);
assert(opening.includes('Layered dawn sky') && opening.includes('Cloud-sea / lower reach'),
  'opening must establish sky and reach depth rather than a flat field');
assert(opening.includes('FIRST WAKE  //  ') && opening.includes("' / 10'"),
  'opening must expose scene pacing within First Wake');
assert(opening.includes('Stable footer separates status/instruction'),
  'opening status and controls must remain separated from narrative copy');

const toastStart = runtime.indexOf('function drawToasts()');
const toastEnd = runtime.indexOf('// ── Fade overlay', toastStart);
const toast = runtime.slice(toastStart, toastEnd);
assert(toast.includes('gameState === STATE.DIALOGUE ? 92 : height - 104'),
  'toasts must avoid dialogue and chapter-banner collision zones');
assert(toast.includes('Math.min(420, Math.max(250, textWidth(t.text) + 36))'),
  'toast background must size to readable content');

const questStart = runtime.indexOf('function drawQuestOverlay()');
const questEnd = runtime.indexOf('function drawEpilogueScreen()', questStart);
const quest = runtime.slice(questStart, questEnd);
assert(quest.includes("text('ACTIVE CREW'"), 'world context rail must expose active crew');
assert(quest.includes("text('FIRST WAKE // CHAPTER I'"),
  'world context rail must retain chapter identity');
assert(quest.includes('T QUEST LOG') && quest.includes('F AIRSHIP'),
  'world context rail must surface the next useful controls');

assert(runtime.includes('window.UI.combatLog.length > 0'),
  'empty combat log must not cover the encounter stage');
assert(runtime.includes('drawCombatLog(width - 222, height - 206, 206, 190)'),
  'non-empty combat log must stay below the enemy presentation');

console.log('Aetherwake Chapter I presentation contract: PASS');
