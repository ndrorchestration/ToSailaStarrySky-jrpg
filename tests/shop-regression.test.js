const assert = require('assert');
const fs = require('fs');

// Quick syntax check before running tests
const syntax = require('child_process').execSync('node --check aetherwake.js 2>&1').toString().trim();
if (syntax) {
  console.error('Syntax check failed:', syntax);
  process.exit(1);
}

// Regression tests for Cluster 4: Shop (D16-D19)
// D16: openShop returns {ok, reason} and M key routes through it
// D17: All items use scrap currency, transactional purchases
// D18: Items have stable IDs
// D19: Echo/heat capacity caps are explicit constants

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

// D16: Verify openShop returns {ok, reason}
test('D16: openShop returns {ok, reason} on failure', () => {
  const openShopMatch = aetherwakeSrc.match(/function openShop\(\) \{([\s\S]*?)^\}/m);
  assert(openShopMatch, 'openShop function should exist');
  const body = openShopMatch[1];
  
  // Check that it returns {ok: false, reason: ...} on distance failure
  assert(body.includes('return { ok: false, reason:'), 
    'openShop should return {ok: false, reason} when merchant is too far');
  assert(body.includes("'Merchant is too far away.'"), 
    'openShop should have appropriate reason message');
  
  // Check successful return
  assert(/return \{ ok: true, items:/.test(body), 
    'openShop should return {ok: true, items} on success');
});

// D16b: Verify M key in handleWorldInput routes through world.openShop()
test('D16b: M key routes through world.openShop() with result check', () => {
  const handleWorldMatch = aetherwakeSrc.match(/function handleWorldInput\(\) \{([\s\S]*?)^\}/m);
  assert(handleWorldMatch, 'handleWorldInput function should exist');
  const body = handleWorldMatch[1];
  
  // Find M key handling
  const mKeyIdx = body.indexOf('if (keysPressed[77]');
  assert(mKeyIdx !== -1, 'M key handling should exist');
  
  // Extract M key block
  let depth = 0;
  let mKeyEnd = mKeyIdx;
  let foundOpen = false;
  for (let i = mKeyIdx; i < body.length; i++) {
    if (body[i] === '{') { depth++; foundOpen = true; }
    if (body[i] === '}') { depth--; if (foundOpen && depth === 0) { mKeyEnd = i; break; } }
  }
  const mKeyBlock = body.substring(mKeyIdx, mKeyEnd + 1);
  
  assert(mKeyBlock.includes('world.openShop()'), 'M key should call world.openShop()');
  assert(mKeyBlock.includes('result.ok') || mKeyBlock.includes('result && result.ok'), 
    'M key should check result.ok before opening state');
});

// D17: Verify all items use scrap currency (no aether kind)
test('D17: All shop items use scrap currency', () => {
  // Check initShop items
  const initShopMatch = aetherwakeSrc.match(/function initShop\(\) \{([\s\S]*?)\n  \}/m);
  assert(initShopMatch, 'initShop function should exist');
  const body = initShopMatch[1];
  
  // All items should have kind: 'scrap'
  const aetherKindMatch = body.match(/kind: 'aether'/);
  assert(!aetherKindMatch, 'No item should have kind: aether (all use scrap)');
  
  // Check purchaseItem uses scrap
  const purchaseMatch = aetherwakeSrc.match(/function purchaseItem\(itemId\) \{([\s\S]*?)^\}/m);
  assert(purchaseMatch, 'purchaseItem function should exist');
  const purchaseBody = purchaseMatch[1];
  
  assert(purchaseBody.includes('player.scrap < item.cost'), 
    'purchaseItem should check scrap currency');
  assert(purchaseBody.includes('player.scrap += changes.scrap'), 
    'purchaseItem should deduct scrap transactionally');
});

// D17b: Verify transactional purchase (validation before commit)
test('D17b: purchaseItem validates before committing', () => {
  const purchaseMatch = aetherwakeSrc.match(/function purchaseItem\(itemId\) \{([\s\S]*?)^\}/m);
  assert(purchaseMatch, 'purchaseItem function should exist');
  const body = purchaseMatch[1];
  
  // Check that it returns early on validation failures without committing
  assert(body.includes('return { ok: false, reason:'), 
    'purchaseItem should return {ok: false, reason} on validation failure');
  assert(body.includes('Unknown item.'), 'Should reject unknown items');
  assert(body.includes('Not enough scrap.'), 'Should reject insufficient scrap');
  
  // Check that changes are prepared but only committed at the end
  assert(body.includes('const changes = { scrap: -item.cost }'), 
    'Should prepare changes object');
  assert(body.includes('player.scrap += changes.scrap'), 
    'Should commit changes at end');
});

// D18: Verify items have stable IDs
test('D18: Shop items have stable IDs', () => {
  const initShopMatch = aetherwakeSrc.match(/function initShop\(\) \{([\s\S]*?)\n  \}/m);
  assert(initShopMatch, 'initShop function should exist');
  const body = initShopMatch[1];
  
  // Check for stable IDs
  assert(body.includes("id: 'solar_resonator_recharge'"), 'Solar Resonator should have stable ID');
  assert(body.includes("id: 'staff_crystal_polish'"), 'Staff Crystal Polish should have stable ID');
  assert(body.includes("id: 'mycelial_thread_sheaf'"), 'Mycelial Thread Sheaf should have stable ID');
  assert(body.includes("id: 'nav_line_compass'"), 'Nav-Line Compass should have stable ID');
  assert(body.includes("id: 'hull_patch_kit'"), 'Hull Patch Kit should have stable ID');
  assert(body.includes("id: 'heat_sink_fitting'"), 'Heat Sink Fitting should have stable ID');
  
  // Check purchaseItem uses ID lookup
  const purchaseMatch = aetherwakeSrc.match(/function purchaseItem\(itemId\) \{([\s\S]*?)^\}/m);
  assert(purchaseMatch, 'purchaseItem should accept itemId');
  const purchaseBody = purchaseMatch[1];
  assert(purchaseBody.includes("i => i.id === itemId"), 
    'purchaseItem should find item by id');
});

// D19: Verify explicit echo and heat capacity caps
test('D19: Echo and heat capacity caps are explicit constants', () => {
  // Check for ECHO_MAX_CAP constant
  assert(aetherwakeSrc.includes('const ECHO_MAX_CAP ='), 
    'ECHO_MAX_CAP constant should be defined');
  assert(aetherwakeSrc.includes('const ECHO_MAX_CAP = 8'), 
    'ECHO_MAX_CAP should be 8');
  
  // Check for HEAT_MAX_CAP constant
  assert(aetherwakeSrc.includes('const HEAT_MAX_CAP ='), 
    'HEAT_MAX_CAP constant should be defined');
  assert(aetherwakeSrc.includes('const HEAT_MAX_CAP = 8'), 
    'HEAT_MAX_CAP should be 8');
  
  // Check that purchaseItem uses these caps
  const purchaseMatch = aetherwakeSrc.match(/function purchaseItem\(itemId\) \{([\s\S]*?)^\}/m);
  assert(purchaseMatch, 'purchaseItem function should exist');
  const purchaseBody = purchaseMatch[1];
  
  assert(purchaseBody.includes('ECHO_MAX_CAP'), 
    'purchaseItem should check ECHO_MAX_CAP for mycelial_thread_sheaf');
  assert(purchaseBody.includes('HEAT_MAX_CAP'), 
    'purchaseItem should check HEAT_MAX_CAP for heat_sink_fitting');
  
  // Check already-maxed rejection
  assert(aetherwakeSrc.includes('Echo capacity already at maximum'), 
    'Should reject when echo capacity is maxed');
  assert(aetherwakeSrc.includes('Heat capacity already at maximum'), 
    'Should reject when heat capacity is maxed');
});

console.log('\nAll Cluster 4 regression tests passed!');
