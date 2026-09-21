const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'modules', 'party-state.js'),
  'utf8'
);

const window = {};
vm.runInNewContext(source, { window, console });

const ender = {
  name: 'Ender',
  level: 1,
  xp: 0,
  xpToNext: 50,
  unlockedAbilities: [],
  equipment: { staff: null, backpack: null },
};

const state = window.AetherPartyState;
state.bootstrap(ender);

assert.strictEqual(state.roster.length, 5);
assert.strictEqual(state.activeParty.length, 3,
  'preservation bootstrap should still start with the current three-slot adapter');
assert.strictEqual(state.maxActiveParty, 5);
assert.strictEqual(state.minActiveParty, 1);

state.setActivePartyIds(['ender']);
assert.deepStrictEqual(
  Array.from(state.activeParty, member => member.id),
  ['ender'],
  'opening must be able to begin with Ender alone'
);

state.roster[1].runtimeImplemented = true;
state.roster[2].runtimeImplemented = true;
state.setActivePartyIds(['ender', 'lyra']);
assert.deepStrictEqual(Array.from(state.activeParty, member => member.id), ['ender', 'lyra']);

state.setActivePartyIds(['ender', 'lyra', 'ionia']);
assert.deepStrictEqual(
  Array.from(state.activeParty, member => member.id),
  ['ender', 'lyra', 'ionia']
);

state.roster[3].runtimeImplemented = true;
state.setActivePartyIds(['ender', 'lyra', 'ionia', 'reson']);
assert.strictEqual(state.activeParty.length, 4);

state.roster[4].runtimeImplemented = true;
state.setActivePartyIds(['ender', 'lyra', 'ionia', 'reson', 'aepex']);
assert.strictEqual(state.activeParty.length, 5);
assert.deepStrictEqual(
  Array.from(state.activeParty, member => member.id),
  ['ender', 'lyra', 'ionia', 'reson', 'aepex']
);

assert.throws(
  () => state.setActivePartyIds([]),
  /ACTIVE_PARTY_IDS_MUST_HAVE_1_TO_5_MEMBERS/
);
assert.throws(
  () => state.setActivePartyIds(['ender', 'ender']),
  /ACTIVE_PARTY_IDS_MUST_BE_UNIQUE/
);
assert.throws(
  () => state.setActivePartyIds(['ender', 'unknown']),
  /ACTIVE_PARTY_UNKNOWN_CHARACTER/
);

console.log('Aetherwake party capacity contract: PASS');
