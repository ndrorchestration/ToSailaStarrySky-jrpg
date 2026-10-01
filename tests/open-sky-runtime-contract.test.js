'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname,'..','aetherwake.js'),'utf8');
const embedded = fs.readFileSync(path.join(__dirname,'..','index-embedded.html'),'utf8');
const desktop = JSON.parse(fs.readFileSync(path.join(__dirname,'..','package.json'),'utf8'));

assert(embedded.includes('modules/air-navigation.js'),
  'embedded runtime does not load air-navigation');
assert.strictEqual(desktop.main, 'index-embedded.html');

assert(runtime.includes("AIRSHIP: 'airship'"),
  'dedicated open-sky state missing');
assert(runtime.includes('function enterAirNavigation()'),
  'flight entry function missing');
assert(runtime.includes('function leaveAirNavigation()'),
  'flight exit function missing');
assert(runtime.includes('function handleAirNavigationInput()'),
  'flight input handler missing');
assert(runtime.includes('function drawAirNavigationScene()'),
  'flight renderer missing');
assert(runtime.includes('nav.undock(airNavigationState)'),
  'moored movement does not cast off');
assert(runtime.includes('const routeFactor = activeRouteAssistId'),
  'route-aware navigation factor is not bound');
assert(runtime.includes('nav.move(airNavigationState, dx * routeFactor, dy * routeFactor)'),
  'route-aware navigation movement not bound');
assert(runtime.includes('nav.changeAltitude(airNavigationState'),
  'altitude controls not bound');
assert(runtime.includes('nav.dock(airNavigationState)'),
  'docking control not bound');
assert(runtime.includes('nav.encounterCheck(airNavigationState)'),
  'deterministic sky encounter cadence not bound');
assert(runtime.includes('startCombat(encounter.enemyId, STATE.AIRSHIP)'),
  'sky encounter does not preserve flight return state');
assert(runtime.includes('combatReturnState = returnState || STATE.WORLD'),
  'combat launcher lacks return-state contract');
assert(runtime.includes('gameState = combatReturnState || STATE.WORLD'),
  'combat completion does not honor return-state contract');
assert(runtime.includes("airNavigationState.mooredLandmarkId !== 'wake-dock'"),
  'landing is not constrained to authored ground-map destination');
assert(!runtime.includes('TURN-BASED 2D6 PbtA'),
  'active title branding still exposes obsolete dice-system identity');

console.log('Aetherwake live open-sky runtime contract: PASS');
