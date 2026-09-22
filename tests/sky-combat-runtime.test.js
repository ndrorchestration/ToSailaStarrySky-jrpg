'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const runtime=fs.readFileSync(path.join(__dirname,'..','aetherwake.js'),'utf8');
const combat=fs.readFileSync(path.join(__dirname,'..','modules','combat.js'),'utf8');
const nav=require('../modules/air-navigation.js');

assert(runtime.includes('startCombat(encounter.enemyId, STATE.AIRSHIP)'),
  'sky encounter does not enter shared turn-based combat');
assert(runtime.includes('combatReturnState = returnState || STATE.WORLD'),
  'combat return-state contract missing');
assert(runtime.includes('if (gameState === STATE.AIRSHIP) airshipFlightMode = true'),
  'combat completion does not restore active flight');
assert(runtime.includes("const skyCombat = combatReturnState === STATE.AIRSHIP") &&
  runtime.includes("domain: skyCombat ? 'sky' : 'ground'"),
  'combat renderer does not receive aerial scene domain');
assert(combat.includes("sceneOptions && sceneOptions.domain === 'sky'"),
  'shared combat renderer lacks sky presentation mode');
assert(combat.includes("sceneDomain === 'sky' ? '⚔ SKY ENCOUNTER ⚔' : '⚔ COMBAT ⚔'"),
  'sky encounter presentation banner missing');
assert(combat.includes("if (sceneDomain === 'ground')"),
  'combat staging no longer distinguishes ground from open sky');
assert(runtime.includes("weatherId: skyTravel && skyTravel.weather ? skyTravel.weather.id : 'clear'"),
  'sky combat handoff does not carry weather context');
assert(runtime.includes('encounterPressure: skyTravel ? skyTravel.encounterPressure : 0'),
  'sky combat handoff does not carry encounter pressure');
assert(combat.includes("sceneWeather === 'crosswind'"),
  'sky combat renderer lacks crosswind staging');
assert(combat.includes("sceneWeather === 'aether-squall'"),
  'sky combat renderer lacks aether-squall staging');
assert(combat.includes("' // PRESSURE ' + scenePressure"),
  'sky combat banner lacks flight pressure context');
assert.deepStrictEqual(
  nav.SKY_ENCOUNTERS.map(e=>e.id).sort(),
  ['aetherLeak','skyPredator','windShear'].sort(),
  'authored sky encounter pool drifted'
);
assert(nav.SKY_ENCOUNTERS.every(e=>Array.isArray(e.altitudes)&&e.altitudes.length),
  'sky encounter altitude eligibility missing');
console.log('Aetherwake sky combat runtime contract: PASS');

