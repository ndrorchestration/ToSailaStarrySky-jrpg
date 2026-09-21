/* ============================================================
   Aetherwake — Memories / RPG Maker-style semantic input
   modules/jrpg-input.js

   Primary keyboard vocabulary follows the RPG Maker MV conventions used
   by Memories:
     OK        Enter / Space / Z
     Cancel    Esc / X / Insert / Numpad 0
     Shift     Shift
     PageUp    PageUp / Q
     PageDown  PageDown / W
     Move      Arrow keys (numpad directions also admitted)

   WASD and Aetherwake-specific hotkeys remain compatibility aliases in
   core, but normal gameplay must not require them.
   ============================================================ */

(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherJrpgInput = api;
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';

  const ACTION = Object.freeze({
    OK: 'ok',
    CANCEL: 'cancel',
    MENU: 'menu',
    SHIFT: 'shift',
    PAGEUP: 'pageup',
    PAGEDOWN: 'pagedown',
    UP: 'up',
    DOWN: 'down',
    LEFT: 'left',
    RIGHT: 'right',
  });

  const KEY_CODES = Object.freeze({
    [ACTION.OK]: Object.freeze([13, 32, 90]),          // Enter, Space, Z
    [ACTION.CANCEL]: Object.freeze([27, 45, 88, 96]),  // Esc, Insert, X, Num0
    [ACTION.MENU]: Object.freeze([27, 88]),             // Esc, X
    [ACTION.SHIFT]: Object.freeze([16]),
    [ACTION.PAGEUP]: Object.freeze([33, 81]),           // PageUp, Q
    [ACTION.PAGEDOWN]: Object.freeze([34, 87]),         // PageDown, W
    [ACTION.UP]: Object.freeze([38, 104]),              // Up, Num8
    [ACTION.DOWN]: Object.freeze([40, 98]),             // Down, Num2
    [ACTION.LEFT]: Object.freeze([37, 100]),            // Left, Num4
    [ACTION.RIGHT]: Object.freeze([39, 102]),           // Right, Num6
  });

  // RPG Maker MV default gamepad mapping.
  const GAMEPAD_BUTTONS = Object.freeze({
    0: ACTION.OK,
    1: ACTION.CANCEL,
    2: ACTION.SHIFT,
    3: ACTION.MENU,
    4: ACTION.PAGEUP,
    5: ACTION.PAGEDOWN,
    12: ACTION.UP,
    13: ACTION.DOWN,
    14: ACTION.LEFT,
    15: ACTION.RIGHT,
  });

  function actionsForKeyCode(code) {
    const numeric = Number(code);
    if (!Number.isInteger(numeric)) return [];
    return Object.keys(KEY_CODES).filter(action =>
      KEY_CODES[action].includes(numeric)
    );
  }

  function isPressed(pressed, action) {
    const codes = KEY_CODES[action];
    if (!pressed || !Array.isArray(codes)) return false;
    return codes.some(code => Boolean(pressed[code]));
  }

  function isHeld(keys, action) {
    const codes = KEY_CODES[action];
    if (!keys || !Array.isArray(codes)) return false;
    return codes.some(code => Boolean(keys[code]));
  }

  function normalizePressed(pressed) {
    const out = {};
    Object.values(ACTION).forEach(action => {
      out[action] = isPressed(pressed, action);
    });
    return out;
  }

  function normalizeHeld(keys) {
    const out = {};
    Object.values(ACTION).forEach(action => {
      out[action] = isHeld(keys, action);
    });
    return out;
  }

  function gamepadActionForButton(index) {
    return Object.prototype.hasOwnProperty.call(GAMEPAD_BUTTONS, index)
      ? GAMEPAD_BUTTONS[index]
      : null;
  }

  function validate() {
    const required = Object.values(ACTION);
    required.forEach(action => {
      if (!Array.isArray(KEY_CODES[action]) || KEY_CODES[action].length === 0) {
        throw new Error('JRPG_INPUT_KEY_MAPPING_REQUIRED:' + action);
      }
    });

    if (!KEY_CODES[ACTION.OK].includes(90) ||
        !KEY_CODES[ACTION.CANCEL].includes(88) ||
        !KEY_CODES[ACTION.MENU].includes(27) ||
        !KEY_CODES[ACTION.PAGEUP].includes(81) ||
        !KEY_CODES[ACTION.PAGEDOWN].includes(87)) {
      throw new Error('JRPG_INPUT_MEMORIES_COMPATIBILITY_INVALID');
    }

    if (GAMEPAD_BUTTONS[0] !== ACTION.OK ||
        GAMEPAD_BUTTONS[1] !== ACTION.CANCEL ||
        GAMEPAD_BUTTONS[3] !== ACTION.MENU) {
      throw new Error('JRPG_INPUT_GAMEPAD_MAPPING_INVALID');
    }

    return true;
  }

  validate();

  return Object.freeze({
    VERSION,
    ACTION,
    KEY_CODES,
    GAMEPAD_BUTTONS,
    actionsForKeyCode,
    isPressed,
    isHeld,
    normalizePressed,
    normalizeHeld,
    gamepadActionForButton,
    validate,
  });
});
