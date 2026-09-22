'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const contract = JSON.parse(fs.readFileSync(
  path.join(__dirname, '..', 'docs', 'input-accessibility-contract.json'),
  'utf8'
));

assert.strictEqual(contract.version, 1);
assert.strictEqual(contract.status, 'design-contract');
assert(Array.isArray(contract.requiredActions) && contract.requiredActions.length >= 15);
assert(Array.isArray(contract.settings) && contract.settings.length >= 10);

const actionIds = new Set();
for (const action of contract.requiredActions) {
  assert(action.id && !actionIds.has(action.id), 'duplicate/missing input action id: ' + action.id);
  actionIds.add(action.id);
  assert(Array.isArray(action.contexts) && action.contexts.length > 0,
    action.id + ' must declare contexts');
  assert(Array.isArray(action.keyboard) && action.keyboard.length > 0,
    action.id + ' must retain a keyboard path');
  assert(Array.isArray(action.gamepad) && action.gamepad.length > 0,
    action.id + ' must define a gamepad target');
  assert(action.remappable === true, action.id + ' must be remappable');
  if (action.singlePressDigital === false) {
    assert(typeof action.plannedAccessibleAlternative === 'string' &&
           action.plannedAccessibleAlternative.length > 0,
      action.id + ' needs a single-press accessible alternative');
  }
}

for (const id of [
  'ui-up','ui-down','ui-left','ui-right','confirm','cancel','open-settings',
  'move-up','move-down','move-left','move-right',
  'interact','quest-log','manual-save','manual-load',
  'airship-altitude-up','airship-altitude-down','airship-dock','airship-land'
]) {
  assert(actionIds.has(id), 'required semantic action missing: ' + id);
}

assert(contract.focusContract.deterministicDirectionalOrder === true);
assert(contract.focusContract.alwaysVisibleFocus === true);
assert(contract.focusContract.focusIndicatorMustNotUseColorAlone === true);
assert(contract.focusContract.restoreFocusOnClose === true);

const settingIds = new Set(contract.settings.map(setting => setting.id));
for (const id of [
  'text-scale','high-contrast-ui','reduced-motion','screen-shake',
  'subtitles','subtitle-size','subtitle-background','speaker-labels',
  'music-volume','effects-volume','dialogue-volume','text-speed'
]) {
  assert(settingIds.has(id), 'required accessibility setting missing: ' + id);
}

assert.strictEqual(contract.settingsPersistence.saveSlotsOwnSettings, false,
  'accessibility settings must not be owned by individual save slots');
assert(contract.settingsPersistence.migrationRequired === true,
  'settings persistence requires versioned migration ownership');

console.log('Aetherwake input/accessibility design contract: PASS');
