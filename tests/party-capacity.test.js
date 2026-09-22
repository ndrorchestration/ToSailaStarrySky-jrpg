const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'modules', 'party-state.js'),
  'utf8'
);

const window = {
  AetherwakeCharacterMagicProfile: require('../modules/character-magic-profile.js'),
};
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
assert.strictEqual(state.activeParty.length, 1,
  'authored opening bootstrap must begin with Ender alone');
assert.deepStrictEqual(Array.from(state.activeParty, member => member.id), ['ender']);
assert.deepStrictEqual(Array.from(state.roster, member => Boolean(member.playable)),
  [true, false, false, false, false]);
assert.strictEqual(state.maxActiveParty, 5);
assert.strictEqual(state.minActiveParty, 1);

assert.throws(
  () => state.setActivePartyIds(['ender', 'lyra']),
  /ACTIVE_PARTY_CHARACTER_NOT_PLAYABLE:lyra/
);

state.recruitCharacter('lyra');
assert.deepStrictEqual(Array.from(state.activeParty, member => member.id), ['ender', 'lyra']);

state.recruitCharacter('ionia');
assert.deepStrictEqual(
  Array.from(state.activeParty, member => member.id),
  ['ender', 'lyra', 'ionia']
);

assert.throws(
  () => state.recruitCharacter('reson'),
  /PARTY_STATE_RECRUITMENT_NOT_AUTHORIZED:reson/
);
state.roster[3].playable = true;
state.setActivePartyIds(['ender', 'lyra', 'ionia', 'reson']);
assert.strictEqual(state.activeParty.length, 4);

state.roster[4].playable = true;
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
