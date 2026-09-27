/* eslint-env node */
'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const src=fs.readFileSync(path.resolve(__dirname,'..','aetherwake.js'),'utf8');
assert(/case 'elder_farmer':\s*(?:ioniaFieldCandidateDrawn\s*=\s*)?drawNPCIonia\(px, py\);/.test(src),
  'legacy Ionia NPC id must route to canonical Ionia visual renderer');
assert(src.includes("function drawNPCIonia(px, py)"), 'Ionia world renderer missing');
assert(src.includes("characters.draw('ionia'"), 'Ionia world renderer must prefer shared character authority');
assert(src.includes('Compatibility fallback only'), 'Ionia legacy sprite fallback boundary missing');
assert(/function drawNPCElder\(px, py\) \{\s*return drawNPCIonia\(px, py\);/.test(src),
  'legacy visual function must remain only as compatibility alias');
console.log('Aetherwake Ionia world visual authority: PASS');
