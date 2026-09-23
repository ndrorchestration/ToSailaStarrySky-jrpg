'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
const html = fs.readFileSync(path.join(__dirname, '..', 'index-embedded.html'), 'utf8');

assert(html.includes('modules/user-settings.js'),
  'user settings persistence module must load in the runtime');
assert(html.indexOf('modules/user-settings.js') < html.indexOf('aetherwake.js'),
  'user settings module must load before the runtime');
assert(html.includes('modules/input-bindings.js') &&
       html.indexOf('modules/input-bindings.js') < html.indexOf('aetherwake.js'),
  'input binding persistence authority must load before the runtime');
assert(html.includes('modules/music-bus.js') &&
       html.indexOf('modules/music-bus.js') < html.indexOf('aetherwake.js'),
  'canonical music bus must load before the runtime');

assert(runtime.includes("SETTINGS: 'settings'"),
  'runtime Settings state is missing');
assert(runtime.includes("inputPrompt('open-settings', 'menu', 'both')"),
  'title screen must expose the live Settings binding before gameplay');
assert(runtime.includes("semanticActionPressed('open-settings')"),
  'title Settings entry must use semantic input');
assert(runtime.includes('function openUserSettingsMenu('),
  'runtime Settings opener is missing');
assert(runtime.includes('function handleSettingsInput()'),
  'runtime Settings semantic input handler is missing');
assert(runtime.includes('function drawSettingsOverlay()'),
  'runtime Settings UI renderer is missing');
assert(runtime.includes('window.AetherFocusManager.createState(items'),
  'Settings UI must use the shared focus manager');
assert(runtime.includes("'▶ '"),
  'Settings focus must not rely on color alone');
assert(runtime.includes('window.AetherUserSettings.save(nextSettings)'),
  'Settings changes must persist through the independent settings store');
assert(runtime.includes('Changes save immediately. Accessibility/input/audio changes apply now; music playback remains silent until a packaged track is registered.'),
  'Settings UI must state the current integration boundary');
assert(runtime.includes("window.AetherUserSettings.SETTING_ORDER.concat(['__controls'])"),
  'Settings must expose the Controls remapping entry without changing the settings schema');
assert(runtime.includes('function openControlsMenu(') &&
       runtime.includes('function drawControlsOverlay()'),
  'Settings must route to a dedicated controls remapping surface');

assert(runtime.includes('VIS.screenShake = !reduceMotion'),
  'screen-shake preference must apply to the current runtime hook');
assert(runtime.includes('VIS.fadeTransitions = !reduceMotion'),
  'reduced-motion preference must disable fade transitions');
assert(runtime.includes('dialogueTypeIn.speed = textSpeeds[userSettings.textSpeed]'),
  'text-speed preference must apply to dialogue type-in timing');

assert(runtime.includes('window.setEffectsVolumePercent(userSettings.effectsVolume)'),
  'Effects volume must apply through the authored SFX master-gain adapter');
assert(runtime.includes('window.AetherMusicBus.setVolumePercent(userSettings.musicVolume)'),
  'Music volume must apply through the canonical music bus');
assert(runtime.includes('_dialogueAudioEl.volume = 0.92 * (dialogueVolume / 100)'),
  'Dialogue volume must scale the authored TTS element level');

console.log('Aetherwake Settings runtime contract: PASS');

assert(runtime.includes('recoveredFromBackup: Boolean(loaded.recoveredFromBackup)'),
  'runtime must preserve user-settings backup recovery provenance');
assert(runtime.includes('futureSchemaProtected: Boolean(loaded.futureSchemaProtected)'),
  'runtime must expose newer-schema settings protection state');

assert(runtime.includes('window._userSettingsStorage.recoveredFromBackup'),
  'settings writes must preserve validated backup after recovery');
