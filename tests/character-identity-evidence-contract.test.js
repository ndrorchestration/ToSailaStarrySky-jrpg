/* eslint-env node */
'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const src=fs.readFileSync(path.resolve(__dirname,'character-identity-evidence.html'),'utf8');
assert(src.includes('../modules/authored-character-art.js'), 'identity evidence must load authored portrait authority');
assert(src.includes('isPortraitReady(ids[i])'), 'identity evidence must inspect per-character authored readiness');
assert(src.includes('function preload()') && src.includes('authoredAtlases[id]=loadImage'),
  'identity evidence must preload admitted authored atlases before one-shot rendering');
assert(src.includes('image(atlas,xs[i]-54,120,108,108,0,0,256,256)'),
  'identity evidence must visibly render the neutral authored atlas cell');
assert(src.includes("'AUTHORED PORTRAIT' : 'PROCEDURAL PORTRAIT'"), 'identity evidence must label portrait source honestly');
assert(src.includes('AetherCharacterRenderer.draw(ids[i]'), 'identity evidence must retain procedural field silhouette comparison');
console.log('Aetherwake character identity evidence contract: PASS');
