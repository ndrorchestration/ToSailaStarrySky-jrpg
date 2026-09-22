const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const canon = require('../modules/character-canon.js');
assert.strictEqual(canon.validate(), true);
assert.strictEqual(canon.PROFILES.ender.age, 22);
assert.strictEqual(canon.PROFILES.ender.nativeJob, 'Rift Scholar');
assert(canon.PROFILES.ender.art.avoid.includes('bodybuilder proportions'));
assert.strictEqual(canon.PROFILES.lyra.age, 24);
assert.strictEqual(canon.PROFILES.lyra.canon.family, 'single mother of Talen, age 5');
assert(canon.PROFILES.lyra.art.avoid.includes('childlike presentation'));
assert.strictEqual(canon.PROFILES.ionia.age, 28);
assert.strictEqual(canon.PROFILES.ionia.canon.experience, 'served Captain Denith for 10 years');
assert.strictEqual(canon.PROFILES.ionia.canon.spellcastingIdentity, 'not established');
assert.strictEqual(canon.PROFILES.reson.age, 25);
assert.deepStrictEqual(
  Array.from(canon.PROFILES.reson.canon.weapons),
  ['combat-rifle-type firearm','pike','sword']
);
assert.strictEqual(canon.PROFILES.aepex.age, 27);
assert(canon.PROFILES.aepex.canon.interests.includes('computers'));
assert(canon.PROFILES.aepex.art.avoid.includes('generic wizard imagery'));

const context = { window: { AetherCharacterCanon: canon }, console };
const partySource = fs.readFileSync(path.resolve(__dirname,'..','modules','party-state.js'),'utf8');
vm.runInNewContext(partySource, context);
const state = context.window.AetherPartyState;
const ender = {level:1,xp:0,xpToNext:50,unlockedAbilities:[],equipment:{staff:null,backpack:null}};
state.bootstrap(ender);
assert.strictEqual(state.validate(), true);
assert.strictEqual(state.characterCanonVersion, canon.VERSION);
for (const member of state.roster) {
  assert.strictEqual(member.artProfileId, member.id);
}

const guardedFiles = [
  'aetherwake.js',
  'modules/world.js',
  'modules/char-create.js',
  'modules/combat.js',
  'modules/ui.js',
  'modules/ui-adapter.js',
];
const forbidden = [
  'Rift Scholar + Dreamwright',
  'Rift Scholar / Dreamwright',
  'Child Dreamer of the Aureate Wake',
  'tired old captain',
  "I've been captain for three hundred years",
  "I've farmed sky-lanes routes",
  'Farmers understand soil',
];
for (const rel of guardedFiles) {
  const body = fs.readFileSync(path.resolve(__dirname,'..',rel),'utf8');
  for (const phrase of forbidden) {
    assert(!body.includes(phrase), rel + ' reintroduced superseded character canon: ' + phrase);
  }
}

console.log('Aetherwake character canon/art alignment: PASS');
