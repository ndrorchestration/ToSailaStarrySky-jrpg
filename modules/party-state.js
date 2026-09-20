/* ============================================================
   Aetherwake JRPG — Persistent Party State
   modules/party-state.js

   First production-architecture bridge:
   - ROSTER contains exactly five stable authored identities.
   - ACTIVE_PARTY contains exactly three references into ROSTER.
   - The current preservation character-creation flow is adapted into
     the first three roster records without changing its player-facing flow.
   - Reson and Aepex remain authored identity shells until the later
     authored-roster/onboarding migration supplies their mechanics.
   ============================================================ */

(function (global) {
  'use strict';

  const DEFINITIONS = Object.freeze([
    Object.freeze({ id: 'ender', canonicalName: 'Ender', nativeJob: 'Rift Scholar' }),
    Object.freeze({ id: 'lyra', canonicalName: 'Lyra', nativeJob: null }),
    Object.freeze({ id: 'ionia', canonicalName: 'Ionia', nativeJob: null }),
    Object.freeze({ id: 'reson', canonicalName: 'Reson', nativeJob: null }),
    Object.freeze({ id: 'aepex', canonicalName: 'Aepex', nativeJob: null }),
  ]);

  const ROSTER = [];
  const ACTIVE_PARTY = [];
  let boundWorldPlayer = null;

  const PERSISTENT_FIELDS = Object.freeze([
    'class',
    'jobId',
    'mechanicsTemplateId',
    'mechanicsTemplateName',
    'synergyBonus',
    'vit',
    'maxVit',
    'echoes',
    'echoesMax',
    'wits',
    'presence',
    'spirit',
    'might',
    'grace',
    'scrap',
    'aether',
    'aetherMax',
    'heat',
    'heatMax',
    'staffCharges',
    'maxStaffCharges',
    'level',
    'xp',
    'xpToNext',
    'unlockedAbilities',
    'equipment',
  ]);

  function cloneJsonValue(value) {
    if (value === undefined) return undefined;
    return JSON.parse(JSON.stringify(value));
  }

  function createShell(definition) {
    return {
      schemaVersion: 1,
      id: definition.id,
      canonicalName: definition.canonicalName,
      name: definition.canonicalName,
      nativeJob: definition.nativeJob,
      runtimeImplemented: false,
      implementationSource: 'authored-shell',
      age: null,
      class: null,
      jobId: null,
      mechanicsTemplateId: null,
      mechanicsTemplateName: null,
      synergyBonus: null,
      vit: null,
      maxVit: null,
      echoes: null,
      echoesMax: null,
      wits: null,
      presence: null,
      spirit: null,
      might: null,
      grace: null,
      scrap: null,
      aether: null,
      aetherMax: null,
      heat: null,
      heatMax: null,
      staffCharges: null,
      maxStaffCharges: null,
      level: null,
      xp: null,
      xpToNext: null,
      unlockedAbilities: [],
      equipment: { staff: null, backpack: null },
    };
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

  function adaptPrototypeCharacter(target, source, definition) {
    if (!target || !source) {
      throw new Error('PARTY_STATE_ADAPT_REQUIRES_TARGET_AND_SOURCE');
    }

    target.schemaVersion = 1;
    target.id = definition.id;
    target.canonicalName = definition.canonicalName;
    target.nativeJob = definition.nativeJob;
    target.runtimeImplemented = true;
    target.implementationSource = definition.id === 'ender'
      ? 'prototype-adapter'
      : 'authored-identity+prototype-mechanics';

    assignIfDefined(target, 'name', source.name || definition.canonicalName);
    assignIfDefined(target, 'age', source.age);
    assignIfDefined(target, 'class', source.class);
    assignIfDefined(target, 'jobId', source.jobId);
    assignIfDefined(target, 'mechanicsTemplateId', source.mechanicsTemplateId || source.jobId);
    assignIfDefined(target, 'mechanicsTemplateName', source.mechanicsTemplateName || source.class);
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
    if (ACTIVE_PARTY.length !== 3) throw new Error('ACTIVE_PARTY_LENGTH_MUST_BE_3');
    if (new Set(ACTIVE_PARTY).size !== 3) throw new Error('ACTIVE_PARTY_REFERENCES_MUST_BE_UNIQUE');

    for (const character of ACTIVE_PARTY) {
      if (!ROSTER.includes(character)) {
        throw new Error('ACTIVE_PARTY_MEMBER_MUST_REFERENCE_ROSTER');
      }
    }

    if (boundWorldPlayer && ROSTER[0] !== boundWorldPlayer) {
      throw new Error('WORLD_PLAYER_MUST_REFERENCE_ROSTER_LEAD');
    }

    return true;
  }

  function bootstrap(worldPlayer) {
    if (!worldPlayer || typeof worldPlayer !== 'object') {
      throw new Error('PARTY_STATE_BOOTSTRAP_REQUIRES_WORLD_PLAYER');
    }

    if (ROSTER.length === 0) {
      boundWorldPlayer = worldPlayer;

      worldPlayer.schemaVersion = 1;
      worldPlayer.id = DEFINITIONS[0].id;
      worldPlayer.canonicalName = DEFINITIONS[0].canonicalName;
      worldPlayer.nativeJob = DEFINITIONS[0].nativeJob;
      worldPlayer.runtimeImplemented = true;
      worldPlayer.implementationSource = 'world-bootstrap';

      ROSTER.push(
        worldPlayer,
        createShell(DEFINITIONS[1]),
        createShell(DEFINITIONS[2]),
        createShell(DEFINITIONS[3]),
        createShell(DEFINITIONS[4])
      );

      ACTIVE_PARTY.push(ROSTER[0], ROSTER[1], ROSTER[2]);
    } else if (ROSTER[0] !== worldPlayer) {
      throw new Error('PARTY_STATE_ALREADY_BOUND_TO_DIFFERENT_WORLD_PLAYER');
    }

    global.ROSTER = ROSTER;
    global.ACTIVE_PARTY = ACTIVE_PARTY;
    global.party = ACTIVE_PARTY;
    global.playerForCombat = ACTIVE_PARTY[0];

    validate();
    return { roster: ROSTER, activeParty: ACTIVE_PARTY };
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

    global.ROSTER = ROSTER;
    global.ACTIVE_PARTY = ACTIVE_PARTY;
    global.party = ACTIVE_PARTY;
    global.playerForCombat = ACTIVE_PARTY[0];

    validate();
    return ACTIVE_PARTY;
  }

  // Formation mutation is intentionally not exposed in this phase.
  // ACTIVE_PARTY is established as canonical references; formation changes
  // land later with safe-state and combat-boundary rules.

  function snapshot() {
    return {
      rosterIds: ROSTER.map(character => character.id),
      activeIds: ACTIVE_PARTY.map(character => character.id),
      runtimeImplemented: ROSTER.map(character => Boolean(character.runtimeImplemented)),
    };
  }

  function exportPersistentState() {
    validate();

    return {
      roster: ROSTER.map((character, index) => {
        const record = {
          id: DEFINITIONS[index].id,
          runtimeImplemented: Boolean(character.runtimeImplemented),
        };

        for (const field of PERSISTENT_FIELDS) {
          if (character[field] !== undefined) {
            record[field] = cloneJsonValue(character[field]);
          }
        }

        return record;
      }),
      activePartyIds: ACTIVE_PARTY.map(character => character.id),
    };
  }

  function validatePersistentState(payload) {
    if (!payload || typeof payload !== 'object') {
      throw new Error('PERSISTENT_STATE_OBJECT_REQUIRED');
    }
    if (!Array.isArray(payload.roster) || payload.roster.length !== DEFINITIONS.length) {
      throw new Error('PERSISTENT_STATE_ROSTER_LENGTH_INVALID');
    }

    const expectedIds = DEFINITIONS.map(definition => definition.id);
    const actualIds = payload.roster.map(record => record && record.id);
    if (actualIds.join('|') !== expectedIds.join('|')) {
      throw new Error('PERSISTENT_STATE_ROSTER_IDENTITY_INVALID');
    }
    if (new Set(actualIds).size !== expectedIds.length) {
      throw new Error('PERSISTENT_STATE_ROSTER_IDS_NOT_UNIQUE');
    }

    for (const record of payload.roster) {
      if (typeof record.runtimeImplemented !== 'boolean') {
        throw new Error('PERSISTENT_STATE_IMPLEMENTATION_FLAG_INVALID');
      }
    }

    if (!Array.isArray(payload.activePartyIds) || payload.activePartyIds.length !== 3) {
      throw new Error('PERSISTENT_STATE_ACTIVE_PARTY_LENGTH_INVALID');
    }
    if (new Set(payload.activePartyIds).size !== 3) {
      throw new Error('PERSISTENT_STATE_ACTIVE_PARTY_IDS_NOT_UNIQUE');
    }

    for (const id of payload.activePartyIds) {
      const index = expectedIds.indexOf(id);
      if (index < 0) {
        throw new Error('PERSISTENT_STATE_ACTIVE_PARTY_ID_UNKNOWN');
      }
      if (!payload.roster[index].runtimeImplemented) {
        throw new Error('PERSISTENT_STATE_ACTIVE_PARTY_MEMBER_NOT_IMPLEMENTED');
      }
    }

    return true;
  }

  function restorePersistentState(payload) {
    if (!boundWorldPlayer || ROSTER.length !== DEFINITIONS.length) {
      throw new Error('PARTY_STATE_NOT_BOOTSTRAPPED');
    }

    validatePersistentState(payload);

    payload.roster.forEach((source, index) => {
      const target = ROSTER[index];
      const definition = DEFINITIONS[index];

      // Canonical identity is code-owned, never save-owned.
      target.schemaVersion = 1;
      target.id = definition.id;
      target.canonicalName = definition.canonicalName;
      target.nativeJob = definition.nativeJob;
      target.name = definition.id === 'ender' ? (target.name || definition.canonicalName) : definition.canonicalName;
      target.runtimeImplemented = source.runtimeImplemented;
      target.implementationSource = source.runtimeImplemented
        ? (definition.id === 'ender' ? 'save-restore' : 'authored-identity+prototype-mechanics')
        : 'authored-shell';

      for (const field of PERSISTENT_FIELDS) {
        if (Object.prototype.hasOwnProperty.call(source, field)) {
          target[field] = cloneJsonValue(source[field]);
        }
      }
    });

    const restoredActiveParty = payload.activePartyIds.map(id => {
      const character = ROSTER.find(record => record.id === id);
      if (!character) throw new Error('PERSISTENT_STATE_ACTIVE_PARTY_REFERENCE_MISSING');
      return character;
    });
    ACTIVE_PARTY.splice(0, ACTIVE_PARTY.length, ...restoredActiveParty);

    global.ROSTER = ROSTER;
    global.ACTIVE_PARTY = ACTIVE_PARTY;
    global.party = ACTIVE_PARTY;
    global.playerForCombat = ACTIVE_PARTY[0];

    validate();
    return { roster: ROSTER, activeParty: ACTIVE_PARTY };
  }

  global.ROSTER = ROSTER;
  global.ACTIVE_PARTY = ACTIVE_PARTY;
  global.AetherPartyState = Object.freeze({
    definitions: DEFINITIONS,
    roster: ROSTER,
    activeParty: ACTIVE_PARTY,
    bootstrap,
    commitPrototypeParty,
    validate,
    snapshot,
    persistentFields: PERSISTENT_FIELDS,
    exportPersistentState,
    validatePersistentState,
    restorePersistentState,
  });
})(window);
