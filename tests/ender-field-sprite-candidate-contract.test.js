'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const vm=require('vm');
const root=path.resolve(__dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets/characters/v1/manifest.json'),'utf8'));
const ender=manifest.characters.ender;
const lyra=manifest.characters.lyra;
const ionia=manifest.characters.ionia;
assert.strictEqual(ender.status,'planned','field candidate must not admit Ender runtime art');
assert.strictEqual(ender.candidateFieldSprite.status,'candidate');
assert.deepStrictEqual(ender.candidateFieldSprite.frames,['idle','walk']);
const imagePath=path.join(root,ender.candidateFieldSprite.path);
const png=fs.readFileSync(imagePath);
assert.strictEqual(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a','candidate must be PNG');
assert.strictEqual(png.readUInt32BE(16),56);
assert.strictEqual(png.readUInt32BE(20),36);
assert.strictEqual(png[25],6,'candidate PNG must carry an alpha channel');
assert.strictEqual(lyra.status,'planned','field candidate must not admit Lyra runtime art');
assert.strictEqual(lyra.candidateFieldSprite.status,'candidate');
assert.deepStrictEqual(lyra.candidateFieldSprite.frames,['idle','walk']);
const lyraImagePath=path.join(root,lyra.candidateFieldSprite.path);
const lyraPng=fs.readFileSync(lyraImagePath);
assert.strictEqual(lyraPng.subarray(0,8).toString('hex'),'89504e470d0a1a0a','Lyra candidate must be PNG');
assert.strictEqual(lyraPng.readUInt32BE(16),56);
assert.strictEqual(lyraPng.readUInt32BE(20),36);
assert.strictEqual(lyraPng[25],6,'Lyra candidate PNG must carry an alpha channel');
assert.strictEqual(ionia.status,'portrait-ready','field candidate must not change Ionia portrait admission');
assert.strictEqual(ionia.candidateFieldSprite.status,'candidate');
assert.deepStrictEqual(ionia.candidateFieldSprite.frames,['idle','walk']);
const ioniaImagePath=path.join(root,ionia.candidateFieldSprite.path);
const ioniaPng=fs.readFileSync(ioniaImagePath);
assert.strictEqual(ioniaPng.subarray(0,8).toString('hex'),'89504e470d0a1a0a','Ionia candidate must be PNG');
assert.strictEqual(ioniaPng.readUInt32BE(16),56);
assert.strictEqual(ioniaPng.readUInt32BE(20),36);
assert.strictEqual(ioniaPng[25],6,'Ionia candidate PNG must carry an alpha channel');
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
const lyraStart=runtimeSource.indexOf('function drawNPCLyra(px, py)');
const lyraEnd=runtimeSource.indexOf('// Legacy function name retained only for compatibility; rendering authority is Lyra.',lyraStart);
const lyraRenderer=runtimeSource.slice(lyraStart,lyraEnd);
assert(lyraRenderer.includes("sprites.drawFieldCandidate('lyra', px, py + 8"),
  'opt-in Lyra candidate must be wired into her live NPC renderer');
assert(runtimeSource.includes("sprites.drawFieldCandidate('ionia', px, py + 8"),
  'opt-in Ionia candidate must be wired into her live NPC renderer');
assert(runtimeSource.includes('ioniaFieldCandidateDrawn ? py - 32 : (lyraFieldCandidateDrawn'),
  'Ionia name label must clear the taller candidate only while it is drawn');
assert(runtimeSource.includes('lyraFieldCandidateDrawn ? py - 32 : py - 12'),
  'Lyra name label must clear the taller candidate only while it is drawn');
const moduleSource=fs.readFileSync(path.join(root,'modules/pixel-sprites.js'),'utf8');
function boot(search){
  const events={requested:[],images:[],rects:[]};
  const sandbox={
    URLSearchParams,
    window:{location:{search}},
    loadImage(asset,onLoad,onError){
      events.requested.push(asset);
      const loaded=asset.includes('field-idle-walk-candidate.png')
        ? {width:56,height:36}
        : (asset.includes('sky-predator-battle.png') ? {width:84,height:36} : {width:224,height:72});
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
  'the selected Ender preview must not draw another character');
const lyraPreview=boot('?aetherwakeFieldArtPreview=lyra');
assert.strictEqual(lyraPreview.api.isFieldArtCandidateRequested('lyra'),true);
assert.strictEqual(lyraPreview.api.isFieldArtCandidateRequested('ender'),false);
assert.strictEqual(lyraPreview.api.drawFieldCandidate('lyra',100,200,{anchor:'bottom-center',scale:1,frame:1}),true,
  'live NPC preview should draw Lyra through the dedicated candidate hook');
assert.deepStrictEqual(lyraPreview.events.requested,[lyra.candidateFieldSprite.path]);
assert.strictEqual(lyraPreview.events.images[0][5],28,'Lyra walk frame should sample the second cell');
const ioniaPreview=boot('?aetherwakeFieldArtPreview=ionia');
assert.strictEqual(ioniaPreview.api.isFieldArtCandidateRequested('ionia'),true);
assert.strictEqual(ioniaPreview.api.drawFieldCandidate('ionia',100,200,{anchor:'bottom-center',scale:1,frame:1}),true,
  'live NPC preview should draw Ionia through the dedicated candidate hook');
assert.deepStrictEqual(ioniaPreview.events.requested,[ionia.candidateFieldSprite.path]);
assert.strictEqual(ioniaPreview.events.images[0][5],28,'Ionia walk frame should sample the second cell');
const normalIonia=boot('');
assert.strictEqual(normalIonia.api.drawFieldCandidate('ionia',100,200,{frame:1}),false);
assert.deepStrictEqual(normalIonia.events.requested,[],'normal game must not load Ionia candidate');
const normalLyra=boot('');
assert.strictEqual(normalLyra.api.drawFieldCandidate('lyra',100,200,{frame:1}),false);
assert.deepStrictEqual(normalLyra.events.requested,[],'normal game must not load Lyra candidate');
assert.strictEqual(normalLyra.api.drawPreview('lyra',100,200,{frame:0}),true);
assert(!normalLyra.events.requested.includes(lyra.candidateFieldSprite.path),
  'Lyra candidate must remain opt-in in normal preview surfaces');
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
const battle=boot('');
assert.strictEqual(battle.api.drawBattleEnemy('skyPredator',100,200,{frame:1}),true);
assert.deepStrictEqual(battle.events.requested,['assets/preview/aetherwake-sky-predator-battle.png'],
  'battle atlas loader must receive its normal path/callback signature');
assert.strictEqual(battle.events.images.length,1,
  'battle atlas should become ready and draw instead of silently falling back');
console.log('Ender, Lyra, and Ionia selected-reference field-sprite candidate contract: PASS');


const aepex = manifest.characters.aepex;
assert.strictEqual(aepex.status, 'planned', 'field candidate must not admit Aepex runtime art');
assert.strictEqual(aepex.candidateFieldSprite.status, 'candidate');
assert.deepStrictEqual(aepex.candidateFieldSprite.frames, ['idle','walk']);
const aepexImagePath = path.join(root, aepex.candidateFieldSprite.path);
const aepexPng = fs.readFileSync(aepexImagePath);
assert.strictEqual(aepexPng.readUInt32BE(16), 56);
assert.strictEqual(aepexPng.readUInt32BE(20), 36);
assert.strictEqual(aepexPng[25], 6, 'Aepex candidate PNG must carry an alpha channel');
const aepexPreview = boot('?aetherwakeFieldArtPreview=aepex');
assert.strictEqual(aepexPreview.api.isFieldArtCandidateRequested('aepex'), true);
assert.strictEqual(aepexPreview.api.drawFieldCandidate('aepex',100,200,{anchor:'bottom-center',scale:1,frame:1}), true);
assert.deepStrictEqual(aepexPreview.events.requested, [aepex.candidateFieldSprite.path]);
assert.strictEqual(aepexPreview.events.images[0][5], 28);
console.log('Aepex selected-reference field-sprite candidate contract: PASS');

const reson = manifest.characters.reson;
assert.strictEqual(reson.status, 'planned', 'field candidate must not admit Reson runtime art');
assert.strictEqual(reson.candidateFieldSprite.status, 'candidate');
assert.deepStrictEqual(reson.candidateFieldSprite.frames, ['idle','walk']);
const resonImagePath = path.join(root, reson.candidateFieldSprite.path);
const resonPng = fs.readFileSync(resonImagePath);
assert.strictEqual(resonPng.readUInt32BE(16), 56);
assert.strictEqual(resonPng.readUInt32BE(20), 36);
assert.strictEqual(resonPng[25], 6, 'Reson candidate PNG must carry an alpha channel');
const resonPreview = boot('?aetherwakeFieldArtPreview=reson');
assert.strictEqual(resonPreview.api.isFieldArtCandidateRequested('reson'), true);
assert.strictEqual(resonPreview.api.drawFieldCandidate('reson',100,200,{anchor:'bottom-center',scale:1,frame:1}), true);
assert.deepStrictEqual(resonPreview.events.requested, [reson.candidateFieldSprite.path]);
assert.strictEqual(resonPreview.events.images[0][5], 28);
console.log('Reson selected-reference field-sprite candidate contract: PASS');
