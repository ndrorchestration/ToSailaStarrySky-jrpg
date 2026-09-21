/* ============================================================
   Aetherwake JRPG — Foundation Spell Admission Contract v0.1
   modules/foundation-spell-admission.js

   Scope:
   - define semantic completeness for exploration and combat spells;
   - keep contract completeness separate from runtime authorization;
   - validate resource, roll, effect, execution, and persistence bindings;
   - fail closed when any required evidence is missing.

   This module does NOT execute spells, mutate gameplay state, grant spells,
   choose balance values, or change persistence schemas.
   ============================================================ */

(function (root, factory) {
  'use strict';

  let masteryDefs = root && root.AetherMasteryDefs;
  let magicAccess = root && root.AetherMagicAccess;
  let effectVocabulary = root && root.AetherEffectVocabulary;

  if (typeof module === 'object' && module.exports) {
    masteryDefs = masteryDefs || require('./mastery-defs.js');
    magicAccess = magicAccess || require('./magic-access.js');
    effectVocabulary = effectVocabulary || require('./effect-vocabulary.js');
  }

  const api = factory(masteryDefs, magicAccess, effectVocabulary);

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherFoundationSpellAdmission = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null),
function (masteryDefs, magicAccess, effectVocabulary) {
  'use strict';

  const VERSION = '0.1.0';

  const STATUS = Object.freeze({
    BLOCKED: 'blocked',
    COMPLETE_NOT_AUTHORIZED: 'complete-not-authorized',
    RUNTIME_READY: 'runtime-ready',
  });

  const MODE = Object.freeze({
    EXPLORATION_READONLY: 'exploration-readonly',
    COMBAT_2D6: 'combat-2d6',
  });

  const REASON = Object.freeze({
    UNKNOWN_SPELL: 'UNKNOWN_SPELL',
    SCHOOL_ACCESS_UNAVAILABLE: 'SCHOOL_ACCESS_UNAVAILABLE',
    CONTRACT_NOT_ESTABLISHED: 'CONTRACT_NOT_ESTABLISHED',
    CONTRACT_IDENTITY_MISMATCH: 'CONTRACT_IDENTITY_MISMATCH',
    CONTRACT_MODE_INVALID: 'CONTRACT_MODE_INVALID',
    CONTRACT_COST_INVALID: 'CONTRACT_COST_INVALID',
    CONTRACT_ROLL_INVALID: 'CONTRACT_ROLL_INVALID',
    CONTRACT_OUTCOMES_INVALID: 'CONTRACT_OUTCOMES_INVALID',
    CONTRACT_EFFECT_NOT_IMPLEMENTED: 'CONTRACT_EFFECT_NOT_IMPLEMENTED',
    CONTRACT_MUTATION_POLICY_INVALID: 'CONTRACT_MUTATION_POLICY_INVALID',
    CONTRACT_EXECUTION_BINDING_INVALID: 'CONTRACT_EXECUTION_BINDING_INVALID',
    CONTRACT_PERSISTENCE_INVALID: 'CONTRACT_PERSISTENCE_INVALID',
  });

  const PERSISTENCE_MODES = Object.freeze([
    'none',
    'combat-local',
    'explicit-write-back',
  ]);

  function fail(reason, detail) {
    const error = new Error(reason + (detail ? ':' + detail : ''));
    error.reason = reason;
    throw error;
  }

  function reasonFromError(error) {
    return error && error.reason
      ? error.reason
      : String(error && error.message || 'UNKNOWN').split(':')[0];
  }

  function includesValue(object, value) {
    return Object.keys(object || {}).some(key => object[key] === value);
  }

  function requireDependencies() {
    if (!masteryDefs ||
        typeof masteryDefs.getFoundationSpellDefinition !== 'function' ||
        typeof masteryDefs.getSpellRuntimeReadiness !== 'function') {
      fail(REASON.CONTRACT_IDENTITY_MISMATCH, 'MASTERY_DEFS_REQUIRED');
    }
    if (!magicAccess || typeof magicAccess.getSchoolAccess !== 'function') {
      fail(REASON.SCHOOL_ACCESS_UNAVAILABLE, 'MAGIC_ACCESS_REQUIRED');
    }
    if (!effectVocabulary ||
        typeof effectVocabulary.validateProfile !== 'function' ||
        !effectVocabulary.RUNTIME_STATUS ||
        !effectVocabulary.RESOURCE) {
      fail(REASON.CONTRACT_OUTCOMES_INVALID, 'EFFECT_VOCABULARY_REQUIRED');
    }
  }

  function validateIdentity(spell, contract) {
    if (!contract || typeof contract !== 'object') {
      fail(REASON.CONTRACT_NOT_ESTABLISHED, spell && spell.id);
    }
    if (contract.spellId !== spell.id ||
        contract.schoolId !== spell.schoolId) {
      fail(REASON.CONTRACT_IDENTITY_MISMATCH, spell.id);
    }
    if (!Object.values(MODE).includes(contract.mode)) {
      fail(REASON.CONTRACT_MODE_INVALID, spell.id);
    }
    return true;
  }

  function validateCost(spell, contract) {
    const cost = contract.cost;
    if (!cost || typeof cost !== 'object') {
      fail(REASON.CONTRACT_COST_INVALID, spell.id);
    }

    if (spell.resourceBinding === masteryDefs.RESOURCE_BINDING.NONE) {
      if (cost.resource !== null || cost.amount !== 0) {
        fail(REASON.CONTRACT_COST_INVALID, spell.id + ':ZERO_COST_REQUIRED');
      }
      return true;
    }

    if (spell.resourceBinding === masteryDefs.RESOURCE_BINDING.AETHER) {
      if (cost.resource !== effectVocabulary.RESOURCE.AETHER ||
          !Number.isFinite(cost.amount) ||
          cost.amount <= 0) {
        fail(REASON.CONTRACT_COST_INVALID, spell.id + ':AETHER_COST_REQUIRED');
      }
      return true;
    }

    fail(REASON.CONTRACT_COST_INVALID, spell.id + ':RESOURCE_BINDING_UNRESOLVED');
  }

  function validatePersistence(spellId, persistence) {
    if (!persistence || typeof persistence !== 'object' ||
        !PERSISTENCE_MODES.includes(persistence.mode) ||
        !Array.isArray(persistence.fields) ||
        persistence.fields.some(field => typeof field !== 'string' || !field) ||
        new Set(persistence.fields).size !== persistence.fields.length) {
      fail(REASON.CONTRACT_PERSISTENCE_INVALID, spellId);
    }
    if (persistence.mode === 'none' && persistence.fields.length !== 0) {
      fail(REASON.CONTRACT_PERSISTENCE_INVALID, spellId + ':NONE_WITH_FIELDS');
    }
    return true;
  }

  function validateExecution(spellId, execution) {
    if (!execution || typeof execution !== 'object' ||
        typeof execution.adapterId !== 'string' || !execution.adapterId ||
        typeof execution.version !== 'string' || !execution.version) {
      fail(REASON.CONTRACT_EXECUTION_BINDING_INVALID, spellId);
    }
    return true;
  }

  function validateExplorationContract(spell, contract) {
    if (!spell.modes.includes('exploration') ||
        contract.mutationPolicy !== 'read-only' ||
        contract.roll !== null ||
        contract.outcomes !== null) {
      fail(REASON.CONTRACT_MUTATION_POLICY_INVALID, spell.id);
    }
    validateCost(spell, contract);
    validateExecution(spell.id, contract.execution);
    validatePersistence(spell.id, contract.persistence);
    if (contract.persistence.mode !== 'none') {
      fail(REASON.CONTRACT_PERSISTENCE_INVALID, spell.id + ':EXPLORATION_MUST_NOT_PERSIST');
    }
    return true;
  }

  function validateCombatContract(spell, contract) {
    if (!spell.modes.includes('combat') ||
        contract.mutationPolicy !== 'effect-resolver') {
      fail(REASON.CONTRACT_MUTATION_POLICY_INVALID, spell.id);
    }

    validateCost(spell, contract);

    const roll = contract.roll;
    if (!roll || typeof roll !== 'object' ||
        roll.system !== '2d6' ||
        typeof roll.stat !== 'string' || !roll.stat ||
        roll.successMin !== 10 ||
        roll.partialMin !== 7) {
      fail(REASON.CONTRACT_ROLL_INVALID, spell.id);
    }

    if (!contract.outcomes || typeof contract.outcomes !== 'object') {
      fail(REASON.CONTRACT_OUTCOMES_INVALID, spell.id);
    }
    try {
      effectVocabulary.validateProfile(spell.id, contract.outcomes);
    } catch (error) {
      fail(REASON.CONTRACT_OUTCOMES_INVALID, spell.id + ':' + error.message);
    }

    effectVocabulary.PHASES.forEach(phase => {
      contract.outcomes[phase].forEach((descriptor, index) => {
        if (descriptor.runtimeStatus !== effectVocabulary.RUNTIME_STATUS.IMPLEMENTED) {
          fail(
            REASON.CONTRACT_EFFECT_NOT_IMPLEMENTED,
            spell.id + ':' + phase + ':' + index
          );
        }
      });
    });

    validateExecution(spell.id, contract.execution);
    validatePersistence(spell.id, contract.persistence);
    return true;
  }

  function validateCompleteContract(spell, contract) {
    requireDependencies();
    validateIdentity(spell, contract);

    if (contract.mode === MODE.EXPLORATION_READONLY) {
      return validateExplorationContract(spell, contract);
    }
    if (contract.mode === MODE.COMBAT_2D6) {
      return validateCombatContract(spell, contract);
    }
    fail(REASON.CONTRACT_MODE_INVALID, spell.id);
  }

  function blocked(characterId, spellId, reason, detail) {
    return {
      characterId,
      spellId,
      status: STATUS.BLOCKED,
      contractComplete: false,
      executionAuthorized: false,
      reason,
      detail: detail || null,
    };
  }

  function assessSpell(characterId, spellId, contract) {
    requireDependencies();
    const spell = masteryDefs.getFoundationSpellDefinition(spellId);
    if (!spell) {
      return blocked(characterId, spellId, REASON.UNKNOWN_SPELL);
    }

    const schoolAccess = magicAccess.getSchoolAccess(characterId, spell.schoolId);
    if (!schoolAccess.canStudySchool) {
      return blocked(
        characterId,
        spellId,
        REASON.SCHOOL_ACCESS_UNAVAILABLE,
        schoolAccess.reason
      );
    }

    if (!contract) {
      return blocked(characterId, spellId, REASON.CONTRACT_NOT_ESTABLISHED);
    }

    try {
      validateCompleteContract(spell, contract);
    } catch (error) {
      return blocked(
        characterId,
        spellId,
        reasonFromError(error),
        error.message
      );
    }

    const runtime = masteryDefs.getSpellRuntimeReadiness(characterId, spellId);
    if (!runtime.canUse) {
      return {
        characterId,
        spellId,
        status: STATUS.COMPLETE_NOT_AUTHORIZED,
        contractComplete: true,
        executionAuthorized: false,
        reason: runtime.reason,
        detail: null,
      };
    }

    return {
      characterId,
      spellId,
      status: STATUS.RUNTIME_READY,
      contractComplete: true,
      executionAuthorized: true,
      reason: 'ok',
      detail: null,
    };
  }

  return Object.freeze({
    VERSION,
    STATUS,
    MODE,
    REASON,
    PERSISTENCE_MODES,
    validateCompleteContract,
    assessSpell,
  });
});
