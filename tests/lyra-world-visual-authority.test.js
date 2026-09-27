/* eslint-env node */
'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const src=fs.readFileSync(path.resolve(__dirname,'..','aetherwake.js'),'utf8');
assert(/case 'child_prophet':\s*(?:lyraFieldCandidateDrawn\s*=\s*)?drawNPCLyra\(px, py\);/.test(src),
  'legacy Lyra NPC id must route to canonical Lyra visual renderer');
assert(src.includes("function drawNPCLyra(px, py)"), 'Lyra world renderer missing');
assert(src.includes("characters.draw('lyra'"), 'Lyra world renderer must prefer shared character authority');
assert(src.includes('Compatibility fallback only: legacy top-down sprite authority.'),
  'Lyra legacy sprite fallback boundary missing');
assert(/function drawNPCChild\(px, py\) \{\s*return drawNPCLyra\(px, py\);/.test(src),
  'legacy child-prophet visual function must remain only as compatibility alias');
console.log('Aetherwake Lyra world visual authority: PASS');
