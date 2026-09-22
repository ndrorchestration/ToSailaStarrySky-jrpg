'use strict';

const assert = require('assert');
const focus = require('../modules/focus-manager.js');

const state = focus.createState(['manual-1','manual-2','manual-3'], 'manual-2');
assert.strictEqual(focus.validateState(state), true);
assert.strictEqual(focus.focusedId(state), 'manual-2');

assert.strictEqual(focus.move(state, 1), 'manual-3');
assert.strictEqual(focus.move(state, 1), 'manual-1', 'focus must wrap forward');
assert.strictEqual(focus.move(state, -1), 'manual-3', 'focus must wrap backward');

assert.strictEqual(
  focus.setItems(state, ['manual-1','manual-2','manual-3','manual-4'], 'manual-2'),
  'manual-2',
  'focus restoration should preserve the requested stable id'
);

const snap = focus.snapshot(state);
assert.strictEqual(snap.focusedId, 'manual-2');
assert.strictEqual(snap.index, 1);
assert(Object.isFrozen(snap), 'focus snapshots must be immutable');

assert.throws(() => focus.createState([], null), /FOCUS_ITEMS_REQUIRED/);
assert.throws(() => focus.createState(['a','a']), /FOCUS_ITEMS_DUPLICATE/);

console.log('Aetherwake focus manager: PASS');
