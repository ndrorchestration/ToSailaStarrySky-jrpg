'use strict';
const assert=require('assert');
const fs=require('fs');
const path=require('path');
const read=p=>fs.readFileSync(path.join(__dirname,'..',p),'utf8');

const authority=read('docs/DOCUMENTATION_AUTHORITY.md');
const readme=read('README.md');
const spec=read('SPEC.md');
const art=read('docs/ART_DIRECTION.md');
const combat=read('docs/JRPG_COMBAT_DIRECTION.md');
const gap=read('gap_analysis.md');
const index=read('index.html');
const embedded=read('index-embedded.html');

assert(authority.includes('all five protagonists simultaneously'),
  'documentation authority lost the five-protagonist final-party direction');
assert(readme.includes('all 5 canonical protagonists simultaneously'),
  'README drifted back from five-protagonist party target');
assert(spec.includes('all five protagonists'),
  'SPEC does not preserve five-protagonist expansion target');
assert(combat.includes('all five when Aepex joins'),
  'combat direction does not scale through the fifth protagonist');

for (const [name,doc] of [['README',readme],['SPEC',spec],['ART_DIRECTION',art]]) {
  assert(!/exactly\s+(3|three)\s+active\s+combatants/i.test(doc),
    name+' reintroduced the superseded permanent three-active target');
}
assert(!readme.includes('Rift Scholar + Dreamwright'),
  'README reintroduced Dreamwright as current Ender identity');
assert(!readme.includes('Young Ender'),
  'README reintroduced Young Ender identity');
assert(art.includes('Ionia: 28') && art.includes('Reson: 25') && art.includes('Aepex: 27'),
  'art direction lost canonical roster identity anchors');
assert(gap.includes('HISTORICAL IMPLEMENTATION AUDIT'),
  'gap analysis is no longer visibly classified as historical evidence');
assert(!index.includes('<title>Aetherwake — Young Ender</title>') && !embedded.includes('<title>Aetherwake — Young Ender</title>'),
  'playable entrypoint title regressed to superseded Young Ender identity');
assert(index.includes('<title>Aetherwake — The Last Solarpunk Airship</title>') &&
       embedded.includes('<title>Aetherwake — The Last Solarpunk Airship</title>'),
  'playable entrypoints lost canonical neutral title');
assert(authority.includes('Aureate Wake') && authority.includes('The Unfinished Song'),
  'ship naming reconciliation boundary disappeared');
console.log('Aetherwake documentation authority contract: PASS');
