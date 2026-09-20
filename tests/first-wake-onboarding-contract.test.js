const assert = require('node:assert/strict');

const { loadBrowserModule } = require('./first-wake-test-helpers');

function run() {
  const context = loadBrowserModule('modules/char-create.js');
  const charCreate = context.AetherCharCreate;

  charCreate.start({ mode: 'authored' });
  assert.equal(charCreate.getSnapshot().mode, 'authored');
  assert.equal(charCreate.getSnapshot().phase, 'intro');

  charCreate.handleInput({}, { 13: true });
  assert.equal(charCreate.getSnapshot().phase, 'roster');
  assert.deepEqual(
    Array.from(charCreate.getSnapshot().partyIds),
    ['ender', 'lyra', 'ionia']
  );

  charCreate.handleInput({}, { 13: true });
  assert.equal(charCreate.getSnapshot().phase, 'confirm');

  charCreate.handleInput({}, { 13: true });
  const snapshot = charCreate.getSnapshot();
  assert.equal(snapshot.phase, 'done');
  assert.deepEqual(Array.from(snapshot.activeIds), ['ender', 'lyra', 'ionia']);
  assert.equal(snapshot.partyIds[1], 'lyra');
  assert.equal(snapshot.partyIds[2], 'ionia');

  charCreate.start({ mode: 'prototype' });
  assert.equal(charCreate.getSnapshot().mode, 'prototype');

  console.log('First Wake onboarding contract: 8/8 passed');
}

run();
