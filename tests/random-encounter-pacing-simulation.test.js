'use strict';
const assert=require('node:assert/strict');
const {create}=require('../modules/random-encounter-director.js');
let seed=0x12345abc;
function rng(){seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;}
const histogram=Array(27).fill(0);
let total=0,min=Infinity,max=0;
for(let i=0;i<100000;i++){
 const d=create();let steps=0;
 while(!d.onWalk(rng)){steps++;if(steps>26)throw Error('UNBOUNDED_ENCOUNTER');}
 steps++;histogram[steps]++;total+=steps;min=Math.min(min,steps);max=Math.max(max,steps);
}
assert.equal(min,12);assert.equal(max,26);
assert(histogram.slice(0,12).every(x=>x===0));
assert.equal(histogram.reduce((a,b)=>a+b,0),100000);
const summary={samples:100000,min,max,meanSteps:total/100000,medianSteps:(()=>{let n=0;for(let i=0;i<histogram.length;i++){n+=histogram[i];if(n>=50000)return i;}})(),atMax:histogram[26],histogram:Object.fromEntries(histogram.map((n,i)=>[i,n]).filter(([i])=>i>=12))};
console.log('Optional encounter pacing seeded simulation PASS',JSON.stringify(summary));
