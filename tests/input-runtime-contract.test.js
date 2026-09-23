const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(
  path.resolve(__dirname, '..', 'aetherwake.js'),
  'utf8'
);

const publish = source.indexOf('// Publish interaction intent before dispatch');
const dispatch = source.indexOf('  handleInput();', publish);
assert(publish >= 0 && dispatch > publish,
  'world interaction intent must be published before input dispatch');

assert(source.includes('function semanticActionHeld(actionId, context)'),
  'held keyboard movement must resolve through semantic bindings');
assert(source.includes("const movementActions = ['move-up','move-down','move-left','move-right'];"),
  'WORLD movement must use semantic action identities');
assert(source.includes('doMoveSemantic(action);'),
  'WORLD semantic movement must preserve immediate first-step behavior');
assert(source.includes("semanticActionPressed('airship-altitude-up')") &&
       source.includes("semanticActionPressed('airship-dock')"),
  'AIRSHIP keyboard controls must consume semantic actions after remapping');

assert(source.includes("const firstContact = !nearest.flags.met;"),
  'dialogue must capture first-contact state before mutating the NPC');
assert(source.includes('openDialogue(nearest, firstContact)'),
  'dialogue must preserve the first-contact intro batch');

assert(source.includes("const shopOpened = world && typeof world.openShop === 'function'"),
  'shop entry must go through the world proximity guard');
assert(source.includes('function mousePressed()'),
  'choice UI must expose a mouse selection path');

assert(source.includes('function refreshSemanticActionsFromKeyboard()'),
  'runtime must derive semantic actions from keyboard events');
assert(source.includes("window.AetherInputActions.actionsForKeyboardEvent"),
  'runtime must use the semantic input action registry');
assert(source.includes("semanticActionPressed('quest-log')"),
  'quest log must consume semantic action input');
assert(source.includes("semanticActionPressed('character-sheet')"),
  'character sheet must consume semantic action input');
assert(source.includes("semanticActionPressed('manual-save')"),
  'manual save must consume semantic action input');
assert(source.includes("semanticActionPressed('manual-load')"),
  'manual load must consume semantic action input');
assert(source.includes("semanticActionPressed('board-or-flight')"),
  'board/flight must consume semantic action input');
assert(source.includes("semanticActionPressed('ledger')"),
  'ledger must consume semantic action input');
assert(source.includes("semanticActionPressed('cancel')"),
  'cancel/close must consume semantic action input');

assert(source.includes('function syncSaveMenuFocusSnapshot()'),
  'save/load overlay must expose deterministic focus state');
assert(source.includes('window.AetherFocusManager.createState(slots'),
  'save/load overlay must create focus through the shared focus manager');
assert(source.includes("semanticActionPressed('ui-up')"),
  'save/load focus must consume semantic UI navigation');
assert(source.includes("semanticActionPressed('ui-down')"),
  'save/load focus must consume semantic UI navigation');
assert(source.includes("'▶ '"),
  'focused save slot must have a non-color-only visual marker');

assert(source.includes('function pollGamepadDiagnostics()'),
  'runtime must poll browser gamepad state each frame');
assert(source.includes('navigator.getGamepads()'),
  'runtime must obtain current gamepad objects from navigator.getGamepads');
assert(source.includes('window.AetherGamepadInput.poll('),
  'runtime gamepad polling must use the semantic gamepad adapter');
assert(source.includes('function dispatchGamepadActions(result)'),
  'runtime must isolate semantic controller dispatch from keyboard dispatch');
assert(source.includes("gameState === STATE.MENU"),
  'safe controller dispatch must support title menu actions');
assert(source.includes("result.pressed.includes('open-settings')"),
  'controller Menu action must open Settings from title');
assert(source.includes("gameState === STATE.SETTINGS"),
  'controller dispatch must support Settings navigation');
assert(source.includes("gameState === STATE.WORLD"),
  'controller dispatch must support WORLD semantic actions');
