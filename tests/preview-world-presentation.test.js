'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const file = path.join(root, 'modules', 'preview-world-presentation.js');
const source = fs.readFileSync(file, 'utf8');
const tileSource = fs.readFileSync(path.join(root, 'modules', 'pixel-tiles.js'), 'utf8');
const spriteSource = fs.readFileSync(path.join(root, 'modules', 'pixel-sprites.js'), 'utf8');
const calls = { images: [], imageCreates: 0, rects: 0, translates: [] };

const sandbox = {
  window: {},
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
  noStroke() {}, noSmooth() {}, fill() {}, rect() { calls.rects++; },
  push() {}, pop() {}, scale() {},
  translate(x, y) { calls.translates.push([x, y]); },
  image(...args) { calls.images.push(args); },
  text() {}, textAlign() {}, textFont() {}, textSize() {},
  stroke() {}, strokeWeight() {}, line() {}, ellipse() {},
  CENTER: 'center', LEFT: 'left', TOP: 'top',
  width: 960, height: 640, frameCount: 20,
};
calls.sprites = [];
vm.runInNewContext(tileSource, sandbox, { filename: 'pixel-tiles.js' });
vm.runInNewContext(spriteSource, sandbox, { filename: 'pixel-sprites.js' });
const spriteAuthority = sandbox.window.AetherPixelSprites;
sandbox.window.AetherPixelSprites = Object.freeze({
  ...spriteAuthority,
  draw(id, ...args) {
    calls.sprites.push(id);
    return spriteAuthority.draw(id, ...args);
  },
});
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
ground[2][3] = 5;
ground[2][4] = 6;
const player = { px: 16 * 16, py: 16 * 16 };
const npcs = [
  { id: 'elder_farmer', tileX: 7, tileY: 7, name: 'Captain Ionia' },
  { id: 'child_prophet', tileX: 8, tileY: 7, name: 'Lyra' },
];

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
const atlas = calls.images[0][0];
const grassAt = (atlas.width + 17) * 4;
const pathAt = (15 * 16 * atlas.width + 15 * 16) * 4;
const pixelAt = (x, y) => Array.from(atlas.pixels.slice((y * atlas.width + x) * 4, (y * atlas.width + x) * 4 + 3));
assert(calls.sprites.includes('lyra'), 'world presentation must draw Lyra using her shared character sprite');
assert.notDeepStrictEqual(Array.from(atlas.pixels.slice(grassAt, grassAt + 3)), [0, 0, 0],
  'map raster must use the shared tile palette');
assert.deepStrictEqual(pixelAt(2 * 16, 2 * 16), [112, 151, 82],
  'floating-island ground must use the authored float tile');
assert.deepStrictEqual(pixelAt(3 * 16, 2 * 16), [47, 97, 127],
  'water ground must use the authored water tile');
assert.deepStrictEqual(pixelAt(4 * 16, 2 * 16), [46, 47, 54],
  'undiscovered lore ground must use the authored lore tile');
assert.notDeepStrictEqual(Array.from(atlas.pixels.slice(pathAt, pathAt + 3)),
  Array.from(atlas.pixels.slice(grassAt, grassAt + 3)),
  'authored route must be visible in the map raster');
assert(calls.sprites.includes('ender'), 'world presentation must draw Ender using the shared sprite authority');
assert(calls.sprites.includes('ionia'), 'world presentation must draw Ionia using the shared sprite authority');

presentation.draw({ groundLayer: ground, player, npcs, width: 960, height: 640, now: 1016 });
assert.strictEqual(calls.imageCreates, 1, 'unchanged map should reuse its raster cache');

console.log('Aetherwake Preview world presentation: PASS');
