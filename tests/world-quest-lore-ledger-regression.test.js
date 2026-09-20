const assert = require('assert');
const fs = require('fs');

// Quick syntax check before running tests
const syntax = require('child_process').execSync('node --check aetherwake.js 2>&1').toString().trim();
if (syntax) {
  console.error('Syntax check failed:', syntax);
  process.exit(1);
}

// Regression tests for Cluster 3: World/Quest/Lore/Ledger (D11-D15)
// D11: Lore uses loreLayer sidecar instead of property on numeric tile
// D12: Quest init publishes after initQuest() completes
// D13: Player coordinates synced (tileX/tileY/x/y)
// D14: Crossing uses hazard-list length, not hard-coded 3
// D15: getLedger() implemented returning deep-copied array

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

// D11: Verify loreLayer sidecar is used instead of _loreText property
test('D11: Lore uses loreLayer sidecar', () => {
  // Check loreLayer is initialized
  assert(aetherwakeSrc.includes('loreLayer = []'), 'loreLayer should be initialized');
  assert(aetherwakeSrc.includes('loreLayer[l.y][l.x] = l.text'), 'loreLayer should store lore text');
  
  // Check that _loreText is NOT used on groundLayer
  const loreAssignMatch = aetherwakeSrc.match(/groundLayer\[l\.y\]\[l\.x\]\._loreText = l\.text;/);
  assert(!loreAssignMatch, 'Should NOT assign _loreText to groundLayer tile');
  
  // Check checkLoreTile uses loreLayer
  const checkLoreMatch = aetherwakeSrc.match(/function checkLoreTile[\s\S]*?function checkHazardProximity/m);
  assert(checkLoreMatch, 'checkLoreTile function should exist');
  const checkLoreBody = checkLoreMatch[0];
  assert(checkLoreBody.includes('loreLayer[ty] && loreLayer[ty][tx]'), 
    'checkLoreTile should read from loreLayer sidecar');
  assert(!checkLoreBody.includes('tile._loreText'), 
    'checkLoreTile should NOT read _loreText from tile');
});

// D12: Verify World.quest is published after initQuest()
test('D12: Quest published after initQuest() completes', () => {
  // Find init function (called from core.js setup())
  const initMatch = aetherwakeSrc.match(/function init\(\) \{([\s\S]*?)^\}/m);
  assert(initMatch, 'init function should exist');
  const body = initMatch[1];
  
  // Check that initQuest() is called before World.quest = quest
  const initQuestIdx = body.indexOf('initQuest()');
  const questAssignIdx = body.indexOf('World.quest = quest');
  
  assert(initQuestIdx !== -1, 'initQuest() should be called in init');
  assert(questAssignIdx !== -1, 'World.quest should be assigned in init');
  assert(initQuestIdx < questAssignIdx, 
    'initQuest() must be called BEFORE World.quest = quest');
});

// D13: Verify coordinate sync in movePlayer
test('D13: Player coordinates synced in movePlayer', () => {
  const movePlayerMatch = aetherwakeSrc.match(/function movePlayer\(dx, dy\) \{([\s\S]*?)^\}/m);
  assert(movePlayerMatch, 'movePlayer function should exist');
  const body = movePlayerMatch[1];
  
  // Check that all four coordinates are updated
  assert(body.includes('player.tileX = nx'), 'tileX should be updated');
  assert(body.includes('player.tileY = ny'), 'tileY should be updated');
  assert(body.includes('player.x = player.tileX'), 'x should be synced to tileX');
  assert(body.includes('player.y = player.tileY'), 'y should be synced to tileY');
});

// D14: Verify advanceCrossing uses hazard-list length
test('D14: advanceCrossing uses hazard-list length', () => {
  const advanceMatch = aetherwakeSrc.match(/function advanceCrossing\(\) \{([\s\S]*?)^\}/m);
  assert(advanceMatch, 'advanceCrossing function should exist');
  const body = advanceMatch[1];
  
  // Check that it uses quest.crossingHazards.length
  assert(body.includes('crossingHazards') && body.includes('.length'), 
    'advanceCrossing should use crossingHazards.length');
  // Check that hard-coded 3 is NOT used
  const hardCodedMatch = body.match(/hazardsCompleted >= 3/);
  assert(!hardCodedMatch, 'Should NOT use hard-coded threshold of 3');
});

// D15: Verify getLedger() is implemented and returns deep copy
test('D15: getLedger() returns deep-copied array', () => {
  // Check getLedger function exists
  const getLedgerMatch = aetherwakeSrc.match(/function getLedger\(\) \{([\s\S]*?)^\}/m);
  assert(getLedgerMatch, 'getLedger function should exist');
  const body = getLedgerMatch[1];
  
  // Check it returns a mapped copy
  assert(body.includes('.map(') || body.includes('slice()'), 
    'getLedger should return a copy of entries');
  assert(body.includes('ledger.entries'), 'getLedger should read from ledger.entries');
});

test('D14b: crossing hazard configuration rejects malformed values', () => {
  const crossingMatch = aetherwakeSrc.match(/function advanceCrossing\(\) \{([\s\S]*?)^\}/m);
  assert(crossingMatch, 'advanceCrossing function should exist');
  const body = crossingMatch[1];

  assert(body.includes('Array.isArray(quest.crossingHazards)'),
    'advanceCrossing should require an array hazard configuration');
  assert(body.includes('quest.crossingHazards.length === 0'),
    'advanceCrossing should reject an empty hazard configuration');
});

console.log('\nAll Cluster 3 regression tests passed!');
