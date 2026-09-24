'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const html = fs.readFileSync(path.join(__dirname, '..', 'index-embedded.html'), 'utf8');
const inlineScripts = [...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)]
  .filter(match => match[1].trim());
const readinessScript = inlineScripts
  .map(match => match[1])
  .find(script => script.includes('REF_MAX_WAIT'));

assert(readinessScript, 'embedded launch readiness gate is missing');
assert(readinessScript.includes('var REF_MAX_WAIT = 20000;'),
  'embedded launch readiness must allow the portable build 20-second startup window');

let now = 0;
let nextTimerId = 0;
const timers = [];
function schedule(callback, delay) {
  timers.push({ callback, due: now + delay, id: ++nextTimerId });
  return nextTimerId;
}
function runNextTimer() {
  timers.sort((left, right) => left.due - right.due);
  const timer = timers.shift();
  assert(timer, 'expected readiness polling to remain scheduled');
  now = timer.due;
  timer.callback();
}

const title = { textContent: 'AETHERWAKE', style: {} };
const subtitle = { textContent: 'initializing the weave...', style: {} };
const loadingScreen = { style: {} };
const canvas = { width: 960, height: 640 };
const document = {
  querySelector(selector) {
    if (selector === 'canvas') return canvas;
    if (selector === '.loading-text') return title;
    if (selector === '.loading-sub') return subtitle;
    return null;
  },
  getElementById(id) {
    return id === 'loading-screen' ? loadingScreen : null;
  },
};
const window = { __awLoadingDone: false, __awLoadingError: false };
const p5 = { disableFriendlyErrors: false };
function hideLoadingScreen() {
  loadingScreen.style.display = 'none';
  window.__awLoadingDone = true;
}

vm.runInNewContext(readinessScript, {
  window,
  document,
  performance: { now: () => now },
  setTimeout: schedule,
  hideLoadingScreen,
  p5,
  console: { log() {}, warn() {} },
});

while (now < 21000 && timers.length) runNextTimer();
assert.strictEqual(window.__awLoadingError, true,
  'slow startup should show a nonterminal delay state after 20 seconds');
assert.match(title.textContent, /TAKING LONGER/,
  'slow startup should explain that it is still waiting');
assert(timers.length > 0,
  'readiness polling must continue after the delay state appears');

window.__awRuntimeReady = true;
window.__awFirstFrame = true;
runNextTimer();

assert.strictEqual(loadingScreen.style.display, 'none',
  'the overlay should disappear when runtime and first frame become ready');
assert.strictEqual(window.__awLoadingDone, true,
  'late readiness should complete the loading screen');
assert.strictEqual(window.__awLoadingError, false,
  'recovered startup should clear the loading error state');

console.log('Aetherwake embedded launch readiness recovery: PASS');
