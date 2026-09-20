const assert = require('node:assert/strict');

const { loadBrowserModule } = require('./first-wake-test-helpers');

const context = loadBrowserModule('modules/first-wake-kits.js');
const kits = context.AetherFirstWakeKits;
const defsContext = loadBrowserModule('modules/ability-defs.js');
const vocabularyContext = loadBrowserModule('modules/effect-vocabulary.js');

assert.equal(kits.validate(), true);
assert.equal(kits.version, 1);
assert.deepEqual(Object.keys(kits.roles), ['reader', 'receiver', 'anchor']);
assert.deepEqual(Object.keys(kits.actors), ['ender', 'lyra', 'ionia']);
assert.equal(kits.roles.receiver.canonStatus, 'provisional');
assert.equal(kits.roles.anchor.canonStatus, 'provisional');
assert.equal(kits.actors.lyra.roleId, 'receiver');
assert.equal(kits.actors.ionia.roleId, 'anchor');
assert.equal(
  vocabularyContext.AetherEffectVocabulary.assertPartyActionCoverage(
    defsContext.AetherAbilityDefs.createPartyRuntimeActions()
  ),
  true
);

console.log('First Wake kit contract: 9/9 passed');
