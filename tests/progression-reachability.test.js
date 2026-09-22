const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'aetherwake.js'),
  'utf8'
);

const combatCtor = source.indexOf('function AetherCombat(p, C) {');
assert(combatCtor >= 0, 'AetherCombat constructor not found');

const combatSource = source.slice(combatCtor);
const victoryStart = combatSource.indexOf('    if (state.enemy.hp <= 0) {');
const defeatFloor = combatSource.indexOf('    if (state.player.vit <= 0) {', victoryStart);

assert(victoryStart >= 0 && defeatFloor > victoryStart,
  'victory reward block not found');

const victory = combatSource.slice(victoryStart, defeatFloor);

assert(victory.includes('this.awardXP(xpReward);'),
  'victory XP does not use the progression-aware awardXP path');
assert(!victory.includes('state.player.xp += xpReward;'),
  'victory still bypasses progression with direct XP mutation');

const awardStart = combatSource.indexOf('  this.awardXP = function(amount) {');
const encounterStart = combatSource.indexOf('  this.beginEncounter = function(enemyId) {', awardStart);
assert(awardStart >= 0 && encounterStart > awardStart,
  'awardXP source block not found');

const awardBlock = combatSource.slice(awardStart, encounterStart);
assert(awardBlock.includes('this.levelUp()'),
  'awardXP does not invoke level-up evaluation');
assert(awardBlock.includes('while (p.level < hardCap'),
  'awardXP must support crossing multiple levels safely');

console.log('Aetherwake progression reachability contract: PASS');
