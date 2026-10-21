'use strict';

// Synthetic read-only reproduction for issue #292 (NOT A SECURITY FIX).
// Runs the exact signed Chapter 1 candidate marker function in an isolated VM.
// fs.writeFileSync is replaced with an in-memory spy; no path is ever written.
// A PASS here means the CHARACTERIZATION is accurate, not that arbitrary
// destination selection is safe or authorized.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const {test} = require('node:test');

const root = path.join(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const start = source.indexOf('function writeDesktopSmokeMarkerOnce() {');
const stop = source.indexOf('\nfunction draw() {', start);
assert(start >= 0 && stop > start, 'marker function must be present at pinned candidate');
const functionSource = source.slice(start, stop);

function characterize(candidate, options = {}) {
  const writes = [];
  const errors = [];
  const appWindow = {
    __awRuntimeReady: options.runtimeReady !== false,
    __awFirstFrame: options.firstFrame !== false,
    __awDesktopSmokeMarkerWritten: false,
    _setupOrder: 'setup-start -> setup-done',
  };
  const context = {
    window: appWindow,
    process: {env: {AETHERWAKE_DESKTOP_SMOKE_MARKER: candidate}},
    nw: undefined,
    require: module => {
      if (module === 'path') return path;
      assert.equal(module, 'fs', 'runtime must only require path and fs');
      return {
        writeFileSync: (target, bytes, opts) => {
          assert.equal(opts.flag, 'wx', 'must preserve exclusive create');
          assert.equal(opts.encoding, 'utf8');
          writes.push({target, payload: JSON.parse(bytes)});
        },
      };
    },
    width: 960,
    height: 640,
    gameState: 'QA_ONLY',
    console: {error: (...args) => errors.push(args)},
  };
  new vm.Script(functionSource + '\nwriteDesktopSmokeMarkerOnce();', {
    filename: 'isolated-signed-candidate-marker-function.js',
  }).runInNewContext(context, {timeout: 1000});
  return {writes, errors, appWindow};
}

test('baseline QA destination is accepted with no real filesystem effect', () => {
  const dest = 'C:\\Users\\runner\\AppData\\Local\\Temp\\aetherwake-desktop-ready.json';
  const result = characterize(dest);
  assert.equal(result.writes.length, 1);
  assert.equal(result.writes[0].target, dest);
  assert.equal(result.writes[0].payload.firstFrame, true);
});

test('CHARACTERIZATION ONLY: caller-chosen system-directory path is currently accepted', () => {
  const dest = 'C:\\Windows\\System32\\aetherwake-desktop-ready.json';
  const result = characterize(dest);
  assert.equal(result.writes.length, 1, 'records unresolved arbitrary-root acceptance');
  assert.equal(result.writes[0].target, dest);
  // No actual write was attempted. An OS ACL might deny a real process.
});

test('CHARACTERIZATION ONLY: parent-directory traversal survives current syntax gate', () => {
  const qaRoot = 'C:\\Temp\\IsolatedQA';
  const traversal = qaRoot + '\\..\\..\\Users\\Public\\aetherwake-desktop-ready.json';
  assert.equal(path.win32.normalize(traversal),
               'C:\\Users\\Public\\aetherwake-desktop-ready.json');
  const normalizedRoot = path.win32.normalize(qaRoot + '\\');
  assert.equal(path.win32.normalize(traversal).startsWith(normalizedRoot), false);
  const result = characterize(traversal);
  assert.equal(result.writes.length, 1, 'records missing normalized-root boundary');
  assert.equal(result.writes[0].target, traversal);
});

test('existing non-QA basename, relative path, and UNC refusal remains intact', () => {
  for (const destination of [
    'C:\\Temp\\another-file.json',
    '.\\aetherwake-desktop-ready.json',
    '\\\\server\\share\\aetherwake-desktop-ready.json',
  ]) {
    assert.equal(characterize(destination).writes.length, 0, destination);
  }
});

test('first-frame and runtime readiness still block marker attempts', () => {
  const dest = 'C:\\Temp\\aetherwake-desktop-ready.json';
  assert.equal(characterize(dest, {runtimeReady: false}).writes.length, 0);
  assert.equal(characterize(dest, {firstFrame: false}).writes.length, 0);
});

test('this suite remains mock-only and does not authorize root selection', () => {
  assert.match(functionSource, /writeFileSync\(markerPath/);
  assert.doesNotMatch(functionSource, /AETHERWAKE_DESKTOP_MARKER_ALLOWED_ROOT/);
  assert.ok(!fs.existsSync(path.join(root, 'aetherwake-desktop-ready.json')));
});
