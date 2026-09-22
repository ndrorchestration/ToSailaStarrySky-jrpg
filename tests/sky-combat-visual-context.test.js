'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const visual = fs.readFileSync(path.join(root, 'modules', 'combat-visual-stage.js'), 'utf8');

assert(runtime.includes("const skyCombat = combatReturnState === STATE.AIRSHIP"),
  'combat dispatch must detect aerial return state');
assert(runtime.includes("domain: skyCombat ? 'sky' : 'ground'"),
  'combat dispatch must pass scene domain');
assert(runtime.includes("weatherId: skyTravel && skyTravel.weather ? skyTravel.weather.id : 'clear'"),
  'combat dispatch must pass weather');
assert(runtime.includes("encounterPressure: skyTravel ? skyTravel.encounterPressure : 0"),
  'combat dispatch must pass wake pressure');

assert(visual.includes("domain === 'sky'"),
  'combat visual stage must distinguish sky domain');
assert(visual.includes("weatherId === 'crosswind'"),
  'combat visual stage must render crosswind context');
assert(visual.includes("weatherId === 'aether-squall'"),
  'combat visual stage must render aether squall context');
assert(visual.includes("'  //  PRESSURE ' + pressure"),
  'combat turn rail must display wake pressure');
assert(visual.includes("String(altitude || 'cruise').toUpperCase()"),
  'combat turn rail must display altitude');

console.log('Aetherwake aerial combat visual context: PASS');
