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
assert(document.schemaVersion === 1, 'save schema version is incorrect');
assert(document.savedAt === fixedTime, 'save timestamp injection failed');
assert(document.partyState.roster.length === 5, 'save roster length is incorrect');
assert(document.partyState.activePartyIds.join('|') === 'ender|lyra|ionia',
  'save active-party IDs are incorrect');

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
const storageResult = saveState.saveToStorage(fakeStorage, { now: fixedTime });
assert(storageResult.ok === true, 'saveToStorage did not succeed');
assert(storageData.has(saveState.storageKey), 'save was not written to storage');

roster[0].scrap = 999;
roster[1].vit = 1;
const loadResult = saveState.loadFromStorage(fakeStorage);
assert(loadResult.ok === true, 'loadFromStorage did not succeed');
assert(roster[0].scrap === savedScrap, 'lead resource state did not restore');
assert(roster[1].vit === savedLyraVit, 'Lyra persistent state did not restore');
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

const future = saveState.createDocument({ now: fixedTime });
future.schemaVersion = 2;
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
const missing = saveState.loadFromStorage(fakeStorage);
assert(missing.ok === false && missing.reason === 'SAVE_NOT_FOUND',
  'missing save should return an explicit not-found result');

assert(Array.isArray(saveState.migrationVersions) && saveState.migrationVersions.length === 0,
  'schema v1 should not claim nonexistent legacy migrations');

console.log('Aetherwake save-state contract: PASS');
