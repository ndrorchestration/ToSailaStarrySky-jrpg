'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const root=path.resolve(__dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets/characters/v1/manifest.json'),'utf8'));
const admitted=['ender','lyra','ionia'];
const held=['aepex','reson'];
for(const id of admitted){
  const c=manifest.characters[id];
  assert(c,id+' portrait manifest missing');
  assert(['portrait-ready','ready'].includes(c.status),id+' portrait must be admitted for runtime review');
  const atlas=c.portraitAtlas;
  assert(atlas,id+' admitted portrait path missing');
  const file=path.join(root,atlas.path);
  const png=fs.readFileSync(file);
  assert.strictEqual(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a',id+' portrait must be PNG');
  assert.strictEqual(png.readUInt32BE(16),768,id+' portrait width');
  assert.strictEqual(png.readUInt32BE(20),512,id+' portrait height');
}
for(const id of held){
  const c=manifest.characters[id];
  assert(c,id+' portrait manifest missing');
  assert(!['portrait-ready','ready'].includes(c.status),id+' portrait must remain runtime-unadmitted');
  assert(c.candidatePortraitAtlas,id+' candidate portrait review source missing');
}
const review=fs.readFileSync(path.join(__dirname,'roster-portrait-review.html'),'utf8');
for(const id of [...admitted,...held]) assert(review.includes('"'+id+'"'),'review must include '+id);
for(const id of admitted){
  assert(review.includes(id+'/portrait-atlas.png'),id+' review must use the admitted atlas');
}
for(const id of held){
  assert(review.includes(id+'/portrait-atlas-candidate.png'),id+' review must use the candidate atlas while held');
}
console.log('Five-protagonist portrait atlas review contract: PASS');
