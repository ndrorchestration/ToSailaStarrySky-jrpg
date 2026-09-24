'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const runtimePath = path.join(__dirname, '..', 'aetherwake.js');
const runtime = fs.readFileSync(runtimePath, 'utf8');

function extractFunction(source, name, nextName) {
  const start = source.indexOf('function ' + name + '() {');
  const end = source.indexOf('\nfunction ' + nextName + '(', start);
  assert.notEqual(start, -1, 'runtime must define ' + name);
  assert.notEqual(end, -1, name + ' must end before ' + nextName);
  return source.slice(start, end);
}

function drawEndScreen() {
  const calls = { rects: [], ellipses: [], text: [], fill: null };
  const sandbox = {
    width: 960,
    height: 640,
    C: {
      navy: [8, 12, 19],
      teal: [42, 255, 181],
      scioto: [124, 200, 232],
      parchment: [232, 220, 198],
    },
    millis: () => 1000,
    push() {}, pop() {}, noSmooth() {}, noStroke() {},
    fill(...color) { calls.fill = color; },
    rect(x, y, w, h) { calls.rects.push({ x, y, w, h, fill: calls.fill }); },
    ellipse(...args) { calls.ellipses.push(args); },
    textAlign() {}, textFont() {}, textSize() {},
    text(...args) { calls.text.push(args); },
    CENTER: 'center',
  };
  vm.runInNewContext(
    extractFunction(runtime, 'drawPreviewEndScreen', 'drawFirstWakeOpening'),
    sandbox,
    { filename: runtimePath }
  );
  vm.runInNewContext('drawPreviewEndScreen()', sandbox);
  return calls;
}

const calls = drawEndScreen();
assert(calls.rects.some(r => r.x === 0 && r.y === 0 && r.w === 960 && r.h === 640),
  'the end card must keep a full-canvas dark base for text contrast');
assert.equal(calls.ellipses.length, 0,
  'the end card must use crisp pixel blocks instead of smooth ellipse glows');

const smallBlocks = calls.rects.filter(r => r.w <= 96 && r.h <= 10);
assert(smallBlocks.length >= 24,
  'the end card must include enough small block shapes to read as pixel art');
assert(smallBlocks.some(r => r.x < 144 || r.x + r.w > 816 || r.y > 512),
  'pixel scenery must remain visible around the central copy');

const copy = calls.text.map(args => String(args[0])).join('\n');
for (const text of [
  'AETHERWAKE // PREVIEW 0.1',
  'END OF PREVIEW',
  'Ender has heard the first warning and survived the first thing in the sky that answered it.',
  'ENTER / SPACE — PLAY AGAIN',
]) {
  assert(copy.includes(text), 'end card copy must remain visible: ' + text);
}

const reloads = [];
const inputSandbox = {
  gameState: 'preview_end',
  prevState: null,
  keysPressed: { 13: true },
  keyCode: 13,
  key: 'Enter',
  STATE: { PREVIEW_END: 'preview_end' },
  VIS: { fadeTransitions: false },
  millis: () => 1000,
  window: { location: { reload() { reloads.push('reload'); } } },
};
vm.runInNewContext(
  extractFunction(runtime, 'handleInput', 'handleWorldInput'),
  inputSandbox,
  { filename: runtimePath }
);
vm.runInNewContext('handleInput()', inputSandbox);
assert.deepEqual(reloads, ['reload'], 'Enter on the end card must still reload the preview');

console.log('Preview end-screen visual and replay contract: PASS');
