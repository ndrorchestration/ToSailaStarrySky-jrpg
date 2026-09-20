const assert = require('assert');
const fs = require('fs');

// Quick syntax check before running tests
const syntax = require('child_process').execSync('node --check aetherwake.js 2>&1').toString().trim();
if (syntax) {
  console.error('Syntax check failed:', syntax);
  process.exit(1);
}

// Regression tests for Cluster 5: Combat/Airship (D20-D23)
// D20: Combat snapshot includes complete player state
// D21: beginEncounter returns {ok, reason} and fails closed
// D22: Combat log uses state.log, renderer handles empty log
// D23: Airship transfer only consumed when player eligible

const aetherwakeSrc = fs.readFileSync('aetherwake.js', 'utf-8');

function test(name, fn) {
  try {
    fn();
    console.log(`PASS ${name}`);
  } catch (error) {
    console.error(`FAIL ${name}: ${error.message}`);
    throw error;
  }
}

// D20: Verify combat snapshot includes complete player state
test('D20: Combat init receives complete player snapshot', () => {
  // Find startCombat function
  const startCombatMatch = aetherwakeSrc.match(/function startCombat\(enemyId\) \{([\s\S]*?)^\}/m);
  assert(startCombatMatch, 'startCombat function should exist');
  const body = startCombatMatch[1];
  
  // Check that player snapshot includes identity fields
  assert(body.includes('name: world.player.name'), 'Should include player name');
  assert(body.includes('class: world.player.class'), 'Should include player class');
  assert(body.includes('maxVit: world.player.maxVit'), 'Should include maxVit');
  
  // Check primary stats
  assert(body.includes('vit: world.player.vit'), 'Should include vit');
  assert(body.includes('scrap: world.player.scrap'), 'Should include scrap');
  
  // Check resource maxima
  assert(body.includes('aetherMax: world.player.aetherMax'), 'Should include aetherMax');
  assert(body.includes('heatMax: world.player.heatMax'), 'Should include heatMax');
  assert(body.includes('echoesMax: world.player.echoesMax'), 'Should include echoesMax');
  
  // Check staff charges
  assert(body.includes('maxStaffCharges: world.player.maxStaffCharges'), 'Should include maxStaffCharges');
  assert(body.includes('staffMax: world.player.maxStaffCharges'), 'StaffMax should come from player, not hard-coded 2');
  assert(!body.includes('staffMax: 2'), 'Should NOT hard-code staffMax: 2');
  
  // Check level/XP
  assert(body.includes('level: world.player.level'), 'Should include level');
  assert(body.includes('xp: world.player.xp'), 'Should include xp');
  
  // Check unlocked abilities (deep copy)
  assert(body.includes('unlockedAbilities: world.player.unlockedAbilities.slice') || 
         body.includes('unlockedAbilities: world.player.unlockedAbilities.slice()'), 
         'Should deep copy unlockedAbilities');
  
  // Check equipment (deep copy)
  assert(body.includes('equipment: world.player.equipment ? JSON.parse(JSON.stringify'), 
         'Should deep copy equipment');
});

// D21: Verify beginEncounter returns {ok, reason} and fails closed
test('D21: beginEncounter returns {ok, reason} for unknown enemy', () => {
  // Find beginEncounter in combat module
  const beginEncounterMatch = aetherwakeSrc.match(/this\.beginEncounter = function\(enemyId\) \{([\s\S]*?)^\}/m);
  assert(beginEncounterMatch, 'beginEncounter should exist in combat module');
  const body = beginEncounterMatch[1];
  
  // Check that unknown enemy returns {ok: false, reason}
  assert(body.includes('return { ok: false, reason:'), 
    'beginEncounter should return {ok: false, reason} for unknown enemy');
  assert(body.includes("'Unknown enemy: ' + enemyId"), 
    'Should include enemy ID in reason');
  
  // Check reset of transient fields
  assert(body.includes('state.log = []'), 
    'Should reset combat log for new encounter');
});

// D21b: Verify startCombat fails closed when beginEncounter returns error
test('D21b: startCombat fails closed on invalid enemy', () => {
  const startCombatMatch = aetherwakeSrc.match(/function startCombat\(enemyId\) \{([\s\S]*?)^\}/m);
  assert(startCombatMatch, 'startCombat function should exist');
  const body = startCombatMatch[1];
  
  // Check that it checks beginEncounter result before entering combat state
  assert(body.includes('const result = combat.beginEncounter'), 
    'Should capture beginEncounter result');
  assert(body.includes('if (!result || !result.ok)'), 
    'Should check result.ok before entering combat');
  assert(body.includes('return;'), 
    'Should return early without entering STATE.COMBAT on failure');
});

