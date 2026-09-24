'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'combat-visual-stage.js'), 'utf8');
const enemyAnchor = { x: 200, y: 160 };
const predatorBounds = {
  left: enemyAnchor.x - 42,
  right: enemyAnchor.x + 42,
  top: enemyAnchor.y - 47,
  bottom: enemyAnchor.y + 25,
};

function renderEnemy(type, now) {
  const rects = [];
  let activeFill = null;
  const sandbox = {
    window: {
      AetherPixelSprites: {
        validate: () => true,
        drawShadow() {},
        drawBattleEnemy() {},
        drawPreview() {},
        draw() {},
      },
    },
    globalThis: {},
    noStroke() {},
    fill(...color) { activeFill = color; },
    rect(...args) { rects.push({ color: activeFill, rect: args }); },
  };
  vm.runInNewContext(source, sandbox, { filename: 'combat-visual-stage.js' });
  sandbox.window.AetherCombatVisual.drawEnemy({
    x: enemyAnchor.x,
    y: enemyAnchor.y,
    now,
    enemy: { type, hp: 100, maxHp: 100 },
  });
  return rects.filter((item) => item.color &&
    item.color[0] === 42 && item.color[1] === 255 && item.color[2] === 181);
}

function pulseCenter(pulseRects) {
  const left = Math.min(...pulseRects.map(({ rect }) => rect[0]));
  const top = Math.min(...pulseRects.map(({ rect }) => rect[1]));
  const right = Math.max(...pulseRects.map(({ rect }) => rect[0] + rect[2]));
  const bottom = Math.max(...pulseRects.map(({ rect }) => rect[1] + rect[3]));
  return { x: (left + right) / 2, y: (top + bottom) / 2 };
}

const firstPulse = renderEnemy('skyPredator', 0);
assert(firstPulse.length >= 8,
  'Sky Predator should draw a crisp cyan pixel pulse around its sprite');
assert(firstPulse.every(({ rect }) => rect[2] <= 3 && rect[3] <= 3),
  'Sky Predator pulse should use small pixel clusters, not a smooth filled shape');
const firstCenter = pulseCenter(firstPulse);
assert(firstCenter.x >= predatorBounds.left && firstCenter.x < predatorBounds.right &&
  firstCenter.y >= predatorBounds.top && firstCenter.y < predatorBounds.bottom,
  'Sky Predator pulse center should stay within the 84×72 sprite bounds');
assert.deepStrictEqual(firstCenter, { x: 177, y: 140 },
  'first pulse should center on the eye feature relative to the bottom-center sprite anchor');

const nextPulse = renderEnemy('skyPredator', 260);
assert.notDeepStrictEqual(nextPulse, firstPulse,
  'Sky Predator pulse should advance with visual time');
assert.deepStrictEqual(pulseCenter(nextPulse), { x: 167, y: 134 },
  'second pulse should follow the eye as the battle sprite changes frame');
assert.strictEqual(renderEnemy('corporateSalvager', 0).length, 0,
  'Sky Predator pulse must not appear on other enemy types');

console.log('Aetherwake Sky Predator pixel VFX: PASS');
