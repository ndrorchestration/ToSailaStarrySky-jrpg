'use strict';

const assert = require('assert');
const path = require('path');

class FakeAudio {
  constructor() {
    this.src = '';
    this.loop = false;
    this.preload = '';
    this.volume = 1;
    this.paused = true;
    this.currentTime = 0;
  }
  setAttribute() {}
  addEventListener() {}
  play() { this.paused = false; return Promise.resolve(); }
  pause() { this.paused = true; }
}

global.Audio = FakeAudio;
global.document = null;
global.addEventListener = function(){};
global.setInterval = function(){ return 1; };
global.clearInterval = function(){};

const modulePath = path.resolve(__dirname, '..', 'modules', 'scene-music.js');
delete require.cache[modulePath];
require(modulePath);

const music = global.AetherSceneMusic;
assert(music, 'scene music API missing');

function route(state, quest) {
  global.gameState = state;
  global._world = quest ? { getQuestState: () => quest } : null;
  music.clearCharacterTheme();
  return music.state.desiredId;
}

assert.strictEqual(route('boot'), null, 'boot belongs to title music');
assert.strictEqual(route('menu'), null, 'menu belongs to title music');
assert.strictEqual(route('opening'), 'first-wake-cinematic');
assert.strictEqual(route('world', {state:'signal',wakeEpilogueId:null}), 'solar-punk-airship');
assert.strictEqual(route('airship', {state:'crossing',wakeEpilogueId:null}), 'solar-punk-airship');
assert.strictEqual(route('combat', {state:'crossing',wakeEpilogueId:null}), 'nocturnal-resolve');
assert.strictEqual(
  route('world', {state:'wake',wakeEpilogueId:'epiline_10'}),
  'open-sky-signal',
  'First Note WAKE must resolve to Ender theme'
);
assert.strictEqual(
  route('world', {state:'done',wakeEpilogueId:'epiline_10'}),
  'open-sky-signal',
  'First Note DONE must retain Ender theme'
);
assert.strictEqual(
  route('world', {state:'done',wakeEpilogueId:'epiline_7'}),
  'solar-punk-airship',
  'non-First-Note endings must not steal Ender theme'
);

global.gameState = 'dialogue';
global._world = { getQuestState: () => ({state:'contact',wakeEpilogueId:null}) };
assert.strictEqual(music.setCharacterTheme('ender'), true);
assert.strictEqual(music.state.desiredId, 'open-sky-signal');
music.clearCharacterTheme();
assert.strictEqual(music.state.desiredId, 'solar-punk-airship');
assert.strictEqual(music.setCharacterTheme('lyra'), false, 'unknown character cue must fail closed');

console.log('Aetherwake Chapter 1 scene-music routing: PASS');
