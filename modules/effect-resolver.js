/* ============================================================
   Aetherwake JRPG — Effect Resolver v0.1
   modules/effect-resolver.js

   Stage 1 resolver scaffold:
   - Pure mutation engine for ordinary damage, restoration, and resource deltas.
   - Uses the frozen effect vocabulary.
   - Fails closed on unsupported implemented effect kinds.
   - Treats DECLARED_NOT_APPLIED effects as explicit no-ops.
   - Not yet wired into live combat resolution in this commit.
   ============================================================ */

(function (root, factory) {
  'use strict';

  let vocabulary = null;

  if (typeof module === 'object' && module.exports) {
    vocabulary = require('./effect-vocabulary.js');
  } else if (root) {
    vocabulary = root.AetherEffectVocabulary;
  }

  const api = factory(vocabulary);

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherEffectResolver = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function (vocabulary) {
  'use strict';

  if (!vocabulary) {
    throw new Error('EFFECT_RESOLVER_REQUIRES_VOCABULARY');
  }

  const VERSION = '0.1.0';

  function finiteNonNegative(value, code) {
    if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
      throw new Error(code);
    }
    return value;
  }

  function requireContext(context) {
    if (!context || typeof context !== 'object' || !context.player) {
      throw new Error('EFFECT_RESOLVER_REQUIRES_PLAYER_CONTEXT');
    }
    return context;
  }

  function implementedDescriptor(kind, target, operation, key, amount) {
    return {
      kind,
      target,
      operation,
      key: key || null,
      runtimeStatus: vocabulary.RUNTIME_STATUS.IMPLEMENTED,
      note: null,
      amount,
    };
  }

  function createDamageEffect(target, amount, key) {
    finiteNonNegative(amount, 'DAMAGE_AMOUNT_INVALID');
    return implementedDescriptor(
      vocabulary.EFFECT_KIND.DAMAGE,
      target,
      vocabulary.OPERATION.APPLY,
      key || 'vitality',
      amount
    );
  }

  function createRestoreEffect(target, amount, key) {
    finiteNonNegative(amount, 'RESTORE_AMOUNT_INVALID');
    return implementedDescriptor(
      vocabulary.EFFECT_KIND.RESTORE,
      target,
      vocabulary.OPERATION.RESTORE,
      key || 'vitality',
      amount
    );
  }

  function createResourceDeltaEffect(resource, delta) {
    if (typeof delta !== 'number' || !Number.isFinite(delta)) {
      throw new Error('RESOURCE_DELTA_INVALID');
    }

    const operation = delta < 0
      ? vocabulary.OPERATION.DECREASE
      : vocabulary.OPERATION.INCREASE;

    return implementedDescriptor(
      vocabulary.EFFECT_KIND.RESOURCE,
      vocabulary.TARGET.SELF,
      operation,
      resource,
      Math.abs(delta)
    );
  }

  function mutationResult(effect, before, after) {
    return {
      applied: true,
      kind: effect.kind,
      target: effect.target,
      key: effect.key,
      operation: effect.operation,
      requestedAmount: effect.amount,
      before,
      after,
      delta: after - before,
    };
  }

  function noOpResult(effect, reason) {
    return {
      applied: false,
      kind: effect.kind,
      target: effect.target,
      key: effect.key,
      operation: effect.operation,
      requestedAmount: effect.amount == null ? null : effect.amount,
      reason,
    };
  }

  function applyDamage(effect, context) {
    const amount = finiteNonNegative(effect.amount, 'DAMAGE_AMOUNT_INVALID');

    if (effect.target === vocabulary.TARGET.SELF) {
      const before = context.player.vit;
      if (typeof before !== 'number') throw new Error('PLAYER_VITALITY_INVALID');
      const after = Math.max(0, before - amount);
      context.player.vit = after;
      return mutationResult(effect, before, after);
    }

    if (effect.target === vocabulary.TARGET.ENEMY) {
      if (!context.enemy || typeof context.enemy.hp !== 'number') {
        throw new Error('ENEMY_HP_UNAVAILABLE');
      }
      const before = context.enemy.hp;
      // Preserve the current runtime's behavior: enemy HP is not clamped here.
      const after = before - amount;
      context.enemy.hp = after;
      return mutationResult(effect, before, after);
    }

    throw new Error('DAMAGE_TARGET_NOT_SUPPORTED:' + effect.target);
  }

  function applyRestore(effect, context) {
    const amount = finiteNonNegative(effect.amount, 'RESTORE_AMOUNT_INVALID');

    if (effect.target !== vocabulary.TARGET.SELF) {
      throw new Error('RESTORE_TARGET_NOT_SUPPORTED:' + effect.target);
    }
    if (effect.key !== 'vitality') {
      throw new Error('RESTORE_KEY_NOT_SUPPORTED:' + effect.key);
    }

    const before = context.player.vit;
    const max = context.player.maxVit;

    if (typeof before !== 'number' || typeof max !== 'number') {
      throw new Error('PLAYER_VITALITY_INVALID');
    }

    const after = Math.min(max, before + amount);
    context.player.vit = after;
    return mutationResult(effect, before, after);
  }

  function resourceSlot(context, key) {
    const player = context.player;

    if (key === vocabulary.RESOURCE.AETHER ||
        key === vocabulary.RESOURCE.HEAT ||
        key === vocabulary.RESOURCE.ECHOES) {
      const slot = player[key];
      if (!slot || typeof slot.current !== 'number' || typeof slot.max !== 'number') {
        throw new Error('RESOURCE_SLOT_INVALID:' + key);
      }
      return {
        get: () => slot.current,
        set: value => { slot.current = value; },
        min: 0,
        max: slot.max,
      };
    }

    if (key === vocabulary.RESOURCE.SCRAP) {
      if (typeof player.scrap !== 'number') throw new Error('RESOURCE_SLOT_INVALID:scrap');
      return {
        get: () => player.scrap,
        set: value => { player.scrap = value; },
        min: 0,
        max: Infinity,
      };
    }

    if (key === vocabulary.RESOURCE.STAFF_CHARGES) {
      if (typeof player.staffCharges !== 'number') {
        throw new Error('RESOURCE_SLOT_INVALID:staffCharges');
      }
      const max = typeof context.staffChargeMax === 'number'
        ? context.staffChargeMax
        : (typeof player.maxStaffCharges === 'number' ? player.maxStaffCharges : Infinity);
      return {
        get: () => player.staffCharges,
        set: value => { player.staffCharges = value; },
        min: 0,
        max,
      };
    }

    throw new Error('RESOURCE_NOT_SUPPORTED:' + key);
  }

  function applyResource(effect, context) {
    if (effect.target !== vocabulary.TARGET.SELF) {
      throw new Error('RESOURCE_TARGET_NOT_SUPPORTED:' + effect.target);
    }

    const amount = finiteNonNegative(effect.amount, 'RESOURCE_AMOUNT_INVALID');
    const slot = resourceSlot(context, effect.key);
    const before = slot.get();

    let rawAfter;
    if (effect.operation === vocabulary.OPERATION.INCREASE) {
      rawAfter = before + amount;
    } else if (effect.operation === vocabulary.OPERATION.DECREASE) {
      rawAfter = before - amount;
    } else {
      throw new Error('RESOURCE_OPERATION_NOT_SUPPORTED:' + effect.operation);
    }

    const after = Math.min(slot.max, Math.max(slot.min, rawAfter));
    slot.set(after);
    return mutationResult(effect, before, after);
  }

  function applyEffect(effect, context) {
    requireContext(context);
    vocabulary.validateEffectDescriptor(effect);

    if (effect.runtimeStatus === vocabulary.RUNTIME_STATUS.DECLARED_NOT_APPLIED) {
      return noOpResult(effect, 'declared_not_applied');
    }

    if (effect.runtimeStatus !== vocabulary.RUNTIME_STATUS.IMPLEMENTED) {
      throw new Error('EFFECT_RUNTIME_STATUS_NOT_SUPPORTED:' + effect.runtimeStatus);
    }

    if (effect.kind === vocabulary.EFFECT_KIND.DAMAGE) {
      return applyDamage(effect, context);
    }
    if (effect.kind === vocabulary.EFFECT_KIND.RESTORE) {
      return applyRestore(effect, context);
    }
    if (effect.kind === vocabulary.EFFECT_KIND.RESOURCE) {
      return applyResource(effect, context);
    }

    throw new Error('EFFECT_KIND_NOT_EXECUTABLE_YET:' + effect.kind);
  }

  function applyEffects(effects, context) {
    if (!Array.isArray(effects)) throw new Error('EFFECT_SEQUENCE_MUST_BE_ARRAY');
    return effects.map(effect => applyEffect(effect, context));
  }

  return Object.freeze({
    VERSION,
    createDamageEffect,
    createRestoreEffect,
    createResourceDeltaEffect,
    applyEffect,
    applyEffects,
  });
});
