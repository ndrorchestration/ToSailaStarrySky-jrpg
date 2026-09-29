'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');

const root=path.resolve(__dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets/characters/v1/manifest.json'),'utf8'));

assert.strictEqual(manifest.likenessAuthority.status,'CREATOR_APPROVED_V1');
assert.strictEqual(
  manifest.likenessAuthority.referenceSha256,
  'e973be82a026e0d2df441471fa5dd0fd5214265152757bec07d9c493563b93de'
);

const expected={
  ender:['very short dark copper-brown / auburn','bright green'],
  reson:['dark brown under backward red cap',null],
  aepex:['dirty/sandy-blond asymmetric undercut',null],
  ionia:['shoulder-length curly blonde','green'],
  lyra:['long natural red / copper-red','green']
};

for(const [id,[hair,eyes]] of Object.entries(expected)){
  const ch=manifest.characters[id];
  assert(ch,'missing character '+id);
  assert.strictEqual(ch.likenessAuthority.status,'LOCKED_TO_APPROVED_ALIGNMENT_V1');
  assert.strictEqual(ch.likenessAuthority.traits.hair,hair);
  if(eyes) assert.strictEqual(ch.likenessAuthority.traits.eyes,eyes);
  assert.strictEqual(ch.candidateFieldSprite.likenessStatus,'SUPERSEDED_REGENERATE');
  assert.strictEqual(ch.candidateFieldSprite.promotionBlocked,true);
  assert.strictEqual(ch.candidateFieldSprite.supersededBy,'docs/PROTAGONIST_VISUAL_ALIGNMENT_V1.md');
}

assert(manifest.characters.ionia.likenessAuthority.traits.hair.includes('curly blonde'));
assert(manifest.characters.lyra.likenessAuthority.traits.hair.includes('red / copper-red'));
assert(manifest.characters.ender.likenessAuthority.traits.eyes==='bright green');

console.log('Aetherwake approved protagonist likeness authority: PASS');
