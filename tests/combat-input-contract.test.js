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

assert(source.includes("drawGlowText('ACTIONS [1-8]'"),
  'combat action panel still advertises the wrong key range');
assert(source.includes('const aH = 154;'),
  'combat action panel is not sized for eight stable slots');
assert(!combatSource.includes("const resourceCost = (action.tier || 0) + action.cost;"),
  'resolveTurn still duplicates the action resource-cost formula');
assert(source.includes('window.AetherAbilityDefs.getActionResourceCost(action)'),
  'combat UI does not use centralized action cost');
assert(source.includes('const weaknessRevealed = Boolean('),
  'combat UI does not gate weakness presentation on reveal state');
assert(source.includes("weakness: unknown. Analyze the target to reveal it."),
  'encounter log does not hide weakness before discovery');
assert(!source.includes("log(state.enemy.name + ' weakness: ' + state.enemy.weakness);"),
  'encounter start still leaks the enemy weakness');
assert(combatSource.includes('window.AetherAbilityDefs.getUseEligibility('),
  'resolveTurn does not use centralized use eligibility');

const eligibilityIndex = combatSource.indexOf('window.AetherAbilityDefs.getUseEligibility(');
const turnIncrementIndex = combatSource.indexOf('state.turn++;', eligibilityIndex);
assert(eligibilityIndex >= 0 && turnIncrementIndex > eligibilityIndex,
  'use eligibility must run before turn consumption');

console.log('Aetherwake combat input/log contract: PASS');
