'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const file = path.join(root, 'modules', 'preview-world-presentation.js');
const source = fs.readFileSync(file, 'utf8');
const skyBackdrop = fs.readFileSync(path.join(root, 'assets', 'preview', 'aetherwake-sky-lanes.svg'), 'utf8');
const worldSource = fs.readFileSync(path.join(root, 'modules', 'world.js'), 'utf8');
const tileSource = fs.readFileSync(path.join(root, 'modules', 'pixel-tiles.js'), 'utf8');
const spriteSource = fs.readFileSync(path.join(root, 'modules', 'pixel-sprites.js'), 'utf8');
const calls = {
  images: [], imageCreates: 0, rects: [], translates: [], scales: [], fillColors: [],
  spriteFrames: [], spriteScales: [], shadowScales: [], backgroundRequests: [],
  backgroundImage: null, completeBackgroundLoad: null,
};
assert.match(skyBackdrop, /<image[^>]+href="data:image\/webp;base64,/,
  'the scenic sky-lanes background should be self-contained for offline desktop builds');

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
  loadImage(assetPath, onLoad) {
    calls.backgroundRequests.push(assetPath);
    calls.backgroundImage = { assetPath, width: 1536, height: 1024 };
    calls.completeBackgroundLoad = onLoad;
    return calls.backgroundImage;
  },
  noStroke() {}, noSmooth() {}, fill(...color) { calls.fillColors.push(color); }, rect(x, y, w, h) { calls.rects.push({ x, y, w, h }); },
  push() {}, pop() {}, scale(...args) { calls.scales.push(args); },
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
    calls.spriteFrames.push({ id, frame: args[2] && args[2].frame });
    calls.spriteScales.push(args[2] && args[2].scale);
    return spriteAuthority.draw(id, ...args);
  },
  drawShadow(...args) {
    calls.shadowScales.push(args[2]);
    return spriteAuthority.drawShadow(...args);
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
ground[11][3] = 6;
ground[18][22] = 3;
const player = { px: 16 * 16, py: 16 * 16, tileX: 16, tileY: 16 };
const npcs = [
  { id: 'elder_farmer', tileX: 7, tileY: 7, name: 'Captain Ionia', flags: { questMarker: true } },
  { id: 'child_prophet', tileX: 8, tileY: 20, name: 'Lyra' },
  { id: 'corporate_salvager', tileX: 26, tileY: 24, name: 'Verrick' },
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
assert.deepStrictEqual(calls.backgroundRequests, ['assets/preview/aetherwake-sky-lanes.svg'],
  'the authored Aetherwake sky-lanes vista should load as the scenic world backdrop');
assert.deepStrictEqual(calls.fillColors.slice(0, 5), [
  [38, 88, 181], [43, 126, 216], [71, 180, 231], [177, 227, 237], [255, 222, 166],
], 'the backdrop should move from vivid cobalt into a warm JRPG horizon');
for (const color of [[55, 187, 111], [223, 156, 77], [60, 229, 218, 230]]) {
  assert(calls.fillColors.some(fill => fill.length === color.length && fill.every((channel, index) => channel === color[index])),
    'floating islands should have vivid greenery, warm metal, and luminous aether accents');
}
assert.deepStrictEqual(calls.scales[0], [1.2], 'world framing should leave room for the scenic sky vista');
assert.deepStrictEqual(calls.translates[0], [163, 3], 'camera should center Ender inside the scenic frame');
assert(calls.spriteScales.slice(0, 4).every(scale => scale === 2),
  'party sprites should preserve their pixel-art scale at the larger world camera scale');
assert.deepStrictEqual(calls.shadowScales.slice(0, 4), [2, 2, 2, 2],
  'party sprites should have grounded pixel shadows');
const atlas = calls.images[0][0];
const grassAt = (atlas.width + 17) * 4;
const pathAt = (15 * 16 * atlas.width + 15 * 16) * 4;
const pixelAt = (x, y, target = atlas) => Array.from(target.pixels.slice((y * target.width + x) * 4, (y * target.width + x) * 4 + 3));
const tilePixelsAt = (tileX, tileY, target = atlas) => {
  const bytes = [];
  for (let y = 0; y < 16; y++) {
    const start = ((tileY * 16 + y) * target.width + tileX * 16) * 4;
    bytes.push(...target.pixels.slice(start, start + 16 * 4));
  }
  return bytes;
};
assert(calls.sprites.includes('lyra'), 'world presentation must draw Lyra using her shared character sprite');
assert.notDeepStrictEqual(Array.from(atlas.pixels.slice(grassAt, grassAt + 3)), [0, 0, 0],
  'map raster must use the shared tile palette');
assert.deepStrictEqual(pixelAt(2 * 16, 2 * 16), [112, 151, 82],
  'floating-island ground must use the authored float tile');
assert.deepStrictEqual(pixelAt(3 * 16, 2 * 16), [47, 97, 127],
  'water ground must use the authored water tile');
assert.deepStrictEqual(pixelAt(4 * 16, 2 * 16), [46, 47, 54],
  'undiscovered lore ground must use the authored lore tile');
assert.deepStrictEqual(pixelAt(3 * 16, 11 * 16), [46, 47, 54],
  'meadow accents must leave authored lore tiles intact');
assert.deepStrictEqual(pixelAt(22 * 16, 18 * 16), [72, 35, 26],
  'meadow accents must leave debris props intact');
assert.deepStrictEqual(pixelAt(2 * 16 + 3, 10 * 16 + 2), [255, 196, 91],
  'playable meadow should include authored flower accents away from the objective path');
assert.deepStrictEqual(pixelAt(21 * 16 + 2, 18 * 16 + 2), [112, 151, 82],
  'playable meadow should include authored grass accents away from the objective path');
assert.deepStrictEqual(pixelAt(10 * 16 + 6, 21 * 16 + 6), [82, 121, 68],
  'scenic lore landmark should include the authored forest tile');
assert.deepStrictEqual(pixelAt(11 * 16 + 7, 21 * 16 + 8), [42, 255, 181],
  'scenic lore landmark should include the authored glowing ruins tile');
assert.deepStrictEqual(pixelAt(11 * 16 + 3, 22 * 16 + 2), [255, 196, 91],
  'scenic lore landmark should include bright flowers at its approach');
assert.deepStrictEqual(pixelAt(2 * 16 + 6, 7 * 16 + 6), [82, 121, 68],
  'the preserved child drawing should sit beside a small forest vignette');
assert.deepStrictEqual(pixelAt(3 * 16 + 3, 7 * 16 + 2), [255, 196, 91],
  'the northern story vignette should use bright flower pixels');
assert.deepStrictEqual(pixelAt(23 * 16 + 7, 12 * 16 + 2), [118, 58, 33],
  'the copper-slate lore point should have a warm village landmark');
assert.deepStrictEqual(pixelAt(23 * 16, 13 * 16), [47, 97, 127],
  'the copper-slate landmark should have a blue bridge approach');
assert.deepStrictEqual(pixelAt(23 * 16 + 3, 13 * 16), [118, 58, 33],
  'the bridge should retain its warm timber detail');
for (const [x, y, label] of [
  [16, 16, 'Ender'],
  [7, 19, 'Lyra upper-left sprite cell'], [8, 19, 'Lyra upper-center sprite cell'], [9, 19, 'Lyra upper-right sprite cell'],
  [7, 20, 'Lyra lower-left sprite cell'], [8, 20, 'Lyra lower-center sprite cell'], [9, 20, 'Lyra lower-right sprite cell'],
  [25, 23, 'Verrick upper-left sprite cell'], [26, 23, 'Verrick upper-center sprite cell'],
  [27, 23, 'Verrick upper-right sprite cell'], [25, 24, 'Verrick lower-left sprite cell'],
  [26, 24, 'Verrick lower-center sprite cell'], [27, 24, 'Verrick lower-right sprite cell'],
]) {
  assert.deepStrictEqual(tilePixelsAt(x, y), tilePixelsAt(18, 17),
    label + ' starting tile must remain clear of decorative terrain accents');
}
assert.deepStrictEqual(pixelAt(7 * 16, 7 * 16), [184, 163, 119],
  'Ionia starting tile must retain the authored objective route');
assert.deepStrictEqual(pixelAt(15 * 16, 15 * 16), [184, 163, 119],
  'Ionia objective route must remain clear of decorative terrain accents');
const routePixels = tilePixelsAt(15, 15);
const routeColors = new Set();
for (let i = 0; i < routePixels.length; i += 4) {
  routeColors.add(routePixels.slice(i, i + 3).join(','));
}
assert.deepStrictEqual(Array.from(routeColors).sort(), ['184,163,119', '230,210,151'],
  'objective route tile must retain its complete authored path pattern');
assert.notDeepStrictEqual(Array.from(atlas.pixels.slice(pathAt, pathAt + 3)),
  Array.from(atlas.pixels.slice(grassAt, grassAt + 3)),
  'authored route must be visible in the map raster');
assert(calls.sprites.includes('ender'), 'world presentation must draw Ender using the shared sprite authority');
assert(calls.sprites.includes('ionia'), 'world presentation must draw Ionia using the shared sprite authority');
assert(calls.sprites.includes('corporateSalvager'), 'world presentation must draw Verrick using his shared character sprite');
const namePlaques = calls.rects.filter(rect => rect.w === 36 && rect.h === 9);
assert.strictEqual(namePlaques.length, 2, 'Ender and Ionia should each have one name plaque');
assert(namePlaques[0].y + namePlaques[0].h <= player.py + 16 - 32,
  'Ender name plaque must sit fully above the sprite');
assert(namePlaques[1].y + namePlaques[1].h <= 7 * 16 + 16 - 32,
  'Ionia name plaque must sit fully above the sprite');
const questMarker = calls.rects.find(rect => rect.w === 7 && rect.h === 7);
assert(questMarker, 'Ionia quest marker should be visible');
assert(questMarker.y + questMarker.h <= namePlaques[1].y,
  'Ionia quest marker must sit above the name plaque without covering the sprite');

presentation.draw({ groundLayer: ground, player, npcs, width: 960, height: 640, now: 1016 });
assert.strictEqual(calls.imageCreates, 1, 'unchanged map should reuse its raster cache');
assert(calls.spriteFrames.filter(sprite => sprite.id !== 'ender').every(sprite => sprite.frame === 0),
  'stationary NPCs must remain on their idle sprite frame');
assert(calls.spriteFrames.filter(sprite => sprite.id === 'ender').every(sprite => sprite.frame === 0),
  'stationary Ender must remain on his idle sprite frame');

const priorFrameCount = calls.spriteFrames.length;
player.tileX += 1;
player.px += 16;
presentation.draw({ groundLayer: ground, player, npcs, width: 960, height: 640, now: 1032 });
assert.deepStrictEqual(calls.translates[2], [144, 3],
  'a one-tile walk should keep Ender centered over the scenic map frame');
presentation.draw({ groundLayer: ground, player, npcs, width: 960, height: 640, now: 1162 });
player.tileX += 1;
player.px += 16;
presentation.draw({ groundLayer: ground, player, npcs, width: 960, height: 640, now: 1163 });
presentation.draw({ groundLayer: ground, player, npcs, width: 960, height: 640, now: 1453 });
presentation.draw({ groundLayer: ground, player, npcs, width: 960, height: 640, now: 1684 });
const movementFrames = calls.spriteFrames.slice(priorFrameCount)
  .filter(sprite => sprite.id === 'ender').map(sprite => sprite.frame);
assert.deepStrictEqual(movementFrames, [0, 1, 1, 1, 0],
  'Ender should animate by elapsed time through repeated steps, then return to idle');
assert(calls.spriteFrames.filter(sprite => sprite.id !== 'ender').every(sprite => sprite.frame === 0),
  'NPCs must stay idle while Ender moves');

const imageCreatesBeforeNpcMove = calls.imageCreates;
npcs[1].tileX = 3;
npcs[1].tileY = 11;
presentation.draw({ groundLayer: ground, player, npcs, width: 960, height: 640, now: 1685 });
assert.strictEqual(calls.imageCreates, imageCreatesBeforeNpcMove + 1,
  'moving an NPC must refresh actor-aware terrain accents');
const movedAtlas = calls.images[calls.images.length - 1][0];
assert.deepStrictEqual(tilePixelsAt(2, 10, movedAtlas), tilePixelsAt(18, 17, movedAtlas),
  'terrain accents must clear from the footprint of an NPC moved into a decorated patch');

const worldSandbox = { window: {}, globalThis: {} };
vm.runInNewContext(worldSource, worldSandbox, { filename: 'world.js' });
const actualWorld = worldSandbox.window.AetherWorld({}, {});
assert.doesNotThrow(() => actualWorld.init(), 'the playable world must initialize before its scenic map is drawn');
const actualGround = vm.runInNewContext('groundLayer', worldSandbox);
const realMapImageCount = calls.imageCreates;
presentation.invalidate();
assert.strictEqual(presentation.draw({
  groundLayer: actualGround,
  player: actualWorld.player,
  npcs: actualWorld.npcs,
  width: 960,
  height: 640,
  now: 1800,
}), true);
assert.strictEqual(calls.imageCreates, realMapImageCount + 1,
  'preview renderer must rasterize the initialized playable-world map');
const realMapAtlas = calls.images[calls.images.length - 1][0];
assert.strictEqual(actualGround[21][10], 2, 'forest landmark must be placed on a real meadow cell');
assert.strictEqual(actualGround[21][11], 2, 'ruins landmark must be placed on a real meadow cell');
assert.strictEqual(actualGround[7][2], 2, 'northern garden must be placed on a real meadow cell');
assert.strictEqual(actualGround[12][23], 2, 'sky-port landmark must be placed on a real meadow cell');
assert.deepStrictEqual(pixelAt(11 * 16 + 7, 21 * 16 + 8, realMapAtlas), [42, 255, 181],
  'initialized playable map must show the authored ruins landmark');
assert.deepStrictEqual(pixelAt(2 * 16 + 6, 7 * 16 + 6, realMapAtlas), [82, 121, 68],
  'initialized playable map must show the northern garden');
assert.deepStrictEqual(pixelAt(23 * 16 + 7, 12 * 16 + 2, realMapAtlas), [118, 58, 33],
  'initialized playable map must show the village beside the aether-core');
for (const [x, y, label] of [[7, 19, 'Lyra'], [7, 20, 'Lyra'], [25, 23, 'Verrick'], [27, 24, 'Verrick']]) {
  assert.deepStrictEqual(tilePixelsAt(x, y, realMapAtlas), tilePixelsAt(18, 17, realMapAtlas),
    label + ' sprite footprint on the playable map must stay free of scenic overlays');
}

assert.strictEqual(typeof calls.completeBackgroundLoad, 'function',
  'the world renderer should retain the scenic image load callback');
calls.completeBackgroundLoad();
const backgroundFrameStart = calls.images.length;
presentation.draw({
  groundLayer: actualGround,
  player: actualWorld.player,
  npcs: actualWorld.npcs,
  width: 960,
  height: 640,
  now: 1816,
});
assert.strictEqual(calls.images.length, backgroundFrameStart + 2,
  'a loaded scenic background should render behind the cached gameplay map');
assert.strictEqual(calls.images[backgroundFrameStart][0], calls.backgroundImage,
  'the generated sky-lanes artwork must render first, behind the map');
assert.strictEqual(calls.images[backgroundFrameStart + 1][0], realMapAtlas,
  'the tile map must remain the foreground gameplay layer');

console.log('Aetherwake Preview world presentation: PASS');
