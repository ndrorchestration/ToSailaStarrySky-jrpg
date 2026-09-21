/* ============================================================
   Aetherwake JRPG — Magic School Access / Learning Boundary
   modules/magic-access.js

   Purpose:
   - derive school access from persistent character identity facts;
   - distinguish innate affinity from broad learnability;
   - preserve UNKNOWN companion magic;
   - refuse to turn school access into spell authorization;
   - avoid inventing mastery XP, Arete costs, equipped slots, or job rules.
   ============================================================ */

(function (root, factory) {
  'use strict';

  let masteryDefs = null;

  if (typeof module === 'object' && module.exports) {
    masteryDefs = require('./mastery-defs.js');
  } else if (root) {
    masteryDefs = root.AetherMasteryDefs;
  }

  const api = factory(masteryDefs);

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherMagicAccess = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function (masteryDefs) {
  'use strict';

  if (!masteryDefs) {
    throw new Error('MAGIC_ACCESS_REQUIRES_MASTERY_DEFS');
  }

  const VERSION = '0.2.0';

  const ACCESS_STATUS = Object.freeze({
    INNATE: 'innate',
    LEARNABLE: 'learnable',
    UNKNOWN: 'unknown',
    UNRECOGNIZED: 'unrecognized',
  });

  const DOMAIN_STATUS = Object.freeze({
    ESTABLISHED: 'established',
  });

  const TREE_STATUS = Object.freeze({
    DESIGN_PROPOSAL: 'design_proposal',
  });

  const RESOURCE_CONTEXT = Object.freeze({
    EXTERNAL_AETHER: 'external_aether',
    INNER_RESOURCE_OPEN: 'inner_resource_open',
  });

  const CORE_DOMAIN_IDS = Object.freeze([
    'elemental',
    'arcane',
    'psychic',
    'spirit',
  ]);

  const ENDER_INNATE_IDS = Object.freeze([
    'aether',
    'resonance',
    'correspondence',
    'lumen',
  ]);

  const RECOGNIZED_SCHOOL_IDS = Object.freeze([
    ...CORE_DOMAIN_IDS,
    ...ENDER_INNATE_IDS,
  ]);

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  const SCHOOL_METADATA = deepFreeze({
    elemental: {
      id: 'elemental',
      label: 'Elemental',
      domainStatus: DOMAIN_STATUS.ESTABLISHED,
      treeStatus: TREE_STATUS.DESIGN_PROPOSAL,
      resourceContext: RESOURCE_CONTEXT.INNER_RESOURCE_OPEN,
    },
    arcane: {
      id: 'arcane',
      label: 'Arcane',
      domainStatus: DOMAIN_STATUS.ESTABLISHED,
      treeStatus: TREE_STATUS.DESIGN_PROPOSAL,
      resourceContext: RESOURCE_CONTEXT.INNER_RESOURCE_OPEN,
    },
    psychic: {
      id: 'psychic',
      label: 'Psychic',
      domainStatus: DOMAIN_STATUS.ESTABLISHED,
      treeStatus: TREE_STATUS.DESIGN_PROPOSAL,
      resourceContext: RESOURCE_CONTEXT.INNER_RESOURCE_OPEN,
    },
    spirit: {
      id: 'spirit',
      label: 'Spirit',
      domainStatus: DOMAIN_STATUS.ESTABLISHED,
      treeStatus: TREE_STATUS.DESIGN_PROPOSAL,
      resourceContext: RESOURCE_CONTEXT.INNER_RESOURCE_OPEN,
    },
    aether: {
      id: 'aether',
      label: 'Aether',
      domainStatus: DOMAIN_STATUS.ESTABLISHED,
      treeStatus: TREE_STATUS.DESIGN_PROPOSAL,
      resourceContext: RESOURCE_CONTEXT.EXTERNAL_AETHER,
    },
    resonance: {
      id: 'resonance',
      label: 'Resonance / Harmonic',
      domainStatus: DOMAIN_STATUS.ESTABLISHED,
      treeStatus: TREE_STATUS.DESIGN_PROPOSAL,
      resourceContext: RESOURCE_CONTEXT.INNER_RESOURCE_OPEN,
    },
    correspondence: {
      id: 'correspondence',
      label: 'Correspondence',
      domainStatus: DOMAIN_STATUS.ESTABLISHED,
      treeStatus: TREE_STATUS.DESIGN_PROPOSAL,
      resourceContext: RESOURCE_CONTEXT.INNER_RESOURCE_OPEN,
    },
    lumen: {
      id: 'lumen',
      label: 'Lumen',
      domainStatus: DOMAIN_STATUS.ESTABLISHED,
      treeStatus: TREE_STATUS.DESIGN_PROPOSAL,
      resourceContext: RESOURCE_CONTEXT.INNER_RESOURCE_OPEN,
    },
  });

  const AUTHORED_CHARACTER_IDS = Object.freeze([
    'ender',
    'lyra',
    'ionia',
    'reson',
    'aepex',
  ]);

  function copy(value) {
    return value == null ? value : JSON.parse(JSON.stringify(value));
  }

  function isRecognizedSchool(schoolId) {
    return RECOGNIZED_SCHOOL_IDS.includes(schoolId);
  }

  function getSchoolMetadata(schoolId) {
    return SCHOOL_METADATA[schoolId] ? copy(SCHOOL_METADATA[schoolId]) : null;
  }

  function getSchoolAccess(characterId, schoolId) {
    if (!isRecognizedSchool(schoolId)) {
      return {
        characterId,
        schoolId,
        status: ACCESS_STATUS.UNRECOGNIZED,
        canStudySchool: false,
        requiresDeliberateTraining: false,
        reason: 'school_not_recognized',
      };
    }

    if (characterId !== 'ender') {
      return {
        characterId,
        schoolId,
        status: ACCESS_STATUS.UNKNOWN,
        canStudySchool: false,
        requiresDeliberateTraining: false,
        reason: AUTHORED_CHARACTER_IDS.includes(characterId)
          ? 'character_school_access_unresolved'
          : 'character_not_authored',
      };
    }

    const affinities = masteryDefs.getAuthoredAffinities('ender');
    if (affinities.status !== masteryDefs.STATUS.ESTABLISHED) {
      throw new Error('ENDER_AFFINITIES_MUST_BE_ESTABLISHED_FOR_MAGIC_ACCESS');
    }

    if (affinities.ids.includes(schoolId)) {
      return {
        characterId,
        schoolId,
        status: ACCESS_STATUS.INNATE,
        canStudySchool: true,
        requiresDeliberateTraining: false,
        reason: 'innate_affinity',
      };
    }

    return {
      characterId,
      schoolId,
      status: ACCESS_STATUS.LEARNABLE,
      canStudySchool: true,
      requiresDeliberateTraining: true,
      reason: 'ender_broad_learnability',
    };
  }

  function getCharacterAccessProfile(characterId) {
    const access = RECOGNIZED_SCHOOL_IDS.map(schoolId =>
      getSchoolAccess(characterId, schoolId)
    );

    return {
      characterId,
      innateSchoolIds: access
        .filter(item => item.status === ACCESS_STATUS.INNATE)
        .map(item => item.schoolId),
      learnableSchoolIds: access
        .filter(item => item.status === ACCESS_STATUS.LEARNABLE)
        .map(item => item.schoolId),
      unknownSchoolIds: access
        .filter(item => item.status === ACCESS_STATUS.UNKNOWN)
        .map(item => item.schoolId),
    };
  }

  function getFoundationSpellStudyAdmission(characterId, spellId) {
    const spell = masteryDefs.getFoundationSpellDefinition(spellId);
    if (!spell) {
      return {
        characterId,
        spellId,
        canStudy: false,
        canUse: false,
        reason: 'unknown_spell',
      };
    }

    const access = getSchoolAccess(characterId, spell.schoolId);
    if (access.status === ACCESS_STATUS.UNKNOWN) {
      return {
        characterId,
        spellId,
        schoolId: spell.schoolId,
        schoolAccess: access.status,
        canStudy: false,
        canUse: false,
        reason: 'school_access_unknown',
      };
    }

    if (!access.canStudySchool) {
      return {
        characterId,
        spellId,
        schoolId: spell.schoolId,
        schoolAccess: access.status,
        canStudy: false,
        canUse: false,
        reason: access.reason,
      };
    }

    if (spell.designStatus !== masteryDefs.DESIGN_STATUS.ESTABLISHED) {
      return {
        characterId,
        spellId,
        schoolId: spell.schoolId,
        schoolAccess: access.status,
        canStudy: false,
        canUse: false,
        reason: 'spell_design_not_established',
      };
    }

    const runtime = masteryDefs.getSpellRuntimeReadiness(characterId, spellId);
    if (!runtime.canUse) {
      return {
        characterId,
        spellId,
        schoolId: spell.schoolId,
        schoolAccess: access.status,
        canStudy: true,
        canUse: false,
        reason: runtime.reason,
      };
    }

    return {
      characterId,
      spellId,
      schoolId: spell.schoolId,
      schoolAccess: access.status,
      canStudy: true,
      canUse: true,
      reason: 'ok',
    };
  }

  function validate() {
    const expectedCore = masteryDefs.DOMAIN_FAMILY_IDS;
    if (CORE_DOMAIN_IDS.join('|') !== expectedCore.join('|')) {
      throw new Error('CORE_DOMAIN_IDS_DRIFTED_FROM_MASTERY_DEFS');
    }

    const expectedInnate = masteryDefs.ENDER_SPECIAL_AFFINITY_IDS;
    if (ENDER_INNATE_IDS.join('|') !== expectedInnate.join('|')) {
      throw new Error('ENDER_INNATE_IDS_DRIFTED_FROM_MASTERY_DEFS');
    }

    if (new Set(RECOGNIZED_SCHOOL_IDS).size !== RECOGNIZED_SCHOOL_IDS.length) {
      throw new Error('RECOGNIZED_SCHOOL_IDS_DUPLICATE');
    }

    RECOGNIZED_SCHOOL_IDS.forEach(schoolId => {
      const metadata = SCHOOL_METADATA[schoolId];
      if (!metadata || metadata.id !== schoolId) {
        throw new Error('SCHOOL_METADATA_MISSING_OR_MISMATCHED:' + schoolId);
      }
      if (metadata.domainStatus !== DOMAIN_STATUS.ESTABLISHED) {
        throw new Error('SCHOOL_DOMAIN_STATUS_INVALID:' + schoolId);
      }
      if (metadata.treeStatus !== TREE_STATUS.DESIGN_PROPOSAL) {
        throw new Error('SCHOOL_TREE_STATUS_INVALID:' + schoolId);
      }
    });

    const ender = getCharacterAccessProfile('ender');
    if (ender.innateSchoolIds.join('|') !== ENDER_INNATE_IDS.join('|')) {
      throw new Error('ENDER_INNATE_ACCESS_INVALID');
    }
    if (ender.learnableSchoolIds.join('|') !== CORE_DOMAIN_IDS.join('|')) {
      throw new Error('ENDER_BROAD_LEARNABILITY_INVALID');
    }
    if (ender.unknownSchoolIds.length !== 0) {
      throw new Error('ENDER_RECOGNIZED_ACCESS_MUST_NOT_BE_UNKNOWN');
    }

    ['lyra', 'ionia', 'reson', 'aepex'].forEach(characterId => {
      const profile = getCharacterAccessProfile(characterId);
      if (profile.innateSchoolIds.length !== 0 ||
          profile.learnableSchoolIds.length !== 0 ||
          profile.unknownSchoolIds.join('|') !== RECOGNIZED_SCHOOL_IDS.join('|')) {
        throw new Error('COMPANION_MAGIC_ACCESS_MUST_REMAIN_UNKNOWN:' + characterId);
      }
    });

    masteryDefs.FOUNDATION_SPELL_ORDER.forEach(spellId => {
      const admission = getFoundationSpellStudyAdmission('ender', spellId);
      if (spellId === 'aetherSense') {
        if (!admission.canStudy || !admission.canUse || admission.reason !== 'ok') {
          throw new Error('AETHER_SENSE_ACCESS_ADMISSION_INVALID');
        }
      } else if (admission.canStudy || admission.canUse ||
                 admission.reason !== 'spell_design_not_established') {
        throw new Error('PROPOSED_FOUNDATION_SPELL_MUST_NOT_BECOME_LEARNED:' + spellId);
      }
    });

    return true;
  }

  validate();

  return Object.freeze({
    VERSION,
    ACCESS_STATUS,
    DOMAIN_STATUS,
    TREE_STATUS,
    RESOURCE_CONTEXT,
    CORE_DOMAIN_IDS,
    ENDER_INNATE_IDS,
    RECOGNIZED_SCHOOL_IDS,
    SCHOOL_METADATA,
    AUTHORED_CHARACTER_IDS,
    isRecognizedSchool,
    getSchoolMetadata,
    getSchoolAccess,
    getCharacterAccessProfile,
    getFoundationSpellStudyAdmission,
    validate,
  });
});
