const assert = require('assert');
const opening = require('../modules/first-wake-opening.js');

assert.strictEqual(opening.VERSION, '0.7.0');
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
assert.strictEqual(opening.SCENES[6].interaction, 'wrong-song');
assert.strictEqual(opening.SCENES[7].interaction, 'find-ionia');
assert.strictEqual(opening.SCENES[8].interaction, 'wake-investigation');
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

const roamBlocked = opening.advance(state);
assert(roamBlocked.event && roamBlocked.event.interaction === 'wake-free-roam',
  'Sequence 05 must not be skippable with Enter');

function move(dx, dy, count) {
  for (let i = 0; i < count; i++) opening.moveWake(state, dx, dy);
}

// Start at Ender's berth (3,5), then freely reach the route chart at (5,2).
move(1, 0, 2);
move(0, -1, 3);
let interaction = opening.interactWake(state);
assert(interaction.event && interaction.event.type === 'wrong-song-triggered',
  'route-chart discovery should be one valid exploration trigger');
assert.strictEqual(state.wakeExploration.anomalyTriggered, true);
opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'wrong_song');
assert.deepStrictEqual(opening.expectedPartyIds(state), ['ender']);

// Find Lyra at (7,3) rather than advancing a dialogue card.
move(1, 0, 2);
move(0, 1, 1);
interaction = opening.interactWake(state);
assert(interaction.event && interaction.event.type === 'wrong-song-acknowledged');
const join = opening.advance(state);
assert(join.event && join.event.type === 'party-join');
assert.strictEqual(join.event.characterId, 'lyra');
assert.deepStrictEqual(state.appliedJoinIds, ['lyra']);
assert.strictEqual(opening.currentScene(state).id, 'ionia_practical');
assert.deepStrictEqual(opening.expectedPartyIds(state), ['ender','lyra']);

// Find Ionia at (12,2).
move(1, 0, 5);
move(0, -1, 1);
interaction = opening.interactWake(state);
assert(interaction.event && interaction.event.type === 'ionia-found');
opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'core_walk');

// Investigation order is flexible. Collect systems then frequency; 2 of 3 opens the Core route.
move(-1, 0, 1);
move(0, 1, 3);
interaction = opening.interactWake(state);
assert(interaction.event && interaction.event.type === 'investigation-clue');
assert.strictEqual(interaction.event.clue, 'systems');
assert.strictEqual(state.wakeExploration.coreUnlocked, false);

move(-1, 0, 2);
move(0, 1, 1);
interaction = opening.interactWake(state);
assert.strictEqual(interaction.event.clue, 'frequency');
assert.strictEqual(state.wakeExploration.clues.length, 2);
assert.strictEqual(state.wakeExploration.coreUnlocked, true);

// Player chooses the threshold at the Core door (13,5).
move(1, 0, 4);
move(0, -1, 1);
interaction = opening.interactWake(state);
assert(interaction.event && interaction.event.type === 'core-threshold');
opening.advance(state);
assert.strictEqual(opening.currentScene(state).id, 'first_wake_card');

opening.advance(state);
assert.strictEqual(state.complete, true);
assert.strictEqual(opening.currentScene(state).id, 'first_wake_card');

const fs = require('fs');
const path = require('path');
const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

assert(runtime.includes("sky_predator: 'skyPredator'"), 'Sky-Predator hazard must map to combat encounter');
assert(runtime.includes("wind_shear: 'windShear'"), 'Wind Shear hazard must map to combat encounter');
assert(runtime.includes("aether_leak: 'aetherLeak'"), 'Aether Leak hazard must map to combat encounter');
assert(runtime.includes("corporate_intercept: 'corporateSalvager'"), 'Corporate Intercept hazard must map to combat encounter');
assert(runtime.includes('triggerHazardEncounter(0)'), 'Crossing proximity must launch hazard encounters');
assert(runtime.includes('combatState.enemy.hp <= 0'), 'Hazard completion must be gated on combat victory');
assert(runtime.includes("quest.state !== QUEST_STATES.CROSSING"), 'Hazards must not trigger outside Crossing');
assert(runtime.includes("Four hazards stand between you"), 'Crossing journal copy must match the four-hazard runtime');
assert(runtime.includes("Crossing — four hazards on the way to the ship."), 'Quest log copy must match the four-hazard runtime');

assert(runtime.includes('if (quest.hazardsCompleted >= 4)'), 'Crossing must not advance before all four hazards are cleared');
assert(runtime.includes('four hazards block the way to the Aureate Wake'), 'Crossing journal must describe four hazards');
assert(runtime.includes('OBJECTIVE // TALK TO THE THREE SIGNAL CONTACTS'), 'World entry must provide an explicit first objective');
assert(runtime.includes('journal: quest.journal.map'), 'Quest state must expose journal entries to the quest log');
assert(runtime.includes("text('JOURNAL'"), 'Quest log must render journal entries');

assert(runtime.includes('function drawWakeResolutionBeat()'), 'Choice resolution must include a dedicated Wake beat before epilogue');
assert(runtime.includes("quest.state === QUEST_STATES.WAKE"), 'Wake state must be explicitly handled');
assert(runtime.includes('ENTER / SPACE — HEAR WHAT FOLLOWS'), 'Wake beat must require deliberate player advance');

console.log('Aetherwake First Wake opening contract: PASS');
