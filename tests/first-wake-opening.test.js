const assert = require('assert');
const opening = require('../modules/first-wake-opening.js');

assert.strictEqual(opening.VERSION, '0.1.0');
assert.strictEqual(opening.validate(), true);
assert.strictEqual(opening.SCENES.length, 10);
assert.strictEqual(opening.SCENES[0].id, 'arrival_horizon');
assert.strictEqual(opening.SCENES[6].id, 'wrong_song');
assert.strictEqual(opening.SCENES[6].joinCharacterId, 'lyra');
assert.deepStrictEqual(opening.SCENES[6].activePartyIds, ['ender']);
assert.strictEqual(opening.SCENES[9].chapterCard, true);
assert(!opening.SCENES.some(scene => scene.activePartyIds.includes('ionia')),
  'Ionia must not join before Sequence 13/14');

const state = opening.createState();
assert.deepStrictEqual(opening.expectedPartyIds(state), ['ender']);

for (let i = 0; i < 6; i++) opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'wrong_song');
assert.deepStrictEqual(opening.expectedPartyIds(state), ['ender']);
const join = opening.advance(state);
assert(join.event && join.event.type === 'party-join');
assert.strictEqual(join.event.characterId, 'lyra');
assert.deepStrictEqual(state.appliedJoinIds, ['lyra']);
assert.deepStrictEqual(opening.expectedPartyIds(state), ['ender','lyra']);

while (!state.complete) opening.advance(state);
assert.strictEqual(state.complete, true);
assert.strictEqual(opening.currentScene(state).id, 'first_wake_card');

console.log('Aetherwake First Wake opening contract: PASS');
