const assert = require('assert');
const input = require('../modules/jrpg-input.js');

assert.strictEqual(input.VERSION, '0.1.0');
assert.strictEqual(input.validate(), true);

assert.deepStrictEqual(input.actionsForKeyCode(90), ['ok']); // Z
assert(input.actionsForKeyCode(13).includes('ok'));          // Enter
assert(input.actionsForKeyCode(32).includes('ok'));          // Space
assert(input.actionsForKeyCode(88).includes('cancel'));      // X
assert(input.actionsForKeyCode(88).includes('menu'));        // X
assert(input.actionsForKeyCode(27).includes('cancel'));      // Esc
assert(input.actionsForKeyCode(27).includes('menu'));        // Esc
assert(input.actionsForKeyCode(81).includes('pageup'));      // Q
assert(input.actionsForKeyCode(87).includes('pagedown'));    // W
assert(input.actionsForKeyCode(38).includes('up'));
assert(input.actionsForKeyCode(40).includes('down'));
assert(input.actionsForKeyCode(37).includes('left'));
assert(input.actionsForKeyCode(39).includes('right'));

const pressed = { 90: true, 38: true };
assert.strictEqual(input.isPressed(pressed, input.ACTION.OK), true);
assert.strictEqual(input.isPressed(pressed, input.ACTION.UP), true);
assert.strictEqual(input.isPressed(pressed, input.ACTION.CANCEL), false);

assert.strictEqual(input.gamepadActionForButton(0), 'ok');
assert.strictEqual(input.gamepadActionForButton(1), 'cancel');
assert.strictEqual(input.gamepadActionForButton(2), 'shift');
assert.strictEqual(input.gamepadActionForButton(3), 'menu');
assert.strictEqual(input.gamepadActionForButton(4), 'pageup');
assert.strictEqual(input.gamepadActionForButton(5), 'pagedown');
assert.strictEqual(input.gamepadActionForButton(12), 'up');
assert.strictEqual(input.gamepadActionForButton(15), 'right');
assert.strictEqual(input.gamepadActionForButton(6), null);

console.log('Aetherwake Memories-style JRPG input authority: PASS');
