'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'world.js'), 'utf8');
const windowObject = { interactionKey: null, UI: {} };
const context = vm.createContext({
  window: windowObject,
  globalThis: windowObject,
  console,
  JSON,
  Math,
  Object,
  Array,
  Number,
  String,
  Boolean,
  Set,
  Map,
  Date,
});
new vm.Script(source, { filename: 'modules/world.js' }).runInContext(context);

assert.strictEqual(typeof windowObject.AetherWorld, 'function',
  'modular World authority did not load');

const world = windowObject.AetherWorld(null, null);
world.init();

const initial = world.snapshotPersistentState();
const crossingQuest = JSON.parse(JSON.stringify(initial.quest));
crossingQuest.state = 'crossing';
crossingQuest.act = 'crossing';
crossingQuest.hazardsCompleted = 0;
crossingQuest.crossingHazards = [
  { id: 'sky_predator', label: 'Sky-Predator', done: false, stat: 'grace' },
  { id: 'wind_shear', label: 'Harmonic Shear', done: false, stat: 'grace' },
  { id: 'aether_leak', label: 'Aether Leak', done: false, stat: 'wits' },
  { id: 'corporate_intercept', label: 'Corporate Intercept', done: false, stat: 'might' },
];

const prepared = world.preparePersistentState(initial.world, crossingQuest);
world.restorePersistentState(prepared, initial.runtime);

let state = world.getQuestState();
assert.strictEqual(state.state, 'crossing');
assert.strictEqual(state.crossingHazards.length, 4);
assert.strictEqual(state.hazardsCompleted, 0);

// A defeat must preserve the unresolved route.
let resolution = world.resolveHazardEncounter(0, false);
assert.strictEqual(resolution.completed, false);
state = world.getQuestState();
assert.strictEqual(state.state, 'crossing');
assert.strictEqual(state.hazardsCompleted, 0);
assert.strictEqual(state.crossingHazards[0].done, false);

// The first three victories must not prematurely unlock CONTACT.
for (let i = 0; i < 3; i++) {
  resolution = world.resolveHazardEncounter(i, true);
  assert.strictEqual(resolution.completed, true);
  state = world.getQuestState();
  assert.strictEqual(state.hazardsCompleted, i + 1);
  assert.strictEqual(state.crossingHazards[i].done, true);
  assert.strictEqual(state.state, 'crossing',
    'CONTACT unlocked before all four Crossing hazards were won');
}

// The fourth victory is the only transition into CONTACT.
resolution = world.resolveHazardEncounter(3, true);
assert.strictEqual(resolution.completed, true);
state = world.getQuestState();
assert.strictEqual(state.hazardsCompleted, 4);
assert.strictEqual(state.state, 'contact');
assert.strictEqual(state.act, 'contact');
assert.strictEqual(state.npcsMet.length, 0,
  'CONTACT must begin with four post-Crossing conversations still required');
assert(state.journal.some(entry =>
  /Corporate Intercept cleared/.test(entry.text)),
  'fourth hazard resolution was not journaled');
assert(state.journal.some(entry =>
  /Four souls ahead/.test(entry.text)),
  'CONTACT transition was not journaled');

console.log('Aetherwake Chapter 1 world lifecycle: PASS');
