'use strict';
// Evidence-only snapshot diagnostic. PASS means incompatibilities were reproduced,
// not that exploration is integrated. Deliberately not a production smoke gate.
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');
const root = path.resolve(__dirname, '..');
function readPinned(file, expected) {
  const bytes = fs.readFileSync(path.join(root, file));
  const sha = crypto.createHash('sha1').update('blob ' + bytes.length + '\0').update(bytes).digest('hex');
  assert.strictEqual(sha, expected, file + ': snapshot changed; reassess this diagnostic');
  return bytes.toString('utf8');
}
readPinned('modules/first-wake-opening.js', '01f0128ef5f34449a3a94b1bc47e6737ffe9e709');
readPinned('tests/fixtures/first-wake-controller-v08.js', 'f6798f482d25b3eb9b231e6c928d23f8dfa11efb');
const game = readPinned('aetherwake.js', 'a2399d6d344cc6db0049205c88af916d6181d736');
const current = require('../modules/first-wake-opening.js');
const recovered = require('./fixtures/first-wake-controller-v08.js');
function declaration(name, next) {
  const start = game.indexOf('function ' + name + '(');
  const end = game.indexOf('function ' + next + '(', start + 1);
  assert(start >= 0 && end > start, 'runtime function boundaries must exist');
  return game.slice(start, end);
}
// Use the real keyPressed, handleInput and advancement bodies. Rendering, audio,
// clock and toast sinks are stubbed; no replacement input dispatcher is invented.
function inputHarness(opening) {
  const state = opening.createState();
  const joins = [];
  const context = {
    window: { AetherFirstWakeOpening: opening, _firstWakeOpeningState: state,
      AetherPartyState: { recruitCharacter(id) { joins.push(id); } } },
    STATE: Object.fromEntries(['OPENING','WORLD','MENU','BOOT','CHARCREATE','DIALOGUE','AIRSHIP','COMBAT','SHOP'].map(x => [x,x])),
    gameState: 'OPENING', prevState: null, keys: {}, keysPressed: {},
    keyCode: 0, key: '', millis: () => 1000, C: {}, showToast() {},
    ENTER: 13, UP_ARROW: 38, DOWN_ARROW: 40, LEFT_ARROW: 37, RIGHT_ARROW: 39,
  };
  vm.createContext(context);
  vm.runInContext(declaration('keyPressed','keyReleased') +
    declaration('handleInput','handleWorldInput') +
    declaration('advanceFirstWakeOpening','drawFirstWakeOpening'), context);
  return { state, joins, press(code) { context.keyCode = code; context.keyPressed(); } };
}
const live = inputHarness(current);
live.press(13);
assert.strictEqual(live.state.sceneIndex, 0, 'current live input respects presentation hold');
current.tickPresentation(live.state, 240);
for (let i = 0; i < 10; i++) live.press(13);
assert(live.state.complete);
assert.deepStrictEqual(live.joins, ['lyra']);
assert(!live.state.wakeExploration);
assert.strictEqual(current.SCENES[6].id, 'lyra_join');
for (const api of ['moveWake','interactWake','wakeExplorationView','nearbyWakeHotspot']) {
  assert.strictEqual(typeof current[api], 'undefined');
}

// Whole-controller replacement gets stuck at the first old interaction gate.
const transplanted = inputHarness(recovered);
recovered.tickPresentation(transplanted.state, 240);
transplanted.press(13);
recovered.tickPresentation(transplanted.state, 60);
transplanted.press(13);
assert.strictEqual(recovered.currentScene(transplanted.state).id, 'dock_walk');
const beforeDock = JSON.stringify(transplanted.state);
for (const key of [39,68,69,13,32]) transplanted.press(key);
assert.strictEqual(JSON.stringify(transplanted.state), beforeDock,
  'current dispatcher cannot satisfy recovered dock interaction gate');
assert.strictEqual(recovered.advance(transplanted.state).event.interaction, 'dock-walk');

// A later directly selected scene is diagnostic setup, not a player route.
transplanted.state.sceneIndex = 5;
const beforeWake = JSON.stringify(transplanted.state);
for (const key of [37,38,39,40,65,68,87,83,69]) transplanted.press(key);
assert.strictEqual(JSON.stringify(transplanted.state), beforeWake,
  'current dispatcher neither moves nor interacts in recovered exploration');

// Renaming the scene alone is also insufficient: old behavior branches on its ID.
const renamedSource = fs.readFileSync(path.join(__dirname, 'fixtures/first-wake-controller-v08.js'), 'utf8')
  .replace("id: 'wrong_song'", "id: 'lyra_join'")
  .replace("'wrong_song',", "'lyra_join',");
const renameContext = { module: { exports: {} } };
vm.runInNewContext(renamedSource, renameContext);
const renamed = renameContext.module.exports;
const renamedState = renamed.createState();
renamedState.sceneIndex = 6;
renamedState.wakeExploration.x = 7;
renamedState.wakeExploration.y = 3;
assert.strictEqual(renamed.wakeExplorationView(renamedState).objective, '');
assert.strictEqual(renamed.interactWake(renamedState).event, null);
assert.strictEqual(renamed.advance(renamedState).event.type, 'party-join',
  'partial scene rename bypasses the old acknowledgement gate');

// Positive control: the recovered controller itself can finish via its own APIs.
const route = recovered.createState();
const events = [];
function advance() {
  recovered.tickPresentation(route, 10000);
  const result = recovered.advance(route);
  if (result.event) events.push(result.event);
  return result;
}
advance(); advance();
for (let i = 0; i < 8; i++) recovered.moveDock(route, 1);
advance();
for (let i = 0; i < 3; i++) recovered.interactBerth(route);
advance();
for (let i = 0; i < 2; i++) recovered.interactTalen(route);
advance();
function visit(x, y) {
  let budget = 30;
  while (route.wakeExploration.x !== x || route.wakeExploration.y !== y) {
    assert(budget-- > 0, 'bounded diagnostic movement must reach target');
    recovered.moveWake(route, Math.sign(x-route.wakeExploration.x), 0);
    if (route.wakeExploration.y !== y) recovered.moveWake(route, 0, Math.sign(y-route.wakeExploration.y));
  }
  return recovered.interactWake(route);
}
visit(5,2);
assert(route.wakeExploration.anomalyTriggered);
advance();
assert.strictEqual(recovered.currentScene(route).id, 'wrong_song');
assert.strictEqual(visit(7,3).event.type, 'wrong-song-acknowledged');
advance();
assert.strictEqual(visit(12,2).event.type, 'ionia-found');
advance();
assert.strictEqual(visit(13,5).event.type, 'core-locked');
visit(5,2); visit(9,6);
assert.strictEqual(route.wakeExploration.coreUnlocked, true);
assert.strictEqual(visit(13,5).event.type, 'core-threshold');
advance(); advance();
assert(route.complete);
assert.deepStrictEqual(events.filter(e => e.type === 'party-join').map(e => e.characterId), ['lyra']);
assert(!recovered.expectedPartyIds(route).includes('ionia'));
console.log('Controller compatibility diagnostic: reproduced missing input routing, dock stall, partial-rename gate bypass; recovered API positive control completed. INTEGRATION=NOT_ESTABLISHED');
