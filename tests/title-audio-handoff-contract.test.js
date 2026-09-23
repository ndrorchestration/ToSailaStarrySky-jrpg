'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const repo = path.resolve(__dirname, '..');
const script = fs.readFileSync(
  path.join(repo, 'scripts', 'admit-title-audio.ps1'),
  'utf8'
);

assert(script.includes('requires a clean working tree before mutation'),
  'admission wrapper must fail closed on pre-existing local changes');
assert(script.includes('detached HEAD is not allowed'),
  'admission wrapper must require a named branch');
assert(script.includes('npm run admit:title-audio -- --source "$Source" --check-only') &&
       script.includes('TITLE_AUDIO_PREFLIGHT=PASS'),
  'admission wrapper must preflight the exact source before repository mutation');
assert(script.includes('assets/audio/aetherwake-skyward-arpeggio-main-title.mp3'),
  'admission wrapper must stage the canonical title MP3');
assert(script.includes('docs/audio-assets.json'),
  'admission wrapper must stage the governed audio manifest');
assert(script.includes('modules/audio-assets-runtime.js'),
  'admission wrapper must stage the generated runtime audio registry');
assert(script.includes('git diff --cached --name-only'),
  'admission wrapper must inspect the exact staged path set');
assert(script.includes('Unexpected staged paths'),
  'admission wrapper must reject scope widening');
assert(script.includes('Expected title-audio admission paths were not staged'),
  'admission wrapper must reject incomplete admission');
assert(script.includes('npm run test:m0-title-audio-ready'),
  'admission wrapper must run the strict M0 audio gate');
assert(script.includes("assets: admit canonical Skyward Arpeggio title theme"),
  'admission wrapper must use a stable explicit commit message');
assert(script.includes('TITLE_AUDIO_ADMISSION=COMMITTED_VERIFIED'),
  'committed admission must emit a machine-readable success marker');
assert(script.includes('NEXT_M0_COMMAND=powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\verify-m0-local.ps1'),
  'admission wrapper must emit the exact next M0 command');

console.log('Aetherwake title-audio handoff contract: PASS');
