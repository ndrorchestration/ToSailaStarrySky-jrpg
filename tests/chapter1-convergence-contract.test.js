'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const opening = require('../modules/first-wake-opening.js');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const worldMirror = fs.readFileSync(path.join(root, 'modules', 'world.js'), 'utf8');

assert.strictEqual(opening.VERSION, '0.7.0',
  'Chapter 1 must use the explorable First Wake opening authority');
assert.strictEqual(opening.validate(), true);
for (const expected of [
  ['lyra_family','wake-free-roam'],
  ['wrong_song','wrong-song'],
  ['ionia_practical','find-ionia'],
  ['core_walk','wake-investigation'],
]) {
  const scene = opening.SCENES.find(entry => entry.id === expected[0]);
  assert(scene && scene.interaction === expected[1],
    expected[0] + ' must remain player-driven');
}
for (const fn of ['moveWake','interactWake','wakeExplorationView','nearbyWakeHotspot']) {
  assert.strictEqual(typeof opening[fn], 'function', 'opening authority missing ' + fn);
}

assert(runtime.includes('const wakeExplorationScene = openingScene && openingScene.sequence >= 5 && openingScene.sequence <= 8'),
  'live runtime must route Sequences 05–08 through exploration input');
assert(runtime.includes('opening.moveWake(openingState, dx, dy)'),
  'live runtime must use authored Wake movement');
assert(runtime.includes('opening.interactWake(openingState)'),
  'live runtime must use authored Wake interactions');
assert(runtime.includes('ANY 2 OF 3 CLUES'),
  'Core investigation guidance must expose the flexible clue gate');

const canonicalHazards = [
  "id: 'sky_predator'",
  "id: 'wind_shear'",
  "id: 'aether_leak'",
  "id: 'corporate_intercept'",
];
for (const marker of canonicalHazards) {
  assert(runtime.includes(marker), 'live runtime missing canonical hazard ' + marker);
  assert(worldMirror.includes(marker), 'world mirror missing canonical hazard ' + marker);
}
assert(runtime.includes('if (quest.hazardsCompleted >= 4)'),
  'Chapter 1 Crossing must require all four hazard victories');
assert(worldMirror.includes('if (quest.hazardsCompleted >= 4)'),
  'world mirror must match four-hazard progression gate');

const proximityStart = runtime.indexOf('function checkHazardProximity(tx, ty)');
const proximityEnd = runtime.indexOf('function completeHazard(index)', proximityStart);
assert(proximityStart >= 0 && proximityEnd > proximityStart,
  'live hazard proximity authority missing');
const proximity = runtime.slice(proximityStart, proximityEnd);
assert(!proximity.includes('Math.random()'),
  'chapter-critical hazard entry must not depend on random rolls');
for (let i = 0; i < 4; i++) {
  assert(proximity.includes('startHazardEncounter(' + i + ')') ||
         proximity.includes('startHazardEncounter(index)'),
    'hazard zone must launch combat through the canonical encounter seam');
}

assert(runtime.includes('Crossing — four hazards on the way to the ship.'),
  'quest log must describe the canonical four-hazard route');
assert(runtime.includes("text('JOURNAL'"),
  'quest log must expose recent Chapter 1 journal state');
assert(runtime.includes('journal: quest.journal.map(entry => ({ ...entry }))'),
  'quest-state projection must expose journal entries');

assert(!runtime.includes('previewEndAt > 0 && millis() >= previewEndAt'),
  'Chapter 1 must not auto-transition into the Preview end card');
assert(!runtime.includes("completedNpcId === 'elder_farmer' && previewEncounterArmed"),
  'Ionia dialogue must not force the old Preview-only Sky-Predator ending');
assert(!runtime.includes("nearest.id === 'elder_farmer' && !previewEncounterStarted"),
  'Ionia contact must not arm the old Preview-only encounter');


assert(runtime.includes('function determineChoiceOutcome(pathId)'),
  'Chapter 1 final choice must use deterministic state-based resolution');
assert(runtime.includes("return score >= 60 ? 'strong' : 'strained';"),
  'Chapter 1 final choice must resolve to deterministic strong/strained outcomes');
assert(!runtime.includes('Simulate 2D6 roll for variant'),
  'Chapter 1 must not use the legacy hidden 2d6 choice roll');
assert(!runtime.includes("quest.choiceVariant = roll >= 10 ? '10+' : '7-9';"),
  'Chapter 1 must not preserve dice-derived choice variants');
assert(!runtime.includes("C: start combat encounter (dev/testing"),
  'normal Chapter 1 world input must not expose the developer combat shortcut');
assert(!runtime.includes("Three hazards between you and the core's last stable chamber"),
  'Chapter 1 journal must not retain the stale three-hazard route');
assert(!runtime.includes("Three voices on the ship"),
  'Chapter 1 journal must not retain stale three-contact copy');


assert(runtime.includes("function getChoiceOutcomeText()"),
  'Chapter 1 must expose the authored path consequence during WAKE');
assert(runtime.includes("'epiline_10',  // best path-C ending: First Note"),
  'First Note must have explicit high-priority ending resolution');
assert(runtime.includes('const choiceOutcome = getChoiceOutcomeText();'),
  'WAKE presentation must render the selected path consequence');
assert(runtime.includes("} else if (quest.state === QUEST_STATES.CONTACT)"),
  'SIGNAL and CONTACT conversation progress must be separate');

console.log('Aetherwake Chapter 1 convergence contract: PASS');
