/* ============================================================
   Aetherwake JRPG — Preservation Field-Role Definitions
   modules/field-role-defs.js

   These are rank-1 preservation-era mechanics templates used by authored
   companion onboarding. They are NOT canonical native jobs, schools, or
   mastery definitions for Lyra/Ionia/Reson/Aepex.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherFieldRoleDefs = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';
  const PROVENANCE = 'preservation-era-prototype-mechanics';

  function deepFreeze(value) {
    if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
    Object.freeze(value);
    Object.keys(value).forEach(key => deepFreeze(value[key]));
    return value;
  }

  const ORDER = Object.freeze([
    'skySailor',
    'engineWright',
    'aetherWeaver',
  ]);

  const DEFS = deepFreeze({
    skySailor: {
      id: 'skySailor',
      name: 'Sky-Sailor',
      tagline: 'Wind navigator · mobile striker',
      vit: 10,
      echoes: 2,
      wits: 1,
      presence: 0,
      spirit: 1,
      might: -1,
      grace: 2,
      color: 'scioto',
      abilities: [
        {
          id: 'windShearDance',
          label: 'Wind-Shear Dance',
          stat: 'grace',
          desc: '2D6+Grace. Evade / reposition. 10+: next Grace roll +1.',
        },
        {
          id: 'aetherCompass',
          label: 'Aether Compass',
          stat: 'wits',
          desc: '2D6+Wits. Reveal resources — gain scrap or aether.',
        },
      ],
      synergyBonus: 'Wind-Reader — Ender\'s Uncover Truth grants +1 to Sky-Sailor\'s Grace rolls.',
      previewGlyph: 'W',
    },
    engineWright: {
      id: 'engineWright',
      name: 'Engine-Wright',
      tagline: 'Mechanical engineer · heavy hitter',
      vit: 12,
      echoes: 2,
      wits: 0,
      presence: 2,
      spirit: 0,
      might: 2,
      grace: -1,
      color: 'rust',
      abilities: [
        {
          id: 'overdriveStrike',
          label: 'Overdrive Strike',
          stat: 'might',
          desc: '2D6+Might. Heavy EMP: 1d6+3 damage. Generates 1 Heat.',
        },
        {
          id: 'patchworkShield',
          label: 'Patchwork Shield',
          stat: 'presence',
          desc: '2D6+Presence. Absorb 1 damage for an ally. Return 1 scrap.',
        },
      ],
      synergyBonus: 'Engine Heart — Ender\'s Mycelial Ledger grants +1 scrap on success while Wright is present.',
      previewGlyph: 'E',
    },
    aetherWeaver: {
      id: 'aetherWeaver',
      name: 'Aether-Weaver',
      tagline: 'Spirit caster · healer & buffer',
      vit: 9,
      echoes: 3,
      wits: 1,
      presence: 1,
      spirit: 2,
      might: -2,
      grace: 0,
      color: 'biolum',
      abilities: [
        {
          id: 'spiritThread',
          label: 'Spirit Thread',
          stat: 'spirit',
          desc: '2D6+Spirit. Heal 1-3 Vit to a target ally.',
        },
        {
          id: 'aetherWeave',
          label: 'Aether Weave',
          stat: 'presence',
          desc: '2D6+Presence. Buff ally\'s next roll +1. Costs 1 Aether.',
        },
      ],
      synergyBonus: 'Dreamweaver\'s Pact — Ender\'s Shared Dream heals +1 extra Vit when Weaver is in party.',
      previewGlyph: 'A',
    },
  });

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function list() {
    return ORDER.map(id => clone(DEFS[id]));
  }

  function getById(id) {
    return DEFS[id] ? clone(DEFS[id]) : null;
  }

  function validateCandidate(order, defs) {
    if (!Array.isArray(order) || order.length === 0) {
      throw new Error('FIELD_ROLE_ORDER_REQUIRED');
    }
    if (!defs || typeof defs !== 'object' || Array.isArray(defs)) {
      throw new Error('FIELD_ROLE_DEFS_OBJECT_REQUIRED');
    }
    if (new Set(order).size !== order.length) {
      throw new Error('FIELD_ROLE_ORDER_DUPLICATE');
    }

    const defIds = Object.keys(defs);
    if (defIds.length !== order.length) {
      throw new Error('FIELD_ROLE_COUNT_MISMATCH');
    }

    order.forEach(id => {
      const def = defs[id];
      if (!def) throw new Error('FIELD_ROLE_DEF_MISSING:' + id);
      if (def.id !== id) throw new Error('FIELD_ROLE_ID_MISMATCH:' + id);
      if (typeof def.name !== 'string' || !def.name) {
        throw new Error('FIELD_ROLE_NAME_INVALID:' + id);
      }
      if (typeof def.tagline !== 'string' || !def.tagline) {
        throw new Error('FIELD_ROLE_TAGLINE_INVALID:' + id);
      }
      if (!Array.isArray(def.abilities) || def.abilities.length !== 2) {
        throw new Error('FIELD_ROLE_ABILITIES_INVALID:' + id);
      }
      const abilityIds = new Set();
      def.abilities.forEach(ability => {
        if (!ability || typeof ability.id !== 'string' || !ability.id) {
          throw new Error('FIELD_ROLE_ABILITY_ID_INVALID:' + id);
        }
        if (abilityIds.has(ability.id)) {
          throw new Error('FIELD_ROLE_ABILITY_DUPLICATE:' + id + ':' + ability.id);
        }
        abilityIds.add(ability.id);
        if (typeof ability.label !== 'string' || !ability.label ||
            typeof ability.stat !== 'string' || !ability.stat ||
            typeof ability.desc !== 'string' || !ability.desc) {
          throw new Error('FIELD_ROLE_ABILITY_METADATA_INVALID:' + id + ':' + ability.id);
        }
      });
      ['vit', 'echoes', 'wits', 'presence', 'spirit', 'might', 'grace'].forEach(field => {
        if (!Number.isFinite(def[field])) {
          throw new Error('FIELD_ROLE_STAT_INVALID:' + id + ':' + field);
        }
      });
      if (typeof def.synergyBonus !== 'string' || !def.synergyBonus) {
        throw new Error('FIELD_ROLE_SYNERGY_INVALID:' + id);
      }
      if (typeof def.previewGlyph !== 'string' || def.previewGlyph.length !== 1) {
        throw new Error('FIELD_ROLE_GLYPH_INVALID:' + id);
      }
    });

    defIds.forEach(id => {
      if (!order.includes(id)) throw new Error('FIELD_ROLE_ORPHAN_DEF:' + id);
    });

    return true;
  }

  function validate() {
    return validateCandidate(ORDER, DEFS);
  }

  validate();

  return Object.freeze({
    VERSION,
    PROVENANCE,
    ORDER,
    DEFS,
    list,
    getById,
    validateCandidate,
    validate,
  });
});
