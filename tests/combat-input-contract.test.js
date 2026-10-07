const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'aetherwake.js'),
  'utf8'
);

const combatCtor = source.indexOf('function AetherCombat(p, C) {');
assert(combatCtor > 0, 'AetherCombat constructor not found');

const coreSource = source.slice(0, combatCtor);
const combatSource = source.slice(combatCtor);

assert(!coreSource.includes('state._secondaryAvailable'),
  'core must not read private combat secondary state');
assert(!coreSource.includes('state._lastAbilityId'),
  'core must not read private combat last-ability state');
assert(coreSource.includes('combat.resolveSecondaryAction();'),
  'core does not delegate secondary input through combat API');

assert(combatSource.includes('this.resolveSecondaryAction = function()'),
  'combat secondary-action API is missing');
assert(combatSource.includes('state._secondaryAvailable = false;'),
  'combat secondary state is not reset/consumed');
assert(combatSource.includes('state._lastAbilityId = null;'),
  'combat last-ability state is not reset');
assert(combatSource.includes("if (actionText) log('[Turn ' + state.turn + '] ' + actionText);"),
  'combat action log does not use actionText');
assert(!combatSource.includes("if (text) log('[Turn ' + state.turn + '] ' + text);"),
  'legacy p5 text-symbol logging bug remains');

assert(source.includes("drawGlowText('ACTIONS'"),
  'combat action panel heading is missing');
assert(source.includes('text(String(idx + 1), ax + 8, ay + 6);'),
  'combat action panel must keep stable numbered action slots');
assert(source.includes('const aH = 76;'),
  'combat action panel must retain the compact V46 command-window height');
assert(!combatSource.includes("const resourceCost = (action.tier || 0) + action.cost;"),
  'resolveTurn still duplicates the action resource-cost formula');
assert(source.includes('window.AetherAbilityDefs.getActionResourceCost(action)'),
  'combat UI does not use centralized action cost');
assert(combatSource.includes('window.AetherAbilityDefs.getUseEligibility('),
  'resolveTurn does not use centralized use eligibility');

const eligibilityIndex = combatSource.indexOf('window.AetherAbilityDefs.getUseEligibility(');
const turnIncrementIndex = combatSource.indexOf('state.turn++;', eligibilityIndex);
assert(eligibilityIndex >= 0 && turnIncrementIndex > eligibilityIndex,
  'use eligibility must run before turn consumption');

console.log('Aetherwake combat input/log contract: PASS');
