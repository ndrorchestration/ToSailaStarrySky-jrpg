'use strict';
// Deliberately RED at PR #276: guards the live-controller prerequisite for HUD tests.
// Do not replace the controller with invented objectives or feedback to make it pass.
const assert = require('assert');
const opening = require('../modules/first-wake-opening.js');
for (const name of ['wakeExplorationView', 'nearbyWakeHotspot']) {
  assert.strictEqual(typeof opening[name], 'function',
    'First Wake HUD is unreachable: the loaded controller must expose ' + name);
}
const state = opening.createState();
for (let i = 0; i < opening.SCENES.length; i++) {
  const scene = opening.currentScene(state);
  if (scene.sequence >= 5 && scene.sequence <= 8) {
    assert(state.wakeExploration, scene.id + ': live exploration state is missing');
    const view = opening.wakeExplorationView(state);
    assert(view && typeof view.objective === 'string' && view.objective.trim(),
      scene.id + ': no authored objective reaches the HUD');
    assert.strictEqual(typeof view.lastMessage, 'string',
      scene.id + ': no authored feedback reaches the HUD');
  }
  if (state.complete) break;
  opening.tickPresentation(state, 10000);
  opening.advance(state);
}
console.log('First Wake live HUD reachability: PASS');
