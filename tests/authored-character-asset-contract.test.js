'use strict';
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const manifest = JSON.parse(fs.readFileSync(path.join(root,'assets','characters','v1','manifest.json'),'utf8'));
function fail(msg){ throw new Error(msg); }
if (manifest.schema !== 'AETHERWAKE_AUTHORED_CHARACTER_ASSET_MANIFEST_V1') fail('character asset manifest schema mismatch');
const ids=['ender','lyra','ionia','reson','aepex'];
for (const id of ids) {
  const c=manifest.characters[id];
  if(!c) fail('missing character entry: '+id);
  if(!['planned','portrait-ready','ready'].includes(c.status)) fail('invalid status: '+id);
  const p=c.portraitAtlas;
  if(p.width!==768||p.height!==512||p.cellWidth!==256||p.cellHeight!==256||p.expressions.length!==6) fail('portrait contract mismatch: '+id);
  const expected={idle:8,walk:6,talk:4,focus:6,attack:8};
  for(const [name,count] of Object.entries(expected)){
    const strip=c.fieldStrips[name];
    if(!strip||strip.frameWidth!==64||strip.frameHeight!==96||strip.frames!==count) fail('field strip contract mismatch: '+id+'/'+name);
    if(c.status==='ready'){
      const fp=path.join(root,strip.path);
      if(!fs.existsSync(fp)) fail('ready strip missing: '+strip.path);
    }
  }
  if((c.status==='portrait-ready'||c.status==='ready') && !fs.existsSync(path.join(root,p.path))) fail('admitted portrait missing: '+p.path);
}
const renderer=fs.readFileSync(path.join(root,'modules','character-renderer.js'),'utf8');
if(!renderer.includes("['ender','reson','aepex','ionia','lyra']") && !renderer.includes("['ender','lyra','ionia','reson','aepex']")) fail('procedural fallback roster authority missing');
console.log('Aetherwake authored character asset contract: PASS');
