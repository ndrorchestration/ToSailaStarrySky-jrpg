const assert = require('node:assert/strict');

const { loadBrowserModule } = require('./first-wake-test-helpers');

function loadCombat() {
  const kitsContext = loadBrowserModule('modules/first-wake-kits.js');
  const defsContext = loadBrowserModule('modules/ability-defs.js');
  const bridgeContext = loadBrowserModule('modules/airship-combat-bridge.js');
  const combatContext = loadBrowserModule('modules/party-combat.js', {
    AetherFirstWakeKits: kitsContext.AetherFirstWakeKits,
    AetherAbilityDefs: defsContext.AetherAbilityDefs,
    AetherAirshipCombatBridge: bridgeContext.AetherAirshipCombatBridge,
  });
  return {
    kits: kitsContext.AetherFirstWakeKits,
    defs: defsContext.AetherAbilityDefs,
    bridge: bridgeContext.AetherAirshipCombatBridge,
    combat: combatContext.AetherPartyCombat,
  };
}

function activeParty() {
  return [
    {
      id: 'ender',
      name: 'Ender',
      roleId: 'reader',
      roleCanonStatus: 'provisional',
      runtimeImplemented: true,
      vit: 13,
      maxVit: 13,
      echoes: 3,
      echoesMax: 3,
      aether: 4,
      aetherMax: 6,
      heat: 1,
      heatMax: 3,
      staffCharges: 2,
      maxStaffCharges: 2,
      level: 1,
      xp: 0,
      xpToNext: 50,
      scrap: 7,
      wits: 2,
      presence: 1,
      spirit: 1,
      might: -1,
      grace: 0,
      unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
    },
    {
      id: 'lyra',
      name: 'Lyra',
      roleId: 'receiver',
      roleCanonStatus: 'provisional',
      runtimeImplemented: false,
      vit: null,
      maxVit: null,
      unlockedAbilities: [],
    },
    {
      id: 'ionia',
      name: 'Ionia',
      roleId: 'anchor',
      roleCanonStatus: 'provisional',
      runtimeImplemented: false,
      vit: null,
      maxVit: null,
      unlockedAbilities: [],
    },
  ];
}

function enemy() {
  return {
    id: 'test-shear',
    name: 'Test Shear',
    hp: 20,
    maxHp: 20,
    might: 1,
    type: 'windShear',
    ability: 'galeForce',
  };
}

function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

