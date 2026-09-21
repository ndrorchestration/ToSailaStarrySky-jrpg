/* ============================================================
   Aetherwake JRPG — Foundation Spell Contract Drafts v0.1
   modules/foundation-spell-contracts.js

   Scope:
   - preserve established Aether Sense execution evidence;
   - make Aether Pulse's unresolved combat design machine-readable;
   - expose admission candidates only when semantic contracts are complete.

   This module does NOT authorize new spells, choose balance values, execute
   effects, alter mastery progression, or modify persistence.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherFoundationSpellContracts = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';

  const STATUS = Object.freeze({
    ESTABLISHED_RUNTIME: 'established-runtime',
    DRAFT_UNRESOLVED: 'draft-unresolved',
    READY_FOR_ADMISSION: 'ready-for-admission',
  });

  const UNKNOWN = 'unknown';

  const BLOCKER = Object.freeze({
    DESIGN_NOT_ESTABLISHED: 'DESIGN_NOT_ESTABLISHED',
    STARTING_OWNERSHIP_NOT_ESTABLISHED: 'STARTING_OWNERSHIP_NOT_ESTABLISHED',
    COST_NOT_SPECIFIED: 'COST_NOT_SPECIFIED',
    ROLL_STAT_NOT_SPECIFIED: 'ROLL_STAT_NOT_SPECIFIED',
    COMMON_OUTCOME_NOT_SPECIFIED: 'COMMON_OUTCOME_NOT_SPECIFIED',
    SUCCESS_OUTCOME_NOT_SPECIFIED: 'SUCCESS_OUTCOME_NOT_SPECIFIED',
    PARTIAL_OUTCOME_NOT_SPECIFIED: 'PARTIAL_OUTCOME_NOT_SPECIFIED',
    FAILURE_OUTCOME_NOT_SPECIFIED: 'FAILURE_OUTCOME_NOT_SPECIFIED',
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
    'aetherSense',
    'aetherPulse',
  ]);

  const CONTRACTS = deepFreeze({
    aetherSense: {
      spellId: 'aetherSense',
      schoolId: 'aether',
      status: STATUS.ESTABLISHED_RUNTIME,
      source: {
        kind: 'mastery-definition+runtime',
        description: 'Detect Aether concentrations, leaks, charged machinery, active fields, and unusual Aether signatures.',
      },
      mode: 'exploration-readonly',
      resourceBinding: 'none',
      cost: {
        resource: null,
        amount: 0,
      },
      roll: null,
      outcomes: null,
      mutationPolicy: 'read-only',
      execution: {
        adapterId: 'aether-sense',
        version: '0.1.0',
      },
      persistence: {
        mode: 'none',
        fields: [],
      },
      startingCharacterIds: ['ender'],
      blockers: [],
      admissionContract: {
        spellId: 'aetherSense',
        schoolId: 'aether',
        mode: 'exploration-readonly',
        cost: {
          resource: null,
          amount: 0,
        },
        roll: null,
        outcomes: null,
        mutationPolicy: 'read-only',
        execution: {
          adapterId: 'aether-sense',
          version: '0.1.0',
        },
        persistence: {
          mode: 'none',
          fields: [],
        },
      },
    },

    aetherPulse: {
      spellId: 'aetherPulse',
      schoolId: 'aether',
      status: STATUS.DRAFT_UNRESOLVED,
      source: {
        kind: 'mastery-definition',
        description: 'Fire a compact burst of Aether at one target; the baseline active Aether technique.',
      },
      mode: 'combat-2d6',
      resourceBinding: 'aether',
      cost: {
        resource: 'aether',
        amount: null,
        status: UNKNOWN,
      },
      roll: {
        system: '2d6',
        stat: UNKNOWN,
        successMin: 10,
        partialMin: 7,
        source: 'established-global-combat-rule',
      },
      requiredEffectKinds: ['damage'],
      outcomes: {
        common: null,
        success: null,
        partial: null,
        failure: null,
      },
      mutationPolicy: 'effect-resolver',
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
      startingCharacterIds: [],
      blockers: [
        BLOCKER.DESIGN_NOT_ESTABLISHED,
        BLOCKER.STARTING_OWNERSHIP_NOT_ESTABLISHED,
        BLOCKER.COST_NOT_SPECIFIED,
        BLOCKER.ROLL_STAT_NOT_SPECIFIED,
        BLOCKER.COMMON_OUTCOME_NOT_SPECIFIED,
        BLOCKER.SUCCESS_OUTCOME_NOT_SPECIFIED,
        BLOCKER.PARTIAL_OUTCOME_NOT_SPECIFIED,
        BLOCKER.FAILURE_OUTCOME_NOT_SPECIFIED,
        BLOCKER.EXECUTION_ADAPTER_NOT_ESTABLISHED,
        BLOCKER.PERSISTENCE_POLICY_NOT_ESTABLISHED,
      ],
      admissionContract: null,
    },
  });

  function getContract(spellId) {
    return CONTRACTS[spellId] ? clone(CONTRACTS[spellId]) : null;
  }

  function listContracts() {
    return DRAFT_ORDER.map(getContract);
  }

  function getAdmissionCandidate(spellId) {
    const contract = CONTRACTS[spellId];
    if (!contract) return null;
    if (contract.status !== STATUS.ESTABLISHED_RUNTIME &&
        contract.status !== STATUS.READY_FOR_ADMISSION) {
      return null;
    }
    return clone(contract.admissionContract || null);
  }

  function getReadiness(spellId) {
    const contract = CONTRACTS[spellId];
    if (!contract) {
      return {
        spellId,
        known: false,
        designComplete: false,
        runtimeEstablished: false,
        reason: 'unknown_foundation_spell_contract',
        blockers: [],
      };
    }

    return {
      spellId,
      known: true,
      designComplete: contract.status !== STATUS.DRAFT_UNRESOLVED,
      runtimeEstablished: contract.status === STATUS.ESTABLISHED_RUNTIME,
      reason: contract.status === STATUS.ESTABLISHED_RUNTIME
        ? 'ok'
        : (contract.status === STATUS.READY_FOR_ADMISSION
            ? 'runtime_authorization_not_established'
            : 'spell_contract_not_established'),
      blockers: contract.blockers.slice(),
    };
  }

  function validateAgainstMastery(masteryDefs) {
    if (!masteryDefs ||
        typeof masteryDefs.getFoundationSpellDefinition !== 'function' ||
        typeof masteryDefs.getSpellRuntimeReadiness !== 'function') {
      throw new Error('FOUNDATION_SPELL_CONTRACT_MASTERY_REQUIRED');
    }

    DRAFT_ORDER.forEach(spellId => {
      const record = CONTRACTS[spellId];
      const spell = masteryDefs.getFoundationSpellDefinition(spellId);
      if (!spell) {
        throw new Error('FOUNDATION_SPELL_CONTRACT_DEFINITION_MISSING:' + spellId);
      }
      if (record.schoolId !== spell.schoolId ||
          record.source.description !== spell.description ||
          record.resourceBinding !== spell.resourceBinding) {
        throw new Error('FOUNDATION_SPELL_CONTRACT_DEFINITION_DRIFT:' + spellId);
      }

      if (spellId === 'aetherSense') {
        if (record.status !== STATUS.ESTABLISHED_RUNTIME ||
            spell.designStatus !== masteryDefs.DESIGN_STATUS.ESTABLISHED ||
            spell.runtimeStatus !== masteryDefs.RUNTIME_STATUS.INTEGRATED ||
            spell.startingCharacterIds.join('|') !== 'ender' ||
            record.startingCharacterIds.join('|') !== 'ender' ||
            record.blockers.length !== 0 ||
            getAdmissionCandidate(spellId) === null) {
          throw new Error('AETHER_SENSE_CONTRACT_INVALID');
        }
        const runtime = masteryDefs.getSpellRuntimeReadiness('ender', spellId);
        if (!runtime.canUse || runtime.reason !== 'ok') {
          throw new Error('AETHER_SENSE_RUNTIME_READINESS_DRIFT');
        }
      }

      if (spellId === 'aetherPulse') {
        if (record.status !== STATUS.DRAFT_UNRESOLVED ||
            spell.designStatus !== masteryDefs.DESIGN_STATUS.DESIGN_PROPOSAL ||
            spell.runtimeStatus !== masteryDefs.RUNTIME_STATUS.NOT_INTEGRATED ||
            spell.startingCharacterIds.length !== 0 ||
            record.startingCharacterIds.length !== 0 ||
            record.cost.status !== UNKNOWN ||
            record.cost.amount !== null ||
            record.roll.stat !== UNKNOWN ||
            getAdmissionCandidate(spellId) !== null ||
            record.blockers.length === 0) {
          throw new Error('AETHER_PULSE_MUST_REMAIN_UNRESOLVED');
        }
      }
    });

    return true;
  }

  return Object.freeze({
    VERSION,
    STATUS,
    UNKNOWN,
    BLOCKER,
    DRAFT_ORDER,
    CONTRACTS,
    getContract,
    listContracts,
    getAdmissionCandidate,
    getReadiness,
    validateAgainstMastery,
  });
});
