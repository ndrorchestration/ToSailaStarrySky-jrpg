/* ============================================================
   Aetherwake JRPG — First Wake party-combat adapter
   modules/party-combat.js

   Combat state is a temporary copy of ACTIVE_PARTY. Canonical roster
   records are changed only by writeBack(), which preserves their object
   identity. Ender keeps the legacy player/action surface as a compatibility
   alias while Lyra and Ionia use their provisional role kits.
   ============================================================ */

(function (root, factory) {
  'use strict';

  let kits = root && root.AetherFirstWakeKits;
  let abilityDefs = root && root.AetherAbilityDefs;
  let airshipBridge = root && root.AetherAirshipCombatBridge;

  if (typeof module === 'object' && module.exports) {
    kits = kits || require('./first-wake-kits.js');
    abilityDefs = abilityDefs || require('./ability-defs.js');
    airshipBridge = airshipBridge || require('./airship-combat-bridge.js');
  }

  const api = factory(kits, abilityDefs, airshipBridge);

  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherPartyCombat = api;
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function (kits, abilityDefs, airshipBridge) {
  'use strict';

  if (!kits) throw new Error('FIRST_WAKE_PARTY_COMBAT_REQUIRES_KITS');
  if (!abilityDefs) throw new Error('FIRST_WAKE_PARTY_COMBAT_REQUIRES_ABILITY_DEFS');
  if (!airshipBridge) throw new Error('FIRST_WAKE_PARTY_COMBAT_REQUIRES_AIRSHIP_BRIDGE');

  const ACTOR_ORDER = Object.freeze(['ender', 'lyra', 'ionia']);
  const TURN_ORDER = Object.freeze(['ender', 'lyra', 'ionia', 'enemy']);
  const LEGACY_ACTIONS = new Set(abilityDefs.ACTION_ORDER);

  const DEFAULT_ENEMIES = Object.freeze({
    skyPredator: Object.freeze({
      id: 'skyPredator',
      name: 'Sky-Predator',
      goal: 'Kill or drive off the predator hunting heat signatures above the Wake.',
      hp: 12, maxHp: 12, might: 1, presence: 0, grace: 0, wits: 0,
      weakness: 'Its brass wing-joints shudder in EMP.',
      status: 'roosting', type: 'skyPredator', ability: 'diveBomb',
      abilityDesc: 'Dive Bomb — 2 damage, ignores dodge', color: 'rust', bodyShape: 'predator',
    }),
    corporateSalvager: Object.freeze({
      id: 'corporateSalvager', name: 'Corporate Salvager',
      goal: 'Secure the Wake\'s core for the syndicate.',
      hp: 10, maxHp: 10, might: 0, presence: 2, grace: 1, wits: 1,
      weakness: 'Class-locked dialogue — the commons outlasts the contract.',
      status: 'negotiating', type: 'corporateSalvager', ability: 'contractClause',
      abilityDesc: 'Contract Clause — you lose 1 scrap', color: 'soil', bodyShape: 'humanoid',
    }),
    windShear: Object.freeze({
      id: 'windShear', name: 'Harmonic Shear Elemental',
      goal: 'Tear the ship apart — harmonic shear strips grace from all who stand here.',
      hp: 14, maxHp: 14, might: 2, presence: 0, grace: 0, wits: 1,
      weakness: 'Uncover Truth reveals the wind pattern — exposing it to EMP.',
      status: 'howling', type: 'windShear', ability: 'galeForce',
      abilityDesc: 'Gale Force — 2 damage, knocks you back', color: 'scioto', bodyShape: 'elemental',
    }),
    aetherLeak: Object.freeze({
      id: 'aetherLeak', name: 'Aether Leak Wraith',
      goal: 'Pool the aether, distort the local weave — and feed.',
      hp: 8, maxHp: 8, might: 0, presence: 1, grace: 2, wits: 1,
      weakness: 'Shared Dream seals the leak — starve the wraith of aether.',
      status: 'draining', type: 'aetherLeak', ability: 'drain',
      abilityDesc: 'Drain — removes 1 aether from you', color: 'teal', bodyShape: 'wraith',
    }),
    engine_spirit: Object.freeze({
      id: 'engine_spirit', name: 'Engine Spirit',
      goal: 'Dissipate the aether — the core sings itself hollow.',
      hp: 10, maxHp: 10, might: 0, presence: 2, grace: 0, wits: 1,
      weakness: 'Harmonic Pulse backlashes — the spirit feeds on its own resonance.',
      status: 'pulsing', type: 'engine_spirit', ability: 'harmonic_pulse',
      abilityDesc: 'Harmonic Pulse — 2D6+Presence, drains 1 aether on 7-9+',
      color: 'biolum', bodyShape: 'core',
    }),
    child_prophet: Object.freeze({
      id: 'child_prophet', name: 'Child Prophet',
      goal: 'Sing the wrong note — unravel the crew\'s confidence one prophecy at a time.',
      hp: 8, maxHp: 8, might: -1, presence: 0, grace: 2, wits: 1,
      weakness: 'Prophecy Voice overreaches — the child hears too much and falters.',
      status: 'chanting', type: 'child_prophet', ability: 'prophecy_voice',
      abilityDesc: 'Prophecy Voice — 2D6+Grace, on 10+ target loses 1 turn confidence',
      color: 'rose', bodyShape: 'prophet',
    }),
    elder_farmer: Object.freeze({
      id: 'elder_farmer', name: 'Elder Farmer',
      goal: 'Hold the ground — the soil remembers every sky-lane that never landed.',
      hp: 16, maxHp: 16, might: 2, presence: 1, grace: 0, wits: 0,
      weakness: 'Soil Anchor roots too deep — the earth tires of holding.',
      status: 'anchored', type: 'elder_farmer', ability: 'soil_anchor',
      abilityDesc: 'Soil Anchor — 2D6+Might, on 10+ root enemy in place for 1 turn',
      color: 'soil', bodyShape: 'farmer',
    }),
  });

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function finite(value, fallback) {
    return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
  }

  function current(value, fallback) {
    if (typeof value === 'number' && Number.isFinite(value)) return value;
    if (value && typeof value.current === 'number' && Number.isFinite(value.current)) {
      return value.current;
    }
    return fallback;
  }

  function maximum(value, fallback) {
    if (value && typeof value.max === 'number' && Number.isFinite(value.max)) return value.max;
    return fallback;
  }

  function resource(value, fallback, maxFallback) {
    const max = maximum(value, maxFallback);
    return { current: Math.max(0, current(value, fallback)), max: Math.max(0, max) };
  }

  function normalizeRng(rng) {
    if (typeof rng === 'function') return rng;
    if (rng && typeof rng.next === 'function') return () => rng.next();
    return () => Math.random();
  }

  function die(state) {
    const value = state._rng();
    if (value >= 1 && value <= 6) return Math.max(1, Math.min(6, Math.floor(value)));
    return Math.floor(Math.max(0, Math.min(0.999999, value)) * 6) + 1;
  }

  function roll2d6(state, stat) {
    const dice = die(state) + die(state);
    const statValue = finite(stat, 0);
    const total = dice + statValue + 0;
    const outcome = total >= 10 ? 'success' : (total >= 7 ? 'partial' : 'failure');
    return { dice, stat: statValue, total, outcome };
  }

  function defaultEnderDefaults() {
    return {
      vit: 13, maxVit: 13, echoes: 3, echoesMax: 3, aether: 4, aetherMax: 6,
      heat: 1, heatMax: 3, staffCharges: 2, maxStaffCharges: 2, level: 1,
      xp: 0, xpToNext: 50, scrap: 7, wits: 2, presence: 1, spirit: 1,
      might: -1, grace: 0, unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
    };
  }

  function makeActor(character, profile) {
    const defaults = profile.defaults || defaultEnderDefaults();
    const actor = {
      id: character.id,
      character,
      roleId: profile.roleId,
      roleLabel: kits.roles[profile.roleId].label,
      roleCanonStatus: kits.roles[profile.roleId].canonStatus,
      actionIds: profile.actionIds.slice(),
      temporary: Boolean(profile.temporary),
      name: character.name || character.canonicalName || profile.id,
      vit: finite(character.vit, defaults.vit),
      maxVit: finite(character.maxVit, defaults.maxVit),
      echoes: resource(character.echoes, defaults.echoes, defaults.echoesMax),
      aether: resource(character.aether, defaults.aether, defaults.aetherMax),
      heat: resource(character.heat, defaults.heat, defaults.heatMax),
      staffCharges: finite(character.staffCharges, defaults.staffCharges),
      maxStaffCharges: finite(character.maxStaffCharges, defaults.maxStaffCharges),
      level: finite(character.level, defaults.level),
      xp: finite(character.xp, defaults.xp),
      xpToNext: finite(character.xpToNext, defaults.xpToNext),
      scrap: finite(character.scrap, defaults.scrap),
      wits: finite(character.wits, defaults.wits),
      presence: finite(character.presence, defaults.presence),
      spirit: finite(character.spirit, defaults.spirit),
      might: finite(character.might, defaults.might),
      grace: finite(character.grace, defaults.grace),
      unlockedAbilities: Array.isArray(character.unlockedAbilities)
        ? character.unlockedAbilities.slice()
        : (defaults.unlockedAbilities || []),
      equipment: character.equipment ? clone(character.equipment) : { staff: null, backpack: null },
      nextRollBonus: 0,
      nextHitReduction: 0,
    };
    return actor;
  }

  function canBeginEncounter(enemy) {
    if (typeof enemy === 'string') return Boolean(DEFAULT_ENEMIES[enemy]);
    return Boolean(enemy && typeof enemy === 'object');
  }

  function normalizeEnemy(enemy) {
    if (!canBeginEncounter(enemy)) {
      throw new Error('Unknown enemy: ' + String(enemy));
    }
    const source = typeof enemy === 'string' ? DEFAULT_ENEMIES[enemy] : enemy;
    if (!source || typeof source !== 'object') throw new Error('FIRST_WAKE_ENEMY_INVALID');
    return Object.assign({
      id: source.id || source.type || 'enemy',
      name: 'Unknown enemy',
      hp: 1,
      maxHp: 1,
      might: 0,
      presence: 0,
      grace: 0,
      wits: 0,
      weakness: 'unknown',
      status: 'active',
      type: source.type || source.id || 'generic',
      ability: null,
      abilities: source.ability ? [source.ability] : [],
      abilityDesc: null,
      color: null,
      bodyShape: null,
      revealed: false,
    }, clone(source), {
      hp: Math.max(0, finite(source.hp, 1)),
      maxHp: Math.max(1, finite(source.maxHp, finite(source.hp, 1))),
      abilities: source.abilities
        ? source.abilities.slice()
        : (source.ability ? [source.ability] : []),
      revealed: Boolean(source.revealed),
    });
  }

  function actorById(state, id) {
    return state.actors.find(actor => actor.id === id) || null;
  }

  function log(state, message) {
    state.log.push(message);
    if (state.log.length > 40) state.log.shift();
  }

  function validate(state) {
    if (!state || typeof state !== 'object') throw new Error('PARTY_COMBAT_STATE_INVALID');
    if (state.schemaVersion !== 1) throw new Error('PARTY_COMBAT_SCHEMA_VERSION_INVALID');
    if (!Array.isArray(state.actors) || state.actors.length !== 3) {
      throw new Error('PARTY_COMBAT_REQUIRES_EXACTLY_3_ACTORS');
    }
    if (state.actors.map(actor => actor && actor.id).join('|') !== ACTOR_ORDER.join('|')) {
      throw new Error('PARTY_COMBAT_ACTOR_ORDER_INVALID');
    }
    state.actors.forEach(actor => {
      if (!actor.character || actor.character.id !== actor.id) {
        throw new Error('PARTY_COMBAT_ACTOR_REFERENCE_INVALID:' + actor.id);
      }
      if (!kits.actors[actor.id] || actor.roleId !== kits.actors[actor.id].roleId) {
        throw new Error('PARTY_COMBAT_ROLE_INVALID:' + actor.id);
      }
      if (!Array.isArray(actor.actionIds) || new Set(actor.actionIds).size !== actor.actionIds.length) {
        throw new Error('PARTY_COMBAT_ACTIONS_INVALID:' + actor.id);
      }
      ['vit', 'maxVit', 'level', 'xp', 'xpToNext', 'scrap'].forEach(key => {
        if (!Number.isFinite(actor[key])) throw new Error('PARTY_COMBAT_NUMERIC_STATE_INVALID:' + actor.id + ':' + key);
      });
    });
    if (state.turnOrder.join('|') !== TURN_ORDER.join('|')) {
      throw new Error('PARTY_COMBAT_TURN_ORDER_INVALID');
    }
    if (!Number.isInteger(state.turnIndex) || state.turnIndex < 0 || state.turnIndex >= state.turnOrder.length) {
      throw new Error('PARTY_COMBAT_TURN_INDEX_INVALID');
    }
    if (state.activeActorId !== state.turnOrder[state.turnIndex]) {
      throw new Error('PARTY_COMBAT_ACTIVE_ACTOR_INVALID');
    }
    if (!state.enemy || !Number.isFinite(state.enemy.hp) || !Number.isFinite(state.enemy.maxHp)) {
      throw new Error('PARTY_COMBAT_ENEMY_INVALID');
    }
    return true;
  }

  function totalResource(actor) {
    return actor.echoes.current + actor.aether.current;
  }

  function pay(actor, cost) {
    if (totalResource(actor) < cost) return false;
    let remaining = cost;
    const fromEchoes = Math.min(actor.echoes.current, remaining);
    actor.echoes.current -= fromEchoes;
    remaining -= fromEchoes;
    actor.aether.current -= remaining;
    return true;
  }

  function clampResource(value, max) {
    return Math.max(0, Math.min(max, value));
  }

  function damageActor(state, actor, amount) {
    const reduction = Math.min(actor.nextHitReduction || 0, amount);
    actor.nextHitReduction = Math.max(0, (actor.nextHitReduction || 0) - reduction);
    const applied = Math.max(0, amount - reduction);
    actor.vit = Math.max(0, actor.vit - applied);
    state.resolverMutations++;
    return applied;
  }

  function restoreActor(state, actor, amount) {
    const before = actor.vit;
    actor.vit = Math.min(actor.maxVit, actor.vit + Math.max(0, amount));
    const applied = actor.vit - before;
    if (applied > 0) state.resolverMutations++;
    return applied;
  }

  function damageEnemy(state, amount) {
    const before = state.enemy.hp;
    state.enemy.hp = Math.max(0, state.enemy.hp - Math.max(0, amount));
    const applied = before - state.enemy.hp;
    if (applied > 0) state.resolverMutations++;
    return applied;
  }

  function chooseAlly(state, actor, requestedId) {
    const requested = requestedId ? actorById(state, requestedId) : null;
    if (requested && requested.id !== actor.id) return requested;
    return state.actors.find(candidate => candidate.id !== actor.id) || actor;
  }

  function advanceTurn(state) {
    let nextIndex = (state.turnIndex + 1) % state.turnOrder.length;
    state.turnIndex = nextIndex;
    state.activeActorId = state.turnOrder[nextIndex];

    if (state.activeActorId === 'enemy' && !state.encounterOver) {
      enemyTurn(state);
      state.turnIndex = 0;
      state.activeActorId = 'ender';
      state.round += 1;
    }
  }

  function enemyTurn(state) {
    const target = state.actors.find(actor => actor.vit > 0) || state.actors[0];
    const amount = state.enemy.type === 'windShear' ? 2 : 1;
    const fieldReduction = Math.min(state.nextHitReduction || 0, amount);
    state.nextHitReduction = Math.max(0, (state.nextHitReduction || 0) - fieldReduction);
    const applied = damageActor(state, target, amount - fieldReduction);
    log(state, '[Enemy turn] ' + state.enemy.name + ' pressures ' + target.name +
      ' for ' + applied + ' Vit' + (fieldReduction ? ' (1 braced).' : '.') );
  }

  function actionOwner(state, actionId) {
    return state.actors.find(actor => actor.actionIds.includes(actionId)) || null;
  }

  function compatibilityActionIds(actor) {
    return actor.id === 'ender' ? abilityDefs.ACTION_ORDER : actor.actionIds;
  }

  function resolveAction(state, actionId, options) {
    validate(state);
    options = options || {};
    if (state.encounterOver) return { accepted: false, reason: 'encounter_over', actionId };
    if (state.activeActorId === 'enemy') return { accepted: false, reason: 'enemy_turn', actionId };

    const actor = actorById(state, state.activeActorId);
    const action = abilityDefs.DEFS[actionId];
    if (!action) {
      log(state, 'Unknown action: ' + actionId);
      return { accepted: false, reason: 'unknown_action', actionId };
    }

    const owner = actionOwner(state, actionId);
    const legacyEnderAction = actor.id === 'ender' && LEGACY_ACTIONS.has(actionId);
    if ((owner && owner.id !== actor.id) || (!owner && !legacyEnderAction)) {
      return { accepted: false, reason: 'not_active_actor', actionId, actorId: actor.id };
    }

    const eligibility = abilityDefs.getPartyUseEligibility(actor, actionId);
    if (!eligibility.canUse && !(legacyEnderAction && eligibility.reason === 'locked' && actionId === 'hold')) {
      if (eligibility.reason === 'locked') log(state, 'Locked action: ' + action.label);
      else if (eligibility.reason === 'insufficient_resources') {
        log(state, 'Not enough resources — ' + action.label +
          ' needs ' + eligibility.resourceCost + ', but only ' + eligibility.availableResource + ' is available.');
      }
      return Object.assign({ accepted: false, actionId }, eligibility);
    }

    const beforeTurn = state.turn;
    const beforeResources = totalResource(actor);
    if (!pay(actor, eligibility.resourceCost)) {
      return { accepted: false, reason: 'insufficient_resources', actionId };
    }

    if (action.type !== 'hold' && action.type !== 'rest') {
      actor.heat.current = clampResource(actor.heat.current + 1, actor.heat.max);
    }

    const bonus = actor.nextRollBonus || 0;
    actor.nextRollBonus = 0;
    const roll = roll2d6(state, action.stat ? actor[action.stat] : 0);
    roll.total += bonus;
    roll.outcome = roll.total >= 10 ? 'success' : (roll.total >= 7 ? 'partial' : 'failure');
    roll.nextRollBonus = bonus;
    state.turn += 1;
    state.lastRoll = roll;
    state.lastOutcome = roll.outcome;
    state.lastEffects = [];
    state._lastAbilityId = action.type === 'ability' || action.type === 'party-ability' ? action.id : null;
    state._secondaryAvailable = false;

    let enemyDamage = 0;
    let ally = chooseAlly(state, actor, options.targetId);
    if (action.id === 'staffStrike') {
      if (actor.staffCharges > 0 && roll.outcome !== 'failure') {
        actor.staffCharges -= 1;
        enemyDamage = damageEnemy(state, roll.outcome === 'success' ? 4 : 2);
        state.lastEffects.push({ kind: 'damage', target: 'enemy', amount: enemyDamage });
      }
    } else if (action.id === 'uncoverTruth' || action.id === 'frequencyRead') {
      if (roll.outcome !== 'failure') {
        state.enemy.revealed = true;
        actor.nextRollBonus = 1;
        state.lastEffects.push({ kind: 'reveal', target: 'enemy', key: 'weakness' });
        state.lastEffects.push({ kind: 'modifier', target: actor.id, key: 'nextRoll', amount: 1 });
      }
    } else if (action.id === 'sharedDream' || action.id === 'echoRedirect') {
      if (roll.outcome === 'success') {
        const amount = restoreActor(state, ally, 2);
        ally.nextRollBonus += 1;
        state.lastEffects.push({ kind: 'restore', target: ally.id, amount });
        state.lastEffects.push({ kind: 'modifier', target: ally.id, key: 'nextRoll', amount: 1 });
      } else if (roll.outcome === 'partial') {
        const amount = restoreActor(state, ally, 1);
        state.lastEffects.push({ kind: 'restore', target: ally.id, amount });
      }
    } else if (action.id === 'mycelialLedger') {
      const amount = roll.outcome === 'success' ? 2 : (roll.outcome === 'partial' ? 1 : 0);
      actor.scrap += amount;
      if (amount) {
        state.resolverMutations++;
        state.lastEffects.push({ kind: 'resource', target: actor.id, key: 'scrap', amount });
      }
    } else if (action.id === 'hold') {
      if (actor.staffCharges < actor.maxStaffCharges) {
        actor.staffCharges += 1;
        state.resolverMutations++;
        state.lastEffects.push({ kind: 'resource', target: actor.id, key: 'staffCharges', amount: 1 });
      }
    } else if (action.id === 'braceTheWake') {
      if (roll.outcome === 'success') {
        state.nextHitReduction = 1;
        state.lastEffects.push({ kind: 'modifier', target: 'field', key: 'nextHitReduction', amount: 1 });
      }
    } else if (action.id === 'routeCommand') {
      if (roll.outcome !== 'failure') {
        ally.nextRollBonus += 1;
        state.lastEffects.push({ kind: 'modifier', target: ally.id, key: 'nextRoll', amount: 1 });
      }
    } else if (action.id === 'windWard') {
      if (roll.outcome === 'success') {
        const amount = restoreActor(state, actor, 1);
        state.lastEffects.push({ kind: 'restore', target: actor.id, amount });
      } else if (roll.outcome === 'partial') {
        damageActor(state, actor, 1);
      } else {
        damageActor(state, actor, 2);
      }
    } else if (action.id === 'aetherSeal') {
      if (roll.outcome === 'success') {
        actor.scrap += 1;
        state.resolverMutations++;
        state.lastEffects.push({ kind: 'resource', target: actor.id, key: 'scrap', amount: 1 });
      } else {
        damageActor(state, actor, 1);
      }
    } else if (action.id === 'rest') {
      actor.heat.current = clampResource(actor.heat.current - 1, actor.heat.max);
      if (roll.outcome === 'success') {
        const amount = restoreActor(state, actor, 1);
        state.lastEffects.push({ kind: 'restore', target: actor.id, amount });
      }
    }

    if (enemyDamage > 0) {
      log(state, actor.name + ' hits ' + state.enemy.name + ' for ' + enemyDamage + ' damage.');
    }
    log(state, '[Turn ' + state.turn + '] ' + actor.name + ' uses ' + action.label +
      ' — ' + roll.total + ' (' + roll.outcome + ').');

    if (state.enemy.hp <= 0) {
      state.encounterOver = true;
      log(state, '── ' + state.enemy.name + ' defeated. ──');
    } else {
      advanceTurn(state);
    }

    state.lastAction = action.id;
    state.lastResources = { before: beforeResources, after: totalResource(actor) };
    if (action.type === 'ability' && roll.outcome === 'success' &&
        abilityDefs.getPartyUseEligibility(actor, action.id).canUse) {
      state._secondaryAvailable = true;
    }
    validate(state);
    return {
      accepted: true,
      actionId,
      actorId: actor.id,
      outcome: roll.outcome,
      roll,
      enemyDamage,
      turn: beforeTurn + 1,
      effects: state.lastEffects.slice(),
    };
  }

  function writeBack(state) {
    validate(state);
    state.actors.forEach(actor => {
      const target = actor.character;
      target.vit = actor.vit;
      target.maxVit = actor.maxVit;
      target.echoes = actor.echoes.current;
      target.echoesMax = actor.echoes.max;
      target.aether = actor.aether.current;
      target.aetherMax = actor.aether.max;
      target.heat = actor.heat.current;
      target.heatMax = actor.heat.max;
      target.staffCharges = actor.staffCharges;
      target.maxStaffCharges = actor.maxStaffCharges;
      target.level = actor.level;
      target.xp = actor.xp;
      target.xpToNext = actor.xpToNext;
      target.scrap = actor.scrap;
      target.provisionalCombatState = {
        nextRollBonus: actor.nextRollBonus,
        nextHitReduction: actor.nextHitReduction,
      };
    });
    state.writtenBack = true;
    return true;
  }

  function compatibilityPlayer(actor) {
    return {
      id: actor.id,
      name: actor.name,
      roleId: actor.roleId,
      roleLabel: actor.roleLabel,
      vit: actor.vit,
      maxVit: actor.maxVit,
      echoes: clone(actor.echoes),
      echoesMax: actor.echoes.max,
      aether: clone(actor.aether),
      aetherMax: actor.aether.max,
      heat: clone(actor.heat),
      heatMax: actor.heat.max,
      staffCharges: actor.staffCharges,
      maxStaffCharges: actor.maxStaffCharges,
      level: actor.level,
      xp: actor.xp,
      xpToNext: actor.xpToNext,
      scrap: actor.scrap,
      wits: actor.wits,
      presence: actor.presence,
      spirit: actor.spirit,
      might: actor.might,
      grace: actor.grace,
      unlockedAbilities: actor.unlockedAbilities.slice(),
      equipment: clone(actor.equipment),
    };
  }

  function actorSnapshot(actor) {
    return {
      id: actor.id,
      name: actor.name,
      roleId: actor.roleId,
      roleLabel: actor.roleLabel,
      roleCanonStatus: actor.roleCanonStatus,
      actionIds: actor.actionIds.slice(),
      temporary: actor.temporary,
      vit: actor.vit,
      maxVit: actor.maxVit,
      echoes: clone(actor.echoes),
      aether: clone(actor.aether),
      heat: clone(actor.heat),
      staffCharges: actor.staffCharges,
      maxStaffCharges: actor.maxStaffCharges,
      level: actor.level,
      xp: actor.xp,
      xpToNext: actor.xpToNext,
      scrap: actor.scrap,
      unlockedAbilities: actor.unlockedAbilities.slice(),
      equipment: clone(actor.equipment),
      nextRollBonus: actor.nextRollBonus,
      nextHitReduction: actor.nextHitReduction,
    };
  }

  function stateSnapshot(state) {
    const active = state.activeActorId === 'enemy'
      ? state.actors[0]
      : actorById(state, state.activeActorId);
    const actions = active && active.id === 'ender'
      ? abilityDefs.createRuntimeActions()
      : (active ? active.actionIds.map(id => Object.assign({}, abilityDefs.DEFS[id])) : []);
    const eligibleActionIds = active ? abilityDefs.getPartyEligibleActionIds(active) : [];
    const actionUseEligibility = Object.fromEntries(actions.map(action => [
      action.id,
      abilityDefs.getPartyUseEligibility(active, action.id),
    ]));
    return {
      schemaVersion: state.schemaVersion,
      turn: state.turn,
      round: state.round,
      player: compatibilityPlayer(active),
      party: state.actors.map(actorSnapshot),
      actors: state.actors.map(actorSnapshot),
      activeActorId: state.activeActorId,
      turnOrder: state.turnOrder.slice(),
      turnIndex: state.turnIndex,
      enemy: clone(state.enemy),
      log: state.log.slice(),
      encounterOver: state.encounterOver,
      actions,
      eligibleActionIds,
      usableActionIds: active ? abilityDefs.getPartyUsableActionIds(active) : [],
      actionUseEligibility,
      secondaryAvailable: Boolean(state._secondaryAvailable),
      lastAbilityId: state._lastAbilityId || null,
      lastRoll: state.lastRoll ? clone(state.lastRoll) : null,
      lastOutcome: state.lastOutcome || null,
      lastEffects: state.lastEffects ? clone(state.lastEffects) : [],
      resolverMutations: state.resolverMutations,
      airship: clone(state.airship),
      writtenBack: Boolean(state.writtenBack),
    };
  }

  function createEncounter(options) {
    options = options || {};
    const activeParty = options.activeParty;
    if (!Array.isArray(activeParty) || activeParty.length !== 3) {
      throw new Error('ACTIVE_PARTY_MUST_HAVE_3_ACTORS');
    }
    if (activeParty.map(character => character && character.id).join('|') !== ACTOR_ORDER.join('|')) {
      throw new Error('ACTIVE_PARTY_ID_ORDER_INVALID');
    }

    const state = {
      schemaVersion: 1,
      actors: ACTOR_ORDER.map((id, index) => makeActor(activeParty[index], kits.actors[id])),
      activeActorId: 'ender',
      turnOrder: TURN_ORDER.slice(),
      turnIndex: 0,
      round: 1,
      turn: 0,
      enemy: normalizeEnemy(options.enemy),
      log: [],
      encounterOver: false,
      resolverMutations: 0,
      lastRoll: null,
      lastOutcome: null,
      lastEffects: [],
      nextHitReduction: 0,
      airship: airshipBridge.createCombatModifiers(options.airshipTransfer || null),
      writtenBack: false,
      _airshipTransferApplied: false,
      _rng: normalizeRng(options.rng),
      _secondaryAvailable: false,
      _lastAbilityId: null,
    };
    validate(state);
    return state;
  }

  function applyInitOptions(state, options) {
    options = options || {};
    const actor = state.actors[0];
    if (options.vit != null) actor.vit = options.vit;
    if (options.scrap != null) actor.scrap = options.scrap;
    if (options.aether != null) actor.aether = resource(options.aether, actor.aether.current, actor.aether.max);
    if (options.heat != null) actor.heat = resource(options.heat, actor.heat.current, actor.heat.max);
    if (options.echoes != null) actor.echoes = resource(options.echoes, actor.echoes.current, actor.echoes.max);
    if (options.charges != null || options.staffCharges != null) {
      actor.staffCharges = options.charges ?? options.staffCharges;
    }
    if (options.staffMax != null) actor.maxStaffCharges = options.staffMax;
    if (options.level != null) actor.level = options.level;
    if (options.xp != null) actor.xp = options.xp;
    if (options.xpToNext != null) actor.xpToNext = options.xpToNext;
    if (Array.isArray(options.unlockedAbilities)) actor.unlockedAbilities = options.unlockedAbilities.slice();
    if (options.equipment) actor.equipment = clone(options.equipment);
    state.enemy = normalizeEnemy(null);
    state.activeActorId = 'ender';
    state.turnIndex = 0;
    state.turn = 0;
    state.round = 1;
    state.log = [];
    state.encounterOver = false;
    state.resolverMutations = 0;
    state._secondaryAvailable = false;
    state._lastAbilityId = null;
    validate(state);
  }

  function createController(options) {
    options = options || {};
    let state = null;
    const p = options.p || null;
    const controller = {
      init(initOptions) {
        const merged = Object.assign({}, options, initOptions || {});
        state = createEncounter({
          activeParty: merged.party || merged.activeParty,
          enemy: DEFAULT_ENEMIES.skyPredator,
          rng: merged.rng,
        });
        applyInitOptions(state, merged);
        return true;
      },
      beginEncounter(enemy) {
        if (!state) this.init({});
        state.enemy = normalizeEnemy(enemy);
        state.activeActorId = 'ender';
        state.turnIndex = 0;
        state.turn = 0;
        state.round = 1;
        state.encounterOver = false;
        state.log = [];
        state.lastRoll = null;
        state.lastOutcome = null;
        state.lastEffects = [];
        state.resolverMutations = 0;
        state._secondaryAvailable = false;
        state._lastAbilityId = null;
        log(state, 'Combat initialized. The weave awaits.');
        log(state, 'Encounter: ' + state.enemy.name + ' — ' + state.enemy.goal);
        log(state, state.enemy.name + ' weakness: ' + state.enemy.weakness);
        return true;
      },
      resolveTurn(actionId, actionOptions) {
        if (!state) return false;
        const result = resolveAction(state, actionId, actionOptions);
        return result.accepted ? result : false;
      },
      resolvePartyAction(actionId, actionOptions) {
        return this.resolveTurn(actionId, actionOptions);
      },
      resolveSecondaryAction() {
        if (!state || !state._secondaryAvailable || !state._lastAbilityId) return false;
        const actionId = state._lastAbilityId;
        state._secondaryAvailable = false;
        const result = resolveAction(state, actionId);
        state._secondaryAvailable = false;
        return result.accepted;
      },
      awardXP(amount) {
        if (!state) return false;
        const actor = state.actors[0];
        actor.xp += amount;
        log(state, '+' + amount + ' XP');
        if (actor.xp >= actor.xpToNext) {
          actor.xp -= actor.xpToNext;
          actor.level += 1;
          actor.xpToNext = Math.floor(50 * Math.pow(1.5, actor.level - 1));
          if (actor.echoes.max < 6) actor.echoes.max += 1;
          const unlocks = rootProgressionUnlocks();
          unlocks.forEach(unlock => {
            if (!actor.unlockedAbilities.includes(unlock.abilityId)) {
              actor.unlockedAbilities.push(unlock.abilityId);
              log(state, unlock.log);
            }
          });
          log(state, '── LEVEL UP! You are now level ' + actor.level + '. Choose a stat to increase. ──');
        }
        return true;
      },
      getAether() {
        return state ? clone(state.actors[0].aether) : { current: 0, max: 0 };
      },
      getCharges() {
        return state ? { current: state.actors[0].staffCharges, max: state.actors[0].maxStaffCharges } : { current: 0, max: 0 };
      },
      getEchoes() {
        return state ? clone(state.actors[0].echoes) : { current: 0, max: 0 };
      },
      getScrap() {
        return state ? state.actors[0].scrap : 0;
      },
      getLevel() {
        return state ? state.actors[0].level : 1;
      },
      getXP() {
        return state ? { current: state.actors[0].xp, toNext: state.actors[0].xpToNext } : { current: 0, toNext: 50 };
      },
      roll2d6() {
        if (!state) return 0;
        return die(state) + die(state);
      },
      roll2d6Plus(stat) {
        if (!state) return { dice: 0, stat: 0, total: 0, outcome: 'failure' };
        return roll2d6(state, stat);
      },
      getState() {
        if (!state) return null;
        return stateSnapshot(state);
      },
      writeBack() {
        if (!state) return false;
        return writeBack(state);
      },
      handleInput() {},
      drawCombatScene() {
        if (!p || typeof p.text !== 'function' || !state) return;
        const active = state.activeActorId === 'enemy' ? 'ENEMY' : state.activeActorId.toUpperCase();
        p.push();
        p.fill(232, 220, 198, 220);
        p.textSize(12);
        p.text('ACTIVE: ' + active + '   NEXT: ' + state.turnOrder[(state.turnIndex + 1) % state.turnOrder.length].toUpperCase(), 250, 78);
        p.text('ROSTER  ' + state.actors.map(actor => actor.id.toUpperCase() + ' ' + actor.vit + '/' + actor.maxVit).join('   '), 250, 98);
        p.text('ROLL  ' + (state.lastRoll ? state.lastRoll.total + ' · ' + state.lastOutcome : '—') +
          '   EFFECTS  ' + (state.lastEffects.length ? state.lastEffects.map(effect => effect.kind).join(', ') : '—'), 250, 118);
        p.pop();
      },
    };

    function rootProgressionUnlocks() {
      const root = typeof window !== 'undefined' ? window : null;
      if (root && root.AetherProgressionDefs &&
          typeof root.AetherProgressionDefs.getUnlocksForLevel === 'function') {
        return root.AetherProgressionDefs.getUnlocksForLevel(state.actors[0].level);
      }
      return state.actors[0].level === 3
        ? [{ abilityId: 'windWard', log: '── LEVEL 3: Wind Ward unlocked! ──' }]
        : [];
    }

    return controller;
  }

  return Object.freeze({
    ACTOR_ORDER,
    TURN_ORDER,
    DEFAULT_ENEMIES,
    createEncounter,
    createController,
    resolveAction,
    validate,
    writeBack,
  });
});
