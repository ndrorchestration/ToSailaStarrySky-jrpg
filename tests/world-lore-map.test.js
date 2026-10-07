'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'modules', 'world.js'), 'utf8');
const runtime = fs.readFileSync(path.join(root, 'aetherwake.js'), 'utf8');
const sectionStart = runtime.indexOf('// === modules/world.js ===');
const sectionEnd = runtime.indexOf('\n// === modules/', sectionStart + 1);
assert(sectionStart >= 0 && sectionEnd > sectionStart,
  'embedded runtime must expose a delimited world module for initialization checks');

for (const [name, moduleSource] of [
  ['world.js', source],
  ['aetherwake.js embedded world module', runtime.slice(sectionStart, sectionEnd)],
]) {
  let productionRefreshes = 0;
  const sandbox = {
    window: {
      AetherPartyState: {
        refreshProductionStats(player) {
          productionRefreshes++;
          player.productionStats = {};
          player.productionDerivedStats = {};
          player.productionStatModelVersion = 'test-harness';
        },
      },
    },
    globalThis: {},
  };
  vm.runInNewContext(moduleSource, sandbox, { filename: name });
  const world = sandbox.window.AetherWorld({}, {});

  assert.doesNotThrow(() => world.init(),
    name + ' must not attach lore metadata to numeric tile cells');
  assert.strictEqual(productionRefreshes, 1,
    name + ' must initialize through the required production-stat authority');
  assert(world.player && world.player.tileX === 16 && world.player.tileY === 16,
    name + ' must expose the player after building the map');
  assert(world.quest && world.quest.state === 'signal',
    name + ' must expose the initialized quest state');
  for (let step = 0; step < 9; step++) world.movePlayer(0, -1);
  for (let step = 0; step < 3; step++) world.movePlayer(1, 0);
  const firstLore = vm.runInNewContext(
    'quest.discoveries.find(entry => entry.x === 19 && entry.y === 7)',
    sandbox
  );
  assert(firstLore, name + ' must preserve lore text for the first accessible lore tile');
  assert.strictEqual(firstLore.text,
    'Ionia\'s watch log, half-buried in deck plating: "Day 47. The core sings wrong. The harmonics slip at dusk. The frequencies hum in the hull."',
    name + ' must reveal the authored text when Ender reaches a lore tile');
}

console.log('Aetherwake world lore map initialization: PASS');