// D22: Verify logCombat writes to combat state log
test('D22: logCombat uses combat state log', () => {
  const logCombatMatch = aetherwakeSrc.match(/function logCombat\(msg\) \{([\s\S]*?)^\}/m);
  assert(logCombatMatch, 'logCombat function should exist');
  const body = logCombatMatch[1];
  
  // Check that it writes to combat state log when available
  assert(body.includes('combat.getState()'), 
    'logCombat should check combat state');
  assert(body.includes('cs.log.push(msg)'), 
    'logCombat should push to combat state log');
  
  // Check fallback to UI.combatLog
  assert(body.includes('window.UI.combatLog.push(msg)'), 
    'logCombat should have UI.combatLog fallback');
});

// D22b: Verify drawCombatLog reads from combat state log
test('D22b: drawCombatLog reads from combat state log', () => {
  const drawLogMatch = aetherwakeSrc.match(/function drawCombatLog\(lx, ly, lw, lh\) \{([\s\S]*?)^\}/m);
  assert(drawLogMatch, 'drawCombatLog function should exist');
  const body = drawLogMatch[1];
  
  // Check that it reads from combat state log
  assert(body.includes('combat.getState()'), 
    'drawCombatLog should check combat state');
  assert(body.includes('cs.log && Array.isArray(cs.log)'), 
    'drawCombatLog should use combat state log when available');
  
  // Check handling of empty log (no throw)
  assert(body.includes('const start = Math.max(0, log.length - maxEntries)'), 
    'Should handle empty log without throwing');
});

// D21c: Invalid enemy preflight must happen before any mutation/transfer consumption
test('D21c: invalid enemy preflight precedes combat init and airship consumption', () => {
  const startCombatMatch = aetherwakeSrc.match(/function startCombat\(enemyId\) \{([\s\S]*?)^\}/m);
  assert(startCombatMatch, 'startCombat function should exist');
  const body = startCombatMatch[1];

  const preflightIdx = body.indexOf('combat.canBeginEncounter');
  const consumeIdx = body.indexOf('consumeTransfer(airshipState)');
  const initIdx = body.indexOf('combat.init(playerSnapshot)');

  assert(preflightIdx !== -1, 'startCombat should preflight enemy identity');
  assert(consumeIdx !== -1, 'startCombat should contain airship transfer consumption');
  assert(initIdx !== -1, 'startCombat should initialize combat for valid encounters');
  assert(preflightIdx < consumeIdx,
    'enemy preflight must occur before airship transfer consumption');
  assert(preflightIdx < initIdx,
    'enemy preflight must occur before combat initialization');

  assert(aetherwakeSrc.includes('this.canBeginEncounter = function(enemyId)'),
    'AetherCombat should expose a non-mutating encounter preflight');
});

// D23: Verify airship transfer only consumed when eligible
test('D23: Airship transfer eligibility check in startCombat', () => {
  const startCombatMatch = aetherwakeSrc.match(/function startCombat\(enemyId\) \{([\s\S]*?)^\}/m);
  assert(startCombatMatch, 'startCombat function should exist');
  const body = startCombatMatch[1];
  
  // Check for eligibility check
  assert(body.includes('isEligible'), 'Should have isEligible check');
  assert(body.includes('world.player.shipBoarded'), 
    'Should check if player is boarded');
  assert(body.includes('pendingCombat'), 
    'Should check for pending combat transfers');
  
  // Verify the structure: the consumeTransfer(airshipState) call must be inside the if (isEligible) block
  // Find the position of the eligibility check and the actual consumeTransfer(airshipState) call
  const eligibleIdx = body.indexOf('if (isEligible) {');
  const consumeCallIdx = body.indexOf('consumeTransfer(airshipState)');
  
  assert(eligibleIdx !== -1, 'Should have if (isEligible) { block');
  assert(consumeCallIdx !== -1, 'Should have consumeTransfer(airshipState) call');
  assert(eligibleIdx < consumeCallIdx, 
    'if (isEligible) must come before consumeTransfer(airshipState)');
  
  // Check that transfer is only consumed when eligible
  assert(body.includes('if (isEligible) {'), 
    'Should conditionally consume transfer');
});

console.log('\nAll Cluster 5 regression tests passed!');
