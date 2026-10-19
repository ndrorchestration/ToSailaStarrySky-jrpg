'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const code=fs.readFileSync(path.join(__dirname,'../modules/combat-visual-stage.js'),'utf8');
const draws=[];
const sandbox={window:{},globalThis:{},noStroke(){},fill(){},rect(x,y,w,h){draws.push([x,y,w,h]);}};
vm.runInNewContext(code,sandbox);
const scene=sandbox.window.AetherCombatVisual;
function measure(type,now){
 draws.length=0;
 assert.equal(scene.drawEnemy({x:500,y:300,now,enemy:{type,hp:8,maxHp:8}}),true);
 const x0=Math.min(...draws.map(v=>v[0]));
 const y0=Math.min(...draws.map(v=>v[1]));
 const x1=Math.max(...draws.map(v=>v[0]+v[2]));
 const y1=Math.max(...draws.map(v=>v[1]+v[3]));
 return {bounds:[x0,y0,x1,y1],shapes:draws.length,draws:JSON.stringify(draws)};
}
for(const type of ['aetherLeak','windShear']){
 const a=measure(type,0),b=measure(type,600);
 assert(a.bounds[2]-a.bounds[0]>=90,'enemy needs gameplay-readable battle width');
 assert(a.bounds[3]-a.bounds[1]>=90,'enemy needs gameplay-readable battle height');
 assert(a.shapes>=12,'enemy needs body/head/details beyond a plain rectangle');
 assert.notEqual(a.draws,b.draws,'idle frames need visible motion');
}
assert.notEqual(measure('aetherLeak',0).draws,measure('windShear',0).draws,
 'different enemy types must have different stage silhouettes');
console.log('Wraith + Wind Shear pixel silhouette scale/motion distinctness: PASS');
