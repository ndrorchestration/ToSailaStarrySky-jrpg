/* ============================================================
   Aetherwake JRPG — Persistent Party State
   modules/party-state.js

   First production-architecture bridge:
   - ROSTER contains exactly five stable authored identities.
   - ACTIVE_PARTY contains 1–5 canonical references into ROSTER.
   - The current preservation character-creation flow is adapted into
     the first three roster records without changing its player-facing flow.
   - Reson and Aepex remain authored identity shells until the later
     authored-roster/onboarding migration supplies their mechanics.
   ============================================================ */

(function (global) {
  'use strict';

  const BALANCE_PROFILE_VERSION = 1;
  const BALANCE_STATUS = 'PROVISIONAL_NOT_CANON';
  const CHARACTER_CANON = global.AetherCharacterCanon || null;
  const JRPG_STAT_MODEL = global.AetherJRPGStatModel || null;

  // Identity facts come from creator canon. Numeric values below are a first
  // balance pass fitted to the existing rank-1 stat scale; they are tuning
  // data, not declarations about unresolved jobs or magic-school ownership.
  const DEFINITIONS = Object.freeze([
    Object.freeze({
      id: 'ender', canonicalName: 'Ender', age: 22, nativeJob: 'Rift Scholar',
      combatRole: 'analyst-controller',
      base: Object.freeze({ vit:13, echoes:3, aether:4, aetherMax:6, heat:1, heatMax:3,
        wits:2, presence:1, spirit:1, might:-1, grace:0 })
    }),
    Object.freeze({
      id: 'lyra', canonicalName: 'Lyra', age: 24, nativeJob: null,
      combatRole: 'perceptive-support',
      base: Object.freeze({ vit:10, echoes:3, aether:3, aetherMax:6, heat:0, heatMax:3,
        wits:1, presence:0, spirit:2, might:-1, grace:1 })
    }),
    Object.freeze({
      id: 'ionia', canonicalName: 'Ionia', age: 28, nativeJob: null,
      combatRole: 'captain-support',
      base: Object.freeze({ vit:12, echoes:2, aether:3, aetherMax:6, heat:0, heatMax:3,
        wits:1, presence:2, spirit:0, might:0, grace:0 })
    }),
    Object.freeze({
      id: 'reson', canonicalName: 'Reson', age: 25, nativeJob: null,
      combatRole: 'durable-weapon-specialist',
      base: Object.freeze({ vit:15, echoes:2, aether:2, aetherMax:6, heat:0, heatMax:3,
        wits:0, presence:0, spirit:1, might:2, grace:0 })
    }),
    Object.freeze({
      id: 'aepex', canonicalName: 'Aepex', age: 27, nativeJob: null,
      combatRole: 'technical-specialist',
      base: Object.freeze({ vit:11, echoes:2, aether:4, aetherMax:6, heat:0, heatMax:3,
        wits:2, presence:1, spirit:0, might:0, grace:0 })
    }),
  ]);

  const ROSTER = [];
  const ACTIVE_PARTY = [];
  const MIN_ACTIVE_PARTY = 1;
  const MAX_ACTIVE_PARTY = 5;
  let boundWorldPlayer = null;

  function createMagicProfile(characterId) {
    if (!global.AetherwakeCharacterMagicProfile ||
        typeof global.AetherwakeCharacterMagicProfile.createProfile !== 'function') {
      throw new Error('PARTY_STATE_MAGIC_PROFILE_MODULE_UNAVAILABLE');
    }
    return global.AetherwakeCharacterMagicProfile.createProfile(characterId);
  }

  function validateMagicProfile(character) {
    if (!global.AetherwakeCharacterMagicProfile ||
        typeof global.AetherwakeCharacterMagicProfile.validateProfile !== 'function') {
      throw new Error('PARTY_STATE_MAGIC_PROFILE_MODULE_UNAVAILABLE');
    }
    const profile = global.AetherwakeCharacterMagicProfile.validateProfile(character.magicProfile);
    if (profile.characterId !== character.id) {
      throw new Error('PARTY_STATE_MAGIC_PROFILE_CHARACTER_MISMATCH');
    }
    return true;
  }

  function ensureMagicProfile(target, characterId) {
    if (!target.magicProfile) target.magicProfile = createMagicProfile(characterId);
    validateMagicProfile(target);
    return target.magicProfile;
  }

  function applyAuthoredProfile(target, definition, options) {
    const opts = options || {};
    const base = definition.base;
    target.schemaVersion = 1;
    target.id = definition.id;
    target.canonicalName = definition.canonicalName;
    target.name = definition.canonicalName;
    target.age = definition.age;
    target.nativeJob = definition.nativeJob;
    target.class = definition.nativeJob;
    target.jobId = definition.nativeJob ? definition.id : null;
    target.combatRole = definition.combatRole;
    target.artProfileId = definition.id;
    target.balanceProfileVersion = BALANCE_PROFILE_VERSION;
    target.balanceStatus = BALANCE_STATUS;
    ensureMagicProfile(target, definition.id);
    // Production JRPG stats are namespaced separately during migration so
    // compatibility-only 2D6 actions cannot accidentally consume 1–75 values.
    if (JRPG_STAT_MODEL && typeof JRPG_STAT_MODEL.getPrimaryStats === 'function') {
      target.productionStats = JRPG_STAT_MODEL.getPrimaryStats(
        definition.id,
        target.level || 1
      );
      target.productionDerivedStats = JRPG_STAT_MODEL.derive(
        target.productionStats,
        target.level || 1,
        target.productionEquipment || {}
      );
      target.productionStatModelVersion = JRPG_STAT_MODEL.VERSION;
    }
    target.vit = base.vit;
    target.maxVit = base.vit;
    target.echoes = base.echoes;
    target.echoesMax = 3;
    target.aether = base.aether;
    target.aetherMax = base.aetherMax;
    target.heat = base.heat;
    target.heatMax = base.heatMax;
    target.wits = base.wits;
    target.presence = base.presence;
    target.spirit = base.spirit;
    target.might = base.might;
    target.grace = base.grace;
    if (opts.initializeProgression !== false) {
      target.level = 1;
      target.xp = 0;
      target.xpToNext = 50;
    }
    if (JRPG_STAT_MODEL && typeof JRPG_STAT_MODEL.getPrimaryStats === 'function') {
      target.productionStats = JRPG_STAT_MODEL.getPrimaryStats(
        definition.id,
        target.level || 1
      );
      target.productionStatModelVersion = JRPG_STAT_MODEL.VERSION;
    }
    return target;
  }

  function createShell(definition) {
    const shell = {
      runtimeImplemented: false,
      playable: false,
      implementationSource: 'authored-balance-shell',
      synergyBonus: null,
      scrap: 5,
      staffCharges: 0,
      maxStaffCharges: 0,
      unlockedAbilities: [],
      equipment: { staff: null, backpack: null },
    };
    return applyAuthoredProfile(shell, definition);
  }

  function currentOf(value) {
    if (value && typeof value === 'object' && value.current != null) return value.current;
    return value;
  }

  function maxOf(value, fallback) {
    if (value && typeof value === 'object' && value.max != null) return value.max;
    return fallback;
  }

  function assignIfDefined(target, key, value) {
    if (value !== undefined) target[key] = value;
  }

  function refreshProductionStats(character) {
    if (!character || typeof character !== 'object') {
      throw new Error('PRODUCTION_STATS_CHARACTER_REQUIRED');
    }
    if (!JRPG_STAT_MODEL ||
        typeof JRPG_STAT_MODEL.getPrimaryStats !== 'function' ||
        typeof JRPG_STAT_MODEL.derive !== 'function') {
      throw new Error('JRPG_STAT_MODEL_UNAVAILABLE');
    }
    const level = character.level || 1;
    character.productionStats = JRPG_STAT_MODEL.getPrimaryStats(character.id, level);
    character.productionDerivedStats = JRPG_STAT_MODEL.derive(
      character.productionStats,
      level,
      character.productionEquipment || {}
    );
    character.productionStatModelVersion = JRPG_STAT_MODEL.VERSION;
    return {
      primary: character.productionStats,
      derived: character.productionDerivedStats,
    };
  }

  function refreshAllProductionStats() {
    if (!JRPG_STAT_MODEL) throw new Error('JRPG_STAT_MODEL_UNAVAILABLE');
    return ROSTER.map(refreshProductionStats);
  }

  function adaptPrototypeCharacter(target, source, definition) {
    if (!target || !source) {
      throw new Error('PARTY_STATE_ADAPT_REQUIRES_TARGET_AND_SOURCE');
    }

    target.schemaVersion = 1;
    target.id = definition.id;
    target.canonicalName = definition.canonicalName;
    target.nativeJob = definition.nativeJob;
    target.runtimeImplemented = true;
    target.playable = true;
    target.implementationSource = 'prototype-adapter';

    assignIfDefined(target, 'name', source.name || definition.canonicalName);
    assignIfDefined(target, 'age', source.age);
    assignIfDefined(target, 'class', source.class);
    assignIfDefined(target, 'jobId', source.jobId);
    assignIfDefined(target, 'synergyBonus', source.synergyBonus);
    assignIfDefined(target, 'vit', source.vit);
    assignIfDefined(target, 'maxVit', source.maxVit);
    assignIfDefined(target, 'wits', source.wits);
    assignIfDefined(target, 'presence', source.presence);
    assignIfDefined(target, 'spirit', source.spirit);
    assignIfDefined(target, 'might', source.might);
    assignIfDefined(target, 'grace', source.grace);
    assignIfDefined(target, 'scrap', source.scrap);
    assignIfDefined(target, 'staffCharges', source.staffCharges);
    assignIfDefined(target, 'maxStaffCharges', source.maxStaffCharges);
    assignIfDefined(target, 'level', source.level);
    assignIfDefined(target, 'xp', source.xp);
    assignIfDefined(target, 'xpToNext', source.xpToNext);

    const echoes = currentOf(source.echoes);
    const echoesMax = maxOf(source.echoes, source.echoesMax);
    const aether = currentOf(source.aether);
    const aetherMax = maxOf(source.aether, source.aetherMax);
    const heat = currentOf(source.heat);
    const heatMax = maxOf(source.heat, source.heatMax);

    assignIfDefined(target, 'echoes', echoes);
    assignIfDefined(target, 'echoesMax', echoesMax);
    assignIfDefined(target, 'aether', aether);
    assignIfDefined(target, 'aetherMax', aetherMax);
    assignIfDefined(target, 'heat', heat);
    assignIfDefined(target, 'heatMax', heatMax);

    if (Array.isArray(source.unlockedAbilities)) {
      target.unlockedAbilities = source.unlockedAbilities.slice();
    }
    if (source.equipment && typeof source.equipment === 'object') {
      target.equipment = Object.assign({}, source.equipment);
    }

    // The preservation creator may still provide temporary names/jobs/stats,
    // but authored protagonist identity and the current fitted balance profile
    // are authoritative at the persistent-roster boundary.
    applyAuthoredProfile(target, definition, { initializeProgression: false });
    return target;
  }

  function validate() {
    if (ROSTER.length !== 5) throw new Error('ROSTER_LENGTH_MUST_BE_5');

    const expectedIds = DEFINITIONS.map(def => def.id);
    const actualIds = ROSTER.map(character => character && character.id);
    if (actualIds.join('|') !== expectedIds.join('|')) {
      throw new Error('ROSTER_IDENTITY_ORDER_INVALID');
    }

    if (new Set(actualIds).size !== 5) throw new Error('ROSTER_IDS_MUST_BE_UNIQUE');

    if (CHARACTER_CANON && CHARACTER_CANON.PROFILES) {
      DEFINITIONS.forEach(definition => {
        const profile = CHARACTER_CANON.PROFILES[definition.id];
        if (!profile) throw new Error('CHARACTER_CANON_PROFILE_MISSING:' + definition.id);
        if (profile.name !== definition.canonicalName || profile.age !== definition.age) {
          throw new Error('CHARACTER_CANON_IDENTITY_DRIFT:' + definition.id);
        }
        if ((profile.nativeJob || null) !== (definition.nativeJob || null)) {
          throw new Error('CHARACTER_CANON_JOB_DRIFT:' + definition.id);
        }
        if (JRPG_STAT_MODEL && JRPG_STAT_MODEL.PROFILES) {
          const expectedProduction = JRPG_STAT_MODEL.getPrimaryStats(definition.id, 1);
          if (!expectedProduction) throw new Error('JRPG_PRODUCTION_PROFILE_MISSING:' + definition.id);
        }
      });
    }
    if (ACTIVE_PARTY.length < MIN_ACTIVE_PARTY || ACTIVE_PARTY.length > MAX_ACTIVE_PARTY) {
      throw new Error('ACTIVE_PARTY_LENGTH_MUST_BE_1_TO_5');
    }
    if (new Set(ACTIVE_PARTY).size !== ACTIVE_PARTY.length) {
      throw new Error('ACTIVE_PARTY_REFERENCES_MUST_BE_UNIQUE');
    }

    for (const character of ACTIVE_PARTY) {
      if (!ROSTER.includes(character)) {
        throw new Error('ACTIVE_PARTY_MEMBER_MUST_REFERENCE_ROSTER');
      }
    }

    for (const character of ROSTER) validateMagicProfile(character);

    if (boundWorldPlayer && ROSTER[0] !== boundWorldPlayer) {
      throw new Error('WORLD_PLAYER_MUST_REFERENCE_ROSTER_LEAD');
    }

    return true;
  }

  function syncGlobals() {
    global.ROSTER = ROSTER;
    global.ACTIVE_PARTY = ACTIVE_PARTY;
    global.party = ACTIVE_PARTY;
    global.playerForCombat = ACTIVE_PARTY[0] || null;
  }

  function setActivePartyIds(ids) {
    if (!boundWorldPlayer || ROSTER.length !== 5) {
      throw new Error('PARTY_STATE_NOT_BOOTSTRAPPED');
    }
    if (!Array.isArray(ids) || ids.length < MIN_ACTIVE_PARTY || ids.length > MAX_ACTIVE_PARTY) {
      throw new Error('ACTIVE_PARTY_IDS_MUST_HAVE_1_TO_5_MEMBERS');
    }
    if (new Set(ids).size !== ids.length) {
      throw new Error('ACTIVE_PARTY_IDS_MUST_BE_UNIQUE');
    }

    const next = ids.map(id => {
      const character = ROSTER.find(entry => entry.id === id);
      if (!character) throw new Error('ACTIVE_PARTY_UNKNOWN_CHARACTER:' + id);
      if (!character.playable) {
        throw new Error('ACTIVE_PARTY_CHARACTER_NOT_PLAYABLE:' + id);
      }
      return character;
    });

    ACTIVE_PARTY.splice(0, ACTIVE_PARTY.length, ...next);
    syncGlobals();
    validate();
    return ACTIVE_PARTY;
  }

  function bootstrap(worldPlayer) {
    if (!worldPlayer || typeof worldPlayer !== 'object') {
      throw new Error('PARTY_STATE_BOOTSTRAP_REQUIRES_WORLD_PLAYER');
    }

    if (ROSTER.length === 0) {
      boundWorldPlayer = worldPlayer;

      applyAuthoredProfile(worldPlayer, DEFINITIONS[0], { initializeProgression: false });
      worldPlayer.runtimeImplemented = true;
      worldPlayer.playable = true;
      worldPlayer.implementationSource = 'world-bootstrap-authored-profile';

      ROSTER.push(
        worldPlayer,
        createShell(DEFINITIONS[1]),
        createShell(DEFINITIONS[2]),
        createShell(DEFINITIONS[3]),
        createShell(DEFINITIONS[4])
      );

      ACTIVE_PARTY.push(ROSTER[0]);
    } else if (ROSTER[0] !== worldPlayer) {
      throw new Error('PARTY_STATE_ALREADY_BOUND_TO_DIFFERENT_WORLD_PLAYER');
    }

    syncGlobals();

    validate();
    return { roster: ROSTER, activeParty: ACTIVE_PARTY };
  }

  function recruitCharacter(characterId) {
    if (!boundWorldPlayer || ROSTER.length !== 5) {
      throw new Error('PARTY_STATE_NOT_BOOTSTRAPPED');
    }
    const character = ROSTER.find(entry => entry.id === characterId);
    if (!character) throw new Error('PARTY_STATE_UNKNOWN_CHARACTER:' + characterId);
    if (characterId === 'reson' || characterId === 'aepex') {
      throw new Error('PARTY_STATE_RECRUITMENT_NOT_AUTHORIZED:' + characterId);
    }

    character.playable = true;
    character.implementationSource = character.runtimeImplemented
      ? character.implementationSource
      : 'story-joined-authored-shell';

    const nextIds = ACTIVE_PARTY.map(entry => entry.id);
    if (!nextIds.includes(characterId)) nextIds.push(characterId);
    setActivePartyIds(nextIds);
    return character;
  }

  function replaceMagicProfile(characterId, nextProfile) {
    if (ROSTER.length !== 5) throw new Error('PARTY_STATE_NOT_BOOTSTRAPPED');

    const character = ROSTER.find(entry => entry.id === characterId);
    if (!character) throw new Error('PARTY_STATE_UNKNOWN_CHARACTER:' + characterId);

    if (!global.AetherwakeCharacterMagicProfile ||
        typeof global.AetherwakeCharacterMagicProfile.validateProfile !== 'function') {
      throw new Error('PARTY_STATE_MAGIC_PROFILE_MODULE_UNAVAILABLE');
    }

    const validated = global.AetherwakeCharacterMagicProfile.validateProfile(nextProfile);
    if (validated.characterId !== characterId) {
      throw new Error('PARTY_STATE_MAGIC_PROFILE_CHARACTER_MISMATCH');
    }

    character.magicProfile = validated;
    validate();
    return character.magicProfile;
  }

  function commitPrototypeParty(prototypeParty) {
    if (!boundWorldPlayer || ROSTER.length !== 5) {
      throw new Error('PARTY_STATE_NOT_BOOTSTRAPPED');
    }
    if (!Array.isArray(prototypeParty) || prototypeParty.length < 3) {
      throw new Error('PROTOTYPE_PARTY_MUST_HAVE_3_MEMBERS');
    }

    adaptPrototypeCharacter(ROSTER[0], prototypeParty[0], DEFINITIONS[0]);
    adaptPrototypeCharacter(ROSTER[1], prototypeParty[1], DEFINITIONS[1]);
    adaptPrototypeCharacter(ROSTER[2], prototypeParty[2], DEFINITIONS[2]);

    ACTIVE_PARTY.splice(0, ACTIVE_PARTY.length, ROSTER[0], ROSTER[1], ROSTER[2]);

    syncGlobals();

    validate();
    return ACTIVE_PARTY;
  }

  // Formation capacity is now 1–5. Scene/combat code remains responsible for
  // calling setActivePartyIds only at admissible story/safe-state boundaries.

  function snapshot() {
    return {
      rosterIds: ROSTER.map(character => character.id),
      activeIds: ACTIVE_PARTY.map(character => character.id),
      runtimeImplemented: ROSTER.map(character => Boolean(character.runtimeImplemented)),
      playable: ROSTER.map(character => Boolean(character.playable)),
      affinityStatus: ROSTER.map(character =>
        character.magicProfile && character.magicProfile.affinityStatus),
      masteryRanks: ROSTER.map(character => ({
        trees: Object.assign({}, character.magicProfile.mastery.trees),
        domains: Object.assign({}, character.magicProfile.mastery.domains),
      })),
      learnedSpells: ROSTER.map(character => character.magicProfile.learnedSpells.slice()),
    };
  }

  global.ROSTER = ROSTER;
  global.ACTIVE_PARTY = ACTIVE_PARTY;
  global.AetherPartyState = Object.freeze({
    definitions: DEFINITIONS,
    balanceProfileVersion: BALANCE_PROFILE_VERSION,
    balanceStatus: BALANCE_STATUS,
    characterCanonVersion: CHARACTER_CANON ? CHARACTER_CANON.VERSION : null,
    productionStatModelVersion: JRPG_STAT_MODEL ? JRPG_STAT_MODEL.VERSION : null,
    roster: ROSTER,
    activeParty: ACTIVE_PARTY,
    bootstrap,
    commitPrototypeParty,
    recruitCharacter,
    replaceMagicProfile,
    setActivePartyIds,
    validate,
    snapshot,
    refreshProductionStats,
    refreshAllProductionStats,
    minActiveParty: MIN_ACTIVE_PARTY,
    maxActiveParty: MAX_ACTIVE_PARTY,
  });
})(window);
