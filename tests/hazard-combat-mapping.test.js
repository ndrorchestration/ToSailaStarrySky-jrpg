const fs = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Contract: hazardCombatMapping.test.js
// Verifies that crossing hazards map to combat enemies, and that the
// completeHazard() → startCombat() → finishCombat() lifecycle resolves
// the hazard after combat instead of auto-completing it.
// ---------------------------------------------------------------------------

const src = fs.readFileSync(
  path.join(__dirname, '..', 'aetherwake.js'),
  'utf8'
);

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

// 1. The HAZARD_ENEMY_MAP constant must exist and map 4 indices.
const mapMatch = src.match(/const\s+HAZARD_ENEMY_MAP\s*=\s*\[([\s\S]*?)\];/);
assert(mapMatch, 'HAZARD_ENEMY_MAP constant must be defined');
const mapBody = mapMatch[1];
// Extract just the single-quoted string literals (ignore inline comments).
const quoted = mapBody.match(/'([^']+)'/g);
assert(quoted, 'HAZARD_ENEMY_MAP must contain quoted string entries');
const mapEntries = quoted.map(s => s.slice(1, -1));
assert(mapEntries.length === 4,
  'HAZARD_ENEMY_MAP must map exactly 4 hazard indices');
assert(mapEntries[0] === 'skyPredator',
  'Hazard 0 (sky_predator) must map to skyPredator enemy');
assert(mapEntries[1] === 'windShear',
  'Hazard 1 (wind_shear) must map to windShear enemy');
assert(mapEntries[2] === 'aetherLeak',
  'Hazard 2 (aether_leak) must map to aetherLeak enemy');
assert(mapEntries[3] === 'corporateSalvager',
  'Hazard 3 (corporate_intercept) must map to corporateSalvager enemy');

// 2. The pendingHazardIndex variable must exist.
assert(
  /let\s+pendingHazardIndex\s*=.*?-1/.test(src),
  'pendingHazardIndex variable must be declared and default to -1'
);

// 3. completeHazard must reference HAZARD_ENEMY_MAP and startCombat.
assert(
  src.includes('HAZARD_ENEMY_MAP[index]') || src.includes('HAZARD_ENEMY_MAP['),
  'completeHazard must reference HAZARD_ENEMY_MAP'
);
assert(
  /function\s+completeHazard\(index\)/.test(src),
  'completeHazard function must still be defined'
);

// 4. The completeHazard function body must call startCombat for the mapped
//    enemy rather than immediately marking the hazard done.
const completeHazardStart = src.indexOf('function completeHazard(index)');
assert(completeHazardStart >= 0, 'completeHazard function not found');
const afterCompleteHazard = src.substring(completeHazardStart, completeHazardStart + 1200);
assert(
  afterCompleteHazard.includes('startCombat'),
  'completeHazard must call startCombat(enemyId)'
);

// 5. finishCombat must handle pendingHazardIndex resolution.
const finishCombatStart = src.indexOf('function finishCombat()');
assert(finishCombatStart >= 0, 'finishCombat function not found');
// Find the NEXT function after finishCombat to bound the search window.
const nextFuncAfterFC = src.indexOf('\nfunction ', finishCombatStart + 400);
const finishCombatEnd = nextFuncAfterFC > 0 ? nextFuncAfterFC : Math.min(finishCombatStart + 4000, src.length);
const afterFinishCombat = src.substring(finishCombatStart, finishCombatEnd);
assert(
  afterFinishCombat.includes('pendingHazardIndex') && afterFinishCombat.includes('hIdx'),
  'finishCombat must resolve pendingHazardIndex after combat'
);
assert(
  afterFinishCombat.includes('quest.crossingHazards[hIdx].done = true'),
  'finishCombat must mark the hazard done'
);
assert(
  afterFinishCombat.includes('quest.hazardsCompleted++'),
  'finishCombat must increment hazardsCompleted'
);

// 6. Confirm the 4 enemy types exist in the combat catalog.
for (const enemyId of ['skyPredator', 'windShear', 'aetherLeak', 'corporateSalvager']) {
  assert(
    src.includes(enemyId + ':') || src.includes(enemyId + ': {'),
    enemyId + ' must exist in the combat enemy catalog'
  );
}

console.log('Aetherwake hazard → combat mapping contract: PASS');
