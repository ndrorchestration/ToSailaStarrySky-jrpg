const fs = require('fs');
const path = require('path');

const runtime = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

assert(!runtime.includes('menuAutoStartTimer'),
  'title/menu must never auto-start Chapter 1 after idle time');
assert(!runtime.includes('millis() - menuAutoStartTimer > 3000'),
  'legacy three-second title auto-start must remain removed');
assert(runtime.includes('if (elapsed >= BOOT_LOAD_MS)'),
  'boot preamble must enter a player-held presentation state after loading');
assert(runtime.includes('const PREAMBLE_PAGES = Object.freeze(['),
  'opening story must be authored as discrete player-paced pages');
assert(runtime.includes('PREAMBLE_PAGE_MIN_MS'),
  'opening story pages must retain an anti-double-tap minimum dwell');
assert(runtime.includes('if (preamblePage < PREAMBLE_PAGES.length - 1)'),
  'boot input must advance one story page before handing off to title');
assert(runtime.includes('[ press any key for next ]') && runtime.includes('[ press any key for title ]'),
  'preamble must expose explicit page and final-title advance prompts');
assert(!runtime.includes('PREAMBLE_DURATION'),
  'story-bearing preamble must not depend on autonomous duration/scroll progression');
assert(runtime.includes('if (gameState === STATE.BOOT)'),
  'boot state must own explicit player advance handling');
assert(runtime.includes('gameState = STATE.MENU;'),
  'final player advance must transition boot presentation to title/menu');
assert(runtime.includes("if (key === 'n' || key === 'N' || key === 'Enter' || key === ' ')"),
  'title/menu must still require an explicit new-game input');

console.log('Aetherwake Chapter 1 opening pacing contract: PASS');
