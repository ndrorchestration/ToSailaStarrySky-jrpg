(function(factory) {
  const root = typeof window !== 'undefined' ? window : globalThis;
  const api = factory(root);
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.AetherInputBindings = api;
})(function(root) {
  'use strict';

  const VERSION = '0.1.0';
  const SCHEMA_VERSION = 1;
  const STORAGE_KEY = 'aetherwake.input-bindings.v1';

  const ACTION_LABELS = Object.freeze({
    'ui-up': 'UI Up',
    'ui-down': 'UI Down',
    'ui-left': 'UI Left',
    'ui-right': 'UI Right',
    'confirm': 'Confirm',
    'cancel': 'Cancel',
    'open-settings': 'Open Settings',
    'continue-game': 'Continue',
    'open-save-load': 'Open Save / Load',
    'move-up': 'Move Up',
    'move-down': 'Move Down',
    'move-left': 'Move Left',
    'move-right': 'Move Right',
    'interact': 'Interact / Talk',
    'covenant-field': 'Covenant Field',
    'toggle-layer': 'Sky / Ground Layer',
    'shop': 'Shop',
    'quest-log': 'Quest Log',
    'character-sheet': 'Character Sheet',
    'ledger': 'Ledger',
    'board-or-flight': 'Board / Flight',
    'manual-save': 'Quick Save',
    'manual-load': 'Quick Load',
    'airship-altitude-up': 'Altitude Up',
    'airship-altitude-down': 'Altitude Down',
    'airship-dock': 'Dock',
    'airship-land': 'Land'
  });

  const GAMEPAD_DEFAULT_BUTTON = Object.freeze({
    'ui-up': 12,
    'ui-down': 13,
    'ui-left': 14,
    'ui-right': 15,
    'confirm': 0,
    'cancel': 1,
    'open-settings': 9,
    'continue-game': 3,
    'open-save-load': 9,
    'move-up': 12,
    'move-down': 13,
    'move-left': 14,
    'move-right': 15,
    'interact': 0,
    'covenant-field': 10,
    'toggle-layer': 8,
    'shop': 11,
    'quest-log': 3,
    'character-sheet': 4,
    'ledger': 5,
    'board-or-flight': 2,
    'manual-save': null,
    'manual-load': null,
    'airship-altitude-up': 7,
    'airship-altitude-down': 6,
    'airship-dock': 0,
    'airship-land': 1
  });

  const BUTTON_LABELS = Object.freeze({
    0: 'A / SOUTH',
    1: 'B / EAST',
    2: 'X / WEST',
    3: 'Y / NORTH',
    4: 'LB',
    5: 'RB',
    6: 'LT',
    7: 'RT',
    8: 'VIEW',
    9: 'MENU',
    10: 'LS',
    11: 'RS',
    12: 'DPAD UP',
    13: 'DPAD DOWN',
    14: 'DPAD LEFT',
    15: 'DPAD RIGHT',
    16: 'HOME'
  });

  const KEY_LABELS = Object.freeze({
    9: 'TAB',
    13: 'ENTER',
    27: 'ESC',
    32: 'SPACE',
    37: '←',
    38: '↑',
    39: '→',
    40: '↓',
    116: 'F5',
    117: 'F6',
    120: 'F9'
  });

  const ALLOWED_CONTEXTUAL_OVERLAPS = Object.freeze([
    Object.freeze(['confirm','interact']),
    Object.freeze(['confirm','airship-dock']),
    Object.freeze(['cancel','airship-land'])
  ]);

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function requireActions() {
    if (!root.AetherInputActions || !root.AetherInputActions.ACTIONS) {
      throw new Error('INPUT_BINDINGS_ACTION_REGISTRY_UNAVAILABLE');
    }
    return root.AetherInputActions;
  }

  function emptyState() {
    return {
      schemaVersion: SCHEMA_VERSION,
      keyboardOverrides: {},
      gamepadOverrides: {}
    };
  }

  function actionIds() {
    return Object.keys(requireActions().ACTIONS);
  }

  function actionLabel(actionId) {
    return ACTION_LABELS[actionId] || actionId;
  }

  function contextsFor(actionId) {
    const actions = requireActions();
    const def = actions.ACTIONS[actionId];
    if (!def) throw new Error('INPUT_BINDINGS_ACTION_UNKNOWN:' + actionId);
    if (def.contexts.includes('global')) {
      return actions.CONTEXTS.filter(context => context !== 'global');
    }
    return def.contexts.map(actions.normalizeContext);
  }

  function contextsOverlap(a, b) {
    const aContexts = new Set(contextsFor(a));
    return contextsFor(b).some(context => aContexts.has(context));
  }

  function overlapAllowed(a, b) {
    return ALLOWED_CONTEXTUAL_OVERLAPS.some(pair =>
      (pair[0] === a && pair[1] === b) || (pair[0] === b && pair[1] === a)
    );
  }

  function defaultKeyboardCodes(actionId, context) {
    const actions = requireActions();
    const def = actions.ACTIONS[actionId];
    if (!def) throw new Error('INPUT_BINDINGS_ACTION_UNKNOWN:' + actionId);
    const normalized = actions.normalizeContext(context);
    const codes = def.keyCodesByContext
      ? (def.keyCodesByContext[normalized] || [])
      : (def.keyCodes || []);
    return codes.slice();
  }

  function keyboardCodesForAction(state, actionId, context) {
    validateState(state);
    if (Object.prototype.hasOwnProperty.call(state.keyboardOverrides, actionId)) {
      return [state.keyboardOverrides[actionId]];
    }
    return defaultKeyboardCodes(actionId, context);
  }

  function gamepadButtonForAction(state, actionId) {
    validateState(state);
    if (Object.prototype.hasOwnProperty.call(state.gamepadOverrides, actionId)) {
      return state.gamepadOverrides[actionId];
    }
    return Object.prototype.hasOwnProperty.call(GAMEPAD_DEFAULT_BUTTON, actionId)
      ? GAMEPAD_DEFAULT_BUTTON[actionId]
      : null;
  }

  function validateOverrideKeys(overrides, type) {
    const ids = new Set(actionIds());
    for (const key of Object.keys(overrides)) {
      if (!ids.has(key)) throw new Error('INPUT_BINDINGS_ACTION_UNKNOWN:' + key);
      const value = overrides[key];
      if (!Number.isInteger(value)) throw new Error('INPUT_BINDINGS_' + type + '_INVALID:' + key);
      if (type === 'KEYBOARD' && (value < 1 || value > 255)) {
        throw new Error('INPUT_BINDINGS_KEYBOARD_RANGE:' + key);
      }
      if (type === 'GAMEPAD' && (value < 0 || value > 16)) {
        throw new Error('INPUT_BINDINGS_GAMEPAD_RANGE:' + key);
      }
    }
  }

  function validateState(state) {
    if (!state || typeof state !== 'object' || Array.isArray(state)) {
      throw new Error('INPUT_BINDINGS_STATE_REQUIRED');
    }
    if (state.schemaVersion !== SCHEMA_VERSION) {
      if (Number.isInteger(state.schemaVersion) && state.schemaVersion > SCHEMA_VERSION) {
        throw new Error('INPUT_BINDINGS_SCHEMA_FUTURE_UNSUPPORTED');
      }
      throw new Error('INPUT_BINDINGS_SCHEMA_UNSUPPORTED');
    }
    if (!state.keyboardOverrides || typeof state.keyboardOverrides !== 'object' ||
        Array.isArray(state.keyboardOverrides)) {
      throw new Error('INPUT_BINDINGS_KEYBOARD_OVERRIDES_INVALID');
    }
    if (!state.gamepadOverrides || typeof state.gamepadOverrides !== 'object' ||
        Array.isArray(state.gamepadOverrides)) {
      throw new Error('INPUT_BINDINGS_GAMEPAD_OVERRIDES_INVALID');
    }
    validateOverrideKeys(state.keyboardOverrides, 'KEYBOARD');
    validateOverrideKeys(state.gamepadOverrides, 'GAMEPAD');

    const ids = actionIds();
    for (let i = 0; i < ids.length; i++) {
      for (let j = i + 1; j < ids.length; j++) {
        const a = ids[i], b = ids[j];
        if (!contextsOverlap(a, b)) continue;

        const sharedContexts = contextsFor(a).filter(context => contextsFor(b).includes(context));
        for (const context of sharedContexts) {
          const aCodes = Object.prototype.hasOwnProperty.call(state.keyboardOverrides, a)
            ? [state.keyboardOverrides[a]]
            : defaultKeyboardCodes(a, context);
          const bCodes = Object.prototype.hasOwnProperty.call(state.keyboardOverrides, b)
            ? [state.keyboardOverrides[b]]
            : defaultKeyboardCodes(b, context);
          if (aCodes.some(code => bCodes.includes(code))) {
            throw new Error('INPUT_BINDINGS_CONFLICT_KEYBOARD:' + a + ':' + b + ':' + context);
          }
        }

        if (!overlapAllowed(a, b)) {
          const aButton = Object.prototype.hasOwnProperty.call(state.gamepadOverrides, a)
            ? state.gamepadOverrides[a]
            : GAMEPAD_DEFAULT_BUTTON[a];
          const bButton = Object.prototype.hasOwnProperty.call(state.gamepadOverrides, b)
            ? state.gamepadOverrides[b]
            : GAMEPAD_DEFAULT_BUTTON[b];
          if (aButton != null && aButton === bButton) {
            throw new Error('INPUT_BINDINGS_CONFLICT_GAMEPAD:' + a + ':' + b);
          }
        }
      }
    }
    return true;
  }

  function effectivePrimaryKeyboardCode(state, actionId, context) {
    const codes = keyboardCodesForAction(state, actionId, context);
    return codes.length ? codes[0] : null;
  }

  function conflictForKeyboard(state, actionId, keyCode) {
    for (const otherId of actionIds()) {
      if (otherId === actionId || !contextsOverlap(actionId, otherId)) continue;
      const sharedContexts = contextsFor(actionId).filter(context => contextsFor(otherId).includes(context));
      for (const context of sharedContexts) {
        if (effectivePrimaryKeyboardCode(state, otherId, context) === keyCode) return otherId;
      }
    }
    return null;
  }

  function conflictForGamepad(state, actionId, buttonIndex) {
    for (const otherId of actionIds()) {
      if (otherId === actionId || !contextsOverlap(actionId, otherId)) continue;
      if (overlapAllowed(actionId, otherId)) continue;
      if (gamepadButtonForAction(state, otherId) === buttonIndex) return otherId;
    }
    return null;
  }

  function setKeyboardBinding(state, actionId, keyCode) {
    validateState(state);
    if (!actionIds().includes(actionId)) throw new Error('INPUT_BINDINGS_ACTION_UNKNOWN:' + actionId);
    if (!Number.isInteger(keyCode) || keyCode < 1 || keyCode > 255) {
      throw new Error('INPUT_BINDINGS_KEYBOARD_RANGE:' + actionId);
    }
    const conflict = conflictForKeyboard(state, actionId, keyCode);
    if (conflict) throw new Error('INPUT_BINDINGS_CONFLICT_KEYBOARD:' + conflict);
    const next = clone(state);
    next.keyboardOverrides[actionId] = keyCode;
    validateState(next);
    return next;
  }

  function setGamepadBinding(state, actionId, buttonIndex) {
    validateState(state);
    if (!actionIds().includes(actionId)) throw new Error('INPUT_BINDINGS_ACTION_UNKNOWN:' + actionId);
    if (!Number.isInteger(buttonIndex) || buttonIndex < 0 || buttonIndex > 16) {
      throw new Error('INPUT_BINDINGS_GAMEPAD_RANGE:' + actionId);
    }
    const conflict = conflictForGamepad(state, actionId, buttonIndex);
    if (conflict) throw new Error('INPUT_BINDINGS_CONFLICT_GAMEPAD:' + conflict);
    const next = clone(state);
    next.gamepadOverrides[actionId] = buttonIndex;
    validateState(next);
    return next;
  }

  function resetAction(state, actionId, device) {
    validateState(state);
    const next = clone(state);
    if (!device || device === 'keyboard') delete next.keyboardOverrides[actionId];
    if (!device || device === 'gamepad') delete next.gamepadOverrides[actionId];
    validateState(next);
    return next;
  }

  function resetAll() {
    return emptyState();
  }

  function keyboardActionsForEvent(eventLike, context, state) {
    validateState(state);
    const keyCode = Number(eventLike && eventLike.keyCode);
    if (!Number.isInteger(keyCode)) return [];
    const actions = requireActions();
    const normalized = actions.normalizeContext(context);
    const matches = [];
    for (const actionId of actionIds()) {
      const def = actions.ACTIONS[actionId];
      if (!def.contexts.includes('global') && !def.contexts.includes(normalized)) continue;
      if (keyboardCodesForAction(state, actionId, normalized).includes(keyCode)) {
        matches.push(actionId);
      }
    }
    return matches;
  }

  function resolveGamepadButtonAction(state, buttonIndex, context, defaultAction) {
    validateState(state);
    const normalized = requireActions().normalizeContext(context);
    const matchingOverrides = [];
    for (const actionId of Object.keys(state.gamepadOverrides)) {
      if (state.gamepadOverrides[actionId] !== buttonIndex) continue;
      const def = requireActions().ACTIONS[actionId];
      if (!def) continue;
      const specific = !def.contexts.includes('global');
      if (def.contexts.includes('global') || def.contexts.includes(normalized)) {
        matchingOverrides.push({ actionId, specific });
      }
    }
    matchingOverrides.sort((a,b) => Number(b.specific) - Number(a.specific));
    if (matchingOverrides.length) return matchingOverrides[0].actionId;

    if (defaultAction &&
        Object.prototype.hasOwnProperty.call(state.gamepadOverrides, defaultAction) &&
        state.gamepadOverrides[defaultAction] !== buttonIndex) {
      return null;
    }
    return defaultAction || null;
  }

  function resolveGamepadDirectionalAction(state, defaultAction) {
    validateState(state);
    if (defaultAction &&
        Object.prototype.hasOwnProperty.call(state.gamepadOverrides, defaultAction)) {
      return null;
    }
    return defaultAction || null;
  }

  function keyLabel(keyCode) {
    if (Object.prototype.hasOwnProperty.call(KEY_LABELS, keyCode)) return KEY_LABELS[keyCode];
    if (keyCode >= 65 && keyCode <= 90) return String.fromCharCode(keyCode);
    if (keyCode >= 48 && keyCode <= 57) return String.fromCharCode(keyCode);
    return 'KEY ' + keyCode;
  }

  function keyboardLabel(state, actionId, context) {
    const codes = keyboardCodesForAction(state, actionId, context);
    return codes.length ? codes.slice(0,2).map(keyLabel).join(' / ') : 'UNBOUND';
  }

  function gamepadLabel(state, actionId) {
    const button = gamepadButtonForAction(state, actionId);
    return button == null ? 'UNBOUND' : (BUTTON_LABELS[button] || ('BUTTON ' + button));
  }

  function prompt(state, actionId, context, device) {
    const which = device || 'both';
    if (which === 'keyboard') return keyboardLabel(state, actionId, context);
    if (which === 'gamepad') return gamepadLabel(state, actionId);
    const keyboard = keyboardLabel(state, actionId, context);
    const gamepad = gamepadLabel(state, actionId);
    if (keyboard === 'UNBOUND') return gamepad;
    if (gamepad === 'UNBOUND') return keyboard;
    return keyboard + ' · ' + gamepad;
  }

  function makeEnvelope(state) {
    validateState(state);
    return {
      schemaVersion: SCHEMA_VERSION,
      savedAt: new Date().toISOString(),
      bindings: clone(state)
    };
  }

  function validateEnvelope(envelope) {
    if (!envelope || typeof envelope !== 'object') throw new Error('INPUT_BINDINGS_ENVELOPE_REQUIRED');
    if (envelope.schemaVersion !== SCHEMA_VERSION) {
      if (Number.isInteger(envelope.schemaVersion) && envelope.schemaVersion > SCHEMA_VERSION) {
        throw new Error('INPUT_BINDINGS_SCHEMA_FUTURE_UNSUPPORTED');
      }
      throw new Error('INPUT_BINDINGS_SCHEMA_UNSUPPORTED');
    }
    validateState(envelope.bindings);
    return true;
  }

  function browserStorage() {
    if (!root || !root.localStorage) return null;
    return {
      type: 'localStorage',
      path() { return 'localStorage://' + STORAGE_KEY; },
      write(envelope) {
        const previous = root.localStorage.getItem(STORAGE_KEY);
        if (previous !== null) root.localStorage.setItem(STORAGE_KEY + '.bak', previous);
        root.localStorage.setItem(STORAGE_KEY, JSON.stringify(envelope));
      },
      read() {
        const primary = root.localStorage.getItem(STORAGE_KEY);
        if (primary === null) return null;
        try {
          const parsed = JSON.parse(primary);
          validateEnvelope(parsed);
          return parsed;
        } catch (primaryError) {
          const backup = root.localStorage.getItem(STORAGE_KEY + '.bak');
          if (backup === null) throw primaryError;
          const parsed = JSON.parse(backup);
          validateEnvelope(parsed);
          return parsed;
        }
      },
      futureSchemaVersion() {
        let newest = null;
        for (const key of [STORAGE_KEY, STORAGE_KEY + '.bak']) {
          const raw = root.localStorage.getItem(key);
          if (raw === null) continue;
          try {
            const parsed = JSON.parse(raw);
            if (parsed && typeof parsed === 'object' && !Array.isArray(parsed) &&
                parsed.bindings && typeof parsed.bindings === 'object' && !Array.isArray(parsed.bindings) &&
                Number.isInteger(parsed.schemaVersion) && parsed.schemaVersion > SCHEMA_VERSION) {
              newest = newest == null ? parsed.schemaVersion : Math.max(newest, parsed.schemaVersion);
            }
          } catch (_) {}
        }
        return newest;
      }
    };
  }

  function nwStorage() {
    if (!root || typeof root.require !== 'function' ||
        !root.nw || !root.nw.App || !root.nw.App.dataPath) return null;
    const fs = root.require('fs');
    const path = root.require('path');
    const target = path.join(root.nw.App.dataPath, 'input-bindings.json');
    const tmp = target + '.tmp';
    const bak = target + '.bak';
    return {
      type: 'nw-file',
      path() { return target; },
      write(envelope) {
        const json = JSON.stringify(envelope, null, 2) + '\n';
        const fd = fs.openSync(tmp, 'w');
        try {
          fs.writeFileSync(fd, json, 'utf8');
          fs.fsyncSync(fd);
        } finally {
          fs.closeSync(fd);
        }
        try {
          if (fs.existsSync(target)) {
            if (fs.existsSync(bak)) fs.unlinkSync(bak);
            fs.renameSync(target, bak);
          }
          fs.renameSync(tmp, target);
        } catch (error) {
          if (!fs.existsSync(target) && fs.existsSync(bak)) fs.renameSync(bak, target);
          if (fs.existsSync(tmp)) {
            try { fs.unlinkSync(tmp); } catch (_) {}
          }
          throw error;
        }
      },
      read() {
        if (!fs.existsSync(target)) return null;
        try {
          const parsed = JSON.parse(fs.readFileSync(target, 'utf8'));
          validateEnvelope(parsed);
          return parsed;
        } catch (primaryError) {
          if (!fs.existsSync(bak)) throw primaryError;
          const parsed = JSON.parse(fs.readFileSync(bak, 'utf8'));
          validateEnvelope(parsed);
          return parsed;
        }
      },
      futureSchemaVersion() {
        let newest = null;
        for (const file of [target, bak]) {
          if (!fs.existsSync(file)) continue;
          try {
            const parsed = JSON.parse(fs.readFileSync(file, 'utf8'));
            if (parsed && typeof parsed === 'object' && !Array.isArray(parsed) &&
                parsed.bindings && typeof parsed.bindings === 'object' && !Array.isArray(parsed.bindings) &&
                Number.isInteger(parsed.schemaVersion) && parsed.schemaVersion > SCHEMA_VERSION) {
              newest = newest == null ? parsed.schemaVersion : Math.max(newest, parsed.schemaVersion);
            }
          } catch (_) {}
        }
        return newest;
      }
    };
  }

  function getStorage() {
    return nwStorage() || browserStorage() || null;
  }

  function load() {
    const storage = getStorage();
    if (!storage) {
      return { bindings: emptyState(), storageType: 'memory-defaults', path: null, isDefault: true };
    }
    const envelope = storage.read();
    if (!envelope) {
      return { bindings: emptyState(), storageType: storage.type, path: storage.path(), isDefault: true };
    }
    validateEnvelope(envelope);
    return {
      bindings: clone(envelope.bindings),
      envelope,
      storageType: storage.type,
      path: storage.path(),
      isDefault: false
    };
  }

  function save(state) {
    const storage = getStorage();
    if (!storage) throw new Error('INPUT_BINDINGS_STORAGE_UNAVAILABLE');
    const protectedVersion = typeof storage.futureSchemaVersion === 'function'
      ? storage.futureSchemaVersion()
      : null;
    if (protectedVersion != null) {
      throw new Error('INPUT_BINDINGS_FUTURE_SCHEMA_PROTECTED:' + protectedVersion);
    }
    const envelope = makeEnvelope(state);
    storage.write(envelope);
    return {
      bindings: clone(state),
      envelope,
      storageType: storage.type,
      path: storage.path()
    };
  }

  return Object.freeze({
    VERSION,
    SCHEMA_VERSION,
    STORAGE_KEY,
    ACTION_LABELS,
    GAMEPAD_DEFAULT_BUTTON,
    BUTTON_LABELS,
    emptyState,
    validateState,
    actionIds,
    actionLabel,
    contextsFor,
    defaultKeyboardCodes,
    keyboardCodesForAction,
    gamepadButtonForAction,
    conflictForKeyboard,
    conflictForGamepad,
    setKeyboardBinding,
    setGamepadBinding,
    resetAction,
    resetAll,
    keyboardActionsForEvent,
    resolveGamepadButtonAction,
    resolveGamepadDirectionalAction,
    keyLabel,
    keyboardLabel,
    gamepadLabel,
    prompt,
    validateEnvelope,
    getStorage,
    load,
    save
  });
});
