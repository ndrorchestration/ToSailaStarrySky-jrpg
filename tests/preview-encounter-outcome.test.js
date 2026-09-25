const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const runtimePath = path.join(__dirname, '..', 'aetherwake.js');
const runtime = fs.readFileSync(runtimePath, 'utf8');
const start = runtime.indexOf('function finishCombat() {');
const end = runtime.indexOf('\nfunction openState(', start);

assert.notEqual(start, -1, 'runtime must define finishCombat');
assert.notEqual(end, -1, 'finishCombat must end before openState');

function completeEncounter({ encounterOver, enemyHp, playerVit, returnState = 'world' }) {
  const autosaves = [];
  const sandbox = {
    combat: {
      getState() {
        return {
          encounterOver,
          enemy: { hp: enemyHp },
          player: { vit: playerVit, scrap: 3 },
        };
      },
    },
    world: { player: { vit: 8, scrap: 0 } },
    window: {},
    pendingHazardIndex: null,
    gameState: 'combat',
    combatReturnState: returnState,
    prevState: 'combat',
    STATE: { WORLD: 'world' },
    VIS: { fadeTransitions: false },
    requestAutosave: reason => autosaves.push(reason),
  };

  vm.runInNewContext(runtime.slice(start, end), sandbox, { filename: runtimePath });
  vm.runInNewContext('finishCombat()', sandbox);
  return { sandbox, autosaves };
}

const victory = completeEncounter({ encounterOver: true, enemyHp: 0, playerVit: 7 });
assert.equal(victory.sandbox.gameState, 'world', 'combat should restore the configured return state');
assert.equal(victory.sandbox.window.gameState, 'world', 'window game state should mirror restored return state');
assert.equal(victory.sandbox.world.player.vit, 7, 'combat vitality must write back to world player');
assert.equal(victory.sandbox.world.player.scrap, 3, 'combat scrap must write back to world player');
assert.deepEqual(victory.autosaves, ['combat-resolution'],
  'terminal combat should request the combat-resolution autosave');

const defeat = completeEncounter({ encounterOver: true, enemyHp: 18, playerVit: 1 });
assert.equal(defeat.sandbox.gameState, 'world', 'terminal defeat should still restore the configured return state');
assert.equal(defeat.sandbox.world.player.vit, 1,
  'generic finishCombat must preserve combat-engine vitality when no mandatory hazard is pending');
assert.deepEqual(defeat.autosaves, ['combat-resolution'],
  'terminal defeat should request the combat-resolution autosave');

const unfinished = completeEncounter({ encounterOver: false, enemyHp: 12, playerVit: 6 });
assert.deepEqual(unfinished.autosaves, [],
  'non-terminal combat must not request a combat-resolution autosave');

console.log('Combat finish smoke: write-back, return state, and autosave semantics PASS.');
