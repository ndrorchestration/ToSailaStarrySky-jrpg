const assert = require('node:assert/strict');

const {
  fakeStorage,
  loadBrowserModule,
} = require('./first-wake-test-helpers');

function run() {
  const storage = fakeStorage();
  storage.setItem('aetherwake.test', 'round-trip');
  assert.equal(storage.getItem('aetherwake.test'), 'round-trip');
  assert.equal(storage.length, 1);

  const context = loadBrowserModule('modules/effect-vocabulary.js');
  assert.equal(context.AetherEffectVocabulary.VERSION, '0.1.0');
  assert.equal(context.AetherEffectVocabulary.PHASES.length, 4);

  console.log('First Wake contract: 2/2 passed');
}

run();
