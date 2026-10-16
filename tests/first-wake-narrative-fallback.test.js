'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const opening = require('../modules/first-wake-opening.js');
const textCalls = [];
const sandbox = {window:{AetherFirstWakeOpening:opening}, width:960,height:640,
  text(value){textCalls.push(String(value));},textWidth(value){return String(value).length*8;},color:(...args)=>args,
  CENTER:'center',LEFT:'left',TOP:'top',BOTTOM:'bottom',CLOSE:'close'};
for (const name of ['push','pop','noStroke','noFill','stroke','strokeWeight','fill','rect','textAlign','textFont','textSize','ellipse','quad','triangle','beginShape','vertex','endShape','smooth','line']) sandbox[name]=()=>{};
vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../modules/first-wake-visual-stage.js'),'utf8'),sandbox);
for (const sequence of [5,6,7,8]) {
  const state=opening.createState();
  while (opening.currentScene(state).sequence<sequence) {opening.tickPresentation(state,10000);opening.advance(state);}
  opening.tickPresentation(state,180);
  const snapshot=JSON.stringify(state),scene=opening.currentScene(state);
  textCalls.length=0;
  sandbox.window.AetherFirstWakeVisual.draw(scene,state,{now:3000});
  for (const line of scene.lines.slice(0,3)) assert(textCalls.includes(line),scene.id+': authored narrative disappeared without exploration API');
  assert(textCalls.includes('ENTER   CONTINUE'),scene.id+': continuation cue disappeared');
  assert.strictEqual(JSON.stringify(state),snapshot,'presentation fallback must not change controller progression');
}
// A controller that supplies the existing exploration contract retains its HUD path.
// These diagnostic strings are not authored game content or containment evidence.
sandbox.window.AetherFirstWakeOpening={
  wakeExplorationView:()=>({zone:'berth',objective:'Compatibility probe',lastMessage:'Probe feedback'}),
  nearbyWakeHotspot:()=>null,
};
textCalls.length=0;
sandbox.window.AetherFirstWakeVisual.draw({id:'core_walk',sequence:8,lines:[]},
  {wakeExploration:{x:2,y:2,clues:[]}}, {now:3000});
assert(textCalls.includes('COMPATIBILITY PROBE') && textCalls.includes('Probe feedback') && textCalls.includes('CLUES'),
  'available exploration controllers must retain their existing HUD path');
console.log('First Wake authored narrative fallback: PASS');