function run() {
  const { kits, defs, combat } = loadCombat();

  assert.equal(combat.canBeginEncounter('skyPredator'), true);
  assert.equal(combat.canBeginEncounter('not-an-enemy'), false);
  assert.equal(kits.version, 1);
  assert.deepEqual(Object.keys(kits.roles), ['reader', 'receiver', 'anchor']);
  assert.deepEqual(Array.from(kits.actors.ender.actionIds), [
    'staffStrike', 'uncoverTruth', 'sharedDream', 'mycelialLedger', 'hold',
  ]);
  assert.deepEqual(Array.from(kits.actors.lyra.actionIds), ['frequencyRead', 'echoRedirect', 'hold']);
  assert.deepEqual(Array.from(kits.actors.ionia.actionIds), ['braceTheWake', 'routeCommand', 'hold']);

  assert.equal(defs.PARTY_ACTION_ORDER.includes('frequencyRead'), true);
  assert.equal(defs.PARTY_ACTION_ORDER.includes('braceTheWake'), true);
  assert.equal(defs.ACTION_ORDER.length, 8);
  assert.equal(defs.createRuntimeActions().length, 8);

  const party = activeParty();
  const before = plain(party);
  const state = combat.createEncounter({
    activeParty: party,
    enemy: enemy(),
    rng: () => 6,
  });

  assert.equal(combat.validate(state), true);
  assert.deepEqual(Array.from(state.actors, actor => actor.id), ['ender', 'lyra', 'ionia']);
  assert.deepEqual(Array.from(state.actors, actor => actor.roleId), ['reader', 'receiver', 'anchor']);
  assert.deepEqual(Array.from(state.turnOrder), ['ender', 'lyra', 'ionia', 'enemy']);
  assert.equal(state.activeActorId, 'ender');
  assert.strictEqual(state.actors[0].character, party[0]);
  assert.notStrictEqual(state.actors[0], party[0]);
  assert.equal(state.actors[1].temporary, true);

  const rejectedWrongActor = combat.resolveAction(state, 'frequencyRead');
  assert.equal(rejectedWrongActor.accepted, false);
  assert.equal(rejectedWrongActor.reason, 'not_active_actor');
  assert.equal(state.turnIndex, 0);
  assert.deepEqual(plain(party), before);

  const enderAction = combat.resolveAction(state, 'staffStrike');
  assert.equal(enderAction.accepted, true);
  assert.equal(state.activeActorId, 'lyra');
  assert.equal(state.turnIndex, 1);

  const lyraBefore = state.actors[1].echoes.current + state.actors[1].aether.current;
  const lyraAction = combat.resolveAction(state, 'frequencyRead');
  assert.equal(lyraAction.accepted, true);
  assert.equal(state.enemy.revealed, true);
  assert.equal(state.activeActorId, 'ionia');
  assert.equal(state.actors[1].echoes.current + state.actors[1].aether.current, lyraBefore - 2);

  const ioniaAction = combat.resolveAction(state, 'braceTheWake');
  assert.equal(ioniaAction.accepted, true);
  assert.equal(state.activeActorId, 'ender');
  assert.equal(state.turnIndex, 0);
  assert.equal(state.log.some(line => line.toLowerCase().includes('enemy turn')), true);

  state.actors[0].vit -= 1;
  state.actors[1].vit -= 1;
  assert.deepEqual(plain(party), before);
  assert.equal(combat.writeBack(state), true);
  assert.strictEqual(state.actors[0].character, party[0]);
  assert.equal(party[0].vit, state.actors[0].vit);
  assert.equal(party[1].vit, state.actors[1].vit);

  const emptyResourceState = combat.createEncounter({
    activeParty: party,
    enemy: enemy(),
    rng: () => 6,
  });
  combat.resolveAction(emptyResourceState, 'hold');
  emptyResourceState.actors[1].echoes.current = 0;
  emptyResourceState.actors[1].aether.current = 0;
  const beforeRejected = plain(emptyResourceState);
  const rejectedCost = combat.resolveAction(emptyResourceState, 'frequencyRead');
  assert.equal(rejectedCost.accepted, false);
  assert.equal(rejectedCost.reason, 'insufficient_resources');
  assert.equal(emptyResourceState.turnIndex, 1);
  assert.deepEqual(
    plain([emptyResourceState.actors[1].echoes, emptyResourceState.actors[1].aether]),
    [beforeRejected.actors[1].echoes, beforeRejected.actors[1].aether]
  );

  assert.throws(
    () => combat.createEncounter({ activeParty: party.slice(0, 2), enemy: enemy() }),
    /ACTIVE_PARTY_MUST_HAVE_3_ACTORS/
  );

  const controller = combat.createController({ party: activeParty() });
  controller.init({
    party: activeParty(),
    airshipTransfer: {
      shipId: 'aureate-wake',
      classId: 'dragonfly-wake',
      shieldMode: 'slip',
      phaseSlipReady: true,
      resonanceLanceDamage: 24,
    },
  });
  const invalidBefore = plain(controller.getState());
  const invalidEncounter = controller.beginEncounter('not-an-enemy');
  assert.equal(invalidEncounter.ok, false);
  assert.deepEqual(plain(controller.getState()), invalidBefore);

  const validEncounter = controller.beginEncounter('skyPredator');
  assert.equal(validEncounter.ok, true);
  const opened = controller.getState();
  assert.equal(opened.enemy.hp, 9);
  assert.equal(opened.airship.classId, 'dragonfly-wake');
  assert.equal(opened.airship.phaseSlipReady, true);
  assert.equal(opened.log.some(line => line.includes('Resonance Lance opens the encounter')), true);

  controller.resolveTurn('hold');
  controller.resolveTurn('hold');
  const beforeIonia = controller.getState();
  controller.resolveTurn('hold');
  const afterRound = controller.getState();
  assert.equal(afterRound.turn, 3);
  assert.equal(afterRound.party[0].vit, beforeIonia.party[0].vit);
  assert.equal(afterRound.airship.phaseSlipReady, false);
  assert.equal(afterRound.log.some(line => line.includes('Phase-Slip caught the incoming strike')), true);

  console.log('First Wake combat contract: 33/33 passed');
}

run();
