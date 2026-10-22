const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const runtime = fs.readFileSync(path.resolve(__dirname, '..', 'aetherwake.js'), 'utf8');

const hazardMatch = runtime.match(/crossingHazards:\s*\[([\s\S]*?)\r?\n\s*\],\r?\n\s*contactNPCs:/);
assert(hazardMatch,
  'crossing hazard definition block is missing');
const hazardBlock = hazardMatch[1];
const definedHazards = (hazardBlock.match(/done: false/g) || []).length;
assert(definedHazards === 3,
  'First Wake Crossing must define exactly three authored hazards');
assert(runtime.includes('quest.hazardsCompleted >= quest.crossingHazards.length'),
  'Crossing progression must derive its threshold from the hazard contract');
assert(!runtime.includes('quest.crossingHazards[3].done'),
  'stale fourth-hazard array access must not return');
assert(runtime.includes("qs.hazardsCompleted + '/' + qs.crossingHazards.length"),
  'quest log must show the real hazard denominator');
assert(runtime.includes("quest.hazardsCompleted + '/' + quest.crossingHazards.length + ' hazards'"),
  'world HUD must show the real hazard denominator');

assert(runtime.includes('function ensureIoniaJoinedForStormChoice()'),
  'Ionia storm/shield recruitment boundary is missing');
assert(runtime.includes("window.AetherPartyState.recruitCharacter('ionia')"),
  'Ionia must join through canonical party-state authority');
assert(runtime.indexOf('ensureIoniaJoinedForStormChoice();') <
       runtime.indexOf('quest.state = QUEST_STATES.CHOICE;'),
  'Ionia must join before the storm choice becomes active');

assert(runtime.includes('chapterOneComplete: false'),
  'Chapter I completion state must initialize false');
assert(runtime.includes('quest.chapterOneComplete = true'),
  'Wake completion must explicitly mark Chapter I complete');
assert(runtime.includes("text('CHAPTER I COMPLETE'"),
  'epilogue must identify Chapter I completion to the player');
assert(runtime.includes('Auroral lanes remain closed. The Wake still needs the rest of its crew.'),
  'Chapter I ending must preserve the auroral-lane crew gate');

console.log('Aetherwake First Wake Chapter I cohesion contract: PASS');
