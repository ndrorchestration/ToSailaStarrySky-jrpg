(function(root) {
  'use strict';

  const VERSION = '0.1.0';

  function normalizeItems(items) {
    if (!Array.isArray(items) || items.length === 0) {
      throw new Error('FOCUS_ITEMS_REQUIRED');
    }
    const out = items.map(item => String(item));
    if (new Set(out).size !== out.length) {
      throw new Error('FOCUS_ITEMS_DUPLICATE');
    }
    if (out.some(item => item.length === 0)) {
      throw new Error('FOCUS_ITEM_EMPTY');
    }
    return out;
  }

  function createState(items, preferredId) {
    const normalized = normalizeItems(items);
    const preferred = preferredId == null ? null : String(preferredId);
    const index = preferred && normalized.includes(preferred)
      ? normalized.indexOf(preferred)
      : 0;
    return {
      version: VERSION,
      items: normalized,
      index
    };
  }

  function validateState(state) {
    if (!state || state.version !== VERSION) throw new Error('FOCUS_STATE_VERSION_INVALID');
    const items = normalizeItems(state.items);
    if (!Number.isInteger(state.index) || state.index < 0 || state.index >= items.length) {
      throw new Error('FOCUS_INDEX_INVALID');
    }
    return true;
  }

  function focusedId(state) {
    validateState(state);
    return state.items[state.index];
  }

  function move(state, delta) {
    validateState(state);
    if (!Number.isInteger(delta) || delta === 0) return focusedId(state);
    const length = state.items.length;
    state.index = (state.index + (delta % length) + length) % length;
    return focusedId(state);
  }

  function setItems(state, items, preferredId) {
    const previous = preferredId == null && state ? focusedId(state) : preferredId;
    const next = createState(items, previous);
    state.version = next.version;
    state.items = next.items;
    state.index = next.index;
    return focusedId(state);
  }

  function snapshot(state) {
    validateState(state);
    return Object.freeze({
      version: state.version,
      items: state.items.slice(),
      index: state.index,
      focusedId: focusedId(state)
    });
  }

  const api = Object.freeze({
    VERSION,
    createState,
    validateState,
    focusedId,
    move,
    setItems,
    snapshot
  });

  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.AetherFocusManager = api;
})(typeof window !== 'undefined' ? window : globalThis);
