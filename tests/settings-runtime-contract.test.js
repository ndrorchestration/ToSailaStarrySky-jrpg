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

assert(runtime.includes("SETTINGS: 'settings'"),
  'runtime Settings state is missing');
assert(runtime.includes("text('SETTINGS — S'"),
  'title screen must expose Settings before gameplay');
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
assert(runtime.includes('Changes save immediately. Integrated now: reduced motion, screen shake, text speed.'),
  'Settings UI must state the current integration boundary');

assert(runtime.includes('VIS.screenShake = !reduceMotion'),
  'screen-shake preference must apply to the current runtime hook');
assert(runtime.includes('VIS.fadeTransitions = !reduceMotion'),
  'reduced-motion preference must disable fade transitions');
assert(runtime.includes('dialogueTypeIn.speed = textSpeeds[userSettings.textSpeed]'),
  'text-speed preference must apply to dialogue type-in timing');

console.log('Aetherwake Settings runtime contract: PASS');
