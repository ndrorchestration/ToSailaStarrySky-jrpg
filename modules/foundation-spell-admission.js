/* ============================================================
   Aetherwake JRPG — Foundation Spell Admission Contract v0.2
   modules/foundation-spell-admission.js

   Scope:
   - preserve established read-only exploration spell contracts;
   - define target JRPG completeness for combat spells;
   - keep contract completeness separate from runtime authorization;
   - fail closed when any required evidence is missing.

   This module does NOT execute spells, mutate gameplay state, grant spells,
   choose balance values, or change persistence schemas.
   ============================================================ */

(function (root, factory) {
  'use strict';

  let masteryDefs = root && root.AetherMasteryDefs;
  let magicAccess = root && root.AetherMagicAccess;
  let effectVocabulary = root && root.AetherEffectVocabulary;
  let combatPolicy = root && root.AetherCombatSystemPolicy;

  if (typeof module === 'object' && module.exports) {
    masteryDefs = masteryDefs || require('./mastery-defs.js');
    magicAccess = magicAccess || require('./magic-access.js');
    effectVocabulary = effectVocabulary || require('./effect-vocabulary.js');
    combatPolicy = combatPolicy || require('./combat-system-policy.js');
  }

  const api = factory(
    masteryDefs,
    magicAccess,
    effectVocabulary,
    combatPolicy
  );

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherFoundationSpellAdmission = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null),
function (masteryDefs, magicAccess, effectVocabulary, combatPolicy) {
  'use strict';

  const VERSION = '0.2.0';

  const STATUS = Object.freeze({
    BLOCKED: 'blocked',
    COMPLETE_NOT_AUTHORIZED: 'complete-not-authorized',
    RUNTIME_READY: 'runtime-ready',
  });

  const MODE = Object.freeze({
    EXPLORATION_READONLY: 'exploration-readonly',
    COMBAT_JRPG: 'combat-jrpg-formula',
  });

  const REASON = Object.freeze({
    UNKNOWN_SPELL: 'UNKNOWN_SPELL',
    SCHOOL_ACCESS_UNAVAILABLE: 'SCHOOL_ACCESS_UNAVAILABLE',
    CONTRACT_NOT_ESTABLISHED: 'CONTRACT_NOT_ESTABLISHED',
    FORMULA_CONTRACT_NOT_ESTABLISHED: 'FORMULA_CONTRACT_NOT_ESTABLISHED',
    CONTRACT_IDENTITY_MISMATCH: 'CONTRACT_IDENTITY_MISMATCH',
    CONTRACT_MODE_INVALID: 'CONTRACT_MODE_INVALID',
    CONTRACT_COST_INVALID: 'CONTRACT_COST_INVALID',
    CONTRACT_LEGACY_RESOLUTION_FORBIDDEN: 'CONTRACT_LEGACY_RESOLUTION_FORBIDDEN',
    CONTRACT_RESOLUTION_INVALID: 'CONTRACT_RESOLUTION_INVALID',
    CONTRACT_TARGETING_INVALID: 'CONTRACT_TARGETING_INVALID',
    CONTRACT_EFFECTS_INVALID: 'CONTRACT_EFFECTS_INVALID',
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
        typeof effectVocabulary.validateEffectDescriptor !== 'function' ||
        !effectVocabulary.RUNTIME_STATUS ||
        !effectVocabulary.RESOURCE) {
      fail(REASON.CONTRACT_EFFECTS_INVALID, 'EFFECT_VOCABULARY_REQUIRED');
    }
    if (!combatPolicy ||
        typeof combatPolicy.validate !== 'function' ||
        !combatPolicy.TARGET ||
        !Array.isArray(combatPolicy.ALLOWED_RNG_USES)) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, 'COMBAT_POLICY_REQUIRED');
    }
    combatPolicy.validate();
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

  function rejectLegacyResolution(spellId, contract) {
    if (Object.prototype.hasOwnProperty.call(contract, 'roll') ||
        Object.prototype.hasOwnProperty.call(contract, 'outcomes')) {
      fail(REASON.CONTRACT_LEGACY_RESOLUTION_FORBIDDEN, spellId);
    }
  }

  function validateResolution(spellId, resolution) {
    if (!resolution || typeof resolution !== 'object' || Array.isArray(resolution)) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, spellId + ':OBJECT_REQUIRED');
    }
    if (resolution.model !== combatPolicy.TARGET.model) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, spellId + ':MODEL');
    }
    if (resolution.formulaId !== spellId) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, spellId + ':FORMULA_ID');
    }
    if (typeof resolution.version !== 'string' || !resolution.version) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, spellId + ':VERSION');
    }
    if (typeof resolution.kind !== 'string' || !resolution.kind) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, spellId + ':KIND');
    }
    if (!resolution.parameters ||
        typeof resolution.parameters !== 'object' ||
        Array.isArray(resolution.parameters) ||
        Object.keys(resolution.parameters).length === 0) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, spellId + ':PARAMETERS');
    }
    if (!Array.isArray(resolution.rngUses) ||
        new Set(resolution.rngUses).size !== resolution.rngUses.length ||
        resolution.rngUses.some(use =>
          !combatPolicy.ALLOWED_RNG_USES.includes(use))) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, spellId + ':RNG_USES');
    }
    return true;
  }

  function validateTargeting(spellId, targeting) {
    if (!targeting || typeof targeting !== 'object' || Array.isArray(targeting) ||
        typeof targeting.mode !== 'string' || !targeting.mode ||
        !Number.isInteger(targeting.maxTargets) || targeting.maxTargets < 1 ||
        typeof targeting.requiresExplicitTarget !== 'boolean') {
      fail(REASON.CONTRACT_TARGETING_INVALID, spellId);
    }
    return true;
  }

  function validateEffects(spellId, effects) {
    if (!Array.isArray(effects) || effects.length === 0) {
      fail(REASON.CONTRACT_EFFECTS_INVALID, spellId + ':NON_EMPTY_ARRAY_REQUIRED');
    }
    effects.forEach((descriptor, index) => {
      try {
        effectVocabulary.validateEffectDescriptor(descriptor);
      } catch (error) {
        fail(
          REASON.CONTRACT_EFFECTS_INVALID,
          spellId + ':' + index + ':' + error.message
        );
      }
      if (descriptor.runtimeStatus !== effectVocabulary.RUNTIME_STATUS.IMPLEMENTED) {
        fail(REASON.CONTRACT_EFFECT_NOT_IMPLEMENTED, spellId + ':' + index);
      }
    });
    return true;
  }

  function validateExplorationContract(spell, contract) {
    if (!spell.modes.includes('exploration') ||
        contract.mutationPolicy !== 'read-only') {
      fail(REASON.CONTRACT_MUTATION_POLICY_INVALID, spell.id);
    }

    rejectLegacyResolution(spell.id, contract);

    if (Object.prototype.hasOwnProperty.call(contract, 'resolution') ||
        Object.prototype.hasOwnProperty.call(contract, 'targeting') ||
        Object.prototype.hasOwnProperty.call(contract, 'effects')) {
      fail(REASON.CONTRACT_MODE_INVALID, spell.id + ':EXPLORATION_TARGET_FIELDS');
    }

    validateCost(spell, contract);
    validateExecution(spell.id, contract.execution);
    validatePersistence(spell.id, contract.persistence);
    if (contract.persistence.mode !== 'none') {
      fail(
        REASON.CONTRACT_PERSISTENCE_INVALID,
        spell.id + ':EXPLORATION_MUST_NOT_PERSIST'
      );
    }
    return true;
  }

  function validateCombatContract(spell, contract) {
    if (!spell.modes.includes('combat') ||
        contract.mutationPolicy !== 'effect-resolver') {
      fail(REASON.CONTRACT_MUTATION_POLICY_INVALID, spell.id);
    }

    rejectLegacyResolution(spell.id, contract);
    validateCost(spell, contract);
    validateResolution(spell.id, contract.resolution);
    validateTargeting(spell.id, contract.targeting);
    validateEffects(spell.id, contract.effects);
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
    if (contract.mode === MODE.COMBAT_JRPG) {
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
      return blocked(
        characterId,
        spellId,
        spell.modes.includes('combat')
          ? REASON.FORMULA_CONTRACT_NOT_ESTABLISHED
          : REASON.CONTRACT_NOT_ESTABLISHED
      );
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
    validateResolution,
    validateTargeting,
    validateCompleteContract,
    assessSpell,
  });
});
