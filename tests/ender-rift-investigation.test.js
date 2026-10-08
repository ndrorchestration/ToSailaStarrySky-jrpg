'use strict';
const assert = require('node:assert/strict');
const opening = require('../modules/first-wake-opening.js');

function dockState() {
  const state = opening.createState();
  opening.tickPresentation(state, opening.SCENES[0].minimumTicks);
  opening.advance(state);
  opening.tickPresentation(state, opening.SCENES[1].minimumTicks);
  opening.advance(state);
  assert.equal(opening.currentScene(state).id, 'dock_walk');
  return state;
}

const before = dockState();
assert.deepEqual(opening.expectedPartyIds(before), ['ender']);
assert.equal(opening.dockRiftView(before).stage, 0);
assert.equal(opening.dockRiftView(before).inRange, false);
assert.equal(opening.interactDockRift(before).advanced, false);
assert.equal(before.dockWalk.rift.stage, 0);

// Natural perception fires once when the player reaches the survey marker.
const first = opening.moveDock(before, 1);
assert.equal(first.event, null);
const noticed = opening.moveDock(before, 1);
assert.equal(noticed.event.type, 'rift-noticed');
assert.equal(opening.dockRiftView(before).stage, 1);
assert.equal(opening.dockRiftView(before).discovered, true);
assert.equal(opening.dockRiftView(before).measured, false);
assert.equal(opening.moveDock(before, 1).event, null);

// Instruments *verify disagreement*; they do not establish a cause.
const instrument = opening.interactDockRift(before);
assert.equal(instrument.event.type, 'rift-measured');
assert.equal(opening.dockRiftView(before).measured, true);
assert.match(opening.dockRiftView(before).lastMessage, /Instrument error is still possible/);
const recorded = opening.interactDockRift(before);
assert.equal(recorded.event.type, 'rift-recorded');
assert.equal(opening.dockRiftView(before).recorded, true);
assert.equal(opening.dockRiftView(before).conclusion, 'UNRESOLVED // CHART REVIEW NEEDED');
assert.equal(opening.interactDockRift(before).advanced, false);
assert.deepEqual(opening.expectedPartyIds(before), ['ender']);

// Interaction is range/scene-limited; notes persist through the scene.
opening.moveDock(before, 1);
opening.moveDock(before, 1);
opening.moveDock(before, 1);
assert.equal(opening.dockRiftView(before).inRange, false);
assert.equal(opening.interactDockRift(before).advanced, false);
opening.moveDock(before, 1);
opening.moveDock(before, 1);
assert.equal(before.dockWalk.ready, true);
opening.advance(before);
assert.equal(opening.currentScene(before).id, 'berth_task');
assert.equal(opening.interactDockRift(before).advanced, false);
assert.deepEqual(opening.expectedPartyIds(before), ['ender']);
assert.equal(before.wakeExploration.anomalyTriggered, false);
assert.deepEqual(before.wakeExploration.clues, []);

// The existing route remains playable even if the optional study is skipped.
const skipped = dockState();
for (let i = 0; i < 8; i++) opening.moveDock(skipped, 1);
assert.equal(opening.dockRiftView(skipped).stage, 1);
opening.advance(skipped);
assert.equal(opening.currentScene(skipped).id, 'berth_task');
assert.equal(skipped.dockWalk.rift.stage, 1);
assert.equal(skipped.wakeExploration.anomalyTriggered, false);
assert.deepEqual(skipped.appliedJoinIds, []);

// Fresh start has no read across sessions and never grants a spell.
const newGame = opening.createState();
assert.equal(newGame.dockWalk.rift.stage, 0);
assert.equal(newGame.wakeExploration.coreUnlocked, false);
assert.equal(newGame.wakeExploration.coreEntered, false);
assert.equal(newGame.complete, false);
console.log('Ender dock Rift Scholar field investigation: PASS');
