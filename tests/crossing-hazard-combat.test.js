'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');

assert(runtime.includes('const HAZARD_ENCOUNTER_IDS = Object.freeze({'),
  'hazard encounter mapping missing');
for (const binding of [
  "sky_predator: 'skyPredator'",
  "wind_shear: 'windShear'",
  "aether_leak: 'aetherLeak'",
  "corporate_intercept: 'corporateSalvager'",
]) {
  assert(runtime.includes(binding), 'hazard enemy mapping missing: ' + binding);
}

assert(runtime.includes('function startHazardEncounter(index)'),
  'hazard encounter launcher missing');
assert(runtime.includes('quest.state !== QUEST_STATES.CROSSING'),
  'hazard checks must be bounded to crossing state');
assert(runtime.includes('pendingHazardIndex = index'),
  'hazard combat must remember the pending hazard');
assert(runtime.includes('startCombat(enemyId, STATE.WORLD)'),
  'hazard must launch the real combat system');
assert(runtime.includes('combatState.enemy.hp <= 0'),
  'hazard completion must require combat victory');
assert(runtime.includes('completeHazard(resolvedHazardIndex)'),
  'victory must complete the pending hazard');
assert(runtime.includes('HAZARD REMAINS //'),
  'defeat path must leave hazard unresolved');

const proximityStart = runtime.indexOf('function checkHazardProximity');
const proximityEnd = runtime.indexOf('function completeHazard', proximityStart);
const proximity = runtime.slice(proximityStart, proximityEnd);
assert(!/completeHazard\(/.test(proximity),
  'proximity trigger must not silently complete hazards');

console.log('Aetherwake crossing hazard combat contract: PASS');
