'use strict';

const assert = require('assert');

global.window = global;
global.AetherInputActions = require('../modules/input-actions.js');
const bindings = require('../modules/input-bindings.js');

let state = bindings.emptyState();
assert.strictEqual(bindings.validateState(state), true);
assert.strictEqual(bindings.keyboardLabel(state, 'interact', 'world'), 'E');
assert.strictEqual(bindings.gamepadLabel(state, 'interact'), 'A / SOUTH');

assert.strictEqual(bindings.keyboardLabel(state, 'covenant-field', 'world'), 'Q');
assert.strictEqual(bindings.keyboardLabel(state, 'toggle-layer', 'world'), 'TAB');
assert.strictEqual(bindings.keyboardLabel(state, 'shop', 'world'), 'M');
assert.strictEqual(bindings.gamepadLabel(state, 'covenant-field'), 'LS');
assert.strictEqual(bindings.gamepadLabel(state, 'toggle-layer'), 'VIEW');
assert.strictEqual(bindings.gamepadLabel(state, 'shop'), 'RS');


assert.deepStrictEqual(
  bindings.keyboardActionsForEvent({ keyCode: 69 }, 'world', state),
  ['interact']
);

state = bindings.setKeyboardBinding(state, 'interact', 74); // J
assert.deepStrictEqual(
  bindings.keyboardActionsForEvent({ keyCode: 69 }, 'world', state),
  [],
  'old keyboard binding must be replaced after remap'
);
assert.deepStrictEqual(
  bindings.keyboardActionsForEvent({ keyCode: 74 }, 'world', state),
  ['interact']
);
assert.strictEqual(bindings.keyboardLabel(state, 'interact', 'world'), 'J');

assert.throws(
  () => bindings.setKeyboardBinding(state, 'quest-log', 74),
  /INPUT_BINDINGS_CONFLICT_KEYBOARD:interact/,
  'same-context keyboard conflicts must fail closed'
);

state = bindings.setGamepadBinding(state, 'quest-log', 8);
assert.strictEqual(bindings.gamepadLabel(state, 'quest-log'), 'VIEW');
assert.strictEqual(
  bindings.resolveGamepadButtonAction(state, 8, 'world', null),
  'quest-log'
);
assert.strictEqual(
  bindings.resolveGamepadButtonAction(state, 3, 'world', 'quest-log'),
  null,
  'old gamepad button must be suppressed after remap'
);

assert.throws(
  () => bindings.setGamepadBinding(state, 'ledger', 8),
  /INPUT_BINDINGS_CONFLICT_GAMEPAD:quest-log/,
  'same-context gamepad conflicts must fail closed'
);


let utilityState = bindings.emptyState();
utilityState = bindings.setKeyboardBinding(utilityState, 'shop', 75); // K
assert.deepStrictEqual(
  bindings.keyboardActionsForEvent({ keyCode: 77 }, 'world', utilityState),
  [],
  'old M shop binding must be suppressed after remap'
);
assert.deepStrictEqual(
  bindings.keyboardActionsForEvent({ keyCode: 75 }, 'world', utilityState),
  ['shop'],
  'remapped shop key must emit shop'
);
utilityState = bindings.setGamepadBinding(utilityState, 'toggle-layer', 6);
assert.strictEqual(
  bindings.resolveGamepadButtonAction(utilityState, 8, 'world', 'toggle-layer'),
  null,
  'old VIEW layer binding must be suppressed after remap'
);
assert.strictEqual(
  bindings.resolveGamepadButtonAction(utilityState, 6, 'world', null),
  'toggle-layer',
  'remapped gamepad layer button must emit toggle-layer'
);

// Context-prioritized default overlaps remain valid.
const defaults = bindings.emptyState();
assert.strictEqual(bindings.conflictForGamepad(defaults, 'interact', 0), null);
assert.strictEqual(bindings.conflictForGamepad(defaults, 'airship-dock', 0), null);

const reset = bindings.resetAction(state, 'interact', 'keyboard');
assert.strictEqual(bindings.keyboardLabel(reset, 'interact', 'world'), 'E');

const memory = new Map();
global.localStorage = {
  getItem(key) { return memory.has(key) ? memory.get(key) : null; },
  setItem(key, value) { memory.set(key, String(value)); },
  removeItem(key) { memory.delete(key); }
};
const saved = bindings.save(state);
assert.strictEqual(saved.storageType, 'localStorage');
const loaded = bindings.load();
assert.deepStrictEqual(loaded.bindings, state,
  'persisted input bindings must round-trip independently from game saves/settings');

const ambiguous = bindings.emptyState();
ambiguous.keyboardOverrides.interact = 84; // collides with quest-log in WORLD.
assert.throws(
  () => bindings.validateState(ambiguous),
  /INPUT_BINDINGS_CONFLICT_KEYBOARD/,
  'ambiguous persisted bindings must fail closed during validation'
);

console.log('Aetherwake input binding persistence/remap contract: PASS');
