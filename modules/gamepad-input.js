(function(root) {
  'use strict';

  const VERSION = '0.1.0';
  const DEADZONE = 0.55;

  const BUTTON = Object.freeze({
    SOUTH: 0,
    EAST: 1,
    WEST: 2,
    NORTH: 3,
    LEFT_SHOULDER: 4,
    RIGHT_SHOULDER: 5,
    LEFT_TRIGGER: 6,
    RIGHT_TRIGGER: 7,
    VIEW: 8,
    MENU: 9,
    LEFT_STICK: 10,
    RIGHT_STICK: 11,
    DPAD_UP: 12,
    DPAD_DOWN: 13,
    DPAD_LEFT: 14,
    DPAD_RIGHT: 15,
    HOME: 16
  });

  function createState() {
    return {
      version: VERSION,
      connectedIndex: null,
      pressedButtons: [],
      axisDirections: []
    };
  }

  function buttonPressed(gamepad, index) {
    const button = gamepad && Array.isArray(gamepad.buttons) ? gamepad.buttons[index] : null;
    return Boolean(button && (button.pressed === true || Number(button.value) >= 0.5));
  }

  function directionSet(gamepad) {
    const directions = new Set();
    if (!gamepad) return directions;

    if (buttonPressed(gamepad, BUTTON.DPAD_UP)) directions.add('up');
    if (buttonPressed(gamepad, BUTTON.DPAD_DOWN)) directions.add('down');
    if (buttonPressed(gamepad, BUTTON.DPAD_LEFT)) directions.add('left');
    if (buttonPressed(gamepad, BUTTON.DPAD_RIGHT)) directions.add('right');

    const axes = Array.isArray(gamepad.axes) ? gamepad.axes : [];
    const x = Number(axes[0] || 0);
    const y = Number(axes[1] || 0);
    if (x <= -DEADZONE) directions.add('left');
    if (x >= DEADZONE) directions.add('right');
    if (y <= -DEADZONE) directions.add('up');
    if (y >= DEADZONE) directions.add('down');
    return directions;
  }

  function directionalAction(direction, context) {
    if (context === 'world' || context === 'airship') return 'move-' + direction;
    if (context === 'menu' || context === 'dialogue' || context === 'combat' || context === 'save-load') {
      return 'ui-' + direction;
    }
    return null;
  }

  function primaryButtonAction(index, context, options) {
    const opts = options || {};

    if (index === BUTTON.SOUTH) {
      if (context === 'airship') return 'airship-dock';
      if (context === 'world') return opts.wakeResolution ? 'confirm' : 'interact';
      return 'confirm';
    }
    if (index === BUTTON.EAST) {
      if (context === 'airship') return 'airship-land';
      if (context === 'world') return null;
      return 'cancel';
    }
    if (index === BUTTON.WEST) {
      if (context === 'world') return 'board-or-flight';
      return null;
    }
    if (index === BUTTON.NORTH) {
      if (context === 'world') return 'quest-log';
      return null;
    }
    if (index === BUTTON.LEFT_SHOULDER && context === 'world') return 'character-sheet';
    if (index === BUTTON.RIGHT_SHOULDER && context === 'world') return 'ledger';
    if (index === BUTTON.LEFT_TRIGGER && context === 'airship') return 'airship-altitude-down';
    if (index === BUTTON.RIGHT_TRIGGER && context === 'airship') return 'airship-altitude-up';
    if (index === BUTTON.MENU && context === 'menu') return 'open-settings';
    return null;
  }

  function poll(gamepad, state, context, options) {
    if (!state || state.version !== VERSION) throw new Error('GAMEPAD_STATE_INVALID');
    const normalizedContext = context === 'saveload' ? 'save-load' : String(context || 'menu');

    if (!gamepad || gamepad.connected === false) {
      state.connectedIndex = null;
      state.pressedButtons = [];
      state.axisDirections = [];
      return { supported: false, reason: 'not-connected', pressed: [], held: [] };
    }
    if (gamepad.mapping && gamepad.mapping !== 'standard') {
      state.connectedIndex = gamepad.index;
      state.pressedButtons = [];
      state.axisDirections = [];
      return { supported: false, reason: 'non-standard-mapping', pressed: [], held: [] };
    }

    const previousButtons = new Set(state.pressedButtons);
    const nowButtons = [];
    const pressed = [];

    for (let i = 0; i < (gamepad.buttons || []).length; i++) {
      if (!buttonPressed(gamepad, i)) continue;
      nowButtons.push(i);
      if (!previousButtons.has(i)) {
        const action = primaryButtonAction(i, normalizedContext, options);
        if (action && !pressed.includes(action)) pressed.push(action);
      }
    }

    const previousDirections = new Set(state.axisDirections);
    const nowDirections = directionSet(gamepad);
    const held = [];
    for (const direction of nowDirections) {
      const action = directionalAction(direction, normalizedContext);
      if (action && !held.includes(action)) held.push(action);
      if (!previousDirections.has(direction) && action && !pressed.includes(action)) {
        pressed.push(action);
      }
    }

    state.connectedIndex = Number.isInteger(gamepad.index) ? gamepad.index : 0;
    state.pressedButtons = nowButtons;
    state.axisDirections = Array.from(nowDirections);

    return {
      supported: true,
      reason: null,
      index: state.connectedIndex,
      id: gamepad.id || '',
      mapping: gamepad.mapping || '',
      pressed,
      held
    };
  }

  const api = Object.freeze({
    VERSION,
    DEADZONE,
    BUTTON,
    createState,
    poll
  });

  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.AetherGamepadInput = api;
})(typeof window !== 'undefined' ? window : globalThis);
