(function(root) {
  'use strict';

  const VERSION = '0.1.0';

  const CONTEXTS = Object.freeze([
    'global', 'menu', 'settings', 'world', 'dialogue', 'combat', 'airship', 'save-load'
  ]);

  const ACTIONS = Object.freeze({
    'ui-up': { contexts: ['menu','dialogue','combat','save-load'], keyCodes: [38] },
    'ui-down': { contexts: ['menu','dialogue','combat','save-load'], keyCodes: [40] },
    'ui-left': { contexts: ['menu','combat','save-load'], keyCodes: [37] },
    'ui-right': { contexts: ['menu','combat','save-load'], keyCodes: [39] },
    'confirm': { contexts: ['global'], keyCodes: [13,32] },
    'cancel': { contexts: ['global'], keyCodes: [27] },
    'open-settings': { contexts: ['menu'], keyCodes: [83] },
    'move-up': { contexts: ['world'], keyCodes: [38,87] },
    'move-down': { contexts: ['world'], keyCodes: [40,83] },
    'move-left': { contexts: ['world'], keyCodes: [37,65] },
    'move-right': { contexts: ['world'], keyCodes: [39,68] },
    'interact': { contexts: ['world','dialogue'], keyCodes: [69] },
    'quest-log': { contexts: ['world'], keyCodes: [84] },
    'character-sheet': { contexts: ['world'], keyCodes: [82] },
    'ledger': { contexts: ['world'], keyCodes: [76] },
    'board-or-flight': { contexts: ['world'], keyCodes: [70] },
    'manual-save': { contexts: ['world','airship'], keyCodes: [116] },
    'manual-load': { contexts: ['world','airship'], keyCodes: [120] },
    'airship-altitude-up': { contexts: ['airship'], keyCodes: [69] },
    'airship-altitude-down': { contexts: ['airship'], keyCodes: [81] },
    'airship-dock': { contexts: ['airship'], keyCodes: [68] },
    'airship-land': { contexts: ['airship'], keyCodes: [76] }
  });

  function normalizeContext(context) {
    if (context === 'saveload') return 'save-load';
    if (context === 'settings') return 'settings';
    if (context === 'questlog' || context === 'charsheet' || context === 'shop' || context === 'ledger') {
      return 'menu';
    }
    if (CONTEXTS.includes(context)) return context;
    return 'global';
  }

  function appliesToContext(definition, context) {
    const normalized = normalizeContext(context);
    return definition.contexts.includes('global') || definition.contexts.includes(normalized);
  }

  function actionsForKeyboardEvent(eventLike, context) {
    const event = eventLike || {};
    const keyCode = Number(event.keyCode);
    if (!Number.isInteger(keyCode)) return [];

    const actions = [];
    for (const id of Object.keys(ACTIONS)) {
      const definition = ACTIONS[id];
      if (!appliesToContext(definition, context)) continue;
      if (definition.keyCodes.includes(keyCode)) actions.push(id);
    }
    return actions;
  }

  function validate() {
    const ids = Object.keys(ACTIONS);
    if (!ids.length) throw new Error('INPUT_ACTIONS_EMPTY');

    const required = [
      'confirm','cancel','open-settings','move-up','move-down','move-left','move-right',
      'interact','quest-log','character-sheet','ledger','board-or-flight',
      'manual-save','manual-load','airship-altitude-up','airship-altitude-down',
      'airship-dock','airship-land'
    ];
    for (const id of required) {
      if (!ACTIONS[id]) throw new Error('INPUT_ACTION_MISSING:' + id);
    }

    for (const id of ids) {
      const def = ACTIONS[id];
      if (!Array.isArray(def.contexts) || !def.contexts.length) {
        throw new Error('INPUT_ACTION_CONTEXT_MISSING:' + id);
      }
      if (!Array.isArray(def.keyCodes) || !def.keyCodes.length ||
          def.keyCodes.some(code => !Number.isInteger(code))) {
        throw new Error('INPUT_ACTION_KEYCODE_INVALID:' + id);
      }
    }
    return true;
  }

  const api = Object.freeze({
    VERSION,
    CONTEXTS,
    ACTIONS,
    normalizeContext,
    actionsForKeyboardEvent,
    validate
  });

  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.AetherInputActions = api;
})(typeof window !== 'undefined' ? window : globalThis);
