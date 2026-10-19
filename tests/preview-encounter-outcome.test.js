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

function completeCombatReturn({ encounterOver, enemyHp, playerVit }) {
  const toasts = [];
  const autosaves = [];
  const sandbox = {
    combat: {
      getState() {
        return {
          encounterOver,
          enemy: { hp: enemyHp },
          player: { vit: playerVit, scrap: 0 },
        };
      },
    },
    world: { player: { vit: 8 } },
    window: {},
    pendingHazardIndex: null,
    randomEncounterPending: false,
    gameState: 'combat',
    combatReturnState: 'world',
    prevState: 'combat',
    STATE: { WORLD: 'world' },
    VIS: { fadeTransitions: false },
    C: { teal: 'teal', rust: 'rust', parchment: 'parchment' },
    millis: () => 1000,
    requestAutosave: reason => autosaves.push(reason),
    showToast: message => toasts.push(message),
  };

  vm.runInNewContext(runtime.slice(start, end), sandbox, { filename: runtimePath });
  vm.runInNewContext('finishCombat()', sandbox);
  return { sandbox, toasts, autosaves };
}

const victory = completeCombatReturn({ encounterOver: true, enemyHp: 0, playerVit: 7 });
assert.equal(victory.sandbox.gameState, 'world', 'completed combat should return to the world');
assert.equal(victory.sandbox.world.player.vit, 7, 'combat result should copy player vitality back to world state');
assert.deepEqual(victory.autosaves, ['combat-resolution'],
  'completed combat should request the current Chapter 1 combat-resolution autosave');

const defeat = completeCombatReturn({ encounterOver: true, enemyHp: 18, playerVit: 1 });
assert.equal(defeat.sandbox.gameState, 'world', 'a completed defeat should still return to the world');
assert.equal(defeat.sandbox.world.player.vit, 1, 'defeat vitality should be preserved for non-hazard combat');
assert.deepEqual(defeat.autosaves, ['combat-resolution'],
  'completed defeat should also checkpoint the resolved combat state');

const unresolved = completeCombatReturn({ encounterOver: false, enemyHp: 18, playerVit: 6 });
assert.equal(unresolved.sandbox.gameState, 'world', 'finishCombat should honor its explicit return-state contract');
assert.deepEqual(unresolved.autosaves, [],
  'combat that is not marked over must not request a resolution autosave');

console.log('Preview combat return contract: world state sync and combat-resolution autosave remain stable.');
