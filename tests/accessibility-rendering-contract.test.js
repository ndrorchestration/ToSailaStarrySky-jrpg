'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

function functionSlice(name) {
  const start = source.indexOf('function ' + name + '(');
  assert(start >= 0, name + ' is missing');
  let end = source.indexOf('\nfunction ', start + 10);
  if (end < 0) end = source.length;
  return source.slice(start, end);
}

assert(source.includes('function accessibilityTextScale()'),
  'text-scale renderer helper is missing');
assert(source.includes('function uiTextSize(baseSize)'),
  'scaled text-size adapter is missing');
assert(source.includes('function applyHighContrastPalette(enabled)'),
  'high-contrast palette adapter is missing');
assert(source.includes("VIS.vignette = !highContrast;"),
  'high contrast must remove vignette interference');
assert(functionSlice('drawScanlines').includes('if (window._highContrastUI) return;'),
  'high contrast must remove scanline interference');

for (const surface of [
  'drawTitleScreen',
  'drawSaveLoadOverlay',
  'drawSettingsOverlay',
  'drawControlsOverlay',
  'drawDialogueOverlay',
  'drawQuestLogOverlay',
  'drawCharSheetOverlay',
  'drawAirNavigationScene',
  'drawCombatPanel',
  'drawCombatLog',
  'drawFirstWakeOpening'
]) {
  assert(functionSlice(surface).includes('uiTextSize('),
    surface + ' does not consume the text-scale renderer');
}

const dialogue = functionSlice('drawDialogueOverlay');
assert(dialogue.includes('subtitleSizeMultiplier()'),
  'dialogue does not apply subtitle-size preference');
assert(dialogue.includes('subtitleBackgroundAlpha()'),
  'dialogue does not apply subtitle-background preference');
assert(dialogue.includes("userSettings.speakerLabels !== false"),
  'dialogue does not honor speaker-label preference');
assert(dialogue.includes('textLeading(16 * accessibilityTextScale() * subtitleSizeMultiplier())'),
  'dialogue line spacing does not scale with accessible text');

assert(source.includes('function maybeGamepadVibrate(kind)'),
  'controller-vibration adapter is missing');
assert(source.includes("userSettings.controllerVibration === 'off'"),
  'controller vibration must honor the off preference');
assert(source.includes("actuator.playEffect('dual-rumble', profile)"),
  'controller vibration must use the standard dual-rumble actuator when available');
assert(source.includes("maybeGamepadVibrate(gameState === STATE.COMBAT ? 'combat' : 'ui')"),
  'handled controller actions are not routed through the vibration preference');

assert(source.includes('PAL.NAVY =') &&
       source.includes('PAL.PARCHMENT =') &&
       source.includes('PAL.TEAL ='),
  'high contrast does not reach the PAL-backed combat/UI layer');

for (const field of [
  'textScale',
  'highContrastUI',
  'subtitleSize',
  'subtitleBackground',
  'speakerLabels',
  'controllerVibration'
]) {
  assert(source.includes(field + ': userSettings.' + field) ||
         source.includes(field + ': highContrast'),
    'applied accessibility snapshot is missing ' + field);
}

console.log('Aetherwake accessibility rendering contract: PASS');
