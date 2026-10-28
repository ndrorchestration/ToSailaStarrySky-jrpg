// Cross-branch production-canon boundary: verify original Git blob identity
// without downloading or trusting an editable source branch at test time.
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const stage = path.join(root, 'godot/art-staging/environment-study');
const manifest = JSON.parse(fs.readFileSync(path.join(stage,'intake-manifest.json'),'utf8'));
assert.equal(manifest.schemaVersion, 1);
assert.equal(manifest.classification, 'PROTOTYPE_REVIEW_ONLY');
assert.match(manifest.source.gitCommit,/^[0-9a-f]{40}$/);
assert.equal(manifest.source.draftPR,476);
assert.equal(manifest.target.basePR,480);
assert.equal(manifest.target.defaultEnabled,false);
for(const key of ['runtimeProgression','saveState','collision']) assert.equal(manifest.target[key],false);
assert.equal(manifest.gates.visualAcceptance,'PENDING');
assert.equal(manifest.gates.productionAssetAdmission,'HOLD');
assert.equal(manifest.gates.merge,'HOLD');
assert.equal(manifest.assets.length,4);
assert.deepEqual(new Set(manifest.assets.map(a=>a.key)),new Set(['water','terrain','foliage','biome']));

const actual=fs.readdirSync(stage).filter(name=>name.endsWith('.png')).sort();
assert.deepEqual(actual,manifest.assets.map(a=>a.name).sort(),'no unreviewed PNG in intake');

function gitBlobSha(bytes){
  return crypto.createHash('sha1').update(Buffer.from(`blob ${bytes.length}\0`)).update(bytes).digest('hex');
}

for(const asset of manifest.assets){
  assert.match(asset.name,/^[a-z_]+\.png$/);
  const file=path.join(stage,asset.name);
  assert.equal(asset.destinationPath,path.relative(root,file).replaceAll(path.sep,'/'));
  assert.equal(asset.sourcePath,'godot/flight_slice/textures/'+asset.name);
  assert.match(asset.gitBlob,/^[0-9a-f]{40}$/);
  const png=fs.readFileSync(file);
  assert.equal(png.length,65737,'bounded original PNG byte identity '+asset.name);
  assert.equal(gitBlobSha(png),asset.gitBlob,'source Git blob content MUST match exactly '+asset.name);
  assert.equal(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a','PNG signature');
  assert.equal(png.toString('ascii',12,16),'IHDR');
  assert.equal(png.readUInt32BE(16),128);
  assert.equal(png.readUInt32BE(20),128);
  assert.equal(png[24],8);
  assert.equal(png[25],6,'RGBA image');
}
const adapter=fs.readFileSync(path.join(root,'godot/scripts/ch1_environment_art_intake.gd'),'utf8');
const chapter=fs.readFileSync(path.join(root,'godot/scripts/first_wake_chapter1_review.gd'),'utf8');
for(const asset of manifest.assets){
 assert(adapter.includes('res://art-staging/environment-study/'+asset.name),'Godot adapter must preload all original assets');
}
assert(chapter.includes('res://scripts/ch1_environment_art_intake.gd'));
assert(chapter.includes('ChapterOneEnvironmentAssetIntakeReviewOnly'));
assert(adapter.includes('visible = false'),'must stay opt-in');
assert(/func set_environment_asset_intake_review_enabled\(enabled: bool\)/.test(chapter),'explicit review switch');
assert(!adapter.includes('user://'),'no save-state access');
assert(!adapter.includes('CollisionShape'),'no collision-owned art');
assert(!adapter.includes('Input.'),'no gameplay input hooks');
console.log('GODOT_ENVIRONMENT_ART_INTAKE_PROVENANCE_PASS assets=4 exact-git-blobs=4 no-gameplay-mutations');
