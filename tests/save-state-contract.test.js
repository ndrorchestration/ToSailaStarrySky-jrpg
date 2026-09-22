const fs = require('fs');
const path = require('path');
const vm = require('vm');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function expectThrow(fn, expected, message) {
  let thrown = null;
  try {
    fn();
  } catch (error) {
    thrown = error;
  }
  assert(thrown, message + ' (did not throw)');
  assert(String(thrown.message).includes(expected),
    message + ' (unexpected error: ' + thrown.message + ')');
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

const root = path.join(__dirname, '..');
const partySrc = fs.readFileSync(path.join(root, 'modules', 'party-state.js'), 'utf8');
const saveSrc = fs.readFileSync(path.join(root, 'modules', 'save-state.js'), 'utf8');

const storageData = new Map();
const fakeStorage = {
  getItem(key) {
    return storageData.has(key) ? storageData.get(key) : null;
  },
  setItem(key, value) {
    storageData.set(key, String(value));
  },
  removeItem(key) {
    storageData.delete(key);
  },
};

const sandbox = {
  window: { localStorage: fakeStorage },
  console,
  Date,
  JSON,
};
vm.createContext(sandbox);
vm.runInContext(partySrc, sandbox, { filename: 'modules/party-state.js' });
vm.runInContext(saveSrc, sandbox, { filename: 'modules/save-state.js' });

const partyState = sandbox.window.AetherPartyState;
const saveState = sandbox.window.AetherSaveState;
assert(partyState && saveState, 'save/party modules were not exposed');

let worldRuntimeState = {
  version: 1,
  playerPosition: { tileX: 4, tileY: 19 },
  dayTime: 0.25,
  skyLayerVisible: false,
  quest: {
    state: 'signal',
    signalHookDoneIds: [],
    crossingHazardDoneIds: [],
    npcsMet: [],
    choiceMade: null,
    choiceVariant: null,
    choicePath: null,
    hullIntegrity: 100,
    morale: 50,
    heatLevel: 1,
    engineIntegration: 0,
    wakeEpilogueId: null,
    discoveries: [],
    journal: [{ state: 'signal', text: 'The Wake rings hollow.' }],
  },
  ledgerEntries: [{ type: 'start', text: 'The ledger opens.' }],
};

let airshipRuntimeState = {
  version: 1,
  power: 6,
  hull: 100,
  phaseIntegrity: 100,
  shieldMode: 'guard',
  driveCharges: 3,
  lanceCharges: 2,
  tetherCharges: 2,
  forgeCharges: 2,
  heat: 0,
  targetIntegrity: 100,
  pendingCombat: { phaseSlip: false, resonanceLanceDamage: 0 },
  cooldowns: {
    phaseSlip: 0,
    resonanceLance: 0,
    rootlineTether: 0,
    patternForge: 0,
  },
};


let airNavigationRuntimeState = {
  version: 1,
  x: 17,
  y: 15,
  altitude: 'cruise',
  heading: 0.5,
  speed: 2,
  discovered: ['wake-dock','verdant-crown'],
  discoveredRoutes: ['rootline-west'],
  mooredLandmarkId: null,
  encounterSteps: 3,
  encounterSeed: 4,
};

let airNavigationRestoreCount = 0;

function validateAirNavigationFixture(payload) {
  if (!payload || payload.version !== 1 ||
      !Number.isFinite(payload.x) ||
      !Array.isArray(payload.discoveredRoutes)) {
    throw new Error('TEST_AIR_NAV_STATE_INVALID');
  }
  return true;
}

let worldRestoreCount = 0;
let airshipRestoreCount = 0;

function validateWorldFixture(payload) {
  if (!payload || payload.version !== 1 ||
      !payload.playerPosition || !Number.isInteger(payload.playerPosition.tileX)) {
    throw new Error('TEST_WORLD_STATE_INVALID');
  }
  return true;
}

function validateAirshipFixture(payload) {
  if (!payload || payload.version !== 1 ||
      typeof payload.shieldMode !== 'string') {
    throw new Error('TEST_AIRSHIP_STATE_INVALID');
  }
  return true;
}

sandbox.window.AetherRuntimePersistence = {
  exportWorldState() {
    return clone(worldRuntimeState);
  },
  validateWorldState(payload) {
    return validateWorldFixture(payload);
  },
  restoreWorldState(payload) {
    validateWorldFixture(payload);
    worldRuntimeState = clone(payload);
    worldRestoreCount++;
    return clone(worldRuntimeState);
  },
  exportAirshipState() {
    return clone(airshipRuntimeState);
  },
  validateAirshipState(payload) {
    return validateAirshipFixture(payload);
  },
  restoreAirshipState(payload) {
    validateAirshipFixture(payload);
    airshipRuntimeState = clone(payload);
    airshipRestoreCount++;
    return clone(airshipRuntimeState);
  },
  exportAirNavigationState() {
    return clone(airNavigationRuntimeState);
  },
  validateAirNavigationState(payload) {
    return validateAirNavigationFixture(payload);
  },
  restoreAirNavigationState(payload) {
    validateAirNavigationFixture(payload);
    airNavigationRuntimeState = clone(payload);
    airNavigationRestoreCount++;
    return clone(airNavigationRuntimeState);
  },
};

const worldPlayer = {};
partyState.bootstrap(worldPlayer);

const prototypeParty = [
  {
    name: 'Young Ender',
    class: 'Rift Scholar + Dreamwright',
    jobId: 'ender',
    vit: 13, maxVit: 13,
    echoes: { current: 3, max: 3 },
    wits: 2, presence: 1, spirit: 1, might: -1, grace: 0,
    scrap: 7,
    aether: { current: 4, max: 6 },
    heat: { current: 1, max: 3 },
    staffCharges: 2, maxStaffCharges: 2,
    level: 1, xp: 0, xpToNext: 50,
    unlockedAbilities: ['uncoverTruth'],
    equipment: { staff: null, backpack: null },
  },
  {
    name: 'Lyra',
    class: 'Sky-Sailor',
    jobId: 'skySailor',
    mechanicsTemplateId: 'skySailor',
    mechanicsTemplateName: 'Sky-Sailor',
    synergyBonus: 'temporary',
    vit: 10, maxVit: 10,
    echoes: { current: 2, max: 3 },
    wits: 1, presence: 0, spirit: 1, might: -1, grace: 2,
    scrap: 5,
    aether: { current: 3, max: 6 },
    heat: { current: 0, max: 3 },
    staffCharges: 1, maxStaffCharges: 2,
    level: 1, xp: 0, xpToNext: 50,
    unlockedAbilities: ['windShearDance'],
    equipment: { staff: null, backpack: null },
  },
  {
    name: 'Ionia',
    class: 'Aether-Weaver',
    jobId: 'aetherWeaver',
    mechanicsTemplateId: 'aetherWeaver',
    mechanicsTemplateName: 'Aether-Weaver',
    synergyBonus: 'temporary',
    vit: 9, maxVit: 9,
    echoes: { current: 3, max: 3 },
    wits: 1, presence: 1, spirit: 2, might: -2, grace: 0,
    scrap: 5,
    aether: { current: 3, max: 6 },
    heat: { current: 0, max: 3 },
    staffCharges: 1, maxStaffCharges: 2,
    level: 1, xp: 0, xpToNext: 50,
    unlockedAbilities: ['spiritThread'],
    equipment: { staff: null, backpack: null },
  },
];

partyState.commitPrototypeParty(prototypeParty);
const roster = sandbox.window.ROSTER;
const active = sandbox.window.ACTIVE_PARTY;

const leadRef = roster[0];
const lyraRef = roster[1];
const activeArrayRef = active;

roster[0].encounterStatus = 'TRANSIENT_DO_NOT_SAVE';
roster[1].temporaryCombatBuff = 99;

const fixedTime = '2026-09-20T12:00:00.000Z';
const document = saveState.createDocument({ now: fixedTime });

assert(document.kind === 'aetherwake-save', 'save kind is incorrect');
assert(document.schemaVersion === 3, 'save schema version is incorrect');
assert(document.savedAt === fixedTime, 'save timestamp injection failed');
assert(document.partyState.roster.length === 5, 'save roster length is incorrect');
assert(document.partyState.activePartyIds.join('|') === 'ender|lyra|ionia',
  'save active-party IDs are incorrect');
assert(document.worldState.version === 1 &&
  document.worldState.playerPosition.tileX === 4,
  'World subsystem payload was not captured');
assert(document.airshipState.version === 1 &&
  document.airshipState.shieldMode === 'guard',
  'Dragonfly subsystem payload was not captured');
assert(document.airNavigationState.version === 1 &&
  document.airNavigationState.discoveredRoutes[0] === 'rootline-west',
  'Air-navigation subsystem payload was not captured');

for (const record of document.partyState.roster) {
  assert(!Object.prototype.hasOwnProperty.call(record, 'canonicalName'),
    'canonicalName must remain code-owned, not save-owned');
  assert(!Object.prototype.hasOwnProperty.call(record, 'nativeJob'),
    'nativeJob must remain code-owned, not save-owned');
  assert(!Object.prototype.hasOwnProperty.call(record, 'encounterStatus'),
    'encounter-local state leaked into save');
  assert(!Object.prototype.hasOwnProperty.call(record, 'temporaryCombatBuff'),
    'temporary combat state leaked into save');
}

const savedScrap = roster[0].scrap;
const savedLyraVit = roster[1].vit;
const savedWorld = clone(worldRuntimeState);
const savedAirship = clone(airshipRuntimeState);
const savedAirNavigation = clone(airNavigationRuntimeState);

const storageResult = saveState.saveToStorage(fakeStorage, { now: fixedTime });
assert(storageResult.ok === true, 'saveToStorage did not succeed');
assert(storageData.has(saveState.storageKey), 'v3 save was not written to current storage key');

roster[0].scrap = 999;
roster[1].vit = 1;
worldRuntimeState.playerPosition.tileX = 20;
worldRuntimeState.quest.hullIntegrity = 1;
airshipRuntimeState.power = 0;
airshipRuntimeState.shieldMode = 'slip';
airNavigationRuntimeState.x = 41;
airNavigationRuntimeState.discoveredRoutes = [];

const loadResult = saveState.loadFromStorage(fakeStorage);
assert(loadResult.ok === true && loadResult.migrated === false,
  'current v2 load did not succeed as a non-migration');
assert(roster[0].scrap === savedScrap, 'lead resource state did not restore');
assert(roster[1].vit === savedLyraVit, 'Lyra persistent state did not restore');
assert(JSON.stringify(worldRuntimeState) === JSON.stringify(savedWorld),
  'World runtime state did not restore');
assert(JSON.stringify(airshipRuntimeState) === JSON.stringify(savedAirship),
  'Dragonfly runtime state did not restore');
assert(JSON.stringify(airNavigationRuntimeState) === JSON.stringify(savedAirNavigation),
  'Air-navigation runtime state did not restore');
assert(worldRestoreCount === 1 && airshipRestoreCount === 1 && airNavigationRestoreCount === 1,
  'subsystem restore adapters were not invoked exactly once');
assert(roster[0] === leadRef && roster[1] === lyraRef,
  'restore replaced canonical roster object references');
assert(sandbox.window.ACTIVE_PARTY === activeArrayRef,
  'restore replaced the canonical ACTIVE_PARTY array');
assert(sandbox.window.ACTIVE_PARTY[0] === roster[0] &&
  sandbox.window.ACTIVE_PARTY[1] === roster[1] &&
  sandbox.window.ACTIVE_PARTY[2] === roster[2],
  'restore broke active-party canonical references');
assert(worldPlayer === roster[0],
  'restore broke world-player canonical reference identity');

// Save-owned attempts to rewrite authored identity must be ignored.
const identityTamper = saveState.createDocument({ now: fixedTime });
identityTamper.partyState.roster[1].name = 'Not Lyra';
identityTamper.partyState.roster[1].canonicalName = 'Not Lyra';
identityTamper.partyState.roster[1].nativeJob = 'Invented Job';
saveState.restoreDocument(identityTamper);
assert(roster[1].name === 'Lyra' && roster[1].canonicalName === 'Lyra',
  'restore allowed authored Lyra identity to be rewritten');
assert(roster[1].nativeJob === null,
  'restore allowed unresolved canonical nativeJob to be fabricated');

const badIdentity = saveState.createDocument({ now: fixedTime });
badIdentity.partyState.roster[1].id = 'impostor';
expectThrow(() => saveState.restoreDocument(badIdentity),
  'PERSISTENT_STATE_ROSTER_IDENTITY_INVALID',
  'tampered roster identity must fail closed');

const invalidBench = saveState.createDocument({ now: fixedTime });
invalidBench.partyState.activePartyIds = ['ender', 'lyra', 'reson'];
expectThrow(() => saveState.restoreDocument(invalidBench),
  'PERSISTENT_STATE_ACTIVE_PARTY_MEMBER_NOT_IMPLEMENTED',
  'unimplemented roster shell must not become active through save data');

const missingSubsystems = saveState.createDocument({ now: fixedTime });
delete missingSubsystems.worldState;
expectThrow(() => saveState.restoreDocument(missingSubsystems),
  'SAVE_V3_SUBSYSTEM_PAYLOADS_REQUIRED',
  'v3 save missing a subsystem payload must fail closed');

const future = saveState.createDocument({ now: fixedTime });
future.schemaVersion = 4;
expectThrow(() => saveState.migrateToCurrent(future),
  'SAVE_SCHEMA_VERSION_FROM_FUTURE',
  'future save schema must fail closed');

const unversioned = saveState.createDocument({ now: fixedTime });
delete unversioned.schemaVersion;
expectThrow(() => saveState.migrateToCurrent(unversioned),
  'SAVE_SCHEMA_VERSION_REQUIRED',
  'unversioned save must fail closed');

expectThrow(() => saveState.deserialize('{not-json'),
  'SAVE_JSON_INVALID',
  'invalid JSON must fail closed');


saveState.clearStorage(fakeStorage);
const legacyV2 = clone(document);
legacyV2.schemaVersion = 2;
delete legacyV2.airNavigationState;
fakeStorage.setItem('aetherwake.save.v2', JSON.stringify(legacyV2));
const beforeV2NavRestores = airNavigationRestoreCount;
const v2Load = saveState.loadFromStorage(fakeStorage);
assert(v2Load.ok === true && v2Load.migrated === true,
  'legacy v2 save did not migrate');
assert(v2Load.document.schemaVersion === 3,
  'legacy v2 save did not migrate to schema v3');
assert(v2Load.document.airNavigationState === null,
  'v2 migration must preserve initialized air-navigation defaults');
assert(airNavigationRestoreCount === beforeV2NavRestores,
  'v2 migration must not restore absent air-navigation state');

// Real v1 -> v3 compatibility path. v1 had no World/Dragonfly/navigation payloads.
saveState.clearStorage(fakeStorage);
const legacyV1 = clone(document);
legacyV1.schemaVersion = 1;
delete legacyV1.worldState;
delete legacyV1.airshipState;
const legacyKey = saveState.legacyStorageKeys[0];
fakeStorage.setItem(legacyKey, JSON.stringify(legacyV1));

const beforeLegacyWorldRestores = worldRestoreCount;
const beforeLegacyAirshipRestores = airshipRestoreCount;
const legacyLoad = saveState.loadFromStorage(fakeStorage);
assert(legacyLoad.ok === true && legacyLoad.migrated === true,
  'legacy v1 save did not migrate');
assert(legacyLoad.sourceKey === legacyKey,
  'legacy load did not report its source key');
assert(legacyLoad.document.schemaVersion === 3,
  'legacy save did not migrate to schema v3');
assert(legacyLoad.document.worldState === null &&
  legacyLoad.document.airshipState === null &&
  legacyLoad.document.airNavigationState === null,
  'v1 migration must preserve initialized defaults for newly introduced domains');
assert(worldRestoreCount === beforeLegacyWorldRestores &&
  airshipRestoreCount === beforeLegacyAirshipRestores,
  'v1 migration must not overwrite newly introduced runtime domains');
assert(storageData.has(saveState.storageKey),
  'successful legacy migration was not copied to the v3 storage key');

saveState.clearStorage(fakeStorage);
assert(!storageData.has(saveState.storageKey) && !storageData.has(legacyKey),
  'clearStorage did not remove current and legacy save keys');
const missing = saveState.loadFromStorage(fakeStorage);
assert(missing.ok === false && missing.reason === 'SAVE_NOT_FOUND',
  'missing save should return an explicit not-found result');

assert(saveState.storageKey === 'aetherwake.save.v3',
  'current storage key does not track schema v3');
assert(saveState.legacyStorageKeys.join('|') === 'aetherwake.save.v2|aetherwake.save.v1',
  'legacy storage key registry is incorrect');
assert(saveState.migrationVersions.join('|') === '1|2',
  'schema v3 must advertise the real v1 and v2 migrations');

console.log('Aetherwake save-state v3 contract: PASS');

