/* ============================================================
   Aetherwake JRPG — Companion Action Contract Drafts v0.1
   modules/companion-action-contracts.js

   Scope:
   - preserve evidence-backed companion action semantics without inventing
     missing outcome rules;
   - make unresolved design fields machine-readable;
   - expose admission candidates only after a draft is actually complete.

   This module does NOT execute actions, authorize companion turns, assign
   canonical jobs/schools, or modify persistence.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherCompanionActionContracts = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.6.0';

  const STATUS = Object.freeze({
    DRAFT_UNRESOLVED: 'draft-unresolved',
    READY_FOR_ADMISSION: 'ready-for-admission',
  });

  const UNKNOWN = 'unknown';

  const COST_STATUS = Object.freeze({
    UNKNOWN,
    DECLARED: 'declared',
  });

  const BLOCKER = Object.freeze({
    COST_NOT_SPECIFIED: 'COST_NOT_SPECIFIED',
    DAMAGE_BAND_NOT_SPECIFIED: 'DAMAGE_BAND_NOT_SPECIFIED',
    HEAT_GAIN_BAND_NOT_SPECIFIED: 'HEAT_GAIN_BAND_NOT_SPECIFIED',
    DAMAGE_FORMULA_EXECUTION_NOT_ESTABLISHED: 'DAMAGE_FORMULA_EXECUTION_NOT_ESTABLISHED',
    ALLY_DAMAGE_ABSORPTION_BAND_NOT_SPECIFIED: 'ALLY_DAMAGE_ABSORPTION_BAND_NOT_SPECIFIED',
    ALLY_DAMAGE_ABSORPTION_TIMING_NOT_SPECIFIED: 'ALLY_DAMAGE_ABSORPTION_TIMING_NOT_SPECIFIED',
    ABSORBED_DAMAGE_DESTINATION_NOT_SPECIFIED: 'ABSORBED_DAMAGE_DESTINATION_NOT_SPECIFIED',
    SCRAP_RETURN_BAND_NOT_SPECIFIED: 'SCRAP_RETURN_BAND_NOT_SPECIFIED',
    SCRAP_RETURN_RECIPIENT_NOT_SPECIFIED: 'SCRAP_RETURN_RECIPIENT_NOT_SPECIFIED',
    ABSORPTION_EFFECT_NOT_EXECUTABLE: 'ABSORPTION_EFFECT_NOT_EXECUTABLE',
    SCRAP_RETURN_EFFECT_NOT_EXECUTABLE: 'SCRAP_RETURN_EFFECT_NOT_EXECUTABLE',
    HEAL_BAND_NOT_SPECIFIED: 'HEAL_BAND_NOT_SPECIFIED',
    HEAL_AMOUNT_SELECTION_NOT_SPECIFIED: 'HEAL_AMOUNT_SELECTION_NOT_SPECIFIED',
    ALLY_TARGET_SELECTION_NOT_SPECIFIED: 'ALLY_TARGET_SELECTION_NOT_SPECIFIED',
    ALLY_RESTORE_EFFECT_NOT_EXECUTABLE: 'ALLY_RESTORE_EFFECT_NOT_EXECUTABLE',
    BUFF_BAND_NOT_SPECIFIED: 'BUFF_BAND_NOT_SPECIFIED',
    ALLY_MODIFIER_TARGET_SELECTION_NOT_SPECIFIED: 'ALLY_MODIFIER_TARGET_SELECTION_NOT_SPECIFIED',
    ALLY_NEXT_ROLL_MODIFIER_NOT_EXECUTABLE: 'ALLY_NEXT_ROLL_MODIFIER_NOT_EXECUTABLE',
    REPOSITION_BAND_NOT_SPECIFIED: 'REPOSITION_BAND_NOT_SPECIFIED',
    PARTIAL_OUTCOME_NOT_SPECIFIED: 'PARTIAL_OUTCOME_NOT_SPECIFIED',
    FAILURE_OUTCOME_NOT_SPECIFIED: 'FAILURE_OUTCOME_NOT_SPECIFIED',
    MOVEMENT_EFFECT_NOT_EXECUTABLE: 'MOVEMENT_EFFECT_NOT_EXECUTABLE',
    GRACE_MODIFIER_EFFECT_NOT_EXECUTABLE: 'GRACE_MODIFIER_EFFECT_NOT_EXECUTABLE',
    REVEAL_TARGET_NOT_SPECIFIED: 'REVEAL_TARGET_NOT_SPECIFIED',
    REVEAL_BAND_NOT_SPECIFIED: 'REVEAL_BAND_NOT_SPECIFIED',
    RESOURCE_GAIN_BAND_NOT_SPECIFIED: 'RESOURCE_GAIN_BAND_NOT_SPECIFIED',
    RESOURCE_GAIN_SELECTION_NOT_SPECIFIED: 'RESOURCE_GAIN_SELECTION_NOT_SPECIFIED',
    RESOURCE_GAIN_AMOUNT_NOT_SPECIFIED: 'RESOURCE_GAIN_AMOUNT_NOT_SPECIFIED',
    SUCCESS_OUTCOME_NOT_SPECIFIED: 'SUCCESS_OUTCOME_NOT_SPECIFIED',
    REVEAL_EFFECT_NOT_EXECUTABLE: 'REVEAL_EFFECT_NOT_EXECUTABLE',
    EXECUTION_ADAPTER_NOT_ESTABLISHED: 'EXECUTION_ADAPTER_NOT_ESTABLISHED',
    PERSISTENCE_POLICY_NOT_ESTABLISHED: 'PERSISTENCE_POLICY_NOT_ESTABLISHED',
  });

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  function clone(value) {
    return value == null ? value : JSON.parse(JSON.stringify(value));
  }

  const DRAFT_ORDER = Object.freeze([
    'windShearDance',
    'aetherCompass',
    'overdriveStrike',
    'patchworkShield',
    'spiritThread',
    'aetherWeave',
  ]);

  const DRAFTS = deepFreeze({
    windShearDance: {
      actionId: 'windShearDance',
      templateId: 'skySailor',
      provenance: 'preservation-era-prototype-mechanics',
      status: STATUS.DRAFT_UNRESOLVED,
      source: {
        kind: 'field-role-declaration',
        text: '2D6+Grace. Evade / reposition. 10+: next Grace roll +1.',
      },
      stat: 'grace',
      roll: {
        system: '2d6',
        stat: 'grace',
        successMin: 10,
        partialMin: 7,
        source: 'established-global-combat-rule',
      },
      cost: {
        status: UNKNOWN,
        resource: null,
        amount: null,
      },
      knownSemantics: [
        {
          id: 'reposition',
          status: 'declared',
          band: UNKNOWN,
          effectKind: 'movement',
          target: 'self',
          operation: 'move',
          key: 'reposition',
          amount: null,
        },
        {
          id: 'nextGraceRoll',
          status: 'declared',
          band: 'success',
          effectKind: 'modifier',
          target: 'self',
          operation: 'increase',
          key: 'nextGraceRoll',
          amount: 1,
        },
      ],
      outcomes: {
        common: null,
        success: null,
        partial: null,
        failure: null,
      },
      execution: {
        status: 'not-established',
        adapterId: null,
        version: null,
      },
      persistence: {
        status: 'not-established',
        mode: null,
        fields: [],
      },
      authoredBindings: {
        nativeJob: UNKNOWN,
        school: UNKNOWN,
      },
      blockers: [
        BLOCKER.COST_NOT_SPECIFIED,
        BLOCKER.REPOSITION_BAND_NOT_SPECIFIED,
        BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED,
        BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED,
        BLOCKER.MOVEMENT_EFFECT_NOT_EXECUTABLE,
        BLOCKER.GRACE_MODIFIER_EFFECT_NOT_EXECUTABLE,
        BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
        BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
      ],
    },
    aetherCompass: {
      actionId: 'aetherCompass',
      templateId: 'skySailor',
      provenance: 'preservation-era-prototype-mechanics',
      status: STATUS.DRAFT_UNRESOLVED,
      source: {
        kind: 'field-role-declaration',
        text: '2D6+Wits. Reveal resources — gain scrap or aether.',
      },
      stat: 'wits',
      roll: {
        system: '2d6',
        stat: 'wits',
        successMin: 10,
        partialMin: 7,
        source: 'established-global-combat-rule',
      },
      cost: {
        status: UNKNOWN,
        resource: null,
        amount: null,
      },
      knownSemantics: [
        {
          id: 'revealResources',
          status: 'declared',
          band: UNKNOWN,
          effectKind: 'reveal',
          target: UNKNOWN,
          operation: 'reveal',
          key: 'resources',
          amount: null,
        },
        {
          id: 'gainResource',
          status: 'declared',
          band: UNKNOWN,
          effectKind: 'resource',
          target: 'self',
          operation: 'increase',
          key: UNKNOWN,
          resourceAlternatives: ['scrap', 'aether'],
          amount: null,
        },
      ],
      outcomes: {
        common: null,
        success: null,
        partial: null,
        failure: null,
      },
      execution: {
        status: 'not-established',
        adapterId: null,
        version: null,
      },
      persistence: {
        status: 'not-established',
        mode: null,
        fields: [],
      },
      authoredBindings: {
        nativeJob: UNKNOWN,
        school: UNKNOWN,
      },
      blockers: [
        BLOCKER.COST_NOT_SPECIFIED,
        BLOCKER.REVEAL_TARGET_NOT_SPECIFIED,
        BLOCKER.REVEAL_BAND_NOT_SPECIFIED,
        BLOCKER.RESOURCE_GAIN_BAND_NOT_SPECIFIED,
        BLOCKER.RESOURCE_GAIN_SELECTION_NOT_SPECIFIED,
        BLOCKER.RESOURCE_GAIN_AMOUNT_NOT_SPECIFIED,
        BLOCKER.SUCCESS_OUTCOME_NOT_SPECIFIED,
        BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED,
        BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED,
        BLOCKER.REVEAL_EFFECT_NOT_EXECUTABLE,
        BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
        BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
      ],
    },
    overdriveStrike: {
      actionId: 'overdriveStrike',
      templateId: 'engineWright',
      provenance: 'preservation-era-prototype-mechanics',
      status: STATUS.DRAFT_UNRESOLVED,
      source: {
        kind: 'field-role-declaration',
        text: '2D6+Might. Heavy EMP: 1d6+3 damage. Generates 1 Heat.',
      },
      stat: 'might',
      roll: {
        system: '2d6',
        stat: 'might',
        successMin: 10,
        partialMin: 7,
        source: 'established-global-combat-rule',
      },
      cost: {
        status: UNKNOWN,
        resource: null,
        amount: null,
      },
      knownSemantics: [
        {
          id: 'heavyEmpDamage',
          status: 'declared',
          band: UNKNOWN,
          effectKind: 'damage',
          target: 'enemy',
          operation: 'apply',
          key: 'emp',
          amount: null,
          amountFormula: '1d6+3',
        },
        {
          id: 'generateHeat',
          status: 'declared',
          band: UNKNOWN,
          effectKind: 'resource',
          target: 'self',
          operation: 'increase',
          key: 'heat',
          amount: 1,
        },
      ],
      outcomes: {
        common: null,
        success: null,
        partial: null,
        failure: null,
      },
      execution: {
        status: 'not-established',
        adapterId: null,
        version: null,
      },
      persistence: {
        status: 'not-established',
        mode: null,
        fields: [],
      },
      authoredBindings: {
        nativeJob: UNKNOWN,
        school: UNKNOWN,
      },
      blockers: [
        BLOCKER.COST_NOT_SPECIFIED,
        BLOCKER.DAMAGE_BAND_NOT_SPECIFIED,
        BLOCKER.HEAT_GAIN_BAND_NOT_SPECIFIED,
        BLOCKER.SUCCESS_OUTCOME_NOT_SPECIFIED,
        BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED,
        BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED,
        BLOCKER.DAMAGE_FORMULA_EXECUTION_NOT_ESTABLISHED,
        BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
        BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
      ],
    },
    patchworkShield: {
      actionId: 'patchworkShield',
      templateId: 'engineWright',
      provenance: 'preservation-era-prototype-mechanics',
      status: STATUS.DRAFT_UNRESOLVED,
      source: {
        kind: 'field-role-declaration',
        text: '2D6+Presence. Absorb 1 damage for an ally. Return 1 scrap.',
      },
      stat: 'presence',
      roll: {
        system: '2d6',
        stat: 'presence',
        successMin: 10,
        partialMin: 7,
        source: 'established-global-combat-rule',
      },
      cost: {
        status: UNKNOWN,
        resource: null,
        amount: null,
      },
      knownSemantics: [
        {
          id: 'allyDamageAbsorption',
          status: 'declared',
          band: UNKNOWN,
          effectKind: 'damage',
          target: 'ally',
          operation: 'absorb',
          key: 'vitality',
          amount: 1,
          timing: UNKNOWN,
          absorbedDamageDestination: UNKNOWN,
        },
        {
          id: 'returnScrap',
          status: 'declared',
          band: UNKNOWN,
          effectKind: 'resource',
          target: UNKNOWN,
          operation: 'return',
          key: 'scrap',
          amount: 1,
        },
      ],
      outcomes: {
        common: null,
        success: null,
        partial: null,
        failure: null,
      },
      execution: {
        status: 'not-established',
        adapterId: null,
        version: null,
      },
      persistence: {
        status: 'not-established',
        mode: null,
        fields: [],
      },
      authoredBindings: {
        nativeJob: UNKNOWN,
        school: UNKNOWN,
      },
      blockers: [
        BLOCKER.COST_NOT_SPECIFIED,
        BLOCKER.ALLY_DAMAGE_ABSORPTION_BAND_NOT_SPECIFIED,
        BLOCKER.ALLY_DAMAGE_ABSORPTION_TIMING_NOT_SPECIFIED,
        BLOCKER.ABSORBED_DAMAGE_DESTINATION_NOT_SPECIFIED,
        BLOCKER.SCRAP_RETURN_BAND_NOT_SPECIFIED,
        BLOCKER.SCRAP_RETURN_RECIPIENT_NOT_SPECIFIED,
        BLOCKER.SUCCESS_OUTCOME_NOT_SPECIFIED,
        BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED,
        BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED,
        BLOCKER.ABSORPTION_EFFECT_NOT_EXECUTABLE,
        BLOCKER.SCRAP_RETURN_EFFECT_NOT_EXECUTABLE,
        BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
        BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
      ],
    },
    spiritThread: {
      actionId: 'spiritThread',
      templateId: 'aetherWeaver',
      provenance: 'preservation-era-prototype-mechanics',
      status: STATUS.DRAFT_UNRESOLVED,
      source: {
        kind: 'field-role-declaration',
        text: '2D6+Spirit. Heal 1-3 Vit to a target ally.',
      },
      stat: 'spirit',
      roll: {
        system: '2d6',
        stat: 'spirit',
        successMin: 10,
        partialMin: 7,
        source: 'established-global-combat-rule',
      },
      cost: {
        status: UNKNOWN,
        resource: null,
        amount: null,
      },
      knownSemantics: [
        {
          id: 'healTargetAlly',
          status: 'declared',
          band: UNKNOWN,
          effectKind: 'restore',
          target: 'ally',
          operation: 'restore',
          key: 'vitality',
          amount: null,
          amountRange: [1, 3],
          amountSelection: UNKNOWN,
          targetSelection: UNKNOWN,
        },
      ],
      outcomes: {
        common: null,
        success: null,
        partial: null,
        failure: null,
      },
      execution: {
        status: 'not-established',
        adapterId: null,
        version: null,
      },
      persistence: {
        status: 'not-established',
        mode: null,
        fields: [],
      },
      authoredBindings: {
        nativeJob: UNKNOWN,
        school: UNKNOWN,
      },
      blockers: [
        BLOCKER.COST_NOT_SPECIFIED,
        BLOCKER.HEAL_BAND_NOT_SPECIFIED,
        BLOCKER.HEAL_AMOUNT_SELECTION_NOT_SPECIFIED,
        BLOCKER.ALLY_TARGET_SELECTION_NOT_SPECIFIED,
        BLOCKER.SUCCESS_OUTCOME_NOT_SPECIFIED,
        BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED,
        BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED,
        BLOCKER.ALLY_RESTORE_EFFECT_NOT_EXECUTABLE,
        BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
        BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
      ],
    },
    aetherWeave: {
      actionId: 'aetherWeave',
      templateId: 'aetherWeaver',
      provenance: 'preservation-era-prototype-mechanics',
      status: STATUS.DRAFT_UNRESOLVED,
      source: {
        kind: 'field-role-declaration',
        text: '2D6+Presence. Buff ally\'s next roll +1. Costs 1 Aether.',
      },
      stat: 'presence',
      roll: {
        system: '2d6',
        stat: 'presence',
        successMin: 10,
        partialMin: 7,
        source: 'established-global-combat-rule',
      },
      cost: {
        status: COST_STATUS.DECLARED,
        resource: 'aether',
        amount: 1,
        sourceText: 'Costs 1 Aether.',
      },
      knownSemantics: [
        {
          id: 'buffAllyNextRoll',
          status: 'declared',
          band: UNKNOWN,
          effectKind: 'modifier',
          target: 'ally',
          operation: 'increase',
          key: 'nextRoll',
          amount: 1,
          targetSelection: UNKNOWN,
        },
      ],
      outcomes: {
        common: null,
        success: null,
        partial: null,
        failure: null,
      },
      execution: {
        status: 'not-established',
        adapterId: null,
        version: null,
      },
      persistence: {
        status: 'not-established',
        mode: null,
        fields: [],
      },
      authoredBindings: {
        nativeJob: UNKNOWN,
        school: UNKNOWN,
      },
      blockers: [
        BLOCKER.BUFF_BAND_NOT_SPECIFIED,
        BLOCKER.ALLY_MODIFIER_TARGET_SELECTION_NOT_SPECIFIED,
        BLOCKER.SUCCESS_OUTCOME_NOT_SPECIFIED,
        BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED,
        BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED,
        BLOCKER.ALLY_NEXT_ROLL_MODIFIER_NOT_EXECUTABLE,
        BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
        BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
      ],
    },
  });

  function getDraft(actionId) {
    return DRAFTS[actionId] ? clone(DRAFTS[actionId]) : null;
  }

  function listDrafts() {
    return DRAFT_ORDER.map(getDraft);
  }

  function getReadiness(actionId) {
    const draft = DRAFTS[actionId];
    if (!draft) {
      return {
        actionId,
        known: false,
        designComplete: false,
        executionAuthorized: false,
        reason: 'unknown_companion_action_contract',
        blockers: [],
      };
    }

    return {
      actionId,
      known: true,
      designComplete: draft.status === STATUS.READY_FOR_ADMISSION,
      executionAuthorized: false,
      reason: draft.status === STATUS.READY_FOR_ADMISSION
        ? 'execution_authorization_not_established'
        : 'outcome_contract_not_established',
      blockers: draft.blockers.slice(),
    };
  }

  function getAdmissionCandidate(actionId) {
    const draft = DRAFTS[actionId];
    if (!draft || draft.status !== STATUS.READY_FOR_ADMISSION) return null;
    return clone(draft.admissionContract || null);
  }

  function validateAgainstFieldRoles(fieldRoleDefs) {
    if (!fieldRoleDefs ||
        typeof fieldRoleDefs.getById !== 'function' ||
        typeof fieldRoleDefs.PROVENANCE !== 'string') {
      throw new Error('COMPANION_CONTRACT_FIELD_ROLE_REGISTRY_REQUIRED');
    }

    DRAFT_ORDER.forEach(actionId => {
      const draft = DRAFTS[actionId];
      const role = fieldRoleDefs.getById(draft.templateId);
      if (!role) {
        throw new Error('COMPANION_CONTRACT_TEMPLATE_MISSING:' + draft.templateId);
      }

      const declaration = role.abilities.find(ability => ability.id === actionId);
      if (!declaration) {
        throw new Error('COMPANION_CONTRACT_ACTION_MISSING:' + actionId);
      }
      if (draft.provenance !== fieldRoleDefs.PROVENANCE) {
        throw new Error('COMPANION_CONTRACT_PROVENANCE_MISMATCH:' + actionId);
      }
      if (draft.stat !== declaration.stat ||
          draft.roll.stat !== declaration.stat ||
          draft.source.text !== declaration.desc) {
        throw new Error('COMPANION_CONTRACT_DECLARATION_DRIFT:' + actionId);
      }
      if (draft.status !== STATUS.DRAFT_UNRESOLVED) {
        throw new Error('COMPANION_CONTRACT_UNEXPECTED_STATUS:' + actionId);
      }
      if (!Array.isArray(draft.blockers) || draft.blockers.length === 0) {
        throw new Error('COMPANION_CONTRACT_BLOCKERS_REQUIRED:' + actionId);
      }
      if (draft.cost.status === COST_STATUS.UNKNOWN) {
        if (draft.cost.resource !== null || draft.cost.amount !== null) {
          throw new Error('COMPANION_CONTRACT_UNKNOWN_COST_MUST_BE_EMPTY:' + actionId);
        }
      } else if (draft.cost.status === COST_STATUS.DECLARED) {
        if (typeof draft.cost.resource !== 'string' || !draft.cost.resource ||
            !Number.isFinite(draft.cost.amount) || draft.cost.amount <= 0 ||
            typeof draft.cost.sourceText !== 'string' || !draft.cost.sourceText ||
            !draft.source.text.includes(draft.cost.sourceText)) {
          throw new Error('COMPANION_CONTRACT_DECLARED_COST_EVIDENCE_INVALID:' + actionId);
        }
      } else {
        throw new Error('COMPANION_CONTRACT_COST_STATUS_INVALID:' + actionId);
      }
      if (draft.authoredBindings.nativeJob !== UNKNOWN ||
          draft.authoredBindings.school !== UNKNOWN) {
        throw new Error('COMPANION_CONTRACT_CANON_BINDING_MUST_REMAIN_UNKNOWN:' + actionId);
      }
      if (getAdmissionCandidate(actionId) !== null) {
        throw new Error('COMPANION_CONTRACT_PREMATURE_ADMISSION_CANDIDATE:' + actionId);
      }
    });

    return true;
  }

  return Object.freeze({
    VERSION,
    STATUS,
    UNKNOWN,
    COST_STATUS,
    BLOCKER,
    DRAFT_ORDER,
    DRAFTS,
    getDraft,
    listDrafts,
    getReadiness,
    getAdmissionCandidate,
    validateAgainstFieldRoles,
  });
});
