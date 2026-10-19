'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const {test} = require('node:test');

const source = fs.readFileSync(path.join(__dirname, '..', 'aetherwake.js'), 'utf8');
const begin = source.indexOf('function writeDesktopSmokeMarkerOnce() {');
const next = source.indexOf('\nfunction draw() {', begin);
assert(begin >= 0 && next > begin, 'exact desktop marker function must be extractable');
const functionSource = source.slice(begin, next);

function probe(options = {}) {
  const writes = [];
  const errors = [];
  const window = {
    __awRuntimeReady: options.ready !== false,
    __awFirstFrame: options.frame !== false,
    __awDesktopSmokeMarkerWritten: !!options.alreadyWritten,
    _setupOrder: 'setup-start -> setup-done',
  };
  const marker = options.envPath || '';
  const args = options.nwArgs || [];
  const ctx = {
    window,
    process: options.noProcess ? undefined : {env: options.noEnv ? undefined : {AETHERWAKE_DESKTOP_SMOKE_MARKER: marker}},
    nw: options.noNW ? undefined : {App: {argv: args}},
    require: options.noRequire ? undefined : (module) => {
      if (module === 'path') return require('node:path');
      assert.equal(module, 'fs');
      return {writeFileSync: (filename, data, encoding) => {
        assert.equal(encoding.encoding, 'utf8');
        assert.equal(encoding.flag, 'wx');
        if (options.simulateExisting) {
          const error = new Error('File exists');
          error.code = 'EEXIST';
          throw error;
        }
        writes.push({filename, payload: JSON.parse(data)});
      }};
    },
    width: 960,
    height: 640,
    gameState: 'boot',
    console: {error: (...x) => errors.push(x)},
  };
  const compiled = new vm.Script(functionSource + '\nwriteDesktopSmokeMarkerOnce();');
  compiled.runInNewContext(ctx, {timeout: 1000});
  return {writes, errors, window, ctx, compiled};
}

test('NW.js argument supplies marker path when renderer env variable is missing', () => {
  const destination = 'C:\\Test Directory\\aetherwake-desktop-ready.json';
  const result = probe({nwArgs: ['--aw-desktop-smoke-marker=' + destination]});
  assert.equal(result.writes.length, 1);
  assert.equal(result.writes[0].filename, destination);
  assert.deepEqual(
    [result.writes[0].payload.runtimeReady, result.writes[0].payload.firstFrame,
      result.writes[0].payload.width, result.writes[0].payload.height],
    [true, true, 960, 640]
  );
  assert.match(result.writes[0].payload.setupOrder, /setup-done/);
  assert.equal(result.window.__awDesktopSmokeMarkerWritten, true);
});

test('environment path continues taking precedence over NW.js argument', () => {
  const result = probe({envPath: 'C:\\Existing\\aetherwake-desktop-ready.json',
    nwArgs: ['--aw-desktop-smoke-marker=C:\\Alternative\\aetherwake-desktop-ready.json']});
  assert.equal(result.writes.length, 1);
  assert.equal(result.writes[0].filename, 'C:\\Existing\\aetherwake-desktop-ready.json');
});

test('no explicitly requested marker means no write', () => {
  for(const input of [{}, {noNW: true}, {nwArgs: ['--unrelated-flag=C:\\tmp\\aetherwake-desktop-ready.json']},
    {nwArgs: ['--aw-desktop-smoke-marker']}, {noEnv: true}]) {
    const result = probe(input);
    assert.equal(result.writes.length, 0);
    assert.equal(result.window.__awDesktopSmokeMarkerWritten, false);
  }
});

test('readiness and first frame remain mandatory even with explicit marker arg', () => {
  const arg = ['--aw-desktop-smoke-marker=C:\\Temp Folder\\aetherwake-desktop-ready.json'];
  assert.equal(probe({ready: false, nwArgs: arg}).writes.length, 0);
  assert.equal(probe({frame: false, nwArgs: arg}).writes.length, 0);
});

test('missing Node runtime environment or require fail closed', () => {
  const arg = ['--aw-desktop-smoke-marker=C:\\Temp\\aetherwake-desktop-ready.json'];
  assert.equal(probe({noProcess: true, nwArgs: arg}).writes.length, 0);
  assert.equal(probe({noEnv: true, nwArgs: arg}).writes.length, 0);
  assert.equal(probe({noRequire: true, nwArgs: arg}).writes.length, 0);
});

test('once-only marker guard remains effective', () => {
  const arg = ['--aw-desktop-smoke-marker=C:\\Temp\\aetherwake-desktop-ready.json'];
  const result = probe({nwArgs: arg});
  result.compiled.runInNewContext(result.ctx, {timeout: 1000});
  assert.equal(result.writes.length, 1);
  assert.equal(probe({nwArgs: arg, alreadyWritten: true}).writes.length, 0);
});

test('both Windows launchers explicitly quote marker paths', () => {
  for(const name of ['.github/workflows/desktop-package.yml', 'scripts/build-windows-release.ps1']){
    const text = fs.readFileSync(path.join(__dirname, '..', name), 'utf8');
    assert.match(text, /-ArgumentList @\(\"`"--aw-desktop-smoke-marker=\$marker`"\"\)/,
      name + ' must preserve spaces in the explicit NW.js marker path');
  }
});

test('non-QA filename, relative path and UNC share are refused', () => {
  for (const destination of [
    'C:\\\\Temp\\\\other.json',
    '..\\\\aetherwake-desktop-ready.json',
    '\\\\Temp\\\\aetherwake-desktop-ready.json',
    '\\\\\\\\server\\\\share\\\\aetherwake-desktop-ready.json',
  ]) {
    const result = probe({nwArgs: ['--aw-desktop-smoke-marker=' + destination]});
    assert.equal(result.writes.length, 0, destination);
    assert.equal(result.window.__awDesktopSmokeMarkerWritten, false);
  }
});

test('existing file collision fails closed rather than overwriting', () => {
  const arg = ['--aw-desktop-smoke-marker=C:\\\\Temp\\\\aetherwake-desktop-ready.json'];
  const result = probe({...{nwArgs:arg}, simulateExisting:true});
  assert.equal(result.writes.length, 0);
  assert.equal(result.window.__awDesktopSmokeMarkerWritten, false);
  assert.equal(result.errors.length, 1);
});
