/* ============================================================
   Aetherwake JRPG — Magic Study Transactions v0.1
   modules/magic-study.js

   Explicit, pure progression transactions.
   No XP curve, teacher, currency, time cost, or runtime combat
   behavior is invented here.
   ============================================================ */

(function (root, factory) {
  const defs = typeof module === 'object' && module.exports
    ? require('./magic-defs.js')
    : root.AetherwakeMagicDefs;
  const mastery = typeof module === 'object' && module.exports
    ? require('./magic-mastery.js')
    : root.AetherwakeMagicMastery;
  const profileApi = typeof module === 'object' && module.exports
    ? require('./character-magic-profile.js')
    : root.AetherwakeCharacterMagicProfile;
  const spellAccess = typeof module === 'object' && module.exports
    ? require('./magic-spell-access.js')
    : root.AetherwakeMagicSpellAccess;

  const api = factory(defs, mastery, profileApi, spellAccess);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherwakeMagicStudy = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (defs, mastery, profileApi, spellAccess) {
  'use strict';

  if (!defs || !mastery || !profileApi || !spellAccess) {
    throw new Error('MAGIC_STUDY_REQUIRES_MAGIC_MODULES');
  }

  const ESTABLISHED_STATUSES = Object.freeze(['established', 'established-family']);

  function optionsObject(options) {
    return options && typeof options === 'object' ? options : {};
  }

  function isDomainAdmitted(domainId, options) {
    const def = defs.NON_ELEMENTAL_DOMAINS[domainId];
    if (!def) throw new Error('MAGIC_STUDY_UNKNOWN_DOMAIN:' + domainId);
    if (ESTABLISHED_STATUSES.includes(def.status)) return true;
    const admitted = optionsObject(options).admittedDomainIds;
    return Array.isArray(admitted) && admitted.includes(domainId);
  }

  function evaluateMasteryAdvance(profile, id, targetRank, options) {
    const validated = profileApi.validateProfile(profile);

    if (!Number.isInteger(targetRank) || targetRank < 1 || targetRank > 5) {
      throw new Error('MAGIC_STUDY_INVALID_TARGET_RANK:' + targetRank);
    }

    const currentRank = profileApi.rankFor(validated, id);
    const reasons = [];
    let sourceKind = null;
    let accessCheck = null;

    if (targetRank !== currentRank + 1) {
      reasons.push('rank_must_advance_exactly_one');
    }

    if (defs.ELEMENTAL_TREES[id]) {
      sourceKind = 'tree';
      accessCheck = mastery.evaluateTreeAccess(validated.mastery, id);
      if (!accessCheck.eligible) reasons.push('tree_prerequisites_not_met');
    } else if (defs.NON_ELEMENTAL_DOMAINS[id]) {
      sourceKind = 'domain';
      if (!isDomainAdmitted(id, options)) reasons.push('domain_not_admitted');
    } else {
      throw new Error('MAGIC_STUDY_UNKNOWN_SOURCE:' + id);
    }

    return Object.freeze({
      id,
      sourceKind,
      currentRank,
      targetRank,
      eligible:reasons.length === 0,
      reasons:Object.freeze(reasons),
      accessCheck,
      runtimeStatus:'EXPLICIT_STUDY_TRANSACTION_ONLY'
    });
  }

  function advanceMastery(profile, id, targetRank, options) {
    const check = evaluateMasteryAdvance(profile, id, targetRank, options);
    if (!check.eligible) {
      throw new Error('MAGIC_STUDY_MASTERY_NOT_ELIGIBLE:' + check.reasons.join(','));
    }
    return profileApi.withMasteryRank(profile, id, targetRank);
  }

  function evaluateSpellStudy(profile, spellId, options) {
    const validated = profileApi.validateProfile(profile);
    const reasons = [];

    if (profileApi.knowsSpell(validated, spellId)) {
      reasons.push('already_learned');
    }

    const access = spellAccess.evaluate(validated.mastery, spellId, options);
    if (!access.eligible) reasons.push(...access.reasons);

    return Object.freeze({
      spellId,
      eligible:reasons.length === 0,
      reasons:Object.freeze(Array.from(new Set(reasons))),
      access,
      runtimeStatus:'EXPLICIT_STUDY_TRANSACTION_ONLY'
    });
  }

  function learnSpell(profile, spellId, options) {
    const check = evaluateSpellStudy(profile, spellId, options);
    if (!check.eligible) {
      throw new Error('MAGIC_STUDY_SPELL_NOT_ELIGIBLE:' + check.reasons.join(','));
    }
    return profileApi.withLearnedSpell(profile, spellId);
  }

  function listStudyableSpells(profile, options) {
    const validated = profileApi.validateProfile(profile);
    return Object.freeze(spellAccess.listAccessible(validated.mastery, options)
      .filter(spell => !validated.learnedSpells.includes(spell.id)));
  }

  return Object.freeze({
    version:'0.1.0',
    runtimeStatus:'EXPLICIT_STUDY_TRANSACTION_ONLY',
    evaluateMasteryAdvance,
    advanceMastery,
    evaluateSpellStudy,
    learnSpell,
    listStudyableSpells,
    isDomainAdmitted
  });
});
