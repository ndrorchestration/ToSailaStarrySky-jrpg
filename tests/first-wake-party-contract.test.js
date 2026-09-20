const assert = require('node:assert/strict');

const { loadBrowserModule } = require('./first-wake-test-helpers');

function worldPlayer() {
  return {
    name: 'Young Ender',
    age: 28,
    class: 'Rift Scholar + Dreamwright',
    vit: 13,
    maxVit: 13,
    echoes: { current: 3, max: 3 },
    wits: 2,
    presence: 1,
    spirit: 1,
    might: -1,
    grace: 0,
    scrap: 7,
    aether: { current: 4, max: 6 },
    heat: { current: 1, max: 3 },
    staffCharges: 2,
    maxStaffCharges: 2,
    level: 1,
    xp: 0,
    xpToNext: 50,
    unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
    equipment: { staff: null, backpack: null },
  };
}

function createState() {
  const player = worldPlayer();
  const context = loadBrowserModule('modules/party-state.js');
  context.AetherPartyState.bootstrap(player);
  return { context, player, state: context.AetherPartyState };
}

function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

function run() {
  const { context, player, state } = createState();
  const result = state.commitFirstWakeParty({
    storyFlags: { lyraJoined: true, ioniaJoined: true },
  });

  assert.deepEqual(
    Array.from(result.roster, character => character.id),
    ['ender', 'lyra', 'ionia', 'reson', 'aepex']
  );
  assert.deepEqual(
    Array.from(result.activeParty, character => character.id),
    ['ender', 'lyra', 'ionia']
  );
  assert.equal(result.roster[1].name, 'Lyra');
  assert.equal(result.roster[1].roleId, 'receiver');
  assert.equal(result.roster[1].roleCanonStatus, 'provisional');
  assert.equal(result.roster[1].jobId, null);
  assert.equal(result.roster[2].name, 'Ionia');
  assert.equal(result.roster[2].roleId, 'anchor');
  assert.equal(result.roster[2].roleCanonStatus, 'provisional');
  assert.equal(result.roster[2].jobId, null);
  assert.equal(result.roster[3].runtimeImplemented, false);
  assert.equal(result.roster[4].runtimeImplemented, false);
  assert.strictEqual(result.roster[0], player);
  assert.strictEqual(result.activeParty[0], result.roster[0]);
  assert.strictEqual(result.activeParty[1], result.roster[1]);
  assert.strictEqual(result.activeParty[2], result.roster[2]);
  assert.strictEqual(context.party, result.activeParty);

  const second = state.commitFirstWakeParty({
    storyFlags: { lyraJoined: true, ioniaJoined: true },
  });
  assert.strictEqual(second.roster, result.roster);
  assert.strictEqual(second.activeParty, result.activeParty);
  assert.deepEqual(Array.from(state.snapshot().activeIds), ['ender', 'lyra', 'ionia']);

  const serialized = {
    roster: plain(result.roster),
    activeIds: result.activeParty.map(character => character.id),
  };
  const hydrated = state.hydrateFirstWakeParty(serialized);
  assert.strictEqual(hydrated.roster[0], player);
  assert.strictEqual(hydrated.activeParty[1], hydrated.roster[1]);

  const beforeInvalid = plain(state.snapshot());
  assert.throws(
    () => state.hydrateFirstWakeParty({
      roster: serialized.roster,
      activeIds: ['lyra', 'ender', 'ionia'],
    }),
    /ACTIVE_PARTY_IDS_INVALID/
  );
  assert.deepEqual(plain(state.snapshot()), beforeInvalid);

  console.log('First Wake party contract: 18/18 passed');
}

run();
