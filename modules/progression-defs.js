/* ============================================================
   Aetherwake JRPG — Progression Definitions v0.1
   modules/progression-defs.js

   Behavior-preserving extraction of the current hardcoded level
   unlocks. This is not the future mastery/tree progression system.
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

  const VERSION = '0.1.0';

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
      if (!Number.isInteger(numericLevel) || numericLevel < 1) {
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

    return true;
  }

  return Object.freeze({
    VERSION,
    LEVEL_UNLOCKS,
    getUnlocksForLevel,
    validateAgainstAbilityDefs,
  });
});
