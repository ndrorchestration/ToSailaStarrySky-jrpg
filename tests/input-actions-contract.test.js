'use strict';

const assert = require('assert');
const input = require('../modules/input-actions.js');

assert.strictEqual(input.VERSION, '0.1.0');
assert.strictEqual(input.validate(), true);

assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 84 }, 'world'),
  ['quest-log'],
  'T must map to quest-log in WORLD'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 83 }, 'boot'),
  ['open-settings'],
  'S must open Settings directly from BOOT'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 83 }, 'menu'),
  ['open-settings'],
  'S must open Settings from the title menu'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 38 }, 'settings'),
  ['ui-up'],
  'Settings must share semantic UI navigation'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 116 }, 'world'),
  ['manual-save'],
  'F5 must map to manual-save in WORLD'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 117 }, 'world'),
  ['open-save-load'],
  'F6 must open the focused Save/Load UI in WORLD'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 117 }, 'airship'),
  ['open-save-load'],
  'F6 must open the focused Save/Load UI in AIRSHIP'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 116 }, 'combat'),
  [],
  'F5 must not map to manual-save in COMBAT'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 69 }, 'world'),
  ['interact'],
  'E must map to interact in WORLD'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 69 }, 'dialogue'),
  ['interact'],
  'E must preserve dialogue advance semantics'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 69 }, 'airship'),
  ['airship-altitude-up'],
  'E must map to altitude-up in AIRSHIP'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 68 }, 'world'),
  ['move-right'],
  'D must remain WORLD move-right'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 68 }, 'airship'),
  ['airship-dock'],
  'D must be AIRSHIP dock and must not also steer right'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 39 }, 'airship'),
  ['move-right'],
  'AIRSHIP right-arrow must steer right'
);
assert.deepStrictEqual(
  input.actionsForKeyboardEvent({ keyCode: 27 }, 'dialogue'),
  ['cancel'],
  'Escape must retain global cancel semantics'
);

const worldUp = input.actionsForKeyboardEvent({ keyCode: 38 }, 'world');
assert(worldUp.includes('move-up'), 'ArrowUp must map to move-up in WORLD');
assert(!worldUp.includes('ui-up'), 'WORLD movement must not also emit menu ui-up');

assert.strictEqual(input.normalizeContext('saveload'), 'save-load');
assert.strictEqual(input.normalizeContext('questlog'), 'menu');

console.log('Aetherwake semantic input actions: PASS');
