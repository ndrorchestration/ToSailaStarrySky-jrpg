/* ============================================================
   Aetherwake JRPG — Progression Definitions v0.2
   modules/progression-defs.js

   Central progression contract. Preserves the current prototype
   level unlocks while establishing bounded long-form progression
   for the authored campaign, mastery, and postgame.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherProgressionDefs = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.2.0';

  // Campaign/progression landmarks. The hard cap is deliberately above the
  // expected main-story range so optional mastery content has real runway.
  const LEVEL_LIMITS = deepFreeze({
    MAIN_STORY_TARGET: 130,
    MASTERY_THRESHOLD: 131,
    MASTER_ART_THRESHOLD: 150,
    POSTGAME_WORLD_MAGIC_THRESHOLD: 150,
    HARD_CAP: 175,
  });

  const PROGRESSION_BANDS = deepFreeze([
    { id: 'foundation', min: 1, max: 30 },
    { id: 'developing', min: 31, max: 70 },
    { id: 'advanced', min: 71, max: 100 },
    { id: 'endgame', min: 101, max: 130 },
    { id: 'mastery', min: 131, max: 149 },
    { id: 'master', min: 150, max: 174 },
    { id: 'capstone', min: 175, max: 175 },
  ]);

  // These are progression eligibility landmarks, not automatic ability grants.
  // Specific Master Arts / world-altering magic remain authored content.
  const MILESTONES = deepFreeze({
    130: {
      id: 'main_story_ceiling',
      kind: 'campaign',
      label: 'Main-story endgame range reached',
    },
    150: {
      id: 'master_art_eligibility',
      kind: 'mastery',
      label: 'Master Art and postgame world-magic eligibility',
    },
    160: {
      id: 'hidden_mastery',
      kind: 'postgame',
      label: 'Hidden mastery / easter-egg progression tier',
    },
    175: {
      id: 'level_cap',
      kind: 'capstone',
      label: 'Maximum character level',
    },
  });

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  const LEVEL_UNLOCKS = deepFreeze({
    3: [
      {
        abilityId: 'windWard',
        log: '── LEVEL 3: Wind Ward unlocked! ──',
      },
    ],
    4: [
      {
        abilityId: 'aetherSeal',
        log: '── LEVEL 4: Aether Seal unlocked! ──',
      },
    ],
    5: [
      {
        abilityId: 'rest',
        log: '── LEVEL 5: Rest unlocked! ──',
      },
    ],
  });

  function normalizeLevel(level) {
    const numeric = Number(level);
    if (!Number.isFinite(numeric)) return 1;
    return Math.max(1, Math.min(LEVEL_LIMITS.HARD_CAP, Math.floor(numeric)));
  }

  // Early thresholds preserve the existing prototype curve:
  // L1→2 50, L2→3 75, L3→4 112, L4→5 168, L5→6 253.
  // From level 6 onward the curve becomes bounded polynomial growth instead of
  // the former x1.5 exponential, which was incompatible with a 150+ level game.
  function getXPToNext(level) {
    const current = normalizeLevel(level);
    if (current >= LEVEL_LIMITS.HARD_CAP) return 0;
    if (current <= 5) {
      return Math.floor(50 * Math.pow(1.5, current - 1));
    }

    const d = current - 5;
    return Math.floor(253 + (42 * d) + (3.5 * Math.pow(d, 1.35)));
  }

  function getProgressionBand(level) {
    const current = normalizeLevel(level);
    const band = PROGRESSION_BANDS.find(entry =>
      current >= entry.min && current <= entry.max
    );
    return band ? Object.assign({}, band) : null;
  }

  function getMilestone(level) {
    const entry = MILESTONES[normalizeLevel(level)];
    return entry ? Object.assign({}, entry) : null;
  }

  function getUnlocksForLevel(level) {
    const entries = LEVEL_UNLOCKS[level] || [];
    return entries.map(entry => Object.assign({}, entry));
  }

  function validateAgainstAbilityDefs(abilityDefs) {
    if (!abilityDefs || !abilityDefs.DEFS) {
      throw new Error('PROGRESSION_REQUIRES_ABILITY_DEFS');
    }

    Object.keys(LEVEL_UNLOCKS).forEach(level => {
      const numericLevel = Number(level);
      if (!Number.isInteger(numericLevel) || numericLevel < 1 ||
          numericLevel > LEVEL_LIMITS.HARD_CAP) {
        throw new Error('PROGRESSION_LEVEL_INVALID:' + level);
      }

      const seen = new Set();
      LEVEL_UNLOCKS[level].forEach(entry => {
        if (!entry || typeof entry.abilityId !== 'string') {
          throw new Error('PROGRESSION_UNLOCK_INVALID:' + level);
        }
        if (!abilityDefs.DEFS[entry.abilityId]) {
          throw new Error('PROGRESSION_UNLOCK_UNKNOWN_ABILITY:' + entry.abilityId);
        }
        if (seen.has(entry.abilityId)) {
          throw new Error('PROGRESSION_UNLOCK_DUPLICATE:' + level + ':' + entry.abilityId);
        }
        seen.add(entry.abilityId);
        if (typeof entry.log !== 'string' || !entry.log) {
          throw new Error('PROGRESSION_UNLOCK_LOG_INVALID:' + entry.abilityId);
        }
      });
    });

    if (getXPToNext(1) !== 50 || getXPToNext(2) !== 75) {
      throw new Error('PROGRESSION_EARLY_XP_COMPATIBILITY_DRIFT');
    }
    if (getXPToNext(LEVEL_LIMITS.HARD_CAP) !== 0) {
      throw new Error('PROGRESSION_CAP_XP_INVALID');
    }

    return true;
  }

  return Object.freeze({
    VERSION,
    LEVEL_LIMITS,
    PROGRESSION_BANDS,
    MILESTONES,
    LEVEL_UNLOCKS,
    normalizeLevel,
    getXPToNext,
    getProgressionBand,
    getMilestone,
    getUnlocksForLevel,
    validateAgainstAbilityDefs,
  });
});
