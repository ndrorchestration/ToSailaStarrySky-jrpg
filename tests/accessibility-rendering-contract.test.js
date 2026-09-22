'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

function sliceFunction(name, nextName) {
  const start = source.indexOf('function ' + name + '(');
  assert(start >= 0, name + ' missing');
  const end = nextName
    ? source.indexOf('function ' + nextName + '(', start + 1)
    : source.length;
  return source.slice(start, end > start ? end : source.length);
}

assert(source.includes('function accessibilityTextScale()'),
  'text-scale policy helper missing');
assert(source.includes('Math.max(1, Math.min(1.75, parsed / 100))'),
  'text scale must clamp to the supported 100–175% range');
assert(source.includes('function uiTextSize(baseSize)'),
  'scaled text-size adapter missing');

for (const fn of [
  'drawTitleScreen',
  'drawSaveLoadOverlay',
  'drawSettingsOverlay',
  'drawControlsOverlay',
  'drawDialogueOverlay'
]) {
  const start = source.indexOf('function ' + fn + '(');
  assert(start >= 0, fn + ' missing');
  const body = source.slice(start, source.indexOf('\nfunction ', start + 10) > start
    ? source.indexOf('\nfunction ', start + 10)
    : source.length);
  assert(body.includes('uiTextSize('),
    fn + ' must consume the shared text-scale adapter');
}

assert(source.includes('function applyHighContrastPalette(enabled)'),
  'high-contrast palette adapter missing');
assert(source.includes('restorePalette();'),
  'high-contrast toggle must restore the baseline palette before applying overrides');
assert(source.includes('VIS.vignette = !highContrast'),
  'high contrast must suppress the vignette that reduces edge contrast');
assert(source.includes("PAL.NAVY = '#05060A'") &&
       source.includes("PAL.PARCHMENT = '#FFFFFF'"),
  'combat/UI high-contrast palette overrides missing');

assert(source.includes('function subtitleSizeMultiplier()'),
  'subtitle-size helper missing');
assert(source.includes('function subtitleBackgroundAlpha()'),
  'subtitle-background helper missing');
assert(source.includes('function dialogueCaptionVisible()'),
  'caption visibility policy missing');
assert(source.includes('window.UI && window.UI.dialogueAudioAvailable === true ? false : true'),
  'Subtitles Off must fail closed to visible text unless playable TTS is positively established');

const dialogue = sliceFunction('drawDialogueOverlay', 'drawShopOverlay');
assert(dialogue.includes('subtitleSizeMultiplier()'),
  'dialogue renderer must apply subtitle size');
assert(dialogue.includes('subtitleBackgroundAlpha()'),
  'dialogue renderer must apply subtitle background');
assert(dialogue.includes("userSettings.speakerLabels !== false"),
  'dialogue renderer must honor speaker-label preference');
assert(dialogue.includes('if (captionVisible)'),
  'dialogue text must be conditioned through the caption visibility policy');

assert(source.includes('window.UI.dialogueAudioAvailable = false;'),
  'optional TTS path must publish unavailable state');
assert(source.includes('window.UI.dialogueAudioAvailable = true;'),
  'playable TTS path must publish available state');

assert(source.includes('function maybeGamepadVibrate(kind)'),
  'controller vibration adapter missing');
assert(source.includes("userSettings.controllerVibration === 'off'"),
  'vibration Off setting must short-circuit');
assert(source.includes("actuator.playEffect('dual-rumble', profile)"),
  'vibration must use supported actuator effect when available');
assert(source.includes('return false;'),
  'vibration path must degrade without throwing when hardware is unavailable');
assert(source.includes("maybeGamepadVibrate(gameState === STATE.COMBAT ? 'combat' : 'ui')"),
  'successful gamepad dispatch must feed the vibration adapter');

assert(source.includes('textScale: userSettings.textScale') &&
       source.includes('highContrastUI: highContrast') &&
       source.includes('subtitles: userSettings.subtitles') &&
       source.includes('controllerVibration: userSettings.controllerVibration'),
  'applied accessibility diagnostics must expose rendering settings');

console.log('Aetherwake accessibility rendering contract: PASS');
