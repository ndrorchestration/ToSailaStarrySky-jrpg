/* ============================================================
   Aetherwake JRPG — Production Formula Engine v1.0
   Binds declarative actions to the research-backed JRPG stat model.
   No PbtA outcome bands. RNG is injected and bounded.
   ============================================================ */

(function (root, factory) {
  'use strict';
  let policy = root && root.AetherCombatSystemPolicy;
  let statModel = root && root.AetherJRPGStatModel;
  if (typeof module === 'object' && module.exports) {
    policy = policy || require('./combat-system-policy.js');
    statModel = statModel || require('./jrpg-stat-model.js');
  }
  const api = factory(policy, statModel);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherCombatFormula = api;
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null),
function (policy, statModel) {
  'use strict';

  if (!policy || typeof policy.validate !== 'function') {
    throw new Error('COMBAT_FORMULA_POLICY_REQUIRED');
  }
  if (!statModel || typeof statModel.resolveDamage !== 'function') {
    throw new Error('COMBAT_FORMULA_STAT_MODEL_REQUIRED');
  }
  policy.validate();

  const VERSION = '1.1.0';

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
      scalingStat: 'might',
      scaling: 1.0,
      defenseStat: 'aetherDefense',
      accuracyPolicy: { mode: 'guaranteed' },
      criticalPolicy: { mode: 'chance', chance: 0.10 },
      variancePolicy: { mode: 'bounded' },
      dedicatedCost: { resource: 'staffCharges', amount: 1 },
    },
    uncoverTruth: {
      id: 'uncoverTruth',
      model: 'jrpg-stat-formula',
      kind: 'analysis',
      reveal: 'weakness',
      nextDamageMultiplier: 1.15,
      charges: 1,
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

  function getFormula(actionId) {
    const formula = FORMULAS[actionId];
    return formula ? JSON.parse(JSON.stringify(formula)) : null;
  }

  function actorPrimary(actor) {
    if (!actor || typeof actor !== 'object') throw new Error('COMBAT_FORMULA_ACTOR_REQUIRED');
    if (actor.productionStats) return actor.productionStats;
    // Explicit compatibility fallback for test/migration callers only.
    return actor;
  }

  function targetDerived(target) {
    if (!target || typeof target !== 'object') throw new Error('COMBAT_FORMULA_TARGET_REQUIRED');
    return target.productionDerivedStats || target;
  }

  function currentResource(actor, key, fallback) {
    if (!actor) return fallback;
    const value = actor[key];
    if (typeof value === 'number' && Number.isFinite(value)) return value;
    if (value && typeof value.current === 'number' && Number.isFinite(value.current)) return value.current;
    return fallback;
  }

  function nextRandom(randomFn) {
    if (typeof randomFn !== 'function') throw new Error('COMBAT_FORMULA_RANDOM_REQUIRED');
    const value = randomFn();
    if (!Number.isFinite(value) || value < 0 || value >= 1) {
      throw new Error('COMBAT_FORMULA_RANDOM_OUT_OF_RANGE');
    }
    return value;
  }

  function resolveDamage(actionId, actor, target, randomFn) {
    const formula = FORMULAS[actionId];
    if (!formula) throw new Error('COMBAT_FORMULA_UNKNOWN_ACTION:' + actionId);
    if (formula.kind !== 'damage') throw new Error('COMBAT_FORMULA_NOT_DAMAGE_ACTION:' + actionId);

    const primary = actorPrimary(actor);
    const derived = targetDerived(target);
    const defense = Number(derived[formula.defenseStat] || 0);

    let hit = true;
    let hitChance = 1;
    let accuracyRoll = null;
    if (formula.accuracyPolicy.mode !== 'guaranteed') {
      hitChance = statModel.resolveHitChance({
        baseAccuracy: formula.accuracyPolicy.baseAccuracy,
        attackerAccuracy: actor.productionDerivedStats && actor.productionDerivedStats.accuracy,
        defenderEvasion: derived.evasion,
      });
      accuracyRoll = nextRandom(randomFn);
      hit = accuracyRoll < hitChance;
    }
    if (!hit) {
      return Object.freeze({
        actionId, kind:'damage', model:formula.model, hit:false,
        critical:false, damage:0, hitChance, accuracyRoll,
      });
    }

    const varianceRng = formula.variancePolicy.mode === 'bounded' ? nextRandom(randomFn) : 0.5;
    const critRng = formula.criticalPolicy.mode === 'chance' ? nextRandom(randomFn) : 0.999999;

    const analysisMultiplier = target && target.analysis &&
      target.analysis.charges > 0
      ? Number(target.analysis.nextDamageMultiplier || 1)
      : 1;

    const result = statModel.resolveDamage({
      attacker: primary,
      scalingStat: formula.scalingStat,
      power: formula.power,
      scaling: formula.scaling,
      defense,
      allowVariance: formula.variancePolicy.mode === 'bounded',
      varianceRng,
      canCrit: formula.criticalPolicy.mode === 'chance',
      critRate: formula.criticalPolicy.chance,
      critRng,
      situationalMultiplier: analysisMultiplier,
    });

    return Object.freeze({
      actionId,
      model: formula.model,
      kind: formula.kind,
      damageType: formula.damageType,
      hit: true,
      hitChance,
      accuracyRoll,
      damage: result.damage,
      critical: result.critical,
      scalingStat: formula.scalingStat,
      scalingValue: primary[formula.scalingStat],
      defenseStat: formula.defenseStat,
      defenseValue: defense,
      defenseMultiplier: result.defenseMultiplier,
      varianceMultiplier: result.variance,
      dedicatedCost: Object.freeze({...formula.dedicatedCost}),
      consumedAnalysis: analysisMultiplier > 1,
      analysisMultiplier,
    });
  }

  function resolveAnalysis(actionId, actor, target) {
    const formula = FORMULAS[actionId];
    if (!formula) throw new Error('COMBAT_FORMULA_UNKNOWN_ACTION:' + actionId);
    if (formula.kind !== 'analysis') throw new Error('COMBAT_FORMULA_NOT_ANALYSIS_ACTION:' + actionId);
    if (!target || typeof target !== 'object') throw new Error('COMBAT_FORMULA_TARGET_REQUIRED');
    return Object.freeze({
      actionId,
      model: formula.model,
      kind: formula.kind,
      reveal: formula.reveal,
      weakness: target.weakness || null,
      modifier: Object.freeze({
        key: 'analyzed',
        nextDamageMultiplier: formula.nextDamageMultiplier,
        charges: formula.charges,
      }),
    });
  }

  function resolveResource(actionId, actor) {
    const formula = FORMULAS[actionId];
    if (!formula) throw new Error('COMBAT_FORMULA_UNKNOWN_ACTION:' + actionId);
    if (formula.kind !== 'resource') throw new Error('COMBAT_FORMULA_NOT_RESOURCE_ACTION:' + actionId);
    const current = Math.max(0, currentResource(actor, formula.resource, 0));
    const max = Math.max(current, currentResource(actor, formula.maxResource, current));
    const delta = Math.max(0, Math.min(formula.amount, max - current));
    return Object.freeze({
      actionId, model:formula.model, kind:formula.kind,
      resource:formula.resource, requestedAmount:formula.amount,
      delta, current, max, capped:delta < formula.amount,
    });
  }

  function resolveRecovery(actionId, actor) {
    const formula = FORMULAS[actionId];
    if (!formula) throw new Error('COMBAT_FORMULA_UNKNOWN_ACTION:' + actionId);
    if (formula.kind !== 'recovery') throw new Error('COMBAT_FORMULA_NOT_RECOVERY_ACTION:' + actionId);
    const heat = Math.max(0, currentResource(actor, 'heat', 0));
    const vit = Math.max(0, currentResource(actor, 'vit', 0));
    const maxVit = Math.max(vit, currentResource(actor, 'maxVit', vit));
    return Object.freeze({
      actionId, model:formula.model, kind:formula.kind,
      heatReduction:Math.min(formula.heatReduction, heat),
      vitalityRestore:Math.min(formula.vitalityRestore, Math.max(0, maxVit-vit)),
      heatBefore:heat, vitalityBefore:vit, vitalityMax:maxVit,
    });
  }

  function resolveAction(actionId, actor, target, randomFn) {
    const formula = FORMULAS[actionId];
    if (!formula) throw new Error('COMBAT_FORMULA_UNKNOWN_ACTION:' + actionId);
    if (formula.kind === 'damage') return resolveDamage(actionId, actor, target, randomFn);
    if (formula.kind === 'analysis') return resolveAnalysis(actionId, actor, target);
    if (formula.kind === 'resource') return resolveResource(actionId, actor);
    if (formula.kind === 'recovery') return resolveRecovery(actionId, actor);
    throw new Error('COMBAT_FORMULA_KIND_NOT_RESOLVABLE:' + formula.kind);
  }

  function validateAgainstAbilityDefs(abilityDefs) {
    if (!abilityDefs || !abilityDefs.DEFS) throw new Error('COMBAT_FORMULA_ABILITY_DEFS_REQUIRED');
    Object.keys(FORMULAS).forEach(actionId => {
      const ability = abilityDefs.DEFS[actionId];
      if (!ability || !ability.resolution ||
          ability.resolution.model !== policy.TARGET.model ||
          ability.resolution.formulaId !== actionId) {
        throw new Error('COMBAT_FORMULA_ABILITY_BINDING_DRIFT:' + actionId);
      }
    });
    return true;
  }

  return Object.freeze({
    VERSION, FORMULAS, getFormula,
    resolveDamage, resolveAnalysis, resolveResource, resolveRecovery, resolveAction,
    validateAgainstAbilityDefs,
  });
});
