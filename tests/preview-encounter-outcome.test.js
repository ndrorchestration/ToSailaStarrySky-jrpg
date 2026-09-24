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

function completePreviewEncounter({ encounterOver, enemyHp, playerVit }) {
  const toasts = [];
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
    gameState: 'combat',
    combatReturnState: 'world',
    prevState: 'combat',
    STATE: { WORLD: 'world' },
    previewEncounterStarted: true,
    previewEncounterFinished: false,
    previewEncounterArmed: false,
    previewEndAt: 0,
    VIS: { fadeTransitions: false },
    C: { teal: 'teal', rust: 'rust', parchment: 'parchment' },
    millis: () => 1000,
    showToast: message => toasts.push(message),
  };

  vm.runInNewContext(runtime.slice(start, end), sandbox, { filename: runtimePath });
  vm.runInNewContext('finishCombat()', sandbox);
  return { sandbox, toasts };
}

const victory = completePreviewEncounter({ encounterOver: true, enemyHp: 0, playerVit: 7 });
assert.equal(victory.sandbox.gameState, 'world', 'combat should return to the world');
assert.equal(victory.sandbox.previewEncounterFinished, true,
  'a real enemy defeat should finish the preview encounter');
assert.equal(victory.sandbox.previewEndAt, 3400,
  'victory should schedule the end card after the return transition');
assert(victory.toasts.includes('THE SKY GOES QUIET // FOR NOW'),
  'victory should show the authored return toast');

const defeat = completePreviewEncounter({ encounterOver: true, enemyHp: 18, playerVit: 1 });
assert.equal(defeat.sandbox.gameState, 'world', 'defeat should return to the world');
assert.equal(defeat.sandbox.previewEncounterFinished, false,
  'defeat must not mark the preview encounter complete');
assert.equal(defeat.sandbox.previewEncounterStarted, false,
  'defeat should leave the encounter available to retry');
assert.equal(defeat.sandbox.previewEncounterArmed, true,
  'returning to Ionia should be able to start a retry');
assert.equal(defeat.sandbox.previewEndAt, 0, 'defeat must not schedule the end card');
assert(defeat.toasts.some(message => /SKY-PREDATOR.*(REMAINS|TRY AGAIN)/.test(message)),
  'defeat should tell the player the encounter remains retryable');
assert(!defeat.toasts.includes('THE SKY GOES QUIET // FOR NOW'),
  'defeat must not display the victory-only toast');

console.log('Preview encounter outcomes: victory completes; defeat remains retryable.');
