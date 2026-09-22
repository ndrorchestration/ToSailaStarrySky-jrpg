/* ============================================================
   Aetherwake JRPG — Magic Spell Access v0.1
   modules/magic-spell-access.js

   Pure, fail-closed access evaluation across elemental and
   non-elemental design catalogs. It never grants mastery, learns
   a spell, mutates roster state, or executes combat behavior.
   ============================================================ */

(function (root, factory) {
  const defs = typeof module === 'object' && module.exports
    ? require('./magic-defs.js')
    : root.AetherwakeMagicDefs;
  const mastery = typeof module === 'object' && module.exports
    ? require('./magic-mastery.js')
    : root.AetherwakeMagicMastery;
  const elemental = typeof module === 'object' && module.exports
    ? require('./elemental-spell-trees.js')
    : root.AetherwakeElementalSpellTrees;
  const nonElemental = typeof module === 'object' && module.exports
    ? require('./non-elemental-spell-trees.js')
    : root.AetherwakeNonElementalSpellTrees;

  const api = factory(defs, mastery, elemental, nonElemental);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherwakeMagicSpellAccess = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (defs, mastery, elemental, nonElemental) {
  'use strict';

  if (!defs || !mastery || !elemental || !nonElemental) {
    throw new Error('MAGIC_SPELL_ACCESS_REQUIRES_MAGIC_CATALOGS');
  }

  const ESTABLISHED_STATUSES = Object.freeze(['established', 'established-family']);

  function buildIndex() {
    const index = {};

    for (const spell of elemental.allSpells()) {
      if (index[spell.id]) throw new Error('MAGIC_SPELL_DUPLICATE_ID:' + spell.id);
      index[spell.id] = Object.freeze(Object.assign({
        catalog:'elemental',
        sourceId:spell.treeId,
        sourceKind:'tree',
        sourceStatus:'admitted'
      }, spell));
    }

    for (const spell of nonElemental.allSpells()) {
      if (index[spell.id]) throw new Error('MAGIC_SPELL_DUPLICATE_ID:' + spell.id);
      const tree = nonElemental.getTree(spell.domainId);
      index[spell.id] = Object.freeze(Object.assign({
        catalog:'non-elemental',
        sourceId:spell.domainId,
        sourceKind:'domain',
        sourceStatus:tree.status
      }, spell));
    }

    return Object.freeze(index);
  }

  const SPELL_INDEX = buildIndex();

  function getSpell(spellId) {
    return SPELL_INDEX[spellId] || null;
  }

  function isDomainAdmitted(domainId, admittedDomainIds) {
    const def = defs.NON_ELEMENTAL_DOMAINS[domainId];
    if (!def) throw new Error('MAGIC_SPELL_ACCESS_UNKNOWN_DOMAIN:' + domainId);

    if (ESTABLISHED_STATUSES.includes(def.status)) return true;

    const admitted = Array.isArray(admittedDomainIds) ? admittedDomainIds : [];
    return admitted.includes(domainId);
  }

  function ownRank(profile, spell) {
    if (spell.sourceKind === 'tree') {
      return mastery.rankOf(profile, {tree:spell.sourceId});
    }
    return mastery.rankOf(profile, {domain:spell.sourceId});
  }

  function unmetRequirements(profile, requirements) {
    const missing = [];
    for (const requirement of requirements || []) {
      if (mastery.rankOf(profile, requirement) < requirement.rank) {
        missing.push(requirement);
      }
    }
    return Object.freeze(missing);
  }

  function evaluate(profile, spellId, options) {
    const spell = getSpell(spellId);
    if (!spell) throw new Error('MAGIC_SPELL_ACCESS_UNKNOWN_SPELL:' + spellId);

    const normalized = mastery.normalizeProfile(profile);
    const opts = options && typeof options === 'object' ? options : {};
    const reasons = [];

    if (spell.sourceKind === 'domain' &&
        !isDomainAdmitted(spell.sourceId, opts.admittedDomainIds)) {
      reasons.push('domain_not_admitted');
    }

    const rank = ownRank(normalized, spell);
    if (rank < spell.rank) reasons.push('insufficient_source_mastery');

    const missing = unmetRequirements(normalized, spell.requiresMastery);
    if (missing.length > 0) reasons.push('missing_cross_mastery');

    return Object.freeze({
      spellId,
      sourceKind:spell.sourceKind,
      sourceId:spell.sourceId,
      sourceStatus:spell.sourceStatus,
      requiredRank:spell.rank,
      currentRank:rank,
      eligible:reasons.length === 0,
      reasons:Object.freeze(reasons),
      missingRequirements:missing,
      runtimeStatus:'ACCESS_EVALUATION_ONLY'
    });
  }

  function listAccessible(profile, options) {
    const out = [];
    for (const spellId of Object.keys(SPELL_INDEX)) {
      const result = evaluate(profile, spellId, options);
      if (result.eligible) out.push(SPELL_INDEX[spellId]);
    }
    return Object.freeze(out);
  }

  function listBySource(sourceId) {
    return Object.freeze(Object.values(SPELL_INDEX)
      .filter(spell => spell.sourceId === sourceId));
  }

  return Object.freeze({
    version:'0.1.0',
    runtimeStatus:'ACCESS_EVALUATION_ONLY',
    ESTABLISHED_STATUSES,
    SPELL_INDEX,
    getSpell,
    evaluate,
    listAccessible,
    listBySource,
    isDomainAdmitted
  });
});
