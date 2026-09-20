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

  const FIRST_WAKE_IDS = Object.freeze(['ender', 'lyra', 'ionia', 'reson', 'aepex']);
  const FIRST_WAKE_ACTIVE_IDS = Object.freeze(['ender', 'lyra', 'ionia']);
  const FIRST_WAKE_ROLES = Object.freeze({
    ender: Object.freeze({ id: 'reader', label: 'Reader', canonStatus: 'provisional' }),
    lyra: Object.freeze({ id: 'receiver', label: 'Receiver', canonStatus: 'provisional' }),
    ionia: Object.freeze({ id: 'anchor', label: 'Anchor', canonStatus: 'provisional' }),
  });

  const ROSTER = [];
  const ACTIVE_PARTY = [];
  let boundWorldPlayer = null;

  function createShell(definition) {
    return {
      schemaVersion: 1,
      id: definition.id,
      canonicalName: definition.canonicalName,
      name: definition.canonicalName,
      nativeJob: definition.nativeJob,
      runtimeImplemented: false,
      implementationSource: 'authored-shell',
      roleId: null,
      roleLabel: null,
      roleCanonStatus: null,
      storyFlags: {},
      age: null,
      class: null,
      jobId: null,
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

  function authoredRecord(target, definition, role, storyFlags) {
    target.schemaVersion = 1;
    target.id = definition.id;
    target.canonicalName = definition.canonicalName;
    target.nativeJob = definition.nativeJob;
    target.roleId = role.id;
    target.roleLabel = role.label;
    target.roleCanonStatus = role.canonStatus;
    target.storyFlags = Object.assign({}, storyFlags);
    target.implementationSource = 'authored-onboarding';

    if (definition.id === 'ender') {
      target.name = 'Ender';
      target.runtimeImplemented = true;
      return target;
    }

    target.name = definition.canonicalName;
    target.runtimeImplemented = false;
    target.class = null;
    target.jobId = null;
    target.age = null;
    target.synergyBonus = null;
    target.unlockedAbilities = [];
    target.equipment = { staff: null, backpack: null };
    return target;
  }

  function commitFirstWakeParty(options) {
    if (!boundWorldPlayer || ROSTER.length !== 5) {
      throw new Error('PARTY_STATE_NOT_BOOTSTRAPPED');
    }

    const providedFlags = options && options.storyFlags ? options.storyFlags : {};
    const storyFlags = Object.assign({ lyraJoined: true, ioniaJoined: true }, providedFlags);
    if (!storyFlags.lyraJoined || !storyFlags.ioniaJoined) {
      throw new Error('FIRST_WAKE_PARTY_REQUIRES_AUTHORED_TRIO');
    }

    authoredRecord(ROSTER[0], DEFINITIONS[0], FIRST_WAKE_ROLES.ender, storyFlags);
    authoredRecord(ROSTER[1], DEFINITIONS[1], FIRST_WAKE_ROLES.lyra, storyFlags);
    authoredRecord(ROSTER[2], DEFINITIONS[2], FIRST_WAKE_ROLES.ionia, storyFlags);

    ACTIVE_PARTY.splice(0, ACTIVE_PARTY.length, ROSTER[0], ROSTER[1], ROSTER[2]);
    global.ROSTER = ROSTER;
    global.ACTIVE_PARTY = ACTIVE_PARTY;
    global.party = ACTIVE_PARTY;
    global.playerForCombat = ACTIVE_PARTY[0];

    validate();
    return { roster: ROSTER, activeParty: ACTIVE_PARTY };
  }

  function cloneValue(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function validateSerializedParty(serializedParty) {
    if (!serializedParty || typeof serializedParty !== 'object') {
      throw new Error('FIRST_WAKE_PARTY_SNAPSHOT_MUST_BE_OBJECT');
    }
    if (!Array.isArray(serializedParty.roster) || serializedParty.roster.length !== 5) {
      throw new Error('FIRST_WAKE_PARTY_ROSTER_INVALID');
    }
    if (!Array.isArray(serializedParty.activeIds) ||
        serializedParty.activeIds.join('|') !== FIRST_WAKE_ACTIVE_IDS.join('|')) {
      throw new Error('ACTIVE_PARTY_IDS_INVALID');
    }

    const stagedRoster = serializedParty.roster.map((character, index) => {
      if (!character || typeof character !== 'object' || character.id !== FIRST_WAKE_IDS[index]) {
        throw new Error('FIRST_WAKE_PARTY_IDENTITY_ORDER_INVALID');
      }
      if (typeof character.name !== 'string' || character.name.length === 0) {
        throw new Error('FIRST_WAKE_PARTY_NAME_INVALID:' + character.id);
      }
      if (character.runtimeImplemented &&
          ['vit', 'maxVit', 'level', 'xp', 'xpToNext'].some(key =>
            typeof character[key] !== 'number' || !Number.isFinite(character[key]))) {
        throw new Error('FIRST_WAKE_PARTY_NUMERIC_STATE_INVALID:' + character.id);
      }
      if (character.id === 'lyra' || character.id === 'ionia') {
        const role = FIRST_WAKE_ROLES[character.id];
        if (character.roleId !== role.id || character.roleCanonStatus !== role.canonStatus ||
            character.jobId !== null) {
          throw new Error('FIRST_WAKE_PARTY_AUTHORED_ROLE_INVALID:' + character.id);
        }
      }
      return cloneValue(character);
    });

    return stagedRoster;
  }

  function replaceRecord(target, source) {
    Object.keys(target).forEach(key => {
      if (!Object.prototype.hasOwnProperty.call(source, key)) delete target[key];
    });
    Object.assign(target, source);
  }

  function hydrateFirstWakeParty(serializedParty) {
    if (!boundWorldPlayer || ROSTER.length !== 5) {
      throw new Error('PARTY_STATE_NOT_BOOTSTRAPPED');
    }

    const stagedRoster = validateSerializedParty(serializedParty);
    stagedRoster.forEach((character, index) => replaceRecord(ROSTER[index], character));
    ACTIVE_PARTY.splice(0, ACTIVE_PARTY.length, ROSTER[0], ROSTER[1], ROSTER[2]);
    global.ROSTER = ROSTER;
    global.ACTIVE_PARTY = ACTIVE_PARTY;
    global.party = ACTIVE_PARTY;
    global.playerForCombat = ACTIVE_PARTY[0];
    validate();
    return { roster: ROSTER, activeParty: ACTIVE_PARTY };
  }

  // Formation mutation is intentionally not exposed in this phase.
  // ACTIVE_PARTY is established as canonical references; formation changes
  // land later with safe-state and combat-boundary rules.

  function snapshot() {
    return {
      rosterIds: ROSTER.map(character => character.id),
      activeIds: ACTIVE_PARTY.map(character => character.id),
      runtimeImplemented: ROSTER.map(character => Boolean(character.runtimeImplemented)),
      roleIds: ROSTER.map(character => character.roleId || null),
    };
  }

  global.ROSTER = ROSTER;
  global.ACTIVE_PARTY = ACTIVE_PARTY;
  global.AetherPartyState = Object.freeze({
    definitions: DEFINITIONS,
    roster: ROSTER,
    activeParty: ACTIVE_PARTY,
    bootstrap,
    commitPrototypeParty,
    commitFirstWakeParty,
    hydrateFirstWakeParty,
    validate,
    snapshot,
  });
})(window);
