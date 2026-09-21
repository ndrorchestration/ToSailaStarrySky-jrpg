/* ============================================================
   Aetherwake JRPG — Aether Pulse Synthetic Evaluation v0.2
   modules/aether-pulse-synthetic-evaluation.js

   Scope:
   - calculate exact 2D6 outcome probabilities for synthetic Aether Pulse
     balance candidates;
   - measure expected enemy damage, expected self-damage, and Aether
     efficiency across supplied stat modifiers;
   - keep every result explicitly synthetic and non-authorizing.

   This module does NOT establish Aether Pulse cost, stat, damage, ownership,
   execution, persistence, mastery, or runtime authorization.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherPulseSyntheticEvaluation = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.2.0';
  const STATUS = 'synthetic-test-only';
  const SPELL_ID = 'aetherPulse';
  const SCHOOL_ID = 'aether';
  const RESOURCE = 'aether';
  const DEFAULT_THRESHOLDS = Object.freeze({
    successMin: 10,
    partialMin: 7,
  });
  const PHASES = Object.freeze(['success', 'partial', 'failure']);

  function clone(value) {
    return value == null ? value : JSON.parse(JSON.stringify(value));
  }

  function finiteNonNegative(value, label) {
    if (!Number.isFinite(value) || value < 0) {
      throw new Error(label);
    }
    return value;
  }

  function validatePhaseMap(map, label) {
    if (!map || typeof map !== 'object') {
      throw new Error(label + '_MUST_BE_OBJECT');
    }
    PHASES.forEach(phase => {
      finiteNonNegative(map[phase], label + '_' + phase.toUpperCase() + '_INVALID');
    });
    return true;
  }

  function validateCandidate(candidate) {
    if (!candidate || typeof candidate !== 'object') {
      throw new Error('SYNTHETIC_CANDIDATE_MUST_BE_OBJECT');
    }
    if (candidate.status !== STATUS || candidate.synthetic !== true) {
      throw new Error('SYNTHETIC_CANDIDATE_BOUNDARY_REQUIRED');
    }
    if (candidate.spellId !== SPELL_ID || candidate.schoolId !== SCHOOL_ID) {
      throw new Error('SYNTHETIC_CANDIDATE_IDENTITY_INVALID');
    }
    if (typeof candidate.candidateId !== 'string' || !candidate.candidateId) {
      throw new Error('SYNTHETIC_CANDIDATE_ID_REQUIRED');
    }
    if (candidate.resource !== RESOURCE ||
        !Number.isFinite(candidate.resourceCost) ||
        candidate.resourceCost <= 0) {
      throw new Error('SYNTHETIC_CANDIDATE_AETHER_COST_INVALID');
    }
    if (typeof candidate.rollStat !== 'string' || !candidate.rollStat) {
      throw new Error('SYNTHETIC_CANDIDATE_ROLL_STAT_REQUIRED');
    }
    validatePhaseMap(candidate.enemyDamage, 'SYNTHETIC_ENEMY_DAMAGE');

    if (candidate.selfDamage == null) {
      candidate = Object.assign({}, candidate, {
        selfDamage: { success: 0, partial: 0, failure: 0 },
      });
    } else {
      validatePhaseMap(candidate.selfDamage, 'SYNTHETIC_SELF_DAMAGE');
    }

    return clone(candidate);
  }

  function validateThresholds(successMin, partialMin) {
    if (!Number.isInteger(successMin) ||
        !Number.isInteger(partialMin) ||
        successMin <= partialMin) {
      throw new Error('SYNTHETIC_2D6_THRESHOLDS_INVALID');
    }
  }

  function getOutcomeCounts(modifier, thresholds) {
    if (!Number.isInteger(modifier)) {
      throw new Error('SYNTHETIC_2D6_MODIFIER_MUST_BE_INTEGER');
    }

    const config = Object.assign({}, DEFAULT_THRESHOLDS, thresholds || {});
    validateThresholds(config.successMin, config.partialMin);

    const counts = {
      success: 0,
      partial: 0,
      failure: 0,
      total: 36,
    };

    for (let d1 = 1; d1 <= 6; d1 += 1) {
      for (let d2 = 1; d2 <= 6; d2 += 1) {
        const total = d1 + d2 + modifier;
        if (total >= config.successMin) {
          counts.success += 1;
        } else if (total >= config.partialMin) {
          counts.partial += 1;
        } else {
          counts.failure += 1;
        }
      }
    }

    return counts;
  }

  function getOutcomeProbabilities(modifier, thresholds) {
    const counts = getOutcomeCounts(modifier, thresholds);
    return {
      success: counts.success / counts.total,
      partial: counts.partial / counts.total,
      failure: counts.failure / counts.total,
      counts,
    };
  }

  function weightedNumerator(values, counts) {
    return (
      values.success * counts.success +
      values.partial * counts.partial +
      values.failure * counts.failure
    );
  }

  function evaluateCandidate(candidate, modifier, thresholds) {
    const checked = validateCandidate(candidate);
    const probabilities = getOutcomeProbabilities(modifier, thresholds);
    const counts = probabilities.counts;

    const enemyNumerator = weightedNumerator(checked.enemyDamage, counts);
    const selfNumerator = weightedNumerator(checked.selfDamage, counts);
    const expectedEnemyDamage = enemyNumerator / counts.total;
    const expectedSelfDamage = selfNumerator / counts.total;

    return {
      status: STATUS,
      synthetic: true,
      designEstablished: false,
      runtimeAuthorized: false,
      spellId: SPELL_ID,
      schoolId: SCHOOL_ID,
      candidateId: checked.candidateId,
      resource: RESOURCE,
      resourceCost: checked.resourceCost,
      rollStat: checked.rollStat,
      modifier,
      probabilities,
      expectedEnemyDamage,
      expectedEnemyDamageNumerator: enemyNumerator,
      expectedSelfDamage,
      expectedSelfDamageNumerator: selfNumerator,
      expectedEnemyDamagePerAether: expectedEnemyDamage / checked.resourceCost,
      boundary: 'synthetic measurement only; no design or runtime authority',
    };
  }


  function validateCandidateSet(candidates) {
    if (!Array.isArray(candidates) || candidates.length === 0) {
      throw new Error('SYNTHETIC_CANDIDATE_SET_REQUIRED');
    }

    const checked = candidates.map(validateCandidate);
    const ids = checked.map(candidate => candidate.candidateId);
    if (new Set(ids).size !== ids.length) {
      throw new Error('SYNTHETIC_CANDIDATE_SET_DUPLICATE_ID');
    }
    return checked;
  }

  function evaluateCandidateSet(candidates, modifier, thresholds) {
    const checked = validateCandidateSet(candidates);
    return checked.map(candidate =>
      evaluateCandidate(candidate, modifier, thresholds)
    );
  }

  function validateModifierSet(modifiers) {
    if (!Array.isArray(modifiers) || modifiers.length === 0) {
      throw new Error('SYNTHETIC_MODIFIER_SET_REQUIRED');
    }
    if (new Set(modifiers).size !== modifiers.length) {
      throw new Error('SYNTHETIC_MODIFIER_SET_DUPLICATE');
    }
    modifiers.forEach(modifier => {
      if (!Number.isInteger(modifier)) {
        throw new Error('SYNTHETIC_2D6_MODIFIER_MUST_BE_INTEGER');
      }
    });
    return modifiers.slice();
  }

  function evaluateCandidateSetAcrossModifiers(candidates, modifiers, thresholds) {
    const checked = validateCandidateSet(candidates);
    const modifierSet = validateModifierSet(modifiers);

    return modifierSet.map(modifier => ({
      modifier,
      evaluations: checked.map(candidate =>
        evaluateCandidate(candidate, modifier, thresholds)
      ),
    }));
  }

  function validateEvaluationForFrontier(evaluation) {
    if (!evaluation ||
        evaluation.status !== STATUS ||
        evaluation.synthetic !== true ||
        evaluation.designEstablished !== false ||
        evaluation.runtimeAuthorized !== false ||
        evaluation.spellId !== SPELL_ID ||
        !Number.isFinite(evaluation.expectedEnemyDamage) ||
        !Number.isFinite(evaluation.expectedSelfDamage) ||
        !Number.isFinite(evaluation.resourceCost) ||
        evaluation.resourceCost <= 0 ||
        !Number.isInteger(evaluation.modifier)) {
      throw new Error('SYNTHETIC_FRONTIER_EVALUATION_INVALID');
    }
    return evaluation;
  }

  function dominates(left, right) {
    validateEvaluationForFrontier(left);
    validateEvaluationForFrontier(right);
    if (left.modifier !== right.modifier) {
      throw new Error('SYNTHETIC_FRONTIER_MODIFIER_MISMATCH');
    }

    const noWorse =
      left.expectedEnemyDamage >= right.expectedEnemyDamage &&
      left.expectedSelfDamage <= right.expectedSelfDamage &&
      left.resourceCost <= right.resourceCost;
    const strictlyBetter =
      left.expectedEnemyDamage > right.expectedEnemyDamage ||
      left.expectedSelfDamage < right.expectedSelfDamage ||
      left.resourceCost < right.resourceCost;

    return noWorse && strictlyBetter;
  }

  function getParetoFrontier(evaluations) {
    if (!Array.isArray(evaluations) || evaluations.length === 0) {
      throw new Error('SYNTHETIC_FRONTIER_SET_REQUIRED');
    }

    const checked = evaluations.map(validateEvaluationForFrontier);
    const ids = checked.map(item => item.candidateId);
    if (new Set(ids).size !== ids.length) {
      throw new Error('SYNTHETIC_FRONTIER_DUPLICATE_CANDIDATE');
    }

    const modifier = checked[0].modifier;
    checked.forEach(item => {
      if (item.modifier !== modifier) {
        throw new Error('SYNTHETIC_FRONTIER_MODIFIER_MISMATCH');
      }
    });

    return checked
      .filter(candidate =>
        !checked.some(other =>
          other.candidateId !== candidate.candidateId &&
          dominates(other, candidate)
        )
      )
      .slice()
      .sort((a, b) => a.candidateId.localeCompare(b.candidateId));
  }

  function evaluateAcrossModifiers(candidate, modifiers, thresholds) {
    const modifierSet = validateModifierSet(modifiers);

    return modifierSet.map(modifier =>
      evaluateCandidate(candidate, modifier, thresholds)
    );
  }

  return Object.freeze({
    VERSION,
    STATUS,
    SPELL_ID,
    SCHOOL_ID,
    RESOURCE,
    DEFAULT_THRESHOLDS,
    PHASES,
    validateCandidate,
    validateCandidateSet,
    getOutcomeCounts,
    getOutcomeProbabilities,
    evaluateCandidate,
    evaluateCandidateSet,
    evaluateAcrossModifiers,
    evaluateCandidateSetAcrossModifiers,
    dominates,
    getParetoFrontier,
  });
});
