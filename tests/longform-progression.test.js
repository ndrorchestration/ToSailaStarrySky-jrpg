const assert = require('assert');
const progression = require('../modules/progression-defs.js');

assert.strictEqual(progression.VERSION, '0.2.0');
assert.strictEqual(progression.LEVEL_LIMITS.MAIN_STORY_TARGET, 130);
assert.strictEqual(progression.LEVEL_LIMITS.MASTERY_THRESHOLD, 131);
assert.strictEqual(progression.LEVEL_LIMITS.MASTER_ART_THRESHOLD, 150);
assert.strictEqual(progression.LEVEL_LIMITS.POSTGAME_WORLD_MAGIC_THRESHOLD, 150);
assert.strictEqual(progression.LEVEL_LIMITS.HARD_CAP, 175);

// Preserve current prototype thresholds.
assert.strictEqual(progression.getXPToNext(1), 50);
assert.strictEqual(progression.getXPToNext(2), 75);
assert.strictEqual(progression.getXPToNext(3), 112);
assert.strictEqual(progression.getXPToNext(4), 168);
assert.strictEqual(progression.getXPToNext(5), 253);

// Long-form curve must remain finite, increasing, and playable.
let previous = progression.getXPToNext(5);
for (let level = 6; level < progression.LEVEL_LIMITS.HARD_CAP; level++) {
  const next = progression.getXPToNext(level);
  assert(Number.isFinite(next), 'XP threshold must remain finite at level ' + level);
  assert(next >= previous, 'XP threshold regressed at level ' + level);
  assert(next < 20000, 'XP threshold became grind-scale excessive at level ' + level);
  previous = next;
}

assert.strictEqual(progression.getXPToNext(175), 0);
assert.strictEqual(progression.normalizeLevel(999), 175);
assert.strictEqual(progression.normalizeLevel(-10), 1);

assert.strictEqual(progression.getProgressionBand(1).id, 'foundation');
assert.strictEqual(progression.getProgressionBand(130).id, 'endgame');
assert.strictEqual(progression.getProgressionBand(131).id, 'mastery');
assert.strictEqual(progression.getProgressionBand(150).id, 'master');
assert.strictEqual(progression.getProgressionBand(175).id, 'capstone');

assert.strictEqual(progression.getMilestone(130).id, 'main_story_ceiling');
assert.strictEqual(progression.getMilestone(150).id, 'master_art_eligibility');
assert.strictEqual(progression.getMilestone(160).id, 'hidden_mastery');
assert.strictEqual(progression.getMilestone(175).id, 'level_cap');

const cumulative = (targetLevel) => {
  let total = 0;
  for (let level = 1; level < targetLevel; level++) {
    total += progression.getXPToNext(level);
  }
  return total;
};

const to130 = cumulative(130);
const to150 = cumulative(150);
const to175 = cumulative(175);
assert(to130 > 0 && to150 > to130 && to175 > to150);
assert(to175 < 2000000, 'total XP curve should stay bounded for a 175-level game');

console.log('Aetherwake long-form progression contract: PASS');
console.log(JSON.stringify({
  xpTo130: to130,
  xpTo150: to150,
  xpTo175: to175,
  level130Next: progression.getXPToNext(130),
  level150Next: progression.getXPToNext(150),
  level174Next: progression.getXPToNext(174),
}, null, 2));
