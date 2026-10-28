'use strict';
// Historical JavaScript path compatibility check. This does not promote
// the JS/p5/NW.js build back to the forward Godot production path.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const sourceName = 'tosailthestarrysky.js';
const sourcePath = path.join(root, sourceName);
const load = filename => fs.readFileSync(path.join(root, filename), 'utf8');

test('renamed legacy runtime is the only active root script source', () => {
  assert.ok(fs.existsSync(sourcePath), 'actual historical runtime source is absent');
  assert.ok(!fs.existsSync(path.join(root, 'aetherwake.js')), 'unexpected duplicate legacy runtime path');
  const code = load(sourceName);
  assert.ok(code.includes('  this.resolveTurn = function(actionId, resources) {'));
  assert.ok(code.includes('  this.ability = function(name, target) {'));
});

test('both historical HTML entrypoints bind the same present runtime script', () => {
  for(const filename of ['index.html','index-embedded.html']){
    const html = load(filename);
    assert.ok(html.includes('<script src="'+sourceName+'"></script>'), filename+' not linked to actual runtime');
    assert.ok(!html.includes('<script src="aetherwake.js"></script>'), filename+' still loads deleted source');
  }
});

test('historical desktop stage source path matches HTML and original source', () => {
  const stage = load('scripts/stage-memories-desktop.js');
  assert.ok(stage.includes("'"+sourceName+"'"), 'stager fails to include live historical runtime');
  assert.ok(!stage.includes("'aetherwake.js'"), 'stager still requires missing historical filename');
  assert.ok(stage.includes('if (!fs.existsSync(src))'), 'stager must fail closed on missing runtime');
});

test('legacy contract tests consume the present source, never a hidden substitute', () => {
  const tests = [
    'resolver-integration', 'input-runtime-contract','enemy-metadata-contract',
    'combat-runtime-contract','progression-reachability','combat-input-contract',
    'open-sky-runtime-contract','secondary-action-contract','character-canon-alignment',
    'runtime-overlay-contract','desktop-package-contract'
  ];
  for(const name of tests){
    const file = load('tests/'+name+'.test.js');
    assert.ok(file.includes(sourceName), name+' must consume current source');
    assert.ok(!file.includes("'aetherwake.js'"), name+' must not use missing source');
  }
});
