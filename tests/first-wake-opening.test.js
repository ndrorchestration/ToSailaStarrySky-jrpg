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

console.log('Aetherwake First Wake opening contract: PASS');
