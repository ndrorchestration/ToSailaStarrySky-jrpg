/* ============================================================
   Aetherwake JRPG — Companion Action Admission Contract v0.2
   modules/companion-action-admission.js

   Scope:
   - define target-system completeness evidence required before a staged
     companion action may even be considered for execution;
   - preserve the current Phase A fail-closed boundary;
   - separate preservation-era evidence from production JRPG contracts;
   - distinguish a complete semantic contract from explicit execution
     authorization.

   This module does NOT execute actions, mutate combat/party state, grant
   authorization, alter save schemas, or establish companion canon.
   ============================================================ */

(function (root, factory) {
  'use strict';

  let effectVocabulary = root && root.AetherEffectVocabulary;
  let combatPolicy = root && root.AetherCombatSystemPolicy;

  if (typeof module === 'object' && module.exports) {
    effectVocabulary = effectVocabulary || require('./effect-vocabulary.js');
    combatPolicy = combatPolicy || require('./combat-system-policy.js');
  }

  const api = factory(effectVocabulary, combatPolicy);

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherCompanionActionAdmission = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null),
function (effectVocabulary, combatPolicy) {
  'use strict';

  const VERSION = '0.2.0';

  const STATUS = Object.freeze({
    BLOCKED: 'blocked',
    COMPLETE_NOT_AUTHORIZED: 'complete-not-authorized',
  });

  const REASON = Object.freeze({
    FORMULA_CONTRACT_NOT_ESTABLISHED: 'FORMULA_CONTRACT_NOT_ESTABLISHED',
    EXECUTION_AUTHORIZATION_NOT_ESTABLISHED: 'EXECUTION_AUTHORIZATION_NOT_ESTABLISHED',
    ACTION_DECLARATION_INVALID: 'ACTION_DECLARATION_INVALID',
    CONTRACT_ACTION_MISMATCH: 'CONTRACT_ACTION_MISMATCH',
    CONTRACT_TEMPLATE_MISMATCH: 'CONTRACT_TEMPLATE_MISMATCH',
    CONTRACT_PROVENANCE_MISMATCH: 'CONTRACT_PROVENANCE_MISMATCH',
    CONTRACT_LEGACY_RESOLUTION_FORBIDDEN: 'CONTRACT_LEGACY_RESOLUTION_FORBIDDEN',
    CONTRACT_RESOLUTION_INVALID: 'CONTRACT_RESOLUTION_INVALID',
    CONTRACT_TARGETING_INVALID: 'CONTRACT_TARGETING_INVALID',
    CONTRACT_COST_INVALID: 'CONTRACT_COST_INVALID',
    CONTRACT_EFFECTS_INVALID: 'CONTRACT_EFFECTS_INVALID',
    CONTRACT_EFFECT_NOT_IMPLEMENTED: 'CONTRACT_EFFECT_NOT_IMPLEMENTED',
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

  function requireVocabulary(vocabulary) {
    if (!vocabulary ||
        typeof vocabulary.validateEffectDescriptor !== 'function' ||
        !vocabulary.RUNTIME_STATUS ||
        !vocabulary.RESOURCE) {
      fail(REASON.CONTRACT_EFFECTS_INVALID, 'EFFECT_VOCABULARY_REQUIRED');
    }
    return vocabulary;
  }

  function requireCombatPolicy(policy) {
    if (!policy ||
        typeof policy.validate !== 'function' ||
        !policy.TARGET ||
        !Array.isArray(policy.ALLOWED_RNG_USES)) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, 'COMBAT_POLICY_REQUIRED');
    }
    policy.validate();
    return policy;
  }

  function validateDeclaration(declaration) {
    if (!declaration || typeof declaration !== 'object') {
      fail(REASON.ACTION_DECLARATION_INVALID, 'OBJECT_REQUIRED');
    }
    ['id', 'label', 'stat', 'desc'].forEach(field => {
      if (typeof declaration[field] !== 'string' || !declaration[field]) {
        fail(REASON.ACTION_DECLARATION_INVALID, field);
      }
    });
    return true;
  }

  function validateResolution(actionId, resolution, policy) {
    if (!resolution || typeof resolution !== 'object' || Array.isArray(resolution)) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, actionId + ':OBJECT_REQUIRED');
    }
    if (resolution.model !== policy.TARGET.model) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, actionId + ':MODEL');
    }
    if (typeof resolution.formulaId !== 'string' ||
        resolution.formulaId !== actionId) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, actionId + ':FORMULA_ID');
    }
    if (typeof resolution.version !== 'string' || !resolution.version) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, actionId + ':VERSION');
    }
    if (typeof resolution.kind !== 'string' || !resolution.kind) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, actionId + ':KIND');
    }
    if (!resolution.parameters ||
        typeof resolution.parameters !== 'object' ||
        Array.isArray(resolution.parameters) ||
        Object.keys(resolution.parameters).length === 0) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, actionId + ':PARAMETERS');
    }
    if (!Array.isArray(resolution.rngUses) ||
        new Set(resolution.rngUses).size !== resolution.rngUses.length ||
        resolution.rngUses.some(use => !policy.ALLOWED_RNG_USES.includes(use))) {
      fail(REASON.CONTRACT_RESOLUTION_INVALID, actionId + ':RNG_USES');
    }
    return true;
  }

  function validateTargeting(actionId, targeting) {
    if (!targeting || typeof targeting !== 'object' || Array.isArray(targeting) ||
        typeof targeting.mode !== 'string' || !targeting.mode ||
        !Number.isInteger(targeting.maxTargets) || targeting.maxTargets < 1 ||
        typeof targeting.requiresExplicitTarget !== 'boolean') {
      fail(REASON.CONTRACT_TARGETING_INVALID, actionId);
    }
    return true;
  }

  function includesValue(object, value) {
    return Object.keys(object).some(key => object[key] === value);
  }

  function validateCost(actionId, cost, vocabulary) {
    if (!cost || typeof cost !== 'object' ||
        !Number.isFinite(cost.amount) ||
        cost.amount < 0) {
      fail(REASON.CONTRACT_COST_INVALID, actionId);
    }

    if (cost.amount === 0) {
      if (cost.resource !== null) {
        fail(REASON.CONTRACT_COST_INVALID, actionId + ':ZERO_COST_REQUIRES_NULL_RESOURCE');
      }
      return true;
    }

    if (typeof cost.resource !== 'string' ||
        !includesValue(vocabulary.RESOURCE, cost.resource)) {
      fail(REASON.CONTRACT_COST_INVALID, actionId + ':UNKNOWN_RESOURCE');
    }
    return true;
  }

  function validateEffects(actionId, effects, vocabulary) {
    if (!Array.isArray(effects) || effects.length === 0) {
      fail(REASON.CONTRACT_EFFECTS_INVALID, actionId + ':NON_EMPTY_ARRAY_REQUIRED');
    }

    effects.forEach((descriptor, index) => {
      try {
        vocabulary.validateEffectDescriptor(descriptor);
      } catch (error) {
        fail(REASON.CONTRACT_EFFECTS_INVALID, actionId + ':' + index + ':' + error.message);
      }
      if (descriptor.runtimeStatus !== vocabulary.RUNTIME_STATUS.IMPLEMENTED) {
        fail(REASON.CONTRACT_EFFECT_NOT_IMPLEMENTED, actionId + ':' + index);
      }
    });
    return true;
  }

  function validateExecutionBinding(actionId, execution) {
    if (!execution || typeof execution !== 'object' ||
        typeof execution.adapterId !== 'string' || !execution.adapterId ||
        typeof execution.version !== 'string' || !execution.version) {
      fail(REASON.CONTRACT_EXECUTION_BINDING_INVALID, actionId);
    }
    return true;
  }

  function validatePersistence(actionId, persistence) {
    if (!persistence || typeof persistence !== 'object' ||
        !PERSISTENCE_MODES.includes(persistence.mode) ||
        !Array.isArray(persistence.fields) ||
        persistence.fields.some(field => typeof field !== 'string' || !field) ||
        new Set(persistence.fields).size !== persistence.fields.length) {
      fail(REASON.CONTRACT_PERSISTENCE_INVALID, actionId);
    }
    if (persistence.mode === 'none' && persistence.fields.length !== 0) {
      fail(REASON.CONTRACT_PERSISTENCE_INVALID, actionId + ':NONE_WITH_FIELDS');
    }
    return true;
  }

  function validateCompleteContract(declaration, role, contract, options) {
    validateDeclaration(declaration);

    const vocabulary = requireVocabulary(
      options && options.effectVocabulary
        ? options.effectVocabulary
        : effectVocabulary
    );
    const policy = requireCombatPolicy(
      options && options.combatPolicy
        ? options.combatPolicy
        : combatPolicy
    );

    if (!role || typeof role.id !== 'string' || !role.id) {
      fail(REASON.ACTION_DECLARATION_INVALID, declaration.id + ':ROLE_REQUIRED');
    }
    if (!contract || typeof contract !== 'object') {
      fail(REASON.FORMULA_CONTRACT_NOT_ESTABLISHED, declaration.id);
    }
    if (contract.actionId !== declaration.id) {
      fail(REASON.CONTRACT_ACTION_MISMATCH, declaration.id);
    }
    if (contract.templateId !== role.id) {
      fail(REASON.CONTRACT_TEMPLATE_MISMATCH, declaration.id);
    }

    const expectedProvenance = options && options.provenance;
    if (typeof expectedProvenance !== 'string' || !expectedProvenance ||
        contract.provenance !== expectedProvenance) {
      fail(REASON.CONTRACT_PROVENANCE_MISMATCH, declaration.id);
    }

    // Preservation-era roll/outcome evidence belongs in draft provenance only.
    // A production admission candidate must be target-system shaped.
    if (Object.prototype.hasOwnProperty.call(contract, 'roll') ||
        Object.prototype.hasOwnProperty.call(contract, 'outcomes')) {
      fail(REASON.CONTRACT_LEGACY_RESOLUTION_FORBIDDEN, declaration.id);
    }

    validateResolution(declaration.id, contract.resolution, policy);
    validateTargeting(declaration.id, contract.targeting);
    validateCost(declaration.id, contract.cost, vocabulary);
    validateEffects(declaration.id, contract.effects, vocabulary);
    validateExecutionBinding(declaration.id, contract.execution);
    validatePersistence(declaration.id, contract.persistence);
    return true;
  }

  function blocked(actionId, reason, detail) {
    return {
      actionId,
      status: STATUS.BLOCKED,
      contractComplete: false,
      executionAuthorized: false,
      reason,
      detail: detail || null,
    };
  }

  function assessAction(declaration, role, contract, options) {
    const actionId = declaration && declaration.id ? declaration.id : null;
    if (!contract) {
      return blocked(actionId, REASON.FORMULA_CONTRACT_NOT_ESTABLISHED);
    }

    try {
      validateCompleteContract(declaration, role, contract, options);
    } catch (error) {
      return blocked(actionId, reasonFromError(error), error.message);
    }

    return {
      actionId,
      status: STATUS.COMPLETE_NOT_AUTHORIZED,
      contractComplete: true,
      executionAuthorized: false,
      reason: REASON.EXECUTION_AUTHORIZATION_NOT_ESTABLISHED,
      detail: null,
    };
  }

  function assessFieldRole(role, contracts, options) {
    if (!role || typeof role !== 'object' || !Array.isArray(role.abilities)) {
      fail(REASON.ACTION_DECLARATION_INVALID, 'FIELD_ROLE_INVALID');
    }
    const registry = contracts && typeof contracts === 'object' ? contracts : {};
    return {
      templateId: role.id,
      actions: role.abilities.map(declaration =>
        assessAction(declaration, role, registry[declaration.id], options)
      ),
    };
  }

  function assessRegistry(fieldRoleDefs, contracts, options) {
    if (!fieldRoleDefs || typeof fieldRoleDefs.list !== 'function') {
      fail(REASON.ACTION_DECLARATION_INVALID, 'FIELD_ROLE_REGISTRY_REQUIRED');
    }

    const provenance = fieldRoleDefs.PROVENANCE;
    const mergedOptions = Object.assign({}, options || {}, { provenance });
    const roles = fieldRoleDefs.list().map(role =>
      assessFieldRole(role, contracts, mergedOptions)
    );
    const actions = roles.flatMap(role => role.actions);

    return {
      version: VERSION,
      targetModel: combatPolicy && combatPolicy.TARGET
        ? combatPolicy.TARGET.model
        : null,
      roles,
      actionCount: actions.length,
      completeCount: actions.filter(action => action.contractComplete).length,
      executionAuthorizedCount: actions.filter(action => action.executionAuthorized).length,
      allFailClosed: actions.every(action => action.executionAuthorized === false),
    };
  }

  return Object.freeze({
    VERSION,
    STATUS,
    REASON,
    PERSISTENCE_MODES,
    validateDeclaration,
    validateResolution,
    validateTargeting,
    validateCompleteContract,
    assessAction,
    assessFieldRole,
    assessRegistry,
  });
});
