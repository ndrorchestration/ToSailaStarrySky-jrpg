'use strict';
// Source-exact document migration contract: nothing here grants production,
 // creator art acceptance, gameplay authority or Windows release rights.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const root = path.resolve(__dirname, '..');
const index = fs.readFileSync(path.join(root,'docs/AGENT_HANDOFF_INDEX.md'),'utf8');
const coordination = fs.readFileSync(path.join(root,'docs/GODOT_MIGRATION_COORDINATION.md'),'utf8');
const sources = [
  [498,'docs/design/EQUIPMENT_PROTOTYPE_TO_PRODUCTION_PIPELINE_2026-10-27.md','d8218d462e0535c9b346388403439d8ab92e569c'],
  [499,'docs/SHIP_POSE_PROTOTYPE_TO_PRODUCTION_ADMISSION.md','8a76d8356213079f4f8e1b8942609212cb72eba1'],
  [500,'docs/VFX_PROTOTYPE_TO_PRODUCTION_PIPELINE_2026-10-27.md','ebe1bcefc3bfc8873f629b5ffe1f926b3366abcc'],
  [501,'docs/design/PERCEPTUAL_BIOME_MATERIAL_PROMOTION_2026-10-27.md','c331fbda71e04432e27bfb6f0179d1806cc5bb7b'],
  [502,'docs/design/CHARACTER_MOTION_PROTOTYPE_TO_PRODUCTION_PIPELINE_2026-10-27.md','0146de79637d794512b2f4380614b71c87099948'],
  [505,'docs/reviews/ENEMY_VISUAL_PROTOTYPE_TO_PRODUCTION_2026-10-27.md','c2e91283294544331a0c3aa9027490d05f9cb846']
];
const gitBlob = raw => crypto.createHash('sha1')
  .update(Buffer.concat([Buffer.from('blob '+raw.length+'\0'),raw])).digest('hex');

test('six exact-source handoffs are preserved, indexed and traceable',()=>{
  for(const [n,filename,expected] of sources) {
    const raw=fs.readFileSync(path.join(root,filename));
    assert.equal(gitBlob(raw),expected,'source blob drift from PR '+n);
    assert.match(index,new RegExp('pull/'+n+'\\b'),'source PR absent: '+n);
    assert.ok(index.includes(filename.replace(/^docs\//,'')),'handoff link missing: '+filename);
  }
});

test('public docs remain review instructions, not shipping or runtime authorization',()=>{
  assert.match(index,/review criteria, not production authorization/i);
  assert.match(index,/no runtime, canonical story, save schema, installer or published release/i);
  assert.match(coordination,/documentation only/i);
  assert.match(coordination,/creator-directed Ionia-first story order/i);
  for(const [,filename] of sources) {
    const body=fs.readFileSync(path.join(root,filename),'utf8');
    assert.match(body,/PROPOSAL|PROPOSED|CANDIDATE|documentation|review-only/i,filename+' missing proposed scope');
  }
});
