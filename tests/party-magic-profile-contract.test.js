const assert = require('assert');

global.window = {};
window.AetherwakeMagicDefs = require('../modules/magic-defs.js');
window.AetherwakeMagicMastery = require('../modules/magic-mastery.js');
window.AetherwakeCharacterMagicProfile = require('../modules/character-magic-profile.js');
const study = require('../modules/magic-study.js');

delete require.cache[require.resolve('../modules/party-state.js')];
require('../modules/party-state.js');

const worldPlayer = {
  name: 'Ender',
  vit: 10,
  maxVit: 10,
  level: 1,
  xp: 0,
  unlockedAbilities: []
};

const boot = window.AetherPartyState.bootstrap(worldPlayer);
assert.strictEqual(boot.roster.length, 5);
assert.strictEqual(boot.activeParty.length, 1);
assert.deepStrictEqual(boot.activeParty.map(character => character.id), ['ender']);
assert.deepStrictEqual(
  boot.roster.map(character => Boolean(character.playable)),
  [true, false, false, false, false]
);

for (const character of boot.roster) {
  assert.ok(character.magicProfile, `${character.id} missing magicProfile`);
  assert.strictEqual(character.magicProfile.characterId, character.id);
  assert.deepStrictEqual(character.magicProfile.mastery.trees, {});
  assert.deepStrictEqual(character.magicProfile.mastery.domains, {});
  assert.deepStrictEqual(character.magicProfile.learnedSpells, []);
}

assert.deepStrictEqual(
  boot.roster[0].magicProfile.innateAffinities,
  ['aether', 'resonance', 'correspondence', 'lumen']
);
assert.strictEqual(boot.roster[0].magicProfile.affinityStatus, 'established');

for (const character of boot.roster.slice(1)) {
  assert.deepStrictEqual(character.magicProfile.innateAffinities, []);
  assert.strictEqual(character.magicProfile.affinityStatus, 'open');
}

const enderProfileBefore = boot.roster[0].magicProfile;
window.AetherPartyState.commitPrototypeParty([
  { name:'Ender', level:1, unlockedAbilities:[] },
  { name:'Lyra', level:1, unlockedAbilities:[] },
  { name:'Ionia', level:1, unlockedAbilities:[] }
]);

assert.strictEqual(
  boot.roster[0].magicProfile,
  enderProfileBefore,
  'prototype adaptation must not overwrite canonical magic profile'
);

let studied = study.advanceMastery(boot.roster[0].magicProfile, 'fire', 1);
studied = study.learnSpell(studied, 'fire.ember_dart');
const persisted = window.AetherPartyState.replaceMagicProfile('ender', studied);
assert.strictEqual(persisted.characterId, 'ender');
assert.strictEqual(persisted.mastery.trees.fire, 1);
assert.deepStrictEqual(persisted.learnedSpells, ['fire.ember_dart']);
assert.strictEqual(boot.roster[0].magicProfile, persisted);

const snapshot = window.AetherPartyState.snapshot();
assert.deepStrictEqual(snapshot.affinityStatus, ['established','open','open','open','open']);
assert.deepStrictEqual(snapshot.masteryRanks[0], { trees:{fire:1}, domains:{} });
assert.deepStrictEqual(snapshot.learnedSpells[0], ['fire.ember_dart']);
assert.deepStrictEqual(snapshot.learnedSpells.slice(1), [[],[],[],[]]);

assert.throws(
  () => window.AetherPartyState.replaceMagicProfile(
    'ender',
    window.AetherwakeCharacterMagicProfile.createProfile('lyra')
  ),
  /PARTY_STATE_MAGIC_PROFILE_CHARACTER_MISMATCH/
);

boot.roster[0].magicProfile = window.AetherwakeCharacterMagicProfile.createProfile('lyra');
assert.throws(
  () => window.AetherPartyState.validate(),
  /PARTY_STATE_MAGIC_PROFILE_CHARACTER_MISMATCH/
);

console.log('party magic-profile integration: PASS');
