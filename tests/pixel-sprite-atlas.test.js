'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const atlasPath = path.join(root, 'assets', 'preview', 'aetherwake-character-sprites.png');
const png = fs.readFileSync(atlasPath);
assert.strictEqual(png.subarray(0, 8).toString('hex'), '89504e470d0a1a0a', 'character atlas must be PNG');
assert.strictEqual(png.readUInt32BE(16) % 4, 0, 'character atlas must divide evenly into four columns');
assert.strictEqual(png.readUInt32BE(20) % 2, 0, 'character atlas must divide evenly into two animation rows');
let offset = 8;
let hasIndexedAlpha = false;
while (offset + 12 <= png.length) {
  const chunkLength = png.readUInt32BE(offset);
  if (png.toString('ascii', offset + 4, offset + 8) === 'tRNS') hasIndexedAlpha = true;
  offset += chunkLength + 12;
}
assert(png[25] === 6 || (png[25] === 3 && hasIndexedAlpha),
  'character atlas must preserve alpha transparency');

const atlas = { width: png.readUInt32BE(16), height: png.readUInt32BE(20) };
const calls = { images: [], rects: [], requested: [] };
const sandbox = {
  window: {},
  globalThis: {},
  loadImage(asset, onLoad) {
    calls.requested.push(asset);
    onLoad();
    return atlas;
  },
  image(...args) { calls.images.push(args); },
  noStroke() {},
  fill() {},
  rect(...args) { calls.rects.push(args); },
};
const source = fs.readFileSync(path.join(root, 'modules', 'pixel-sprites.js'), 'utf8');
vm.runInNewContext(source, sandbox, { filename: 'pixel-sprites.js' });

const api = sandbox.window.AetherPixelSprites;
assert(api, 'shared pixel sprite authority was not exposed');
assert.strictEqual(typeof api.drawPreview, 'function', 'preview sprite atlas renderer is missing');
assert.strictEqual(api.PREVIEW_ATLAS_PATH, 'assets/preview/aetherwake-character-sprites.png');

assert.strictEqual(api.drawPreview('ender', 100, 200, {
  anchor: 'bottom-center',
  scale: 2,
  frame: 1,
}), true);
assert.deepStrictEqual(calls.requested, ['assets/preview/aetherwake-character-sprites.png']);
assert.strictEqual(calls.images.length, 1, 'loaded atlas must render the detailed Ender sprite');
assert.strictEqual(calls.images[0][0], atlas);
assert.deepStrictEqual(calls.images[0].slice(1, 5), [78, 144, 44, 56],
  'preview characters must render at a readable 22×28 pixel size with 2× nearest-neighbor scaling');
assert.strictEqual(calls.images[0][6], atlas.height / 2,
  'walking frame must sample the second atlas row');

const cellWidth = atlas.width / 4;
const sourceWidth = Math.min(cellWidth, (atlas.height / 2) * 0.76);
for (const [id, column] of [['ionia', 1], ['lyra', 2], ['corporateSalvager', 3]]) {
  api.drawPreview(id, 100, 200, { anchor: 'bottom-center', scale: 2, frame: 0 });
  const rendered = calls.images[calls.images.length - 1];
  const expectedX = column * cellWidth + (cellWidth - sourceWidth) / 2;
  assert(Math.abs(rendered[5] - expectedX) < 0.01,
    id + ' must sample its assigned character column');
  assert.strictEqual(rendered[6], 0, id + ' idle frame must sample the first atlas row');
}

const fallbackCalls = { images: [], rects: [] };
const fallbackSandbox = {
  window: {},
  globalThis: {},
  image(...args) { fallbackCalls.images.push(args); },
  noStroke() {},
  fill() {},
  rect(...args) { fallbackCalls.rects.push(args); },
};
vm.runInNewContext(source, fallbackSandbox, { filename: 'pixel-sprites-fallback.js' });
assert.strictEqual(fallbackSandbox.window.AetherPixelSprites.drawPreview('ender', 100, 200, {
  anchor: 'bottom-center',
  scale: 2,
}), true, 'legacy pixel sprite fallback must draw while atlas loading is unavailable');
assert.strictEqual(fallbackCalls.images.length, 0, 'fallback must not sample an unloaded atlas');
assert(fallbackCalls.rects.length > 0, 'fallback sprite pixels were not drawn');

const failedCalls = { images: [], rects: [] };
const failedSandbox = {
  window: {},
  globalThis: {},
  loadImage(asset, onLoad, onError) {
    onError(new Error('offline asset unavailable'));
    return null;
  },
  image(...args) { failedCalls.images.push(args); },
  noStroke() {},
  fill() {},
  rect(...args) { failedCalls.rects.push(args); },
};
vm.runInNewContext(source, failedSandbox, { filename: 'pixel-sprites-load-failure.js' });
assert.strictEqual(failedSandbox.window.AetherPixelSprites.drawPreview('ionia', 0, 0), true,
  'atlas load failure must preserve the in-code fallback sprite');
assert.strictEqual(failedCalls.images.length, 0, 'failed atlas must never be sampled');
assert(failedCalls.rects.length > 0, 'atlas load failure left Ionia invisible');

console.log('Aetherwake Preview character sprite atlas: PASS');
