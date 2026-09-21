/* ============================================================
   Aetherwake JRPG — Mastery / Authored Progression Definitions
   modules/mastery-defs.js

   Phase A boundary:
   - code-owned established domain/affinity/native-job facts;
   - explicit UNKNOWN for unresolved authored data;
   - no mutable mastery ranks/XP;
   - no save-schema changes;
   - no changes to current combat eligibility.
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

  const VERSION = '0.1.0';
  const STATUS = Object.freeze({
    ESTABLISHED: 'established',
    UNKNOWN: 'unknown',
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

  function copyIds(ids) {
    return Array.isArray(ids) ? ids.slice() : [];
  }

  function isValidId(id) {
    return typeof id === 'string' &&
      /^[a-z][a-z0-9-]*$/.test(id);
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
    });

    return true;
  }

  validate();

  return Object.freeze({
    VERSION,
    STATUS,
    DOMAIN_FAMILY_IDS,
    ENDER_SPECIAL_AFFINITY_IDS,
    AUTHORED_CHARACTER_IDS,
    getAuthoredAffinities,
    getNativeJobStatus,
    validateIdList,
    validate,
  });
});
