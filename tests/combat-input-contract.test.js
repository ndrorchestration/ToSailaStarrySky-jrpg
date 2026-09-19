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

console.log('Aetherwake combat input/log contract: PASS');
