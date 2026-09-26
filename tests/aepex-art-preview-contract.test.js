'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const vm=require('vm');
const root=path.resolve(__dirname,'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets/characters/v1/manifest.json'),'utf8'));
const aepex=manifest.characters.aepex;
assert.strictEqual(aepex.status,'planned','candidate must not be runtime-admitted');
assert.strictEqual(aepex.candidatePortraitAtlas.status,'candidate');
assert.deepStrictEqual(aepex.candidatePortraitAtlas.expressions,['neutral','talk','concern','focus','hurt','smile']);
const imagePath=path.join(root,aepex.candidatePortraitAtlas.path);
const png=fs.readFileSync(imagePath);
assert.strictEqual(png.toString('hex',0,8),'89504e470d0a1a0a','candidate must be PNG');
assert.strictEqual(png.readUInt32BE(16),768,'atlas width must match contract');
assert.strictEqual(png.readUInt32BE(20),512,'atlas height must match contract');
let offset=8,hasTransparentPaletteEntry=false;
while(offset<png.length){
  const size=png.readUInt32BE(offset);
  const type=png.toString('ascii',offset+4,offset+8);
  if(type==='tRNS'){
    for(let i=offset+8;i<offset+8+size;i++)if(png[i]<255)hasTransparentPaletteEntry=true;
  }
  offset+=12+size;
}
assert(hasTransparentPaletteEntry,'candidate must retain transparent background');
const source=fs.readFileSync(path.join(root,'modules/character-art-preview.js'),'utf8');
function boot(search){
  const events=[];
  const sandbox={
    URLSearchParams,
    location:{search},
    loadImage(file,onLoad){
      events.push({type:'load',file});
      const loaded={width:768,height:512};
      onLoad(loaded);
      return loaded;
    },
    imageMode(){},push(){},pop(){},
    image(...args){events.push({type:'image',args});},
    CORNER:'CORNER',
    window:{location:{search}}
  };
  vm.createContext(sandbox);
  vm.runInContext(source,sandbox);
  return {api:sandbox.window.AetherCharacterArtPreview,events};
}
const normal=boot('');
assert.strictEqual(normal.api.getPreviewCharacterId(),null);
assert.strictEqual(normal.api.drawPortrait('aepex',0,0,88,{expression:'talk'}),false);
assert.strictEqual(normal.events.length,0,'normal runtime must not load or draw candidate');
const preview=boot('?aetherwakeArtPreview=aepex');
assert.strictEqual(preview.api.getPreviewCharacterId(),'aepex');
assert.strictEqual(preview.api.normalizeExpression('speaking'),'talk');
assert.strictEqual(preview.api.drawPortrait('reson',0,0,88,{expression:'neutral'}),false);
assert.strictEqual(preview.api.drawPortrait('aepex',4,8,88,{expression:'smile'}),true);
const draw=preview.events.find(event=>event.type==='image');
assert(draw,'candidate image should draw in explicit preview mode');
assert.strictEqual(draw.args[5],512,'smile should use the sixth atlas cell');
assert.strictEqual(draw.args[6],256,'smile should use the bottom atlas row');
assert.strictEqual(preview.events.filter(event=>event.type==='load').length,1,'atlas should load once');
console.log('Aetherwake Aepex art preview contract: PASS');
