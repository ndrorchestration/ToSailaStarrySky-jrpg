/* ============================================================
   Aetherwake JRPG — Combat Formula Resolver v0.3
   modules/combat-formula.js

   Production formula migration:
   - resolves formula-driven combat actions without PbtA outcome bands;
   - keeps bounded RNG explicit and injectable for deterministic tests;
   - supports numeric damage, deterministic resource, and recovery formulas;
   - Staff Strike, Hold, and Rest are the first migrated actions.

   This module resolves numeric action results only. State mutation remains
   owned by the effect resolver.
   ============================================================ */

(function (root, factory) {
  'use strict';

  let policy = root && root.AetherCombatSystemPolicy;
  if (typeof module === 'object' && module.exports) {
    policy = policy || require('./combat-system-policy.js');
  }

  const api = factory(policy);

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherCombatFormula = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null),
function (policy) {
  'use strict';

  if (!policy || typeof policy.validate !== 'function') {
    throw new Error('COMBAT_FORMULA_POLICY_REQUIRED');
  }
  policy.validate();

  const VERSION = '0.3.0';

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  const FORMULAS = deepFreeze({
    staffStrike: {
      id: 'staffStrike',
      model: 'jrpg-stat-formula',
      kind: 'damage',
      damageType: 'emp',
      power: 5,
      scaling: {
        stat: 'might',
        coefficient: 1,
      },
      defenseInteraction: {
        stat: 'empDefense',
        coefficient: 1,
        fallback: 0,
      },
      accuracyPolicy: {
        mode: 'guaranteed',
      },
      criticalPolicy: {
        mode: 'chance',
        chance: 0.10,
        multiplier: 1.5,
      },
      variancePolicy: {
        mode: 'bounded',
        min: 0.95,
        max: 1.05,
      },
      minimumDamage: 1,
      dedicatedCost: {
        resource: 'staffCharges',
        amount: 1,
      },
    },
    hold: {
      id: 'hold',
      model: 'jrpg-stat-formula',
      kind: 'resource',
      resource: 'staffCharges',
      amount: 1,
      maxResource: 'maxStaffCharges',
    },
    rest: {
      id: 'rest',
      model: 'jrpg-stat-formula',
      kind: 'recovery',
      heatReduction: 2,
      vitalityRestore: 1,
    },
  });

  function finite(value, code) {
    if (typeof value !== 'number' || !Number.isFinite(value)) throw new Error(code);
    return value;
  }

  function probability(value, code) {
    finite(value, code);
    if (value < 0 || value > 1) throw new Error(code);
    return value;
  }

  function validateDamageFormula(formula) {
    if (typeof formula.damageType !== 'string' || !formula.damageType) {
      throw new Error('FORMULA_DAMAGE_TYPE_REQUIRED');
    }
    finite(formula.power, 'FORMULA_POWER_INVALID');
    if (!formula.scaling || typeof formula.scaling.stat !== 'string') {
      throw new Error('FORMULA_SCALING_INVALID');
    }
    finite(formula.scaling.coefficient, 'FORMULA_SCALING_INVALID');
    if (!formula.defenseInteraction || typeof formula.defenseInteraction.stat !== 'string') {
      throw new Error('FORMULA_DEFENSE_INVALID');
    }
    finite(formula.defenseInteraction.coefficient, 'FORMULA_DEFENSE_INVALID');
    finite(formula.defenseInteraction.fallback, 'FORMULA_DEFENSE_INVALID');

    if (!formula.accuracyPolicy ||
        !['guaranteed', 'chance'].includes(formula.accuracyPolicy.mode)) {
      throw new Error('FORMULA_ACCURACY_POLICY_INVALID');
    }
    if (formula.accuracyPolicy.mode === 'chance') {
      probability(formula.accuracyPolicy.chance, 'FORMULA_ACCURACY_CHANCE_INVALID');
    }

    if (!formula.criticalPolicy ||
        !['disabled', 'chance'].includes(formula.criticalPolicy.mode)) {
      throw new Error('FORMULA_CRITICAL_POLICY_INVALID');
    }
    if (formula.criticalPolicy.mode === 'chance') {
      probability(formula.criticalPolicy.chance, 'FORMULA_CRITICAL_CHANCE_INVALID');
      finite(formula.criticalPolicy.multiplier, 'FORMULA_CRITICAL_MULTIPLIER_INVALID');
      if (formula.criticalPolicy.multiplier < 1) {
        throw new Error('FORMULA_CRITICAL_MULTIPLIER_INVALID');
      }
    }

    if (!formula.variancePolicy ||
        !['disabled', 'bounded'].includes(formula.variancePolicy.mode)) {
      throw new Error('FORMULA_VARIANCE_POLICY_INVALID');
    }
    if (formula.variancePolicy.mode === 'bounded') {
      finite(formula.variancePolicy.min, 'FORMULA_VARIANCE_INVALID');
      finite(formula.variancePolicy.max, 'FORMULA_VARIANCE_INVALID');
      if (formula.variancePolicy.min <= 0 ||
          formula.variancePolicy.max < formula.variancePolicy.min) {
        throw new Error('FORMULA_VARIANCE_INVALID');
      }
    }

    finite(formula.minimumDamage, 'FORMULA_MIN_DAMAGE_INVALID');
    if (formula.minimumDamage < 0) throw new Error('FORMULA_MIN_DAMAGE_INVALID');

    if (!formula.dedicatedCost ||
        typeof formula.dedicatedCost.resource !== 'string' ||
        !formula.dedicatedCost.resource) {
      throw new Error('FORMULA_DEDICATED_COST_INVALID');
    }
    finite(formula.dedicatedCost.amount, 'FORMULA_DEDICATED_COST_INVALID');
    if (formula.dedicatedCost.amount < 0) {
      throw new Error('FORMULA_DEDICATED_COST_INVALID');
    }
  }

  function validateResourceFormula(formula) {
    if (typeof formula.resource !== 'string' || !formula.resource) {
      throw new Error('FORMULA_RESOURCE_REQUIRED');
    }
    finite(formula.amount, 'FORMULA_RESOURCE_AMOUNT_INVALID');
    if (formula.amount < 0) throw new Error('FORMULA_RESOURCE_AMOUNT_INVALID');
    if (typeof formula.maxResource !== 'string' || !formula.maxResource) {
      throw new Error('FORMULA_RESOURCE_MAX_REQUIRED');
    }
  }

  function validateRecoveryFormula(formula) {
    finite(formula.heatReduction, 'FORMULA_RECOVERY_HEAT_INVALID');
    finite(formula.vitalityRestore, 'FORMULA_RECOVERY_VITALITY_INVALID');
    if (formula.heatReduction < 0) throw new Error('FORMULA_RECOVERY_HEAT_INVALID');
    if (formula.vitalityRestore < 0) throw new Error('FORMULA_RECOVERY_VITALITY_INVALID');
  }

  function validateFormula(formula) {
    if (!formula || typeof formula !== 'object') throw new Error('FORMULA_REQUIRED');
    if (formula.model !== policy.TARGET.model) throw new Error('FORMULA_MODEL_INVALID');
    if (typeof formula.id !== 'string' || !formula.id) throw new Error('FORMULA_ID_REQUIRED');

    if (formula.kind === 'damage') {
      validateDamageFormula(formula);
    } else if (formula.kind === 'resource') {
      validateResourceFormula(formula);
    } else if (formula.kind === 'recovery') {
      validateRecoveryFormula(formula);
    } else {
      throw new Error('FORMULA_KIND_NOT_SUPPORTED');
    }
    return true;
  }

  function getFormula(actionId) {
    const formula = FORMULAS[actionId];
    return formula ? JSON.parse(JSON.stringify(formula)) : null;
  }

  function readStat(subject, stat, fallback) {
    if (subject && typeof subject[stat] === 'number' && Number.isFinite(subject[stat])) {
      return subject[stat];
    }
    return fallback;
  }

  function readResource(subject, key, fallback) {
    if (!subject) return fallback;
    const value = subject[key];
    if (typeof value === 'number' && Number.isFinite(value)) return value;
    if (value && typeof value.current === 'number' && Number.isFinite(value.current)) {
      return value.current;
    }
    return fallback;
  }

  function nextRandom(randomFn) {
    if (typeof randomFn !== 'function') throw new Error('COMBAT_FORMULA_RANDOM_REQUIRED');
    const value = randomFn();
    if (typeof value !== 'number' || !Number.isFinite(value) || value < 0 || value >= 1) {
      throw new Error('COMBAT_FORMULA_RANDOM_OUT_OF_RANGE');
    }
    return value;
  }

  function resolveDamage(actionId, actor, target, randomFn) {
    const formula = FORMULAS[actionId];
    if (!formula) throw new Error('COMBAT_FORMULA_UNKNOWN_ACTION:' + actionId);
    validateFormula(formula);
    if (formula.kind !== 'damage') {
      throw new Error('COMBAT_FORMULA_NOT_DAMAGE_ACTION:' + actionId);
    }
    if (!actor || typeof actor !== 'object') throw new Error('COMBAT_FORMULA_ACTOR_REQUIRED');
    if (!target || typeof target !== 'object') throw new Error('COMBAT_FORMULA_TARGET_REQUIRED');

    let hit = true;
    let accuracyRoll = null;
    if (formula.accuracyPolicy.mode === 'chance') {
      accuracyRoll = nextRandom(randomFn);
      hit = accuracyRoll < formula.accuracyPolicy.chance;
    }

    if (!hit) {
      return {
        actionId,
        model: formula.model,
        kind: formula.kind,
        damageType: formula.damageType,
        hit: false,
        critical: false,
        damage: 0,
        basePower: formula.power,
        scalingStat: formula.scaling.stat,
        scalingValue: readStat(actor, formula.scaling.stat, 0),
        defenseStat: formula.defenseInteraction.stat,
        defenseValue: readStat(
          target,
          formula.defenseInteraction.stat,
          formula.defenseInteraction.fallback
        ),
        accuracyRoll,
        varianceMultiplier: null,
        criticalRoll: null,
        dedicatedCost: JSON.parse(JSON.stringify(formula.dedicatedCost)),
      };
    }

    const scalingValue = readStat(actor, formula.scaling.stat, 0);
    const defenseValue = readStat(
      target,
      formula.defenseInteraction.stat,
      formula.defenseInteraction.fallback
    );
    const scaledPower = formula.power +
      scalingValue * formula.scaling.coefficient;
    const mitigation = defenseValue * formula.defenseInteraction.coefficient;
    const preVariance = Math.max(formula.minimumDamage, scaledPower - mitigation);

    let varianceMultiplier = 1;
    if (formula.variancePolicy.mode === 'bounded') {
      const varianceRoll = nextRandom(randomFn);
      varianceMultiplier = formula.variancePolicy.min +
        varianceRoll * (formula.variancePolicy.max - formula.variancePolicy.min);
    }

    let damage = Math.max(
      formula.minimumDamage,
      Math.round(preVariance * varianceMultiplier)
    );

    let critical = false;
    let criticalRoll = null;
    if (formula.criticalPolicy.mode === 'chance') {
      criticalRoll = nextRandom(randomFn);
      critical = criticalRoll < formula.criticalPolicy.chance;
      if (critical) {
        damage = Math.max(
          formula.minimumDamage,
          Math.round(damage * formula.criticalPolicy.multiplier)
        );
      }
    }

    return {
      actionId,
      model: formula.model,
      kind: formula.kind,
      damageType: formula.damageType,
      hit: true,
      critical,
      damage,
      basePower: formula.power,
      scaledPower,
      scalingStat: formula.scaling.stat,
      scalingValue,
      defenseStat: formula.defenseInteraction.stat,
      defenseValue,
      mitigation,
      accuracyRoll,
      varianceMultiplier,
      criticalRoll,
      dedicatedCost: JSON.parse(JSON.stringify(formula.dedicatedCost)),
    };
  }

  function resolveResource(actionId, actor) {
    const formula = FORMULAS[actionId];
    if (!formula) throw new Error('COMBAT_FORMULA_UNKNOWN_ACTION:' + actionId);
    validateFormula(formula);
    if (formula.kind !== 'resource') {
      throw new Error('COMBAT_FORMULA_NOT_RESOURCE_ACTION:' + actionId);
    }
    if (!actor || typeof actor !== 'object') throw new Error('COMBAT_FORMULA_ACTOR_REQUIRED');

    const current = Math.max(0, readResource(actor, formula.resource, 0));
    const rawMax = readResource(actor, formula.maxResource, current);
    const max = Math.max(current, rawMax);
    const delta = Math.max(0, Math.min(formula.amount, max - current));

    return {
      actionId,
      model: formula.model,
      kind: formula.kind,
      resource: formula.resource,
      requestedAmount: formula.amount,
      delta,
      current,
      max,
      capped: delta < formula.amount,
    };
  }

  function resolveRecovery(actionId, actor) {
    const formula = FORMULAS[actionId];
    if (!formula) throw new Error('COMBAT_FORMULA_UNKNOWN_ACTION:' + actionId);
    validateFormula(formula);
    if (formula.kind !== 'recovery') {
      throw new Error('COMBAT_FORMULA_NOT_RECOVERY_ACTION:' + actionId);
    }
    if (!actor || typeof actor !== 'object') throw new Error('COMBAT_FORMULA_ACTOR_REQUIRED');

    const heatCurrent = Math.max(0, readResource(actor, 'heat', 0));
    const vitCurrent = Math.max(0, readResource(actor, 'vit', 0));
    const vitMax = Math.max(vitCurrent, readResource(actor, 'maxVit', vitCurrent));

    const heatReduction = Math.min(formula.heatReduction, heatCurrent);
    const vitalityRestore = Math.min(
      formula.vitalityRestore,
      Math.max(0, vitMax - vitCurrent)
    );

    return {
      actionId,
      model: formula.model,
      kind: formula.kind,
      requestedHeatReduction: formula.heatReduction,
      heatReduction,
      requestedVitalityRestore: formula.vitalityRestore,
      vitalityRestore,
      heatBefore: heatCurrent,
      vitalityBefore: vitCurrent,
      vitalityMax: vitMax,
    };
  }

  function resolveAction(actionId, actor, target, randomFn) {
    const formula = FORMULAS[actionId];
    if (!formula) throw new Error('COMBAT_FORMULA_UNKNOWN_ACTION:' + actionId);
    if (formula.kind === 'damage') {
      return resolveDamage(actionId, actor, target, randomFn);
    }
    if (formula.kind === 'resource') {
      return resolveResource(actionId, actor);
    }
    if (formula.kind === 'recovery') {
      return resolveRecovery(actionId, actor);
    }
    throw new Error('COMBAT_FORMULA_KIND_NOT_RESOLVABLE:' + formula.kind);
  }

  function validateAgainstAbilityDefs(abilityDefs) {
    if (!abilityDefs || !abilityDefs.DEFS) {
      throw new Error('COMBAT_FORMULA_ABILITY_DEFS_REQUIRED');
    }
    Object.keys(FORMULAS).forEach(actionId => {
      const formula = FORMULAS[actionId];
      validateFormula(formula);
      const ability = abilityDefs.DEFS[actionId];
      if (!ability) throw new Error('COMBAT_FORMULA_ABILITY_MISSING:' + actionId);
      if (!ability.resolution ||
          ability.resolution.model !== formula.model ||
          ability.resolution.formulaId !== formula.id) {
        throw new Error('COMBAT_FORMULA_ABILITY_BINDING_DRIFT:' + actionId);
      }
    });
    return true;
  }

  Object.keys(FORMULAS).forEach(id => validateFormula(FORMULAS[id]));

  return Object.freeze({
    VERSION,
    FORMULAS,
    validateFormula,
    getFormula,
    resolveDamage,
    resolveResource,
    resolveRecovery,
    resolveAction,
    validateAgainstAbilityDefs,
  });
});
