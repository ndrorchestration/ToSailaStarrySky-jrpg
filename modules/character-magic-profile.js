/* ============================================================
   Aetherwake JRPG — Character Magic Profile v0.2
   modules/character-magic-profile.js

   Separates innate affinity from learned mastery. Affinity never
   implies Rank 1+ mastery. This is a pure data/validation layer. Learned spells are tracked\n   separately from mastery and affinity.
   ============================================================ */

(function (root, factory) {
  const defs = typeof module === 'object' && module.exports
    ? require('./magic-defs.js')
    : root.AetherwakeMagicDefs;
  const mastery = typeof module === 'object' && module.exports
    ? require('./magic-mastery.js')
    : root.AetherwakeMagicMastery;
  const api = factory(defs, mastery);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherwakeCharacterMagicProfile = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (defs, mastery) {
  'use strict';

  if (!defs || !mastery) throw new Error('CHARACTER_MAGIC_PROFILE_REQUIRES_MAGIC_MODULES');

  const CHARACTER_IDS = Object.freeze(['ender', 'lyra', 'ionia', 'reson', 'aepex']);

  const AFFINITY_RECORDS = Object.freeze({
    ender: Object.freeze({
      status: 'established',
      innateAffinities: Object.freeze(['aether', 'resonance', 'correspondence', 'lumen'])
    }),
    lyra: Object.freeze({ status: 'open', innateAffinities: Object.freeze([]) }),
    ionia: Object.freeze({ status: 'open', innateAffinities: Object.freeze([]) }),
    reson: Object.freeze({ status: 'open', innateAffinities: Object.freeze([]) }),
    aepex: Object.freeze({ status: 'open', innateAffinities: Object.freeze([]) })
  });

  function validateCharacterId(characterId) {
    if (!CHARACTER_IDS.includes(characterId)) {
      throw new Error('CHARACTER_MAGIC_PROFILE_UNKNOWN_CHARACTER:' + characterId);
    }
    return characterId;
  }

  function validateAffinityId(id) {
    if (!defs.NON_ELEMENTAL_DOMAINS[id] && !defs.ELEMENTAL_TREES[id]) {
      throw new Error('CHARACTER_MAGIC_PROFILE_UNKNOWN_AFFINITY:' + id);
    }
    return id;
  }

  function freezeProfile(profile) {
    return Object.freeze({
      schemaVersion: 2,
      characterId: profile.characterId,
      affinityStatus: profile.affinityStatus,
      innateAffinities: Object.freeze(profile.innateAffinities.slice()),
      mastery: Object.freeze({
        trees: Object.freeze(Object.assign({}, profile.mastery.trees)),
        domains: Object.freeze(Object.assign({}, profile.mastery.domains))
      }),
      learnedSpells: Object.freeze(profile.learnedSpells.slice()),
      unlockedHybrids: Object.freeze(profile.unlockedHybrids.slice())
    });
  }

  function createProfile(characterId) {
    validateCharacterId(characterId);
    const affinity = AFFINITY_RECORDS[characterId];

    return freezeProfile({
      characterId,
      affinityStatus: affinity.status,
      innateAffinities: affinity.innateAffinities,
      mastery: { trees: {}, domains: {} },
      learnedSpells: [],
      unlockedHybrids: []
    });
  }

  function validateProfile(profile) {
    if (!profile || typeof profile !== 'object') {
      throw new Error('CHARACTER_MAGIC_PROFILE_REQUIRED');
    }

    validateCharacterId(profile.characterId);

    if (!Array.isArray(profile.innateAffinities)) {
      throw new Error('CHARACTER_MAGIC_PROFILE_AFFINITIES_MUST_BE_ARRAY');
    }
    const seen = new Set();
    for (const id of profile.innateAffinities) {
      validateAffinityId(id);
      if (seen.has(id)) throw new Error('CHARACTER_MAGIC_PROFILE_DUPLICATE_AFFINITY:' + id);
      seen.add(id);
    }

    const normalizedMastery = mastery.normalizeProfile(profile.mastery || {});

    const learnedSpells = profile.learnedSpells == null ? [] : profile.learnedSpells;
    if (!Array.isArray(learnedSpells)) {
      throw new Error('CHARACTER_MAGIC_PROFILE_LEARNED_SPELLS_MUST_BE_ARRAY');
    }
    const learnedSeen = new Set();
    for (const spellId of learnedSpells) {
      if (typeof spellId !== 'string' || !spellId) {
        throw new Error('CHARACTER_MAGIC_PROFILE_INVALID_LEARNED_SPELL');
      }
      if (learnedSeen.has(spellId)) {
        throw new Error('CHARACTER_MAGIC_PROFILE_DUPLICATE_LEARNED_SPELL:' + spellId);
      }
      learnedSeen.add(spellId);
    }

    const unlockedHybrids = Array.isArray(profile.unlockedHybrids) ? profile.unlockedHybrids : [];

    return freezeProfile({
      characterId: profile.characterId,
      affinityStatus: profile.affinityStatus || AFFINITY_RECORDS[profile.characterId].status,
      innateAffinities: profile.innateAffinities,
      mastery: normalizedMastery,
      learnedSpells,
      unlockedHybrids
    });
  }

  function hasAffinity(profile, id) {
    validateAffinityId(id);
    return validateProfile(profile).innateAffinities.includes(id);
  }

  function rankFor(profile, id) {
    const validated = validateProfile(profile);
    if (defs.ELEMENTAL_TREES[id]) {
      return validated.mastery.trees[id] || 0;
    }
    if (defs.NON_ELEMENTAL_DOMAINS[id]) {
      return validated.mastery.domains[id] || 0;
    }
    throw new Error('CHARACTER_MAGIC_PROFILE_UNKNOWN_MASTERY_ID:' + id);
  }

  function withMasteryRank(profile, id, rank) {
    const validated = validateProfile(profile);
    const next = {
      characterId: validated.characterId,
      affinityStatus: validated.affinityStatus,
      innateAffinities: validated.innateAffinities,
      mastery: {
        trees: Object.assign({}, validated.mastery.trees),
        domains: Object.assign({}, validated.mastery.domains)
      },
      learnedSpells: validated.learnedSpells,
      unlockedHybrids: validated.unlockedHybrids
    };

    if (defs.ELEMENTAL_TREES[id]) next.mastery.trees[id] = rank;
    else if (defs.NON_ELEMENTAL_DOMAINS[id]) next.mastery.domains[id] = rank;
    else throw new Error('CHARACTER_MAGIC_PROFILE_UNKNOWN_MASTERY_ID:' + id);

    mastery.normalizeProfile(next.mastery);
    return validateProfile(next);
  }

  function knowsSpell(profile, spellId) {
    if (typeof spellId !== 'string' || !spellId) {
      throw new Error('CHARACTER_MAGIC_PROFILE_INVALID_LEARNED_SPELL');
    }
    return validateProfile(profile).learnedSpells.includes(spellId);
  }

  function withLearnedSpell(profile, spellId) {
    if (typeof spellId !== 'string' || !spellId) {
      throw new Error('CHARACTER_MAGIC_PROFILE_INVALID_LEARNED_SPELL');
    }
    const validated = validateProfile(profile);
    if (validated.learnedSpells.includes(spellId)) return validated;

    return validateProfile({
      characterId: validated.characterId,
      affinityStatus: validated.affinityStatus,
      innateAffinities: validated.innateAffinities,
      mastery: validated.mastery,
      learnedSpells: validated.learnedSpells.concat(spellId),
      unlockedHybrids: validated.unlockedHybrids
    });
  }

  return Object.freeze({
    version: '0.2.0',
    runtimeStatus: 'PURE_PROFILE_SCHEMA_V2',
    CHARACTER_IDS,
    AFFINITY_RECORDS,
    createProfile,
    validateProfile,
    hasAffinity,
    rankFor,
    withMasteryRank,
    knowsSpell,
    withLearnedSpell
  });
});
