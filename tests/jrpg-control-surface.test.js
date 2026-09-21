const assert = require('assert');
const fs = require('fs');

const source = fs.readFileSync('aetherwake.js', 'utf8');
const airshipUi = fs.readFileSync('modules/airship-ui.js', 'utf8');
const charCreate = fs.readFileSync('modules/char-create.js', 'utf8');

function block(name, nextName) {
  const start = source.indexOf('function ' + name);
  assert(start >= 0, name + ' function missing');
  const end = nextName
    ? source.indexOf('function ' + nextName, start + 1)
    : source.length;
  return source.slice(start, end >= 0 ? end : source.length);
}

const keyTyped = block('keyTyped', 'windowResized');
assert(keyTyped.includes('handleTypedChar'),
  'keyTyped must remain available for character text entry');
assert(!keyTyped.includes('startGame()') &&
  !keyTyped.includes('gameState = STATE.MENU') &&
  !keyTyped.includes('startCombat(') &&
  !keyTyped.includes('handleChoiceInput('),
  'keyTyped must not perform game-state actions; keyPressed is the single action authority');

assert(source.includes('let overlayStateStack = []'),
  'nested JRPG overlay stack is missing');
const openState = block('openState', 'closeOverlay');
const closeOverlay = block('closeOverlay', 'startFade');
assert(openState.includes('overlayStateStack.push(gameState)'),
  'openState must push the current state for nested menus');
assert(closeOverlay.includes('overlayStateStack.pop()'),
  'closeOverlay must pop one nested menu level');
assert(closeOverlay.includes("overlayStateStack[overlayStateStack.length - 1]"),
  'prevState compatibility projection must follow the remaining stack');

// Title/menu flow is explicit: no timer-driven implicit new game.
assert(!source.includes('millis() - menuAutoStartTimer > 3000'),
  'title menu must not auto-start a new game');
assert(source.includes("label: 'NEW GAME'"),
  'title menu must expose NEW GAME');
assert(source.includes("label: 'CONTINUE'"),
  'title menu must expose CONTINUE when a save exists');

const titleInput = block('handleTitleMenuInput', 'getSystemMenuCommands');
assert(titleInput.includes('input.up') && titleInput.includes('input.down'),
  'title menu must use directional cursor input');
assert(titleInput.includes('input.ok'),
  'title menu must use semantic OK to confirm');

const handleInputBlock = block('handleInput', 'handleWorldInput');
assert(handleInputBlock.includes('if (gameState === STATE.DIALOGUE)'),
  'dialogue input branch is missing');
assert(handleInputBlock.includes("if (cancel)") &&
  handleInputBlock.includes("world.closeDialogue()"),
  'JRPG cancel must close dialogue');
assert(handleInputBlock.includes("if (ok || keysPressed[69])") &&
  handleInputBlock.includes("world.nextDialogueLine()"),
  'JRPG OK must advance dialogue independently of cancel');

// Normal world play must be possible without letter hotkeys.
const worldInput = block('handleWorldInput', 'getTitleMenuCommands');
assert(worldInput.includes('inputPressed(api.ACTION.OK)'),
  'WORLD must use semantic OK for contextual interaction');
assert(worldInput.includes('inputPressed(api.ACTION.MENU)'),
  'WORLD must use semantic MENU for pause/system menu');
assert(worldInput.includes('openState(STATE.SYSTEMMENU)'),
  'WORLD semantic menu must open system menu');

// Specialty world actions are reachable from the system menu.
for (const command of [
  "label: 'STATUS'",
  "label: 'QUEST'",
  "label: 'MYCELIAL LEDGER'",
  "label: 'AETHER SENSE'",
  "label: 'COVENANT FIELD'",
  "label: 'SKY / GROUND LAYER'",
  "label: 'SAVE'",
  "label: 'LOAD'",
]) {
  assert(source.includes(command), 'system menu missing ' + command);
}

// Save/load must return to WORLD before invoking their safe-state APIs.
const activateSystem = block('activateSystemMenuCommand', 'handleSystemMenuInput');
assert(activateSystem.includes("command.id === 'save'") &&
  activateSystem.includes('closeOverlay();') &&
  activateSystem.includes('quickSaveGame();'),
  'system menu SAVE must close to safe WORLD state before saving');
assert(activateSystem.includes("command.id === 'load'") &&
  activateSystem.includes('quickLoadGame();'),
  'system menu LOAD must be accessible through normal menu flow');

// Core choice must support directional cursor + OK, numbers optional only.
assert(worldInput.includes("questState.state === 'choice'"),
  'WORLD must detect the Core choice surface');
assert(worldInput.includes('choiceCursor') &&
  worldInput.includes('world.selectChoicePath(choiceCursor)'),
  'Core choice must support cursor + semantic OK');
assert(source.includes('↑↓ SELECT   ·   Z/ENTER OK   ·   1/2/3 SHORTCUT'),
  'Core choice UI must label numbers as shortcuts, not required controls');

// Combat already exposes cursor + confirm; numbers remain optional shortcuts.
const handleInput = block('handleInput', 'handleWorldInput');
assert(handleInput.includes('combatCursor') &&
  handleInput.includes("combat.resolveTurn(selected.id, null)"),
  'combat must resolve the cursor-selected action with semantic OK');
assert(handleInput.includes('inputPressed(A.SHIFT)'),
  'combat secondary/special action must be reachable through semantic Shift');

// Airship must be fully cursor-driven.
const airshipInput = block('handleAirshipInput', 'doMove');
assert(airshipInput.includes('input.cancel'),
  'airship must use semantic cancel/back');
assert(airshipInput.includes('input.up') && airshipInput.includes('input.down') &&
  airshipInput.includes('input.left') && airshipInput.includes('input.right'),
  'airship must support directional selection');
assert(airshipInput.includes('input.ok') &&
  airshipInput.includes('activateAirshipCommand(commands[airshipCursor])'),
  'airship must execute selected command through semantic OK');
assert(airshipUi.includes('↑↓/←→ SELECT   ·   Z/ENTER OK   ·   X/ESC BACK'),
  'airship UI must advertise JRPG semantic controls');

// Onboarding should teach the same language.
assert(charCreate.includes('Z / ENTER') || charCreate.includes('Z/ENTER'),
  'onboarding must teach Z/Enter confirm');
assert(charCreate.includes('X / ESC') || charCreate.includes('X/ESC'),
  'onboarding must teach X/Esc cancel');

// Title screen is the player-facing control contract.
assert(source.includes('ARROWS  move / select'),
  'title must advertise arrow navigation');
assert(source.includes('Z / ENTER / SPACE  confirm / interact'),
  'title must advertise semantic OK');
assert(source.includes('X / ESC  menu / back'),
  'title must advertise semantic cancel/menu');
assert(source.includes('SHIFT  dash / special'),
  'title must advertise Shift');
assert(source.includes('Q / W  page'),
  'title must advertise page controls');

console.log('Aetherwake complete Memories-style JRPG control surface: PASS');
