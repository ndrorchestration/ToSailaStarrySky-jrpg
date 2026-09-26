'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const root=path.resolve(__dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets/characters/v1/manifest.json'),'utf8'));
const ids=['ender','lyra','ionia','aepex','reson'];
for (const id of ids) {
  const record=manifest.characters[id];
  assert(record, id+' manifest record missing');
  assert(record.candidateFieldSprite, id+' candidate field sprite missing');
  assert.strictEqual(record.candidateFieldSprite.status,'candidate',id+' candidate must remain candidate');
  assert.deepStrictEqual(record.candidateFieldSprite.frames,['idle','walk']);
  const file=path.join(root,record.candidateFieldSprite.path);
  const png=fs.readFileSync(file);
  assert.strictEqual(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a',id+' must be PNG');
  assert.strictEqual(png.readUInt32BE(16),56,id+' width');
  assert.strictEqual(png.readUInt32BE(20),36,id+' height');
  assert.strictEqual(png[25],6,id+' alpha');
}
const review=fs.readFileSync(path.join(__dirname,'field-sprite-roster-review.html'),'utf8');
for (const id of ids) assert(review.includes("'"+id+"'"),'review must include '+id);
console.log('Five-protagonist field sprite candidate review contract: PASS');
