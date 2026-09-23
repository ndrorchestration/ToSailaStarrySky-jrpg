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

assert(source.includes("'ACTIONS [1-8] · USE ' + inputPrompt('confirm', 'combat', 'gamepad')"),
  'combat action panel must advertise stable numeric shortcuts and the active controller Confirm prompt');
assert(source.includes('const aH = 154;'),
  'combat action panel is not sized for eight stable slots');
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

assert(source.includes('let combatActionFocus = null;'),
  'combat must own an explicit semantic action focus state');
assert(source.includes('function ensureCombatActionFocus()'),
  'combat action focus initializer is missing');
assert(source.includes('function moveCombatActionFocus(delta)'),
  'combat directional focus helper is missing');
assert(source.includes('function activateCombatFocusedAction()'),
  'combat confirm activation helper is missing');
assert(source.includes("semanticActionPressed('ui-up')") &&
       source.includes("semanticActionPressed('ui-down')"),
  'keyboard combat focus must consume semantic UI navigation');
assert(source.includes("(focused ? '▶ ' : '  ')"),
  'combat focus must expose a non-color-only marker');
assert(source.includes('combat.resolveTurn(focus.focusedId, null)'),
  'focused combat action must route through the canonical resolveTurn API');

console.log('Aetherwake combat input/log contract: PASS');
