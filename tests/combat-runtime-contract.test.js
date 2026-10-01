const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'aetherwake.js'),
  'utf8'
);

function assertIncludes(fragment, message) {
  assert(source.includes(fragment), message);
}

assertIncludes(
  'const productionDerivedStats = scaledTemplate.productionDerivedStats',
  'live encounters must construct production-derived defense data'
);
assertIncludes(
  'productionDerivedStats,',
  'live enemy state must expose production-derived defense data'
);
assertIncludes(
  'window.AetherPartyState.refreshProductionStats(p);',
  'combat level-up must refresh production stats'
);
assertIncludes(
  'world.player.productionDerivedStats = JSON.parse(JSON.stringify(p.productionDerivedStats));',
  'combat write-back must preserve production-derived stats'
);
assertIncludes(
  'const activeLead =',
  'encounter scaling must identify the live combat lead'
);
assertIncludes(
  'partySize: partyLevels.length',
  'encounter scaling must not silently scale for inactive companions'
);
assertIncludes(
  "state.encounterOver = true;",
  'combat must close encounters on both victory and defeat paths'
);
assertIncludes(
  'state._defeat = true;',
  'combat defeat must expose an explicit terminal marker'
);
assertIncludes(
  "'Action blocked by current SSOT: '",
  'SSOT-blocked actions must retain a distinct runtime reason'
);
assertIncludes(
  "'Not enough resources — '",
  'resource failures must remain distinct from SSOT-blocked actions'
);
assert(!source.includes('The remaining five actions stay on the legacy 2D6 compatibility'),
  'combat boundary comment must not claim live contract actions are legacy');

console.log('Aetherwake combat runtime contract: PASS');