assert(source.includes("gameState === STATE.DIALOGUE"),
  'controller dispatch must support dialogue confirm/cancel');
assert(source.includes("gameState === STATE.AIRSHIP"),
  'controller dispatch must support AIRSHIP semantic actions');
assert(source.includes('function gamepadMovementShouldFire(actionId, result, now)'),
  'controller movement must use a bounded repeat clock');
assert(source.includes('function moveWorldBySemanticAction(actionId)'),
  'WORLD controller movement must not synthesize keyboard events');
assert(source.includes('function moveAirshipBySemanticAction(actionId)'),
  'AIRSHIP controller movement must use the navigation subsystem directly');
assert(source.includes('window._lastGamepadDispatchHandled'),
  'controller dispatch result must remain inspectable for regression tests');

assert(source.includes("if (gameState === STATE.COMBAT)"),
  'controller semantic dispatcher must include COMBAT');
assert(source.includes("pressed.includes('ui-up') || pressed.includes('ui-left')"),
  'controller combat focus must support previous-action navigation');
assert(source.includes("pressed.includes('ui-down') || pressed.includes('ui-right')"),
  'controller combat focus must support next-action navigation');
assert(source.includes("pressed.includes('confirm')") &&
       source.includes('activateCombatFocusedAction();'),
  'controller combat Confirm must activate the focused action');

assert(source.includes("semanticActionPressed('open-save-load')"),
  'keyboard runtime must expose a focused Save/Load entry action');
assert(source.includes("pressed.includes('open-save-load')"),
  'controller runtime must expose a focused Save/Load entry action');
assert(source.includes("pressed.includes('continue-game')"),
  'controller runtime must expose semantic title Continue');
assert(source.includes("semanticActionPressed('continue-game')"),
  'keyboard runtime must route title Continue through semantic input');
assert(source.includes("inputPrompt('continue-game', 'menu', 'both')"),
  'title Continue prompt must reflect the active binding');
assert(source.includes("if (gameState === STATE.SAVELOAD)"),
  'controller dispatcher must handle the Save/Load overlay semantically');

assert(source.includes("CONTROLS: 'controls'"),
  'runtime must expose a dedicated Controls remapping state');
assert(source.includes('function drawControlsOverlay()'),
  'runtime must render the Controls remapping surface');
assert(source.includes('function commitKeyboardBindingCapture(code)'),
  'runtime must capture and persist keyboard remaps');
assert(source.includes('function commitGamepadBindingCapture(buttonIndex)'),
  'runtime must capture and persist gamepad remaps');
assert(source.includes('window.AetherInputBindings.setKeyboardBinding(') &&
       source.includes('window.AetherInputBindings.setGamepadBinding('),
  'remap UI must route through the versioned input-binding authority');
assert(source.includes('window.AetherInputPrompt = inputPrompt'),
  'dynamic prompt ownership must be exposed from the active binding state');

assert(source.includes("inputPrompt('confirm', 'boot', 'both')") &&
       source.includes("inputPrompt('open-settings', 'boot', 'both')"),
  'BOOT hints must reflect active confirm/settings bindings');
assert(source.includes("inputPrompt('confirm', 'world', 'both') + ' — HEAR WHAT FOLLOWS'"),
  'WAKE resolution hint must reflect the active Confirm binding');
assert(source.includes("inputPrompt('character-sheet', 'world', 'both')"),
  'character-sheet close hint must reflect its active binding');
assert(!source.includes('[ ENTER/CONFIRM skip  |  S/MENU settings ]'),
  'BOOT retains stale physical-key instructions');
assert(!source.includes('Tab: toggle log'),
  'combat log must not advertise a nonexistent toggle');
assert(!source.includes('[ R ] to begin again'),
  'epilogue must not advertise a nonexistent restart binding');

console.log('Aetherwake input runtime contract: PASS');
