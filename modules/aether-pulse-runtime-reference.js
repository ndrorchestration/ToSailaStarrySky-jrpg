/* ============================================================
   Aetherwake JRPG — Aether Pulse Legacy 2D6 Balance Reference v0.1
   modules/aether-pulse-runtime-reference.js

   Scope:
   - preserve a machine-readable snapshot of the preservation-era 2D6 combat
     scale for historical comparison only;
   - compare synthetic Pulse measurements to the legacy charged Staff Strike
     and preservation-era enemy HP bands;
   - fail closed on missing evaluator dependencies.

   This is a LEGACY 2D6 REFERENCE, not current Staff Strike behavior or a target balance specification,
   creator-canon decision, or authorization for Aether Pulse.
   ============================================================ */

(function (root, factory) {
  'use strict';

  let pulseEvaluation = root && root.AetherPulseSyntheticEvaluation;

  if (typeof module === 'object' && module.exports) {
    pulseEvaluation = pulseEvaluation ||
      require('./aether-pulse-synthetic-evaluation.js');
  }

  const api = factory(pulseEvaluation);

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherPulseRuntimeReference = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null),
function (pulseEvaluation) {
  'use strict';

  const VERSION = '0.1.0';
  const STATUS = 'legacy-2d6-reference';

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) {
      return value;
    }
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  const REFERENCE = deepFreeze({
    status: STATUS,
    authority: 'preservation-legacy-runtime-only',
    sourceFiles: [
      'modules/combat.js',
      'modules/ability-defs.js',
    ],
    ender: {
      wits: 2,
      might: -1,
      aetherCurrent: 4,
      aetherMax: 6,
      staffCharges: 2,
    },
    enemyHp: {
      aetherLeak: 8,
      corporateSalvager: 10,
      skyPredator: 12,
      windShear: 14,
    },
    staffStrike: {
      rollSystem: '2d6',
      stat: 'might',
      modifier: -1,
      registryCost: 0,
      dedicatedResource: 'staffCharges',
      dedicatedResourceConsumedOn: ['success', 'partial'],
      dedicatedResourceAmount: 1,
      chargedCastAssumption: true,
      enemyDamageMean: {
        success: 5.5,
        partial: 4.5,
        failure: 0,
      },
      selfDamageMean: {
        success: 0,
        partial: 1,
        failure: 3,
      },
    },
    caveats: [
      'Reference describes preservation-era 2D6 behavior, not current Staff Strike behavior or final combat balance.',
      'Staff Strike damage assumes at least one staff charge is available.',
      'Generic prototype action resources must not define Aether Pulse resource semantics.',
      'Aether Pulse remains design_proposal / not_integrated / draft-unresolved.',
    ],
  });

  function requireEvaluator() {
    if (!pulseEvaluation ||
        typeof pulseEvaluation.getOutcomeCounts !== 'function' ||
        typeof pulseEvaluation.evaluateCandidate !== 'function') {
      throw new Error('AETHER_PULSE_SYNTHETIC_EVALUATOR_REQUIRED');
    }
  }

  function weightedMean(values, counts) {
    return (
      values.success * counts.success +
      values.partial * counts.partial +
      values.failure * counts.failure
    ) / counts.total;
  }

  function evaluateStaffStrike(modifier) {
    requireEvaluator();
    const resolvedModifier = modifier == null
      ? REFERENCE.staffStrike.modifier
      : modifier;
    const counts = pulseEvaluation.getOutcomeCounts(resolvedModifier);
    const expectedEnemyDamage = weightedMean(
      REFERENCE.staffStrike.enemyDamageMean,
      counts
    );
    const expectedSelfDamage = weightedMean(
      REFERENCE.staffStrike.selfDamageMean,
      counts
    );
    const expectedChargeConsumption = (
      counts.success + counts.partial
    ) / counts.total;

    return {
      status: STATUS,
      actionId: 'staffStrike',
      modifier: resolvedModifier,
      chargedCastAssumption: true,
      probabilities: {
        success: counts.success / counts.total,
        partial: counts.partial / counts.total,
        failure: counts.failure / counts.total,
        counts,
      },
      expectedEnemyDamage,
      expectedSelfDamage,
      expectedChargeConsumption,
      expectedEnemyDamagePerExpectedCharge:
        expectedChargeConsumption > 0
          ? expectedEnemyDamage / expectedChargeConsumption
          : null,
    };
  }

  function enemyCoverage(expectedDamage) {
    if (!Number.isFinite(expectedDamage) || expectedDamage < 0) {
      throw new Error('EXPECTED_DAMAGE_INVALID');
    }
    const result = {};
    Object.keys(REFERENCE.enemyHp).forEach(enemyId => {
      const hp = REFERENCE.enemyHp[enemyId];
      result[enemyId] = {
        hp,
        expectedHpFractionPerCast: hp > 0 ? expectedDamage / hp : null,
      };
    });
    return result;
  }

  function compareSyntheticPulse(candidate, pulseModifier) {
    requireEvaluator();
    const pulse = pulseEvaluation.evaluateCandidate(candidate, pulseModifier);
    const staff = evaluateStaffStrike();
    const castCapacityAtCurrentAether = Math.floor(
      REFERENCE.ender.aetherCurrent / pulse.resourceCost
    );
    const castCapacityAtMaxAether = Math.floor(
      REFERENCE.ender.aetherMax / pulse.resourceCost
    );

    return {
      status: STATUS,
      synthetic: true,
      designEstablished: false,
      runtimeAuthorized: false,
      pulse,
      staffReference: staff,
      deltas: {
        expectedEnemyDamage:
          pulse.expectedEnemyDamage - staff.expectedEnemyDamage,
        expectedSelfDamage:
          pulse.expectedSelfDamage - staff.expectedSelfDamage,
      },
      ratios: {
        enemyDamageVsChargedStaff:
          staff.expectedEnemyDamage > 0
            ? pulse.expectedEnemyDamage / staff.expectedEnemyDamage
            : null,
      },
      resourceEnvelope: {
        currentAether: REFERENCE.ender.aetherCurrent,
        maxAether: REFERENCE.ender.aetherMax,
        costPerPulse: pulse.resourceCost,
        castCapacityAtCurrentAether,
        castCapacityAtMaxAether,
        expectedDamageAtCurrentAether:
          castCapacityAtCurrentAether * pulse.expectedEnemyDamage,
        expectedDamageAtMaxAether:
          castCapacityAtMaxAether * pulse.expectedEnemyDamage,
      },
      enemyCoverage: enemyCoverage(pulse.expectedEnemyDamage),
      boundary:
        'comparison against preservation-era 2D6 prototype only; no target design or runtime authority',
    };
  }

  return Object.freeze({
    VERSION,
    STATUS,
    REFERENCE,
    evaluateStaffStrike,
    enemyCoverage,
    compareSyntheticPulse,
  });
});
