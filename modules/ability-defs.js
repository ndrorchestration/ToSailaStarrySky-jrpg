/* ============================================================
   Aetherwake JRPG — Ability Definitions v0.1
   modules/ability-defs.js

   Behavior-preserving extraction of the eight current combat actions.
   This module owns action identity/metadata only. resolveTurn() remains
   the executable authority until the generic resolver phase.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherAbilityDefs = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  const ACTION_ORDER = Object.freeze([
    'staffStrike',
    'uncoverTruth',
    'sharedDream',
    'mycelialLedger',
    'hold',
    'windWard',
    'aetherSeal',
    'rest',
  ]);

  const DEFS = deepFreeze({
    staffStrike: {
      id: 'staffStrike',
      label: 'Resonator Staff — EMP strike',
      stat: 'might',
      cost: 0,
      type: 'attack',
      tier: 0,
      effectProfile: 'staffStrike',
      desc: '1d6+2 EMP, 10ft melee / 60ft beam, 1 charge',
    },
    uncoverTruth: {
      id: 'uncoverTruth',
      label: 'Uncover Truth — read the weave',
      stat: 'wits',
      cost: 1,
      type: 'ability',
      tier: 1,
      effectProfile: 'uncoverTruth',
      desc: '2D6+Wits. Reveal enemy weakness. +1 next roll.',
    },
    sharedDream: {
      id: 'sharedDream',
      label: 'Shared Dream — lend your vision',
      stat: 'spirit',
      cost: 1,
      type: 'ability',
      tier: 1,
      effectProfile: 'sharedDream',
      desc: '2D6+Spirit. Ally +1 next action OR heal 1-2 Vit',
    },
    mycelialLedger: {
      id: 'mycelialLedger',
      label: 'Mycelial Ledger — account the commons',
      stat: 'presence',
      cost: 0,
      type: 'ability',
      tier: 0,
      effectProfile: 'mycelialLedger',
      desc: '2D6+Presence. Gain scrap or aether',
    },
    hold: {
      id: 'hold',
      label: 'Hold position — conserve',
      stat: null,
      cost: 0,
      type: 'hold',
      tier: 0,
      effectProfile: 'hold',
      desc: 'Regain 1 staff charge in sunlight',
    },
    windWard: {
      id: 'windWard',
      label: 'Wind Ward — ground yourself',
      stat: 'grace',
      cost: 1,
      type: 'defense',
      tier: 1,
      effectProfile: 'windWard',
      desc: '2D6+Grace. Resist wind shear. Restore 1 Vit if 10+',
    },
    aetherSeal: {
      id: 'aetherSeal',
      label: 'Aether Seal — close the leak',
      stat: 'wits',
      cost: 1,
      type: 'defense',
      tier: 2,
      effectProfile: 'aetherSeal',
      desc: '2D6+Wits. Drain aether pool. Gain scrap on 10+',
    },
    rest: {
      id: 'rest',
      label: 'Rest — lower your heat',
      stat: null,
      cost: 0,
      type: 'rest',
      tier: 0,
      effectProfile: 'rest',
      desc: 'Reduce current heat by 1. Recover 1 Vit on 10+',
    },
  });

  function validateDefs() {
    const ids = Object.keys(DEFS);

    if (ids.length !== ACTION_ORDER.length) {
      throw new Error('ABILITY_DEF_COUNT_MISMATCH');
    }
    if (new Set(ACTION_ORDER).size !== ACTION_ORDER.length) {
      throw new Error('ABILITY_ACTION_ORDER_DUPLICATE');
    }

    ACTION_ORDER.forEach(id => {
      const def = DEFS[id];
      if (!def) throw new Error('ABILITY_DEF_MISSING:' + id);
      if (def.id !== id) throw new Error('ABILITY_DEF_ID_MISMATCH:' + id);
      if (def.effectProfile !== id) {
        throw new Error('ABILITY_EFFECT_PROFILE_BINDING_INVALID:' + id);
      }
      if (typeof def.label !== 'string' || !def.label) {
        throw new Error('ABILITY_LABEL_INVALID:' + id);
      }
      if (typeof def.cost !== 'number' || typeof def.tier !== 'number') {
        throw new Error('ABILITY_COST_OR_TIER_INVALID:' + id);
      }
      if (typeof def.type !== 'string' || !def.type) {
        throw new Error('ABILITY_TYPE_INVALID:' + id);
      }
    });

    const orphans = ids.filter(id => !ACTION_ORDER.includes(id));
    if (orphans.length) throw new Error('ABILITY_DEF_ORPHANS:' + orphans.join(','));

    return true;
  }

  function createRuntimeActions() {
    validateDefs();
    return ACTION_ORDER.map(id => Object.assign({}, DEFS[id]));
  }

  function assertRuntimeActions(actions) {
    if (!Array.isArray(actions)) throw new Error('RUNTIME_ACTIONS_MUST_BE_ARRAY');
    if (actions.length !== ACTION_ORDER.length) throw new Error('RUNTIME_ACTION_COUNT_MISMATCH');

    actions.forEach((action, index) => {
      const expectedId = ACTION_ORDER[index];
      const expected = DEFS[expectedId];

      if (!action || action.id !== expectedId) {
        throw new Error('RUNTIME_ACTION_ORDER_MISMATCH:' + expectedId);
      }

      ['label', 'stat', 'cost', 'type', 'tier', 'effectProfile', 'desc'].forEach(key => {
        if (action[key] !== expected[key]) {
          throw new Error('RUNTIME_ACTION_FIELD_MISMATCH:' + expectedId + ':' + key);
        }
      });
    });

    return true;
  }

  validateDefs();

  return Object.freeze({
    VERSION,
    ACTION_ORDER,
    DEFS,
    validateDefs,
    createRuntimeActions,
    assertRuntimeActions,
  });
});
