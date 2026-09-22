'use strict';

const assert = require('assert');
global.window = global;
global.AetherInputActions = require('../modules/input-actions.js');
const bindings = require('../modules/input-bindings.js');
const pad = require('../modules/gamepad-input.js');

function gamepad(buttonIndexes, axes, mapping) {
  const buttons = Array.from({ length: 17 }, (_, index) => ({
    pressed: buttonIndexes.includes(index),
    value: buttonIndexes.includes(index) ? 1 : 0
  }));
  return {
    index: 0,
    id: 'Test Standard Pad',
    connected: true,
    mapping: mapping == null ? 'standard' : mapping,
    buttons,
    axes: axes || [0,0,0,0]
  };
}

let state = pad.createState();
let result = pad.poll(gamepad([pad.BUTTON.MENU]), state, 'boot');
assert.deepStrictEqual(result.pressed, ['open-settings']);

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.SOUTH]), state, 'opening');
assert.deepStrictEqual(result.pressed, ['confirm']);

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.SOUTH]), state, 'menu');
assert.deepStrictEqual(result.pressed, ['confirm']);

result = pad.poll(gamepad([pad.BUTTON.SOUTH]), state, 'menu');
assert.deepStrictEqual(result.pressed, [], 'held buttons must not repeat as edge presses');

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.SOUTH]), state, 'world');
assert.deepStrictEqual(result.pressed, ['interact']);


state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.LEFT_STICK]), state, 'world');
assert.deepStrictEqual(result.pressed, ['covenant-field'],
  'Left stick press must expose covenant-field in WORLD');

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.VIEW]), state, 'world');
assert.deepStrictEqual(result.pressed, ['toggle-layer'],
  'View must expose layer toggle in WORLD');

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.RIGHT_STICK]), state, 'world');
assert.deepStrictEqual(result.pressed, ['shop'],
  'Right stick press must expose Shop in WORLD');

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.MENU]), state, 'world');
assert.deepStrictEqual(result.pressed, ['open-save-load'],
  'Menu must open Save/Load from WORLD');

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.MENU]), state, 'airship');
assert.deepStrictEqual(result.pressed, ['open-save-load'],
  'Menu must open Save/Load from AIRSHIP');

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.SOUTH]), state, 'world', { wakeResolution: true });
assert.deepStrictEqual(result.pressed, ['confirm'],
  'WAKE substate must prioritize confirm over ordinary world interact');

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.SOUTH, pad.BUTTON.EAST]), state, 'airship');
assert(result.pressed.includes('airship-dock'));
assert(result.pressed.includes('airship-land'));
assert(!result.pressed.includes('confirm'));
assert(!result.pressed.includes('cancel'));

state = pad.createState();
result = pad.poll(gamepad([], [0.8, -0.8, 0, 0]), state, 'world');
assert(result.held.includes('move-right'));
assert(result.held.includes('move-up'));

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.DPAD_DOWN]), state, 'save-load');
assert(result.pressed.includes('ui-down'));
assert(result.held.includes('ui-down'));

let bindingState = bindings.emptyState();
bindingState = bindings.setGamepadBinding(bindingState, 'quest-log', pad.BUTTON.VIEW);
state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.NORTH]), state, 'world', {
  bindingsSystem: bindings,
  bindings: bindingState
});
assert.deepStrictEqual(result.pressed, [],
  'old default controller button must be suppressed after a remap');
assert.deepStrictEqual(result.rawPressedButtons, [pad.BUTTON.NORTH],
  'adapter must preserve raw button edges for remap capture');

state = pad.createState();
result = pad.poll(gamepad([pad.BUTTON.VIEW]), state, 'world', {
  bindingsSystem: bindings,
  bindings: bindingState
});
assert.deepStrictEqual(result.pressed, ['quest-log'],
  'remapped controller button must emit the semantic action');

state = pad.createState();
result = pad.poll(gamepad([], [0,0,0,0], 'raw'), state, 'menu');
assert.strictEqual(result.supported, false);
assert.strictEqual(result.reason, 'non-standard-mapping');

console.log('Aetherwake standard gamepad adapter: PASS');
