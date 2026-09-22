const assert = require('assert');
const opening = require('../modules/first-wake-opening.js');

assert.strictEqual(opening.VERSION, '0.5.0');
assert.strictEqual(opening.validate(), true);
assert.strictEqual(opening.SCENES.length, 10);
assert.strictEqual(opening.SCENES[0].id, 'arrival_horizon');
assert.strictEqual(opening.SCENES[0].cinematic, true);
assert.strictEqual(opening.SCENES[1].cinematic, true);
assert.strictEqual(opening.SCENES[2].interactive, true);
assert.strictEqual(opening.SCENES[3].interactive, true);
assert.strictEqual(opening.SCENES[3].interaction, 'berth-task');
assert.strictEqual(opening.SCENES[6].id, 'wrong_song');
assert.strictEqual(opening.SCENES[6].joinCharacterId, 'lyra');
assert.deepStrictEqual(opening.SCENES[6].activePartyIds, ['ender']);
assert.strictEqual(opening.SCENES[9].chapterCard, true);
assert.deepStrictEqual(
  opening.SCENES.map(scene => scene.visual),
  ['dock-horizon','arrival','dock-walk','berth','talen','household','wrong-song','practical','core-walk','chapter']
);
assert(!opening.SCENES.some(scene => scene.activePartyIds.includes('ionia')),
  'Ionia must not join before Sequence 13/14');

const state = opening.createState();
assert.deepStrictEqual(opening.expectedPartyIds(state), ['ender']);

let held = opening.advance(state);
assert(held.event && held.event.type === 'presentation-required');
assert.strictEqual(opening.currentScene(state).id, 'arrival_horizon');
opening.tickPresentation(state, opening.SCENES[0].minimumTicks);
assert.strictEqual(opening.presentationReady(state), true);
opening.advance(state);

held = opening.advance(state);
assert(held.event && held.event.type === 'presentation-required');
assert.strictEqual(opening.currentScene(state).id, 'ender_arrives');
opening.tickPresentation(state, opening.SCENES[1].minimumTicks);
opening.advance(state);

assert.strictEqual(opening.currentScene(state).id, 'dock_walk');
const blocked = opening.advance(state);
assert(blocked.event && blocked.event.type === 'interaction-required');
assert.strictEqual(opening.currentScene(state).id, 'dock_walk');
assert.strictEqual(opening.dockWalkProgress(state), 0);

for (let i = 0; i < 8; i++) opening.moveDock(state, 1);
assert.strictEqual(opening.dockWalkProgress(state), 1);
assert.strictEqual(state.dockWalk.ready, true);
opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'berth_task');

let berthBlocked = opening.advance(state);
assert(berthBlocked.event && berthBlocked.event.type === 'interaction-required');
assert.strictEqual(berthBlocked.event.interaction, 'berth-task');
assert.strictEqual(opening.berthTaskProgress(state), 0);

opening.interactBerth(state);
assert.strictEqual(opening.berthTaskProgress(state), 1 / 3);
opening.interactBerth(state);
assert.strictEqual(opening.berthTaskProgress(state), 2 / 3);
const berthDone = opening.interactBerth(state);
assert.strictEqual(berthDone.ready, true);
assert.strictEqual(opening.berthTaskProgress(state), 1);

opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'talen_staying');

for (let i = 0; i < 2; i++) opening.advance(state);
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
