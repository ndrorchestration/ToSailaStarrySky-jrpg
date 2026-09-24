'use strict';
const assert=require('assert');
const crypto=require('crypto');
const fs=require('fs');
const path=require('path');
const repo=path.resolve(__dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(repo,'docs','audio-assets.json'),'utf8'));
const scene=fs.readFileSync(path.join(repo,'modules','scene-music.js'),'utf8');
const expected={
 'first-wake-cinematic':['assets/audio/amonigio-umulula.mp3','bce86fc575323b99573e420dcb6c0d19bfe1eb8e6ba637edc2b72c1edf20cd98',5364037],
 'nocturnal-resolve':['assets/audio/nocturnal-resolve.mp3','c8a35d42762705011f8a9eeefebea91736b333677a9b1117087490bbf0dbc65c',6500031],
 'solar-punk-airship':['assets/audio/solar-punk-airship.mp3','d5d1561c1ef056978342732e363df5411860611739fb485bb707c6e98800335c',4432217],
};
for(const track of manifest.chapter1Tracks || []){
 const e=expected[track.id]; assert(e,'unexpected Chapter 1 track '+track.id);
 assert.strictEqual(track.canonicalPath,e[0]); assert.strictEqual(track.sourceVerification.sha256,e[1]); assert.strictEqual(track.sourceVerification.bytes,e[2]);
 assert.strictEqual(track.repositoryStatus,'admitted','Chapter 1 soundtrack track not admitted: '+track.id);
 assert.strictEqual(track.runtimeRegistration,true,'Chapter 1 soundtrack track not registered: '+track.id);
 const p=path.join(repo,track.canonicalPath); assert(fs.existsSync(p),'missing soundtrack asset '+track.id);
 const b=fs.readFileSync(p); assert.strictEqual(b.length,e[2]); assert.strictEqual(crypto.createHash('sha256').update(b).digest('hex'),e[1]);
 assert(scene.includes(track.canonicalPath),'scene music controller missing path '+track.id);
}
assert(scene.includes("if (state === 'combat') return TRACKS.combat;"));
assert(scene.includes("if (state === 'opening') return TRACKS.opening;"));
assert(scene.includes("state === 'world' || state === 'airship'"));
console.log('Aetherwake Chapter 1 soundtrack readiness: PASS');
