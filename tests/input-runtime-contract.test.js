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
assert(/keyRepeatFirst\[code\] = true;\r?\n\s+doMove\(code\);/.test(source),
  'the first movement keypress must move immediately');
assert(source.includes('delete keyRepeat[keyCode];') &&
       source.includes('delete keyRepeatFirst[keyCode];'),
  'movement repeat state must clear on key release so discrete taps are not swallowed');

assert(source.includes("const firstContact = !nearest.flags.met;"),
  'dialogue must capture first-contact state before mutating the NPC');
assert(source.includes('openDialogue(nearest, firstContact)'),
  'dialogue must preserve the first-contact intro batch');

assert(source.includes("const shopOpened = world && typeof world.openShop === 'function'"),
  'shop entry must go through the world proximity guard');
assert(source.includes('function mousePressed()'),
  'choice UI must expose a mouse selection path');

console.log('Aetherwake input runtime contract: PASS');
