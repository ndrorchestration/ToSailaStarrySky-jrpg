'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const vm=require('vm');
const root=path.resolve(__dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets/characters/v1/manifest.json'),'utf8'));
const ender=manifest.characters.ender;
assert.strictEqual(ender.status,'planned','field candidate must not admit Ender runtime art');
assert.strictEqual(ender.candidateFieldSprite.status,'candidate');
assert.deepStrictEqual(ender.candidateFieldSprite.frames,['idle','walk']);
const imagePath=path.join(root,ender.candidateFieldSprite.path);
const png=fs.readFileSync(imagePath);
assert.strictEqual(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a','candidate must be PNG');
assert.strictEqual(png.readUInt32BE(16),56);
assert.strictEqual(png.readUInt32BE(20),36);
assert.strictEqual(png[25],6,'candidate PNG must carry an alpha channel');
const runtimeSource=fs.readFileSync(path.join(root,'aetherwake.js'),'utf8');
const playerStart=runtimeSource.indexOf('function drawPlayer()');
const playerEnd=runtimeSource.indexOf('// --- NPCs',playerStart);
const playerRenderer=runtimeSource.slice(playerStart,playerEnd);
assert(playerRenderer.includes("sprites.drawFieldCandidate('ender', px + 8, py + 16"),
  'opt-in candidate must be wired into the live player renderer');
assert(playerRenderer.includes('fieldCandidateDrawn ? py - 28 : py - 6'),
  'Ender name label must track the taller candidate only while it is actually drawn');
assert(playerRenderer.includes("sprites.draw('ender', px, py, { frame: fieldFrame });"),
  'existing runtime fallback must remain available');
const moduleSource=fs.readFileSync(path.join(root,'modules/pixel-sprites.js'),'utf8');
function boot(search){
  const events={requested:[],images:[],rects:[]};
  const sandbox={
    URLSearchParams,
    window:{location:{search}},
    loadImage(asset,onLoad){
      events.requested.push(asset);
      const loaded=asset.includes('field-idle-walk-candidate.png')
        ? {width:56,height:36}
        : {width:224,height:72};
      if(onLoad)onLoad(loaded);
      return loaded;
    },
    image(...args){events.images.push(args);},
    noSmooth(){},noStroke(){},fill(){},rect(...args){events.rects.push(args);}
  };
  vm.createContext(sandbox);
  vm.runInContext(moduleSource,sandbox);
  return {api:sandbox.window.AetherPixelSprites,events};
}
const runtimePreview=boot('?aetherwakeFieldArtPreview=ender');
assert.strictEqual(runtimePreview.api.isFieldArtCandidateRequested('ender'),true);
assert.strictEqual(runtimePreview.api.isFieldArtCandidateRequested('lyra'),false);
assert.strictEqual(runtimePreview.api.drawFieldCandidate('ender',100,200,{anchor:'bottom-center',scale:1,frame:1}),true,
  'live player preview should draw Ender through the dedicated candidate hook');
assert.deepStrictEqual(runtimePreview.events.requested,[ender.candidateFieldSprite.path]);
assert.strictEqual(runtimePreview.events.images[0][5],28,'live player walk frame should sample the second cell');
assert.strictEqual(runtimePreview.api.drawFieldCandidate('lyra',100,200,{frame:1}),false,
  'the dedicated field preview hook must refuse unrelated characters');
const normal=boot('');
assert.strictEqual(normal.api.drawPreview('ender',100,200,{anchor:'bottom-center',scale:2,frame:1}),true);
assert(!normal.events.requested.includes(ender.candidateFieldSprite.path),'normal game must not load candidate');
const review=boot('?aetherwakeFieldArtPreview=ender');
assert.strictEqual(review.api.drawPreview('ender',100,200,{anchor:'bottom-center',scale:2,frame:0}),true);
assert.deepStrictEqual(review.events.requested,[ender.candidateFieldSprite.path]);
assert.deepStrictEqual(review.events.images[0].slice(1,5),[72,128,56,72]);
assert.strictEqual(review.events.images[0][5],0,'idle frame samples the first cell');
assert.strictEqual(review.api.drawPreview('ender',100,200,{anchor:'bottom-center',scale:2,frame:1}),true);
assert.strictEqual(review.events.images[1][5],28,'walk frame samples the second cell');
const unrelated=boot('?aetherwakeFieldArtPreview=ender');
assert.strictEqual(unrelated.api.drawPreview('lyra',100,200,{anchor:'bottom-center',scale:2,frame:0}),true);
assert.deepStrictEqual(unrelated.events.requested,['assets/preview/aetherwake-preview-party-atlas-v2.png'],
  'Ender candidate must not replace Lyra or load outside its opt-in identity');
console.log('Ender selected-reference field-sprite candidate contract: PASS');
