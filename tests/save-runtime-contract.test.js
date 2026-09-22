const assert = require('assert');
const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
const html = fs.readFileSync(path.join(__dirname, '..', 'index-embedded.html'), 'utf8');

assert(html.includes('modules/save-system.js'), 'save-system module is not loaded by the runtime');
assert(html.indexOf('modules/save-system.js') < html.indexOf('aetherwake.js'),
  'save-system module must load before aetherwake.js');

assert(runtime.includes("SAVELOAD: 'saveload'"), 'save/load UI state missing');
assert(runtime.includes("CONTINUE — C"), 'title Continue command missing');
assert(runtime.includes("openSaveLoadMenu('save')"), 'manual save UI entry missing');
assert(runtime.includes("openSaveLoadMenu('load')"), 'manual load UI entry missing');
assert(runtime.includes('function buildSavePayload()'), 'runtime save snapshot missing');
assert(runtime.includes('function applySaveEnvelope(envelope)'), 'runtime restore path missing');
assert(runtime.includes('window.AetherPartyState.setActivePartyIds(ids)'),
  'load path must restore canonical active-party references');
assert(runtime.includes('window.AetherPartyState.validate()'),
  'load path must validate canonical party invariants');
assert(runtime.includes('restorePersistentState(payload.airNavigation)'),
  'air-navigation persistence must be restored through its validated contract');
assert(runtime.includes("autosave('chapter-handoff')"), 'chapter handoff autosave missing');
assert(runtime.includes("autosave('quest-advance')"), 'quest-transition autosave missing');
assert(runtime.includes("autosave('combat-resolution')"), 'combat-resolution autosave missing');
assert(runtime.includes('if (!world || !world.player || gameOver) return false;'),
  'saving must fail closed when the world is unavailable or game is over');
assert(runtime.includes('quest.state === QUEST_STATES.WAKE'),
  'saving must account for the transient Wake resolution state');
assert(runtime.includes("return gameState === STATE.WORLD || gameState === STATE.AIRSHIP"),
  'manual saving must be limited to stable world/airship states');

console.log('Aetherwake save-runtime contract: PASS');
