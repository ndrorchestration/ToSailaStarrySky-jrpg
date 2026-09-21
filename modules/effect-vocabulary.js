/* ============================================================
   Aetherwake JRPG — Effect Vocabulary v0.1
   modules/effect-vocabulary.js

   Scope:
   - Defines the smallest ordinary effect language needed to describe
     the current combat surface without changing combat resolution.
   - Provides bridge profiles for the eight current player actions.
   - Records known "declared but not applied" prototype semantics
     instead of presenting text-only behavior as implemented state.
   - Does NOT implement the future generic resolver or ABILITY_DEFS.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherEffectVocabulary = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';

  const EFFECT_KIND = Object.freeze({
    DAMAGE: 'damage',
    RESTORE: 'restore',
    RESOURCE: 'resource',
    MODIFIER: 'modifier',
    STATUS: 'status',
    REVEAL: 'reveal',
    MOVEMENT: 'movement',
  });

  const TARGET = Object.freeze({
    SELF: 'self',
    ENEMY: 'enemy',
    ALLY: 'ally',
    FIELD: 'field',
  });

  const RESOURCE = Object.freeze({
    ECHOES: 'echoes',
    AETHER: 'aether',
    HEAT: 'heat',
    SCRAP: 'scrap',
    STAFF_CHARGES: 'staffCharges',
  });

  const OPERATION = Object.freeze({
    APPLY: 'apply',
    INCREASE: 'increase',
    DECREASE: 'decrease',
    RESTORE: 'restore',
    REVEAL: 'reveal',
    MOVE: 'move',
  });

  const RUNTIME_STATUS = Object.freeze({
    IMPLEMENTED: 'implemented',
    DECLARED_NOT_APPLIED: 'declared_not_applied',
  });

  const PHASES = Object.freeze(['common', 'success', 'partial', 'failure']);

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  function effect(kind, target, operation, key, runtimeStatus, note) {
    return {
      kind,
      target,
      operation,
      key: key || null,
      runtimeStatus: runtimeStatus || RUNTIME_STATUS.IMPLEMENTED,
      note: note || null,
    };
  }

  // Bridge metadata only. resolveTurn() remains the executable authority in
  // this migration phase. Unmigrated actions remain outcome-oriented. Migrated
  // formula actions place their unconditional executable effects in `common`
  // and leave legacy outcome-band phases empty.
  const ACTION_EFFECT_PROFILES = deepFreeze({
    staffStrike: {
      // First JRPG-formula migration: these effects are no longer selected by
      // success/partial/failure bands. Numeric EMP damage comes from
      // modules/combat-formula.js; the effect resolver owns mutation.
      common: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.HEAT),
        effect(EFFECT_KIND.DAMAGE, TARGET.ENEMY, OPERATION.APPLY, 'emp'),
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.DECREASE, RESOURCE.STAFF_CHARGES),
      ],
      success: [],
      partial: [],
      failure: [],
    },

    uncoverTruth: {
      common: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.HEAT),
      ],
      success: [
        effect(
          EFFECT_KIND.REVEAL, TARGET.ENEMY, OPERATION.REVEAL, 'weakness',
          RUNTIME_STATUS.DECLARED_NOT_APPLIED,
          'Current runtime narrates the reveal but stores no reveal state.'
        ),
        effect(
          EFFECT_KIND.MODIFIER, TARGET.SELF, OPERATION.INCREASE, 'nextRoll',
          RUNTIME_STATUS.DECLARED_NOT_APPLIED,
          'Current runtime assigns a local nextRollBonus but never applies it to a later roll.'
        ),
      ],
      partial: [],
      failure: [
        effect(EFFECT_KIND.DAMAGE, TARGET.SELF, OPERATION.APPLY, 'vitality'),
      ],
    },

    sharedDream: {
      common: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.HEAT),
      ],
      success: [
        effect(
          EFFECT_KIND.RESTORE, TARGET.SELF, OPERATION.RESTORE, 'vitality',
          RUNTIME_STATUS.IMPLEMENTED,
          'One current random branch restores vitality.'
        ),
        effect(
          EFFECT_KIND.MODIFIER, TARGET.ALLY, OPERATION.INCREASE, 'nextRoll',
          RUNTIME_STATUS.DECLARED_NOT_APPLIED,
          'The alternate current branch narrates +1 but does not persist or consume a modifier.'
        ),
      ],
      partial: [
        effect(EFFECT_KIND.RESTORE, TARGET.SELF, OPERATION.RESTORE, 'vitality'),
      ],
      failure: [
        effect(EFFECT_KIND.DAMAGE, TARGET.SELF, OPERATION.APPLY, 'vitality'),
      ],
    },

    mycelialLedger: {
      common: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.HEAT),
      ],
      success: [
        effect(
          EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.AETHER,
          RUNTIME_STATUS.IMPLEMENTED,
          'One current random branch gains aether.'
        ),
        effect(
          EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.SCRAP,
          RUNTIME_STATUS.IMPLEMENTED,
          'The alternate current branch gains scrap.'
        ),
      ],
      partial: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.SCRAP),
      ],
      failure: [
        effect(EFFECT_KIND.DAMAGE, TARGET.SELF, OPERATION.APPLY, 'vitality'),
      ],
    },

    hold: {
      // Deterministic JRPG resource action: no outcome bands, no self-damage.
      common: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.STAFF_CHARGES),
      ],
      success: [],
      partial: [],
      failure: [],
    },

    windWard: {
      common: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.HEAT),
      ],
      success: [
        effect(EFFECT_KIND.RESTORE, TARGET.SELF, OPERATION.RESTORE, 'vitality'),
      ],
      partial: [
        effect(EFFECT_KIND.DAMAGE, TARGET.SELF, OPERATION.APPLY, 'vitality'),
      ],
      failure: [
        effect(EFFECT_KIND.DAMAGE, TARGET.SELF, OPERATION.APPLY, 'vitality'),
      ],
    },

    aetherSeal: {
      common: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.HEAT),
      ],
      success: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.INCREASE, RESOURCE.SCRAP),
      ],
      partial: [
        effect(EFFECT_KIND.DAMAGE, TARGET.SELF, OPERATION.APPLY, 'vitality'),
      ],
      failure: [
        effect(EFFECT_KIND.DAMAGE, TARGET.SELF, OPERATION.APPLY, 'vitality'),
      ],
    },

    rest: {
      // Deterministic JRPG recovery action: no outcome bands or failure damage.
      common: [
        effect(EFFECT_KIND.RESOURCE, TARGET.SELF, OPERATION.DECREASE, RESOURCE.HEAT),
        effect(EFFECT_KIND.RESTORE, TARGET.SELF, OPERATION.RESTORE, 'vitality'),
      ],
      success: [],
      partial: [],
      failure: [],
    },
  });

  const CURRENT_RUNTIME_EFFECT_SURFACE = deepFreeze({
    playerActions: [
      EFFECT_KIND.DAMAGE,
      EFFECT_KIND.RESTORE,
      EFFECT_KIND.RESOURCE,
      EFFECT_KIND.MODIFIER,
      EFFECT_KIND.REVEAL,
    ],
    enemyBranches: [
      EFFECT_KIND.DAMAGE,
      EFFECT_KIND.RESOURCE,
      EFFECT_KIND.STATUS,
      EFFECT_KIND.MOVEMENT,
    ],
  });

  function includesValue(object, value) {
    return Object.keys(object).some(key => object[key] === value);
  }

  function validateEffectDescriptor(descriptor) {
    if (!descriptor || typeof descriptor !== 'object') {
      throw new Error('EFFECT_DESCRIPTOR_MUST_BE_OBJECT');
    }
    if (!includesValue(EFFECT_KIND, descriptor.kind)) {
      throw new Error('UNKNOWN_EFFECT_KIND:' + descriptor.kind);
    }
    if (!includesValue(TARGET, descriptor.target)) {
      throw new Error('UNKNOWN_EFFECT_TARGET:' + descriptor.target);
    }
    if (!includesValue(OPERATION, descriptor.operation)) {
      throw new Error('UNKNOWN_EFFECT_OPERATION:' + descriptor.operation);
    }
    if (!includesValue(RUNTIME_STATUS, descriptor.runtimeStatus)) {
      throw new Error('UNKNOWN_EFFECT_RUNTIME_STATUS:' + descriptor.runtimeStatus);
    }
    if (descriptor.kind === EFFECT_KIND.RESOURCE &&
        !includesValue(RESOURCE, descriptor.key)) {
      throw new Error('UNKNOWN_EFFECT_RESOURCE:' + descriptor.key);
    }
    if (descriptor.key != null && typeof descriptor.key !== 'string') {
      throw new Error('EFFECT_KEY_MUST_BE_STRING_OR_NULL');
    }
    return true;
  }

  function validateProfile(profileId, profile) {
    if (!profile || typeof profile !== 'object') {
      throw new Error('EFFECT_PROFILE_MUST_BE_OBJECT:' + profileId);
    }
    PHASES.forEach(phase => {
      if (!Array.isArray(profile[phase])) {
        throw new Error('EFFECT_PROFILE_PHASE_MUST_BE_ARRAY:' + profileId + ':' + phase);
      }
      profile[phase].forEach(validateEffectDescriptor);
    });
    return true;
  }

  function validateVocabulary() {
    Object.keys(ACTION_EFFECT_PROFILES).forEach(profileId => {
      validateProfile(profileId, ACTION_EFFECT_PROFILES[profileId]);
    });
    return true;
  }

  function assertActionCoverage(actions) {
    if (!Array.isArray(actions)) throw new Error('ACTIONS_MUST_BE_ARRAY');

    const actionIds = actions.map(action => action && action.id);
    if (new Set(actionIds).size !== actionIds.length) {
      throw new Error('ACTION_IDS_MUST_BE_UNIQUE');
    }

    const profileIds = Object.keys(ACTION_EFFECT_PROFILES);
    const missingProfiles = actionIds.filter(id => !ACTION_EFFECT_PROFILES[id]);
    const orphanProfiles = profileIds.filter(id => !actionIds.includes(id));

    if (missingProfiles.length) {
      throw new Error('ACTIONS_MISSING_EFFECT_PROFILES:' + missingProfiles.join(','));
    }
    if (orphanProfiles.length) {
      throw new Error('ORPHAN_EFFECT_PROFILES:' + orphanProfiles.join(','));
    }

    actions.forEach(action => {
      if (action.effectProfile !== action.id) {
        throw new Error('ACTION_EFFECT_PROFILE_BINDING_INVALID:' + action.id);
      }
      validateProfile(action.id, ACTION_EFFECT_PROFILES[action.id]);
    });

    return true;
  }

  validateVocabulary();

  return Object.freeze({
    VERSION,
    EFFECT_KIND,
    TARGET,
    RESOURCE,
    OPERATION,
    RUNTIME_STATUS,
    PHASES,
    ACTION_EFFECT_PROFILES,
    CURRENT_RUNTIME_EFFECT_SURFACE,
    validateEffectDescriptor,
    validateProfile,
    validateVocabulary,
    assertActionCoverage,
  });
});
