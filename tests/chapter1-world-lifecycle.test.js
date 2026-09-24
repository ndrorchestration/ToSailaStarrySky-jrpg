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

// CONTACT must require all four post-Crossing voices, even when some were
// already encountered earlier in the chapter.
const contacts = [
  { id: 'elder_farmer', x: 7, y: 7 },
  { id: 'engine_spirit', x: 22, y: 10 },
  { id: 'child_prophet', x: 8, y: 20 },
  { id: 'corporate_salvager', x: 26, y: 24 },
];

for (let i = 0; i < contacts.length; i++) {
  const contact = contacts[i];
  const current = world.snapshotPersistentState();
  current.world.playerPosition = {
    tileX: contact.x,
    tileY: contact.y,
    px: contact.x * 16,
    py: contact.y * 16,
  };
  const repositioned = world.preparePersistentState(current.world, current.quest);
  world.restorePersistentState(repositioned, current.runtime);
  windowObject.interactionKey = 'e';
  world.interact();
  windowObject.interactionKey = null;

  state = world.getQuestState();
  assert.strictEqual(state.npcsMet.length, i + 1,
    'CONTACT voice count did not advance exactly once');
  if (i < 3) {
    assert.strictEqual(state.state, 'contact',
      'CHOICE unlocked before all four CONTACT voices were heard');
  }
}

state = world.getQuestState();
assert.strictEqual(state.state, 'choice');
assert.strictEqual(state.npcsMet.length, 4);
assert(state.journal.some(entry => /All four voices heard/.test(entry.text)),
  'CHOICE transition was not journaled');

// Deterministically restore a completed choice record, then prove the
// deliberate WAKE beat exists before DONE.
let chosen = world.snapshotPersistentState();
chosen.quest.state = 'choice';
chosen.quest.act = 'choice';
chosen.quest.choiceMade = 'Drive the core up / Find what\'s above';
chosen.quest.choicePath = 'path_c';
chosen.quest.choiceVariant = 'strong';
chosen.quest.hullIntegrity = 80;
chosen.quest.morale = 65;
chosen.quest.engineIntegration = 80;
let preparedChoice = world.preparePersistentState(chosen.world, chosen.quest);
world.restorePersistentState(preparedChoice, chosen.runtime);

world.advanceQuest();
state = world.getQuestState();
assert.strictEqual(state.state, 'wake',
  'completed CHOICE must enter the deliberate WAKE resolution beat');
assert.strictEqual(state.wakeEpilogueId, 'epiline_10',
  'high-state path-C resolution must reach The First Note instead of a generic ending');
assert(typeof state.choiceOutcomeText === 'string' && state.choiceOutcomeText.length > 40,
  'WAKE must expose the chosen strong/strained path consequence');

world.advanceQuest();
state = world.getQuestState();
assert.strictEqual(state.state, 'done',
  'WAKE confirmation must close Chapter I into DONE');
assert(state.journal.some(entry => /The ending found you/.test(entry.text)),
  'Chapter I DONE transition was not journaled');

console.log('Aetherwake Chapter 1 world lifecycle: PASS');
