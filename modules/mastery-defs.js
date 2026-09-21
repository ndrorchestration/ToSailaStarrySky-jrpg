/* ============================================================
   Aetherwake JRPG — Mastery / Magic-System Definitions
   modules/mastery-defs.js

   Phase B boundary:
   - preserves code-owned established domain/affinity/native-job facts;
   - adds the authored four-school Ender magic foundation as immutable data;
   - keeps proposed spell-tree content explicitly DESIGN_PROPOSAL;
   - keeps unresolved companion magic explicitly UNKNOWN;
   - does not add mutable mastery ranks/XP, save-schema changes, or combat use;
   - fails closed when proposed spells are queried for runtime use.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherMasteryDefs = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.2.0';

  const STATUS = Object.freeze({
    ESTABLISHED: 'established',
    UNKNOWN: 'unknown',
  });

  const DESIGN_STATUS = Object.freeze({
    ESTABLISHED: 'established',
    DESIGN_PROPOSAL: 'design_proposal',
  });

  const RUNTIME_STATUS = Object.freeze({
    INTEGRATED: 'integrated',
    NOT_INTEGRATED: 'not_integrated',
  });

  const RESOURCE_BINDING = Object.freeze({
    NONE: 'none',
    AETHER: 'aether',
    ARETE_PENDING: 'arete_pending',
  });

  const DOMAIN_FAMILY_IDS = Object.freeze([
    'elemental',
    'arcane',
    'psychic',
    'spirit',
  ]);

  const ENDER_SPECIAL_AFFINITY_IDS = Object.freeze([
    'aether',
    'resonance',
    'correspondence',
    'lumen',
  ]);

  const AUTHORED_CHARACTER_IDS = Object.freeze([
    'ender',
    'lyra',
    'ionia',
    'reson',
    'aepex',
  ]);

  const AUTHORED_AFFINITIES = Object.freeze({
    ender: Object.freeze({
      status: STATUS.ESTABLISHED,
      ids: ENDER_SPECIAL_AFFINITY_IDS,
    }),
  });

  const NATIVE_JOB_FACTS = Object.freeze({
    ender: Object.freeze({
      status: STATUS.ESTABLISHED,
      id: 'rift-scholar',
      label: 'Rift Scholar',
    }),
  });

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  function branch(id, label) {
    return { id, label };
  }

  const SCHOOL_ORDER = ENDER_SPECIAL_AFFINITY_IDS;

  const SCHOOL_DEFS = deepFreeze({
    aether: {
      id: 'aether',
      label: 'Aether',
      affinityStatus: STATUS.ESTABLISHED,
      treeStatus: DESIGN_STATUS.DESIGN_PROPOSAL,
      combatIdentity: 'Resource control, magical infrastructure, field manipulation, barriers, sealing, and Aether discharge.',
      branches: [
        branch('flow', 'Flow'),
        branch('ward', 'Ward'),
        branch('flux', 'Flux'),
      ],
      foundationSpellIds: ['aetherSense', 'aetherPulse'],
    },
    resonance: {
      id: 'resonance',
      label: 'Resonance / Harmonic',
      affinityStatus: STATUS.ESTABLISHED,
      treeStatus: DESIGN_STATUS.DESIGN_PROPOSAL,
      combatIdentity: 'Frequency, synchronization, buffs, disruption, counters, stagger, and resonant field control.',
      branches: [
        branch('concord', 'Concord'),
        branch('dissonance', 'Dissonance'),
        branch('chorus', 'Chorus'),
      ],
      foundationSpellIds: ['resonantPing', 'attune'],
    },
    correspondence: {
      id: 'correspondence',
      label: 'Correspondence',
      affinityStatus: STATUS.ESTABLISHED,
      treeStatus: DESIGN_STATUS.DESIGN_PROPOSAL,
      combatIdentity: 'Space, distance, adjacency, positioning, gravity, boundaries, teleportation, and impossible geometry.',
      branches: [
        branch('traverse', 'Traverse'),
        branch('anchor', 'Anchor'),
        branch('fold', 'Fold'),
      ],
      foundationSpellIds: ['spatialSense', 'riftStep'],
    },
    lumen: {
      id: 'lumen',
      label: 'Lumen',
      affinityStatus: STATUS.ESTABLISHED,
      treeStatus: DESIGN_STATUS.DESIGN_PROPOSAL,
      combatIdentity: 'Light, solar/radiant energy, healing, revelation, cleansing, barriers, charging, and refraction.',
      branches: [
        branch('radiance', 'Radiance'),
        branch('dawn', 'Dawn'),
        branch('prism', 'Prism'),
      ],
      foundationSpellIds: ['lumenSpark', 'solarMend'],
    },
  });

  function foundationSpell(id, label, schoolId, modes, role, resourceBinding, verbs, description) {
    return {
      id,
      label,
      schoolId,
      tier: 1,
      branchId: null,
      modes,
      role,
      resourceBinding,
      resourceCost: null,
      designStatus: DESIGN_STATUS.DESIGN_PROPOSAL,
      runtimeStatus: RUNTIME_STATUS.NOT_INTEGRATED,
      verbs,
      description,
    };
  }

  const FOUNDATION_SPELL_ORDER = Object.freeze([
    'aetherSense',
    'aetherPulse',
    'resonantPing',
    'attune',
    'spatialSense',
    'riftStep',
    'lumenSpark',
    'solarMend',
  ]);

  const FOUNDATION_SPELLS = deepFreeze({
    aetherSense: foundationSpell(
      'aetherSense',
      'Aether Sense',
      'aether',
      ['exploration', 'combat'],
      'perception',
      RESOURCE_BINDING.NONE,
      ['detect', 'identify'],
      'Detect Aether concentrations, leaks, charged machinery, active fields, and unusual Aether signatures.'
    ),
    aetherPulse: foundationSpell(
      'aetherPulse',
      'Aether Pulse',
      'aether',
      ['combat'],
      'offense',
      RESOURCE_BINDING.AETHER,
      ['discharge', 'damage'],
      'Fire a compact burst of Aether at one target; the baseline active Aether technique.'
    ),
    resonantPing: foundationSpell(
      'resonantPing',
      'Resonant Ping',
      'resonance',
      ['exploration', 'combat'],
      'perception',
      RESOURCE_BINDING.ARETE_PENDING,
      ['probe', 'reveal'],
      'Read a target frequency profile to expose weakness, instability, enchantment, or mechanical resonance.'
    ),
    attune: foundationSpell(
      'attune',
      'Attune',
      'resonance',
      ['exploration', 'combat'],
      'setup',
      RESOURCE_BINDING.ARETE_PENDING,
      ['tune', 'resist'],
      'Tune Ender to a selected frequency, preparing later Resonance techniques and resisting hostile resonance.'
    ),
    spatialSense: foundationSpell(
      'spatialSense',
      'Spatial Sense',
      'correspondence',
      ['exploration', 'combat'],
      'perception',
      RESOURCE_BINDING.NONE,
      ['perceive', 'map'],
      'Perceive distortions, hidden paths, dimensional seams, unstable geometry, and true distance.'
    ),
    riftStep: foundationSpell(
      'riftStep',
      'Rift Step',
      'correspondence',
      ['exploration', 'combat'],
      'movement',
      RESOURCE_BINDING.ARETE_PENDING,
      ['reposition', 'teleport'],
      'Perform a short-range instantaneous reposition as the foundation of Traverse techniques.'
    ),
    lumenSpark: foundationSpell(
      'lumenSpark',
      'Lumen Spark',
      'lumen',
      ['exploration', 'combat'],
      'utility-offense',
      RESOURCE_BINDING.ARETE_PENDING,
      ['illuminate', 'reveal', 'damage'],
      'Generate controlled magical light that can illuminate, expose some hidden phenomena, and harm a target.'
    ),
    solarMend: foundationSpell(
      'solarMend',
      'Solar Mend',
      'lumen',
      ['exploration', 'combat'],
      'restoration',
      RESOURCE_BINDING.ARETE_PENDING,
      ['restore', 'warm'],
      'Channel Lumen as restorative warmth for minor healing or recovery.'
    ),
  });

  function copyIds(ids) {
    return Array.isArray(ids) ? ids.slice() : [];
  }

  function clone(value) {
    return value == null ? value : JSON.parse(JSON.stringify(value));
  }

  function isValidId(id) {
    return typeof id === 'string' &&
      /^[a-z][A-Za-z0-9-]*$/.test(id);
  }

  function getAuthoredAffinities(characterId) {
    if (!AUTHORED_CHARACTER_IDS.includes(characterId)) {
      return { status: STATUS.UNKNOWN, ids: [] };
    }

    const fact = AUTHORED_AFFINITIES[characterId];
    if (!fact) {
      return { status: STATUS.UNKNOWN, ids: [] };
    }

    return {
      status: fact.status,
      ids: copyIds(fact.ids),
    };
  }

  function getNativeJobStatus(characterId) {
    if (!AUTHORED_CHARACTER_IDS.includes(characterId)) {
      return {
        status: STATUS.UNKNOWN,
        id: null,
        label: null,
      };
    }

    const fact = NATIVE_JOB_FACTS[characterId];
    if (!fact) {
      return {
        status: STATUS.UNKNOWN,
        id: null,
        label: null,
      };
    }

    return {
      status: fact.status,
      id: fact.id,
      label: fact.label,
    };
  }

  function getSchoolDefinition(schoolId) {
    return SCHOOL_DEFS[schoolId] ? clone(SCHOOL_DEFS[schoolId]) : null;
  }

  function getFoundationSpellDefinition(spellId) {
    return FOUNDATION_SPELLS[spellId] ? clone(FOUNDATION_SPELLS[spellId]) : null;
  }

  function listFoundationSpellsForSchool(schoolId) {
    const school = SCHOOL_DEFS[schoolId];
    if (!school) return [];
    return school.foundationSpellIds.map(id => clone(FOUNDATION_SPELLS[id]));
  }

  function getMagicProfile(characterId) {
    const affinities = getAuthoredAffinities(characterId);
    if (affinities.status !== STATUS.ESTABLISHED) {
      return {
        characterId,
        status: STATUS.UNKNOWN,
        affinityIds: [],
        schoolIds: [],
        foundationCandidateIds: [],
      };
    }

    const schoolIds = affinities.ids.filter(id => Boolean(SCHOOL_DEFS[id]));
    const foundationCandidateIds = FOUNDATION_SPELL_ORDER.filter(spellId =>
      schoolIds.includes(FOUNDATION_SPELLS[spellId].schoolId)
    );

    return {
      characterId,
      status: STATUS.ESTABLISHED,
      affinityIds: copyIds(affinities.ids),
      schoolIds: copyIds(schoolIds),
      foundationCandidateIds: copyIds(foundationCandidateIds),
    };
  }

  function getSpellRuntimeReadiness(characterId, spellId) {
    const spell = FOUNDATION_SPELLS[spellId];
    if (!spell) {
      return {
        canUse: false,
        reason: 'unknown_spell',
        characterId,
        spellId,
      };
    }

    const profile = getMagicProfile(characterId);
    if (profile.status !== STATUS.ESTABLISHED) {
      return {
        canUse: false,
        reason: 'character_magic_profile_unknown',
        characterId,
        spellId,
      };
    }

    if (!profile.schoolIds.includes(spell.schoolId)) {
      return {
        canUse: false,
        reason: 'school_not_in_authored_affinities',
        characterId,
        spellId,
      };
    }

    if (spell.designStatus !== DESIGN_STATUS.ESTABLISHED) {
      return {
        canUse: false,
        reason: 'design_proposal_not_runtime_authorized',
        characterId,
        spellId,
      };
    }

    if (spell.runtimeStatus !== RUNTIME_STATUS.INTEGRATED) {
      return {
        canUse: false,
        reason: 'runtime_not_integrated',
        characterId,
        spellId,
      };
    }

    return {
      canUse: true,
      reason: 'ok',
      characterId,
      spellId,
    };
  }

  function validateIdList(name, ids) {
    if (!Array.isArray(ids) || ids.length === 0) {
      throw new Error(name + '_MUST_BE_NONEMPTY_ARRAY');
    }

    const seen = new Set();
    ids.forEach(id => {
      if (!isValidId(id)) {
        throw new Error(name + '_ID_INVALID:' + id);
      }
      if (seen.has(id)) {
        throw new Error(name + '_ID_DUPLICATE:' + id);
      }
      seen.add(id);
    });
  }

  function validateSchoolDefinitions() {
    validateIdList('SCHOOL_ORDER', SCHOOL_ORDER);

    if (SCHOOL_ORDER.join('|') !== ENDER_SPECIAL_AFFINITY_IDS.join('|')) {
      throw new Error('SCHOOL_ORDER_MUST_MATCH_ENDER_AFFINITIES');
    }

    const schoolIds = Object.keys(SCHOOL_DEFS);
    if (schoolIds.length !== SCHOOL_ORDER.length) {
      throw new Error('SCHOOL_DEF_COUNT_MISMATCH');
    }

    SCHOOL_ORDER.forEach(id => {
      const school = SCHOOL_DEFS[id];
      if (!school || school.id !== id) {
        throw new Error('SCHOOL_DEF_ID_MISMATCH:' + id);
      }
      if (school.affinityStatus !== STATUS.ESTABLISHED) {
        throw new Error('SCHOOL_AFFINITY_STATUS_INVALID:' + id);
      }
      if (school.treeStatus !== DESIGN_STATUS.DESIGN_PROPOSAL) {
        throw new Error('SCHOOL_TREE_STATUS_INVALID:' + id);
      }
      if (!Array.isArray(school.branches) || school.branches.length !== 3) {
        throw new Error('SCHOOL_BRANCH_COUNT_INVALID:' + id);
      }

      const branchIds = school.branches.map(item => item.id);
      validateIdList('SCHOOL_BRANCH_' + id.toUpperCase(), branchIds);

      if (!Array.isArray(school.foundationSpellIds) ||
          school.foundationSpellIds.length !== 2) {
        throw new Error('SCHOOL_FOUNDATION_COUNT_INVALID:' + id);
      }
    });

    schoolIds.forEach(id => {
      if (!SCHOOL_ORDER.includes(id)) throw new Error('ORPHAN_SCHOOL_DEF:' + id);
    });

    return true;
  }

  function validateFoundationSpells() {
    validateIdList('FOUNDATION_SPELL_ORDER', FOUNDATION_SPELL_ORDER);

    const spellIds = Object.keys(FOUNDATION_SPELLS);
    if (spellIds.length !== FOUNDATION_SPELL_ORDER.length) {
      throw new Error('FOUNDATION_SPELL_COUNT_MISMATCH');
    }

    FOUNDATION_SPELL_ORDER.forEach(id => {
      const spell = FOUNDATION_SPELLS[id];
      if (!spell || spell.id !== id) {
        throw new Error('FOUNDATION_SPELL_ID_MISMATCH:' + id);
      }
      if (!SCHOOL_DEFS[spell.schoolId]) {
        throw new Error('FOUNDATION_SPELL_UNKNOWN_SCHOOL:' + id);
      }
      if (spell.tier !== 1 || spell.branchId !== null) {
        throw new Error('FOUNDATION_SPELL_TIER_INVALID:' + id);
      }
      if (spell.designStatus !== DESIGN_STATUS.DESIGN_PROPOSAL) {
        throw new Error('FOUNDATION_SPELL_DESIGN_STATUS_INVALID:' + id);
      }
      if (spell.runtimeStatus !== RUNTIME_STATUS.NOT_INTEGRATED) {
        throw new Error('FOUNDATION_SPELL_RUNTIME_STATUS_INVALID:' + id);
      }
      if (!Object.values(RESOURCE_BINDING).includes(spell.resourceBinding)) {
        throw new Error('FOUNDATION_SPELL_RESOURCE_BINDING_INVALID:' + id);
      }
      if (spell.resourceCost !== null) {
        throw new Error('FOUNDATION_SPELL_COST_MUST_REMAIN_UNFROZEN:' + id);
      }
      if (!Array.isArray(spell.modes) || spell.modes.length === 0 ||
          !Array.isArray(spell.verbs) || spell.verbs.length === 0) {
        throw new Error('FOUNDATION_SPELL_METADATA_INVALID:' + id);
      }
    });

    SCHOOL_ORDER.forEach(schoolId => {
      const expected = SCHOOL_DEFS[schoolId].foundationSpellIds;
      const actual = FOUNDATION_SPELL_ORDER.filter(id =>
        FOUNDATION_SPELLS[id].schoolId === schoolId
      );
      if (actual.join('|') !== expected.join('|')) {
        throw new Error('SCHOOL_FOUNDATION_BINDING_INVALID:' + schoolId);
      }
    });

    if (FOUNDATION_SPELLS.aetherwake) {
      throw new Error('AETHERWAKE_CAPSTONE_MUST_REMAIN_PLOT_GATED');
    }

    return true;
  }

  function validate() {
    validateIdList('DOMAIN_FAMILY', DOMAIN_FAMILY_IDS);
    validateIdList('ENDER_AFFINITY', ENDER_SPECIAL_AFFINITY_IDS);
    validateIdList('AUTHORED_CHARACTER', AUTHORED_CHARACTER_IDS);

    const enderAffinities = getAuthoredAffinities('ender');
    if (enderAffinities.status !== STATUS.ESTABLISHED ||
        enderAffinities.ids.join('|') !== ENDER_SPECIAL_AFFINITY_IDS.join('|')) {
      throw new Error('ENDER_AFFINITY_FACT_INVALID');
    }

    const enderJob = getNativeJobStatus('ender');
    if (enderJob.status !== STATUS.ESTABLISHED ||
        enderJob.id !== 'rift-scholar' ||
        enderJob.label !== 'Rift Scholar') {
      throw new Error('ENDER_NATIVE_JOB_FACT_INVALID');
    }

    ['lyra', 'ionia', 'reson', 'aepex'].forEach(characterId => {
      const affinity = getAuthoredAffinities(characterId);
      if (affinity.status !== STATUS.UNKNOWN || affinity.ids.length !== 0) {
        throw new Error('UNRESOLVED_AFFINITY_MUST_REMAIN_UNKNOWN:' + characterId);
      }

      const job = getNativeJobStatus(characterId);
      if (job.status !== STATUS.UNKNOWN || job.id !== null || job.label !== null) {
        throw new Error('UNRESOLVED_NATIVE_JOB_MUST_REMAIN_UNKNOWN:' + characterId);
      }

      const magic = getMagicProfile(characterId);
      if (magic.status !== STATUS.UNKNOWN ||
          magic.schoolIds.length !== 0 ||
          magic.foundationCandidateIds.length !== 0) {
        throw new Error('UNRESOLVED_MAGIC_PROFILE_MUST_REMAIN_UNKNOWN:' + characterId);
      }
    });

    validateSchoolDefinitions();
    validateFoundationSpells();

    const enderMagic = getMagicProfile('ender');
    if (enderMagic.schoolIds.join('|') !== SCHOOL_ORDER.join('|') ||
        enderMagic.foundationCandidateIds.join('|') !== FOUNDATION_SPELL_ORDER.join('|')) {
      throw new Error('ENDER_MAGIC_PROFILE_INVALID');
    }

    FOUNDATION_SPELL_ORDER.forEach(spellId => {
      const readiness = getSpellRuntimeReadiness('ender', spellId);
      if (readiness.canUse ||
          readiness.reason !== 'design_proposal_not_runtime_authorized') {
        throw new Error('PROPOSED_FOUNDATION_SPELL_MUST_FAIL_CLOSED:' + spellId);
      }
    });

    return true;
  }

  validate();

  return Object.freeze({
    VERSION,
    STATUS,
    DESIGN_STATUS,
    RUNTIME_STATUS,
    RESOURCE_BINDING,
    DOMAIN_FAMILY_IDS,
    ENDER_SPECIAL_AFFINITY_IDS,
    AUTHORED_CHARACTER_IDS,
    SCHOOL_ORDER,
    SCHOOL_DEFS,
    FOUNDATION_SPELL_ORDER,
    FOUNDATION_SPELLS,
    getAuthoredAffinities,
    getNativeJobStatus,
    getSchoolDefinition,
    getFoundationSpellDefinition,
    listFoundationSpellsForSchool,
    getMagicProfile,
    getSpellRuntimeReadiness,
    validateIdList,
    validateSchoolDefinitions,
    validateFoundationSpells,
    validate,
  });
});
