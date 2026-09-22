/* ============================================================
   Aetherwake JRPG — Magic Mastery Evaluator v0.1
   modules/magic-mastery.js

   Pure eligibility/synergy logic for the design registry.
   This module never grants spells, mutates character state, or
   authorizes runtime combat behavior.
   ============================================================ */

(function (root, factory) {
  const defs = typeof module === 'object' && module.exports
    ? require('./magic-defs.js')
    : root.AetherwakeMagicDefs;
  const api = factory(defs);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherwakeMagicMastery = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (defs) {
  'use strict';

  if (!defs) throw new Error('MAGIC_MASTERY_REQUIRES_MAGIC_DEFS');

  const MIN_RANK = 0;
  const MAX_RANK = 5;

  function assertRank(value, label) {
    if (!Number.isInteger(value) || value < MIN_RANK || value > MAX_RANK) {
      throw new Error('MAGIC_MASTERY_INVALID_RANK:' + label);
    }
    return value;
  }

  function normalizeProfile(profile) {
    const source = profile && typeof profile === 'object' ? profile : {};
    const trees = source.trees && typeof source.trees === 'object' ? source.trees : {};
    const domains = source.domains && typeof source.domains === 'object' ? source.domains : {};

    const normalizedTrees = {};
    const normalizedDomains = {};

    for (const [id, value] of Object.entries(trees)) {
      if (!defs.ELEMENTAL_TREES[id]) {
        throw new Error('MAGIC_MASTERY_UNKNOWN_TREE:' + id);
      }
      normalizedTrees[id] = assertRank(value, 'tree:' + id);
    }

    for (const [id, value] of Object.entries(domains)) {
      if (!defs.NON_ELEMENTAL_DOMAINS[id]) {
        throw new Error('MAGIC_MASTERY_UNKNOWN_DOMAIN:' + id);
      }
      normalizedDomains[id] = assertRank(value, 'domain:' + id);
    }

    return Object.freeze({
      trees: Object.freeze(normalizedTrees),
      domains: Object.freeze(normalizedDomains)
    });
  }

  function rankOf(profile, ref) {
    if (!ref || typeof ref !== 'object') throw new Error('MAGIC_MASTERY_INVALID_REFERENCE');
    const normalized = normalizeProfile(profile);

    if (ref.tree) {
      if (!defs.ELEMENTAL_TREES[ref.tree]) throw new Error('MAGIC_MASTERY_UNKNOWN_TREE:' + ref.tree);
      return normalized.trees[ref.tree] || 0;
    }

    if (ref.domain) {
      if (!defs.NON_ELEMENTAL_DOMAINS[ref.domain]) throw new Error('MAGIC_MASTERY_UNKNOWN_DOMAIN:' + ref.domain);
      return normalized.domains[ref.domain] || 0;
    }

    throw new Error('MAGIC_MASTERY_REFERENCE_REQUIRES_TREE_OR_DOMAIN');
  }

  function meets(profile, requirement) {
    return rankOf(profile, requirement) >= requirement.rank;
  }

  function evaluateTreeAccess(profile, treeId) {
    const tree = defs.ELEMENTAL_TREES[treeId];
    if (!tree) throw new Error('MAGIC_MASTERY_UNKNOWN_TREE:' + treeId);

    const normalized = normalizeProfile(profile);
    const missingAll = [];
    const missingAny = [];

    for (const requirement of tree.requires || []) {
      if (!meets(normalized, requirement)) missingAll.push(requirement);
    }

    if (tree.requiresAny && tree.requiresAny.length > 0) {
      const hasAny = tree.requiresAny.some(requirement => meets(normalized, requirement));
      if (!hasAny) missingAny.push(...tree.requiresAny);
    }

    return Object.freeze({
      treeId,
      eligible: missingAll.length === 0 && missingAny.length === 0,
      missingAll: Object.freeze(missingAll.slice()),
      missingAny: Object.freeze(missingAny.slice()),
      benefitsActive: Object.freeze((tree.benefitsFrom || []).filter(requirement => meets(normalized, requirement)))
    });
  }

  function thresholdForRanks(rankA, rankB) {
    assertRank(rankA, 'synergy:a');
    assertRank(rankB, 'synergy:b');
    const floor = Math.min(rankA, rankB);

    if (floor >= 5) return Object.freeze({ key:'5+5', level:'grand-synthesis-art' });
    if (floor >= 4) return Object.freeze({ key:'4+4', level:'advanced-synergy-passive' });
    if (floor >= 3) return Object.freeze({ key:'3+3', level:'cross-school-art' });
    if (floor >= 2) return Object.freeze({ key:'2+2', level:'minor-interaction' });
    return Object.freeze({ key:null, level:'none' });
  }

  function rankForId(profile, id) {
    const normalized = normalizeProfile(profile);
    if (defs.ELEMENTAL_TREES[id]) return normalized.trees[id] || 0;
    if (defs.NON_ELEMENTAL_DOMAINS[id]) return normalized.domains[id] || 0;
    throw new Error('MAGIC_MASTERY_UNKNOWN_ID:' + id);
  }

  function evaluateSynergy(profile, a, b) {
    const rankA = rankForId(profile, a);
    const rankB = rankForId(profile, b);
    const threshold = thresholdForRanks(rankA, rankB);
    const definition = defs.CROSS_MASTERY.find(entry =>
      (entry.a === a && entry.b === b) || (entry.a === b && entry.b === a)
    ) || null;

    return Object.freeze({
      a,
      b,
      rankA,
      rankB,
      registered: Boolean(definition),
      thresholdKey: threshold.key,
      level: threshold.level,
      active: Boolean(definition) && threshold.level !== 'none',
      behavior: definition && threshold.level !== 'none' ? definition.behavior : null,
      grand: definition && threshold.level === 'grand-synthesis-art' ? definition.grand : null
    });
  }

  function availableSynergies(profile) {
    const normalized = normalizeProfile(profile);
    return Object.freeze(defs.CROSS_MASTERY
      .map(entry => evaluateSynergy(normalized, entry.a, entry.b))
      .filter(result => result.active));
  }

  function reactionFor(state, applied) {
    if (!state || !applied) throw new Error('MAGIC_REACTION_REQUIRES_STATE_AND_APPLIED');
    return defs.REACTION_STATES.find(entry => entry.state === state && entry.applied === applied) || null;
  }

  function compressedTier(rank) {
    assertRank(rank, 'compressed-tier');
    if (rank === 0) return 0;
    return defs.MASTERY_RANKS[rank].compressedTier;
  }

  return Object.freeze({
    version: '0.1.0',
    runtimeStatus: 'PURE_DESIGN_ELIGIBILITY_ONLY',
    normalizeProfile,
    rankOf,
    evaluateTreeAccess,
    thresholdForRanks,
    evaluateSynergy,
    availableSynergies,
    reactionFor,
    compressedTier
  });
});
