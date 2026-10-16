'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
// First message is existing candidate copy from PR258 f6798f4. No canon is added.
const messages = [
  'The Core route stays sealed. You need more than one way of seeing the problem.',
  'A short observation.', 'W'.repeat(72), '🧭'.repeat(72), '',
];
let view, calls = [];
const sandbox = {window:{AetherFirstWakeOpening:{
  wakeExplorationView:()=>view, nearbyWakeHotspot:()=>null,
}}, width:960,height:640,
  text(value,x,y){calls.push({value:String(value),x,y});},
  textWidth(value){return String(value).length * 8;},color:(...args)=>args,
  CENTER:'center',LEFT:'left',TOP:'top',BOTTOM:'bottom',CLOSE:'close'};
for (const name of ['push','pop','noStroke','noFill','stroke','strokeWeight','fill','rect','textAlign','textFont','textSize','ellipse','quad','triangle','beginShape','vertex','endShape','smooth','line']) sandbox[name]=()=>{};
vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../modules/first-wake-visual-stage.js'),'utf8'),sandbox);
for (const message of messages) {
  view={zone:'berth',objective:'Existing objective',lastMessage:message}; calls=[];
  sandbox.window.AetherFirstWakeVisual.draw({id:'core_walk',sequence:8,lines:[]},
    {wakeExploration:{x:2,y:2,clues:[]}}, {now:3000});
  const feedback=calls.find(c=>c.y===559);
  assert(feedback,'feedback must be rendered');
  assert(sandbox.textWidth(feedback.value)<=496,'feedback must fit 520px panel with 12px side padding');
  if(message==='A short observation.') assert.strictEqual(feedback.value,message);
  assert(!/[\uD800-\uDBFF]$/.test(feedback.value.replace(/…$/,'')),'ellipsis must not split surrogate pairs');
}
console.log('First Wake feedback measured text bounds: PASS');
