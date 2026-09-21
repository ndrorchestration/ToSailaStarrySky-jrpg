/* ============================================================
   Aetherwake JRPG — Encounter Scaling v0.1
   modules/encounter-scaling.js

   Bounded adaptive encounter tuning. Story/region authorship remains the
   primary difficulty anchor; party level and size adjust within limits.
   ============================================================ */

(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherEncounterScaling = api;
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';

  const LIMITS = Object.freeze({
    MIN_PARTY_SIZE: 1,
    MAX_PARTY_SIZE: 5,
    MIN_LEVEL_DELTA: -8,
    MAX_LEVEL_DELTA: 18,
    HP_PER_LEVEL: 0.035,
    HP_PER_EXTRA_PARTY_MEMBER: 0.18,
    HP_PER_MISSING_PARTY_MEMBER: -0.12,
    MIN_HP_FACTOR: 0.55,
    MAX_HP_FACTOR: 2.75,
  });

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function normalizePartyLevels(levels, fallbackLevel) {
    const filtered = Array.isArray(levels)
      ? levels.filter(level => Number.isFinite(level) && level >= 1)
      : [];
    if (filtered.length) return filtered.map(level => Math.floor(level));
    return [Math.max(1, Math.floor(Number(fallbackLevel) || 1))];
  }

  function getContext(options) {
    options = options || {};
    const levels = normalizePartyLevels(options.partyLevels, options.playerLevel);
    const averageLevel = levels.reduce((sum, level) => sum + level, 0) / levels.length;
    const highestLevel = Math.max.apply(null, levels);
    const partySize = clamp(
      Number.isFinite(options.partySize) ? Math.floor(options.partySize) : levels.length,
      LIMITS.MIN_PARTY_SIZE,
      LIMITS.MAX_PARTY_SIZE
    );
    return {
      partyLevels: levels.slice(),
      averageLevel,
      highestLevel,
      partySize,
    };
  }

  function scaleEnemy(template, options) {
    if (!template || typeof template !== 'object') {
      throw new Error('ENCOUNTER_SCALING_REQUIRES_TEMPLATE');
    }

    const context = getContext(options);
    const recommendedLevel = Number.isFinite(template.recommendedLevel)
      ? Math.max(1, Math.floor(template.recommendedLevel))
      : Math.round(context.averageLevel);
    const recommendedPartySize = Number.isFinite(template.recommendedPartySize)
      ? clamp(Math.floor(template.recommendedPartySize), 1, 5)
      : context.partySize;

    const rawLevelDelta = context.averageLevel - recommendedLevel;
    const boundedLevelDelta = clamp(
      rawLevelDelta,
      LIMITS.MIN_LEVEL_DELTA,
      LIMITS.MAX_LEVEL_DELTA
    );
    const partyDelta = context.partySize - recommendedPartySize;

    let hpFactor = 1 + (boundedLevelDelta * LIMITS.HP_PER_LEVEL);
    hpFactor += partyDelta >= 0
      ? partyDelta * LIMITS.HP_PER_EXTRA_PARTY_MEMBER
      : partyDelta * Math.abs(LIMITS.HP_PER_MISSING_PARTY_MEMBER);
    hpFactor = clamp(hpFactor, LIMITS.MIN_HP_FACTOR, LIMITS.MAX_HP_FACTOR);

    const baseHp = Math.max(1, Number(template.maxHp ?? template.hp ?? 1));
    const scaledMaxHp = Math.max(1, Math.round(baseHp * hpFactor));

    // Threat tier is metadata for authored mechanics/reinforcements. It does not
    // silently rewrite boss scripts or fixed special abilities.
    const threatTier = clamp(
      Math.floor(Math.max(0, boundedLevelDelta) / 6) + Math.max(0, partyDelta),
      0,
      5
    );

    return Object.assign({}, template, {
      hp: scaledMaxHp,
      maxHp: scaledMaxHp,
      scaling: {
        recommendedLevel,
        recommendedPartySize,
        averagePartyLevel: Number(context.averageLevel.toFixed(2)),
        highestPartyLevel: context.highestLevel,
        partySize: context.partySize,
        rawLevelDelta: Number(rawLevelDelta.toFixed(2)),
        boundedLevelDelta: Number(boundedLevelDelta.toFixed(2)),
        partyDelta,
        hpFactor: Number(hpFactor.toFixed(3)),
        threatTier,
      },
    });
  }

  return Object.freeze({
    VERSION,
    LIMITS,
    getContext,
    scaleEnemy,
  });
});
