const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const runtime = fs.readFileSync(path.resolve(__dirname, '..', 'aetherwake.js'), 'utf8');
const capture = fs.readFileSync(path.resolve(__dirname, '..', 'scripts', 'capture-player-evidence.js'), 'utf8');

const vignetteStart = runtime.indexOf('function drawVignette()');
const vignetteEnd = runtime.indexOf('// ── Toast rendering', vignetteStart);
assert(vignetteStart >= 0 && vignetteEnd > vignetteStart, 'vignette implementation is missing');
const vignette = runtime.slice(vignetteStart, vignetteEnd);
assert(!vignette.includes('ellipse('),
  'vignette must not stack filled center ellipses over gameplay');
assert(vignette.includes('noFill()') && vignette.includes('const maxAlpha = window._isNight ? 72 : 34'),
  'vignette must remain edge-only with restrained day/night opacity');

const dialogueStart = runtime.indexOf('function drawDialogueOverlay()');
const dialogueEnd = runtime.indexOf('function drawShopOverlay()', dialogueStart);
assert(dialogueStart >= 0 && dialogueEnd > dialogueStart, 'dialogue overlay implementation is missing');
const dialogue = runtime.slice(dialogueStart, dialogueEnd);
assert(dialogue.includes('78 * (openness / 255)'),
  'dialogue backdrop must use the restrained single dimmer');
assert(!dialogue.includes('180 * (openness / 255)'),
  'opaque dialogue backdrop regression must not return');
assert(dialogue.includes('width/2 - 320') && dialogue.includes('bw = 640') && dialogue.includes('bh = 112'),
  'dialogue box must preserve the expanded readable layout');
assert(dialogue.includes('textSize(14)') && dialogue.includes('textLeading(18)'),
  'dialogue body must preserve readable native-size typography');

assert(runtime.includes('function completeDialogueTypeIn()'),
  'dialogue type-in completion helper is missing');
assert(/if \(dialogueTypeIn\.active\) \{\r?\n\s+completeDialogueTypeIn\(\);/.test(runtime),
  'confirm must complete current dialogue type-in before advancing');

assert(runtime.includes('drawPixelBorder(px + 8, ey, pw - 16, 66'),
  'combat enemy box must preserve extra weakness space');
assert(runtime.includes("wrapText('Weakness: ' +"),
  'combat weakness text must wrap rather than clip');
assert(runtime.includes('function drawCombatResource(label, value, x, y, labelColor)'),
  'combat resources must use the compact resource renderer');
assert(runtime.includes('const leftX = px + 14') && runtime.includes('const rightX = px + 118'),
  'combat resources must remain in two bounded columns');

assert(capture.includes("window.gameState === 'menu'"),
  'player evidence must wait for the real title/menu state');
assert(capture.includes("await page.waitForTimeout(180);"),
  'player evidence must allow a rendered frame to settle');
const ioniaCaptureAt = capture.indexOf("'captain-ionia-dialogue'");
const enterBeforeIonia = capture.lastIndexOf("await page.keyboard.press('Enter');", ioniaCaptureAt);
const settleBeforeIonia = capture.lastIndexOf('await page.waitForTimeout(180);', ioniaCaptureAt);
assert(ioniaCaptureAt > 0 &&
       enterBeforeIonia >= 0 &&
       settleBeforeIonia > enterBeforeIonia &&
       settleBeforeIonia < ioniaCaptureAt,
  'dialogue evidence must complete type-in and settle before capture');

console.log('Aetherwake Chapter I readability contract: PASS');
