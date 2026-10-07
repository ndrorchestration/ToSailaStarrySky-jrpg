'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const saveBase = require('../modules/save-system.js');
const validator = require('../modules/save-payload-validator.js');
const air = require('../modules/air-navigation.js');
const routeNetwork = require('../modules/route-network-state.js');

function loadBrowserModule(file, windowObject) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  const context = vm.createContext({
    window: windowObject,
    globalThis: windowObject,
    console,
    JSON,
    Math,
    Object,
    Array,
    Number,
    String,
    Boolean,
    Set,
    Map,
    Date,
  });
  new vm.Script(source, { filename: file }).runInContext(context);
}

const windowObject = {};
windowObject.AetherwakeCharacterMagicProfile = {
  createProfile(characterId) {
    return {
      characterId,
      affinityStatus: 'provisional',
      mastery: { trees: {}, domains: {} },
      learnedSpells: [],
    };
  },
  validateProfile(profile) {
    if (!profile || typeof profile.characterId !== 'string') {
      throw new Error('TEST_MAGIC_PROFILE_INVALID');
    }
    return profile;
  },
};

loadBrowserModule('modules/jrpg-stat-model.js', windowObject);
loadBrowserModule('modules/party-state.js', windowObject);
loadBrowserModule('modules/world.js', windowObject);

assert(windowObject.AetherJRPGStatModel, 'production JRPG stat model did not load');
assert(windowObject.AetherPartyState, 'actual party-state module did not load');
assert(windowObject.AetherWorld, 'actual world module did not load');

const world = windowObject.AetherWorld(null, null);
world.init();
windowObject.AetherPartyState.bootstrap(world.player);

const storageMap = new Map();
const save = saveBase._createForTesting({
  localStorage: {
    setItem(k, v) { storageMap.set(k, String(v)); },
    getItem(k) { return storageMap.has(k) ? storageMap.get(k) : null; },
    removeItem(k) { storageMap.delete(k); },
  },
});

let airState = air.createState({ mooredLandmarkId: 'wake-dock', speed: 0 });
let routeState = routeNetwork.createState();

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function buildPayload() {
  const snapshot = world.snapshotPersistentState();
  const payload = {
    runtime: {
      scene: 'world',
      dayTime: snapshot.runtime.dayTime,
      skyLayerVisible: snapshot.runtime.skyLayerVisible,
      playtimeMs: 1234,
    },
    world: snapshot.world,
    quest: snapshot.quest,
    party: {
      roster: windowObject.ROSTER.map(clone),
      activeIds: windowObject.ACTIVE_PARTY.map(character => character.id),
    },
    airNavigation: air.exportPersistentState(airState),
    routeNetwork: routeNetwork.exportPersistentState(routeState),
  };
  validator.validatePayload(payload, {
    validateAirNavigation(candidate) {
      return air.validatePersistentState(candidate);
    },
    validateRouteNetwork(candidate) {
      return routeNetwork.validatePersistentState(candidate);
    },
  });
  return payload;
}

function prepareEnvelope(envelope) {
  const payload = clone(envelope.payload);
  validator.validatePayload(payload, {
    validateAirNavigation(candidate) {
      return air.validatePersistentState(candidate);
    },
    validateRouteNetwork(candidate) {
      return routeNetwork.validatePersistentState(candidate);
    },
  });

  const preparedWorld = world.preparePersistentState(payload.world, payload.quest);
  const preparedRoster = payload.party.roster.map((record, index) => {
    const target = windowObject.ROSTER[index];
    assert(target && target.id === record.id, 'SAVE_PARTY_IDENTITY_MISMATCH');
    return clone(record);
  });
  const preparedAir = payload.airNavigation
    ? air.restorePersistentState(payload.airNavigation)
    : null;
  const preparedRoute = routeNetwork.restorePersistentState(payload.routeNetwork);

  return {
    payload,
    preparedWorld,
    preparedRoster,
    preparedActiveIds: payload.party.activeIds.slice(),
    preparedAir,
    preparedRoute,
  };
}

