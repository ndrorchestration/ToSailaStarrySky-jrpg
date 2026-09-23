'use strict';

const assert = require('assert');

class FakeAudio {
  constructor() {
    this.volume = 1;
    this.loop = false;
    this.src = '';
    this.currentTime = 0;
    this.playCalls = 0;
    this.pauseCalls = 0;
  }
  addEventListener() {}
  play() {
    this.playCalls++;
    return Promise.resolve();
  }
  pause() {
    this.pauseCalls++;
  }
}

global.window = global;
global.Audio = FakeAudio;
const bus = require('../modules/music-bus.js');

assert.strictEqual(bus.VERSION, '0.1.0');
assert.strictEqual(bus.snapshot().volumePercent, 80);
assert.deepStrictEqual(bus.listTracks(), []);

assert.deepStrictEqual(
  bus.play('missing'),
  { ok: false, reason: 'MUSIC_TRACK_UNREGISTERED:missing' },
  'unregistered music must fail closed without network playback'
);

assert.throws(
  () => bus.registerTrack({ id: 'remote', src: 'https://example.com/music.mp3' }),
  /MUSIC_TRACK_REMOTE_SOURCE_FORBIDDEN/,
  'runtime music authority must not silently admit remote sources'
);

bus.registerTrack({
  id: 'title',
  src: 'assets/audio/title.mp3',
  title: 'Title',
  loop: true
});
assert.strictEqual(bus.listTracks()[0].id, 'title');

bus.setVolumePercent(50);
assert.strictEqual(bus.snapshot().volumePercent, 50);
assert.strictEqual(bus.snapshot().effectiveVolume, 0.5);

bus.setDuckFactor(0.4);
assert.strictEqual(bus.snapshot().effectiveVolume, 0.2);

const result = bus.play('title');
assert.strictEqual(result.ok, true);
assert.strictEqual(bus.snapshot().currentTrackId, 'title');
assert.strictEqual(bus.snapshot().hasAudioElement, true);

bus.stop();
assert.strictEqual(bus.snapshot().currentTrackId, null);

console.log('Aetherwake canonical music bus contract: PASS');
