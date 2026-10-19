'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const source = fs.readFileSync(path.join(__dirname, '..', 'modules', 'first-wake-visual-stage.js'), 'utf8');
const start = source.indexOf("if (paintedBackdrop && scene.id === 'dock_walk') {");
const end = source.indexOf('// Perspective cues pull the eye toward the ship', start);
assert(start > 0 && end > start, 'dock contact bridge must be confined to painted interactive dock walk');
const section = source.slice(start, end);
assert(section.includes('quad(88, 397, 743, 397, 724, 468, 72, 468)'), 'bridge contact surface must support both actors');
assert(section.includes('line(112, 467, 108, 524)') && section.includes('line(697, 467, 716, 526)'), 'bridge must have visible structural supports');
assert(section.includes('line(109, 518, 186, 470)') && section.includes('line(716, 518, 635, 468)'), 'bridge braces must connect to deck');
assert(section.includes('quad(73, 462, 116, 462, 120, 481, 69, 481)') &&
  section.includes('quad(676, 460, 726, 460, 733, 479, 672, 479)'),
  'bridge ends must retain localized masonry and berth bearing seats');
assert(section.includes('quad(679, 443, 718, 443, 727, 459, 674, 459)'),
  'dock berth must retain a narrow rig-to-bearing-seat boarding joint');
assert(!section.includes('width, height'), 'bridge must not become a full-screen overlay');
assert(source.includes('paintedBackdrop ? 52 : 165'), 'preserve visually subordinate original traversal lane');
// Exact convex deck quadrilateral containment for nine logical positions, not screenshots
// visibility or player-eye acceptance assertion.
assert(source.includes('Math.round(145 + progress * 405)'), 'Ender walk x contract unexpectedly changed');
assert(source.includes('Math.round(442 + progress * -16)'), 'Ender walk y contract unexpectedly changed');
assert(source.includes('const ioniaX = cinematic ?') && source.includes(': 612;'), 'Ionia dock x contract unexpectedly changed');
assert(source.includes('const ioniaY = cinematic ?') && source.includes(': 416;'), 'Ionia dock y contract unexpectedly changed');
const deck = [[88, 397], [743, 397], [724, 468], [72, 468]];
function insideDeck(x, y) {
  const signed = deck.map((point, i) => {
    const next = deck[(i + 1) % deck.length];
    return (next[0] - point[0]) * (y - point[1]) -
      (next[1] - point[1]) * (x - point[0]);
  });
  return signed.every(value => value >= 0) || signed.every(value => value <= 0);
}
for (let step = 0; step <= 8; step++) {
  const progress = step / 8;
  const x = Math.round(145 + progress * 405);
  const footY = Math.round(442 - progress * 16);
  assert(insideDeck(x, footY), 'Ender leaves dock deck polygon at step ' + step);
}
assert(insideDeck(612, 416), 'Ionia dock feet must remain inside bridge polygon');
console.log('First Wake dock bridge nine-step trajectory and structural contract: PASS');

