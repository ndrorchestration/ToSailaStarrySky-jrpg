const assert = require('assert');
const opening = require('../modules/first-wake-opening.js');

assert.strictEqual(opening.VERSION, '0.8.0');
assert.strictEqual(opening.validate(), true);
assert.strictEqual(opening.SCENES.length, 10);
assert.strictEqual(opening.SCENES[0].id, 'arrival_horizon');
assert.strictEqual(opening.SCENES[0].cinematic, true);
assert.strictEqual(opening.SCENES[1].cinematic, true);
assert.strictEqual(opening.SCENES[2].interactive, true);
assert.strictEqual(opening.SCENES[3].interactive, true);
assert.strictEqual(opening.SCENES[3].interaction, 'berth-task');
assert.strictEqual(opening.SCENES[4].interactive, true);
assert.strictEqual(opening.SCENES[4].interaction, 'talen-beat');
assert.strictEqual(opening.SCENES[5].interaction, 'wake-free-roam');
assert.strictEqual(opening.SCENES[6].id, 'wrong_song');
assert.strictEqual(opening.SCENES[6].interaction, 'wrong-song');
assert.strictEqual(opening.SCENES[6].joinCharacterId, 'lyra');
assert.deepStrictEqual(opening.SCENES[6].activePartyIds, ['ender']);
assert.strictEqual(opening.SCENES[7].interaction, 'find-ionia');
assert.strictEqual(opening.SCENES[8].interaction, 'wake-investigation');
assert.strictEqual(opening.SCENES[9].chapterCard, true);
assert.deepStrictEqual(
  opening.SCENES.map(scene => scene.visual),
  ['dock-horizon','arrival','dock-walk','berth','talen','household','wrong-song','practical','core-walk','chapter']
);
assert(!opening.SCENES.some(scene => scene.activePartyIds.includes('ionia')),
  'Ionia must not join during the bounded First Wake opening');

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
assert.strictEqual(blocked.event.interaction, 'dock-walk');
assert.strictEqual(opening.dockWalkProgress(state), 0);

for (let i = 0; i < 8; i++) opening.moveDock(state, 1);
assert.strictEqual(opening.dockWalkProgress(state), 1);
assert.strictEqual(state.dockWalk.ready, true);
opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'berth_task');

const berthBlocked = opening.advance(state);
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

const talenBlocked = opening.advance(state);
assert(talenBlocked.event && talenBlocked.event.type === 'interaction-required');
assert.strictEqual(talenBlocked.event.interaction, 'talen-beat');
assert.strictEqual(opening.talenBeatProgress(state), 0);

opening.interactTalen(state);
assert.strictEqual(opening.talenBeatProgress(state), 0.5);
const talenDone = opening.interactTalen(state);
assert.strictEqual(talenDone.ready, true);
assert.strictEqual(opening.talenBeatProgress(state), 1);

opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'lyra_family');
let wakeBlocked = opening.advance(state);
assert(wakeBlocked.event && wakeBlocked.event.type === 'interaction-required');
assert.strictEqual(wakeBlocked.event.interaction, 'wake-free-roam');

// Explore from berth (3,5) to the route chart (5,2) and trigger the Wrong Song.
for (let i = 0; i < 2; i++) opening.moveWake(state, 1, 0);
for (let i = 0; i < 3; i++) opening.moveWake(state, 0, -1);
let wakeEvent = opening.interactWake(state);
assert(wakeEvent.event && wakeEvent.event.type === 'wrong-song-triggered');
assert.strictEqual(opening.wakeExplorationView(state).anomalyTriggered, true);

opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'wrong_song');
assert.deepStrictEqual(opening.expectedPartyIds(state), ['ender']);
wakeBlocked = opening.advance(state);
assert(wakeBlocked.event && wakeBlocked.event.type === 'interaction-required');
assert.strictEqual(wakeBlocked.event.interaction, 'wrong-song');

// Move to Lyra (7,3) and acknowledge the anomaly.
for (let i = 0; i < 2; i++) opening.moveWake(state, 1, 0);
opening.moveWake(state, 0, 1);
wakeEvent = opening.interactWake(state);
assert(wakeEvent.event && wakeEvent.event.type === 'wrong-song-acknowledged');
assert.strictEqual(opening.wakeExplorationView(state).wrongSongAcknowledged, true);

const join = opening.advance(state);
assert(join.event && join.event.type === 'party-join');
assert.strictEqual(join.event.characterId, 'lyra');
assert.deepStrictEqual(state.appliedJoinIds, ['lyra']);
assert.strictEqual(opening.currentScene(state).id, 'ionia_practical');
assert.deepStrictEqual(opening.expectedPartyIds(state), ['ender','lyra']);

// Move to Ionia (12,2) and complete the practical handoff.
for (let i = 0; i < 5; i++) opening.moveWake(state, 1, 0);
opening.moveWake(state, 0, -1);
wakeEvent = opening.interactWake(state);
assert(wakeEvent.event && wakeEvent.event.type === 'ionia-found');
assert.strictEqual(opening.wakeExplorationView(state).ioniaFound, true);

opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'core_walk');
wakeBlocked = opening.advance(state);
assert(wakeBlocked.event && wakeBlocked.event.type === 'interaction-required');
assert.strictEqual(wakeBlocked.event.interaction, 'wake-investigation');

// Collect two independent clues: route-chart structural evidence, then telemetry systems evidence.
for (let i = 0; i < 7; i++) opening.moveWake(state, -1, 0);
wakeEvent = opening.interactWake(state);
assert(wakeEvent.event && wakeEvent.event.type === 'investigation-clue');
assert.strictEqual(wakeEvent.event.clue, 'structural');

for (let i = 0; i < 6; i++) opening.moveWake(state, 1, 0);
for (let i = 0; i < 3; i++) opening.moveWake(state, 0, 1);
wakeEvent = opening.interactWake(state);
assert(wakeEvent.event && wakeEvent.event.type === 'investigation-clue');
assert.strictEqual(wakeEvent.event.clue, 'systems');
assert.strictEqual(opening.wakeExplorationView(state).coreUnlocked, true);

// Enter the now-unlocked core threshold at (13,5).
for (let i = 0; i < 2; i++) opening.moveWake(state, 1, 0);
wakeEvent = opening.interactWake(state);
assert(wakeEvent.event && wakeEvent.event.type === 'core-threshold');
assert.strictEqual(opening.wakeExplorationView(state).coreEntered, true);

opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'first_wake_card');
const complete = opening.advance(state);
assert(complete.event && complete.event.type === 'opening-complete');
assert.strictEqual(state.complete, true);
assert.strictEqual(opening.currentScene(state).id, 'first_wake_card');

console.log('Aetherwake First Wake opening contract: PASS');