function applyEnvelope(envelope) {
  const prepared = prepareEnvelope(envelope);

  prepared.preparedRoster.forEach((record, index) => {
    Object.assign(windowObject.ROSTER[index], clone(record));
  });
  windowObject.AetherPartyState.setActivePartyIds(prepared.preparedActiveIds);
  windowObject.AetherPartyState.validate();

  world.restorePersistentState(prepared.preparedWorld, prepared.payload.runtime);
  airState = prepared.preparedAir;
  routeState = prepared.preparedRoute;
}

const before = {
  world: clone(world.snapshotPersistentState()),
  roster: windowObject.ROSTER.map(clone),
  activeIds: windowObject.ACTIVE_PARTY.map(character => character.id),
  air: air.exportPersistentState(airState),
  route: routeNetwork.exportPersistentState(routeState),
};

const saved = save.save('manual-1', buildPayload(), {
  gameVersion: '0.1.0-preview.1',
  playtimeMs: 1234,
  chapter: 'Preview 0.1 — First Wake',
  location: 'Aureate Wake',
  partySummary: ['Ender'],
});
assert(saved && saved.envelope && saved.envelope.slot === 'manual-1');

// Deliberately mutate independent live owners after save.
world.player.tileX = 2;
world.player.tileY = 3;
world.player.px = 32;
world.player.py = 48;
windowObject.ROSTER[0].scrap = (windowObject.ROSTER[0].scrap || 0) + 77;
airState = air.createState({
  x: 21,
  y: 13,
  altitude: 'high',
  speed: 2,
  mooredLandmarkId: null,
});
routeState = routeNetwork.setCondition(routeState, 'rootline-west', 'shifted');

assert.notStrictEqual(windowObject.ROSTER[0].scrap, before.roster[0].scrap);
assert.strictEqual(world.player.tileX, 2);
assert.strictEqual(airState.x, 21);
assert.strictEqual(routeNetwork.conditionFor(routeState, 'rootline-west'), 'shifted');

const loaded = save.load('manual-1');
assert(loaded && loaded.envelope, 'manual-1 could not be reloaded');
applyEnvelope(loaded.envelope);

const after = {
  world: clone(world.snapshotPersistentState()),
  roster: windowObject.ROSTER.map(clone),
  activeIds: windowObject.ACTIVE_PARTY.map(character => character.id),
  air: air.exportPersistentState(airState),
  route: routeNetwork.exportPersistentState(routeState),
};

assert.deepStrictEqual(after.world, before.world,
  'actual world snapshot/restore authority did not round-trip');
assert.deepStrictEqual(after.roster, before.roster,
  'actual canonical party records did not round-trip');
assert.deepStrictEqual(after.activeIds, before.activeIds,
  'actual party-state active IDs did not round-trip');
assert.deepStrictEqual(after.air, before.air,
  'actual air-navigation persistence did not round-trip');
assert.deepStrictEqual(after.route, before.route,
  'actual route-network persistence did not round-trip');

// Bind the executable subsystem proof back to the production coordinator.
const runtimeSource = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
for (const expected of [
  'world.snapshotPersistentState()',
  'window.AetherSaveSystem.save(',
  '{ preserveBackup }',
  'prepareSaveEnvelopeForApply(loaded.envelope);',
  'applySaveEnvelope(loaded.envelope);',
  'world.restorePersistentState(prepared.preparedWorld, payload.runtime);',
  'window.AetherPartyState.setActivePartyIds(prepared.preparedActiveIds);',
  'window.AetherAirNavigation.restorePersistentState(payload.airNavigation)',
  'window.AetherRouteNetworkState.restorePersistentState(',
  'payload.routeNetwork',
]) {
  assert(runtimeSource.includes(expected),
    'production persistence coordinator lost binding: ' + expected);
}

console.log('Aetherwake deterministic persistence round trip: PASS');
