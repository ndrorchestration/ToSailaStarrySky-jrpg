'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const root=path.resolve(__dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets/characters/v1/manifest.json'),'utf8'));
const ids=['ender','lyra','ionia','aepex','reson'];
for(const id of ids){
  const c=manifest.characters[id];
  assert(c,id+' portrait manifest missing');
  const atlas=c.candidatePortraitAtlas||c.portraitAtlas;
  assert(atlas,id+' review portrait path missing');
  if(c.candidatePortraitAtlas){
    assert.strictEqual(c.candidatePortraitAtlas.status,'candidate',id+' preview atlas must remain candidate');
  }
  const file=path.join(root,atlas.path);
  const png=fs.readFileSync(file);
  assert.strictEqual(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a',id+' portrait must be PNG');
  assert.strictEqual(png.readUInt32BE(16),768,id+' portrait width');
  assert.strictEqual(png.readUInt32BE(20),512,id+' portrait height');
}
const review=fs.readFileSync(path.join(__dirname,'roster-portrait-review.html'),'utf8');
for(const id of ids)assert(review.includes('"'+id+'"'),'review must include '+id);
for(const id of ['ender','lyra','aepex','reson']){
  assert(review.includes(id+'/portrait-atlas-candidate.png'),id+' review must use candidate atlas');
}
assert(review.includes('ionia/portrait-atlas.png'),'Ionia review must use the admitted atlas');
console.log('Five-protagonist portrait atlas review contract: PASS');