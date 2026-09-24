'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const file = path.join(root, 'modules', 'preview-world-presentation.js');
const source = fs.readFileSync(file, 'utf8');
const calls = { images: [], imageCreates: 0, rects: 0, translates: [] };

const sandbox = {
  window: {
    AetherPixelTiles: {
      PALETTE: { G: [20, 180, 60], P: [220, 180, 90] },
      get(id) {
        return { frames: [Array(16).fill(id === 'path' ? 'P'.repeat(16) : 'G'.repeat(16))] };
      },
    },
    AetherPixelSprites: {
      draw(id) { calls.sprites.push(id); return true; },
    },
  },
  globalThis: {},
  calls,
  createImage(width, height) {
    calls.imageCreates++;
    return {
      width,
      height,
      pixels: new Uint8ClampedArray(width * height * 4),
      loadPixels() {},
      updatePixels() {},
    };
  },
  noStroke() {}, fill() {}, rect() { calls.rects++; },
  push() {}, pop() {}, scale() {},
  translate(x, y) { calls.translates.push([x, y]); },
  image(...args) { calls.images.push(args); },
  text() {}, textAlign() {}, textFont() {}, textSize() {},
  stroke() {}, strokeWeight() {}, line() {}, ellipse() {},
  CENTER: 'center', LEFT: 'left', TOP: 'top',
  width: 960, height: 640, frameCount: 20,
};
calls.sprites = [];
vm.runInNewContext(source, sandbox, { filename: 'preview-world-presentation.js' });

const presentation = sandbox.window.AetherPreviewWorldPresentation;
assert(presentation, 'Preview world presentation module is missing');
assert.strictEqual(typeof presentation.draw, 'function');

const ground = Array.from({ length: 32 }, () => Array(32).fill(2));
ground[0][0] = 1;
ground[1][1] = 3;
ground[2][2] = 4;
ground[3][3] = 5;
ground[4][4] = 6;
const player = { px: 16 * 16, py: 16 * 16 };
const npcs = [{ id: 'elder_farmer', tileX: 7, tileY: 7, name: 'Captain Ionia' }];

assert.strictEqual(presentation.draw({
  groundLayer: ground,
  player,
  npcs,
  width: 960,
  height: 640,
  now: 1000,
}), true);
assert.strictEqual(calls.imageCreates, 1, 'tile map should be rasterized once, not redrawn cell-by-cell each frame');
assert(calls.images.length >= 1, 'cached tile map was not composited into the world scene');
assert(calls.sprites.includes('ender'), 'world presentation must draw Ender using the shared sprite authority');
assert(calls.sprites.includes('ionia'), 'world presentation must draw Ionia using the shared sprite authority');

presentation.draw({ groundLayer: ground, player, npcs, width: 960, height: 640, now: 1016 });
assert.strictEqual(calls.imageCreates, 1, 'unchanged map should reuse its raster cache');

console.log('Aetherwake Preview world presentation: PASS');
