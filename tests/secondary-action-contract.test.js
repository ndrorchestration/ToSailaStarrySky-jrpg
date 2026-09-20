const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'aetherwake.js'),
  'utf8'
);

const combatCtor = source.indexOf('function AetherCombat(p, C) {');
assert(combatCtor >= 0, 'AetherCombat constructor not found');
const combat = source.slice(combatCtor);

const eligibilityIndex = combat.indexOf(
  'const useEligibility = window.AetherAbilityDefs.getUseEligibility('
);
const resetIndex = combat.indexOf(
  'state._secondaryAvailable = false;',
  eligibilityIndex
);
const turnIndex = combat.indexOf('state.turn++;', eligibilityIndex);

assert(eligibilityIndex >= 0, 'primary use eligibility not found');
assert(resetIndex > eligibilityIndex && resetIndex < turnIndex,
  'secondary window is not reset after admission and before turn execution');

assert(!combat.includes('if (state.player.echoes.current >= 2) {'),
  'secondary availability still uses hardcoded echo threshold');
assert(combat.includes(
  'const secondaryEligibility = window.AetherAbilityDefs.getUseEligibility('
), 'secondary availability does not use centralized use eligibility');

assert(combat.includes('secondaryAvailable: Boolean(state._secondaryAvailable)'),
  'secondary availability is not exposed for runtime verification');
assert(combat.includes('lastAbilityId: state._lastAbilityId || null'),
  'last ability ID is not exposed for runtime verification');

const secondaryApiStart = combat.indexOf('  this.resolveSecondaryAction = function() {');
const secondaryApiEnd = combat.indexOf('  this.roll2d6 = roll2d6;', secondaryApiStart);
assert(secondaryApiStart >= 0 && secondaryApiEnd > secondaryApiStart,
  'secondary API block not found');

const secondaryApi = combat.slice(secondaryApiStart, secondaryApiEnd);
assert(secondaryApi.includes('const result = this.resolveTurn(abilityId, null);'),
  'secondary API does not delegate to normal action resolution');
assert(secondaryApi.includes('state._secondaryAvailable = false;'),
  'secondary API does not consume the secondary opportunity');
assert(secondaryApi.includes('return result !== false;'),
  'secondary API does not report failed admission');

console.log('Aetherwake secondary-action contract: PASS');
