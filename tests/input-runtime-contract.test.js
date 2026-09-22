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

assert(source.includes(
  'const movementCodes = [UP_ARROW, DOWN_ARROW, LEFT_ARROW, RIGHT_ARROW, 87, 83, 65, 68];'
), 'WASD and arrow movement codes must share the repeat path');
assert(source.includes('if (code === UP_ARROW || code === 87)'),
  'WASD north movement is not mapped');
assert(source.includes('if (code === RIGHT_ARROW || code === 68)'),
  'WASD east movement is not mapped');
assert(source.includes('keyRepeatFirst[code] = true;\n        doMove(code);'),
  'the first movement keypress must move immediately');

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
assert(source.includes('Combat action') && source.includes('remains keyboard-authoritative'),
  'runtime must preserve the boundary that combat action selection is not controller-enabled yet');

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
assert(source.includes("if (gameState === STATE.SAVELOAD)"),
  'controller dispatcher must handle the Save/Load overlay semantically');

console.log('Aetherwake input runtime contract: PASS');
