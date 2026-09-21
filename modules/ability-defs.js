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

  const VERSION = '0.2.0';

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

  // Baseline actions are available independent of learned ability state.
  // All other actions require their ID to be present in actor.unlockedAbilities.
  const ALWAYS_AVAILABLE = Object.freeze([
    'staffStrike',
    'hold',
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
      resolution: { model: 'jrpg-stat-formula', formulaId: 'staffStrike' },
      desc: 'Formula-driven EMP strike. Uses 1 Resonator Staff charge.',
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
      resolution: { model: 'jrpg-stat-formula', formulaId: 'hold' },
      desc: 'Deterministically regain 1 staff charge, up to maximum.',
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
      resolution: { model: 'jrpg-stat-formula', formulaId: 'rest' },
      desc: 'Deterministically reduce Heat by up to 2 and restore up to 1 Vit.',
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
      if (def.resolution &&
          (def.resolution.model !== 'jrpg-stat-formula' ||
           def.resolution.formulaId !== id)) {
        throw new Error('ABILITY_FORMULA_BINDING_INVALID:' + id);
      }
      if ((id === 'staffStrike' || id === 'hold' || id === 'rest') && !def.resolution) {
        throw new Error('ABILITY_FORMULA_BINDING_MISSING:' + id);
      }
    });

    const orphans = ids.filter(id => !ACTION_ORDER.includes(id));
    if (orphans.length) throw new Error('ABILITY_DEF_ORPHANS:' + orphans.join(','));

    ALWAYS_AVAILABLE.forEach(id => {
      if (!DEFS[id]) throw new Error('ALWAYS_AVAILABLE_UNKNOWN_ACTION:' + id);
    });

    return true;
  }

  function isActionUnlocked(actor, actionId) {
    if (!DEFS[actionId]) return false;
    if (ALWAYS_AVAILABLE.includes(actionId)) return true;
    return Boolean(
      actor &&
      Array.isArray(actor.unlockedAbilities) &&
      actor.unlockedAbilities.includes(actionId)
    );
  }

  function getEligibleActionIds(actor) {
    return ACTION_ORDER.filter(id => isActionUnlocked(actor, id));
  }

  function getActionResourceCost(actionOrId) {
    const action = typeof actionOrId === 'string' ? DEFS[actionOrId] : actionOrId;
    if (!action || typeof action !== 'object') {
      throw new Error('UNKNOWN_ACTION_FOR_RESOURCE_COST:' + actionOrId);
    }

    const tier = action.tier == null ? 0 : action.tier;
    const cost = action.cost == null ? 0 : action.cost;

    if (!Number.isFinite(tier) || tier < 0 || !Number.isFinite(cost) || cost < 0) {
      throw new Error('ACTION_RESOURCE_COST_INVALID:' + (action.id || actionOrId));
    }

    // Preserve the current prototype rule exactly. This function centralizes
    // the rule; it does not redesign the economy.
    return tier + cost;
  }

  function currentResource(actor, key) {
    if (!actor) return 0;
    const value = actor[key];
    if (typeof value === 'number' && Number.isFinite(value)) return Math.max(0, value);
    if (value && typeof value.current === 'number' && Number.isFinite(value.current)) {
      return Math.max(0, value.current);
    }
    return 0;
  }

  function getAvailableActionResource(actor) {
    return currentResource(actor, 'echoes') + currentResource(actor, 'aether');
  }

  function getUseEligibility(actor, actionId) {
    const action = DEFS[actionId];
    if (!action) {
      return {
        canUse: false,
        reason: 'unknown_action',
        actionId,
        resourceCost: null,
        availableResource: getAvailableActionResource(actor),
      };
    }

    const resourceCost = getActionResourceCost(action);
    const availableResource = getAvailableActionResource(actor);

    if (!isActionUnlocked(actor, actionId)) {
      return {
        canUse: false,
        reason: 'locked',
        actionId,
        resourceCost,
        availableResource,
      };
    }

    if (actionId === 'staffStrike' && actor &&
        Object.prototype.hasOwnProperty.call(actor, 'staffCharges') &&
        currentResource(actor, 'staffCharges') < 1) {
      return {
        canUse: false,
        reason: 'insufficient_dedicated_resource',
        actionId,
        resourceCost,
        availableResource,
        dedicatedResource: 'staffCharges',
        dedicatedAvailable: currentResource(actor, 'staffCharges'),
      };
    }

    if (availableResource < resourceCost) {
      return {
        canUse: false,
        reason: 'insufficient_resources',
        actionId,
        resourceCost,
        availableResource,
      };
    }

    return {
      canUse: true,
      reason: 'ok',
      actionId,
      resourceCost,
      availableResource,
    };
  }

  function getUsableActionIds(actor) {
    return ACTION_ORDER.filter(id => getUseEligibility(actor, id).canUse);
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
      if (expected.resolution) {
        if (!action.resolution ||
            action.resolution.model !== expected.resolution.model ||
            action.resolution.formulaId !== expected.resolution.formulaId) {
          throw new Error('RUNTIME_ACTION_RESOLUTION_MISMATCH:' + expectedId);
        }
      }
    });

    return true;
  }

  validateDefs();

  return Object.freeze({
    VERSION,
    ACTION_ORDER,
    ALWAYS_AVAILABLE,
    DEFS,
    validateDefs,
    isActionUnlocked,
    getEligibleActionIds,
    getActionResourceCost,
    getAvailableActionResource,
    getUseEligibility,
    getUsableActionIds,
    createRuntimeActions,
    assertRuntimeActions,
  });
});
