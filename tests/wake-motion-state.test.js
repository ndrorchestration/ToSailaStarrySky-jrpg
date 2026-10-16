'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path'),vm=require('vm');
const opening=require('../modules/first-wake-opening.js');
const state=opening.createState({exploration:true});
for(let i=0;i<6;i++)opening.advance(state);
const e=state.wakeExploration;
assert.strictEqual(e.moving,false,'exploration must begin idle');
assert.strictEqual(e.facing,'right');
assert(opening.moveWake(state,-1,0).moved);
assert.strictEqual(e.moving,true,'a successful exploration step must request walk rendering');
assert.strictEqual(e.facing,'left','horizontal movement must update the supported facing');
opening.tickPresentation(state,11);assert(e.moving,'walk pulse must remain active before its deadline');
opening.tickPresentation(state,1);assert.strictEqual(e.moving,false,'idle must resume at the presentation-clock deadline');
assert(!Object.hasOwn(state,'sceneTicks'),'motion must not create a second scene clock');
opening.moveWake(state,0,-1);assert.strictEqual(e.facing,'left','vertical steps retain the existing supported lateral facing');
const draws=[];
const sandbox={window:{AetherFirstWakeOpening:opening,AetherAuthoredCharacterArt:{drawProvisionalFieldCharacter(id,x,y,opts){if(id==='ender')draws.push({kind:'authored',...opts});return false;}},
  AetherCharacterRenderer:{validate:()=>true,draw(id,x,y,opts){if(id==='ender')draws.push({kind:'fallback',...opts});}}},
  width:960,height:640,CENTER:'center',LEFT:'left',TOP:'top',BOTTOM:'bottom',CLOSE:'close',
  textWidth:s=>String(s).length*8,color:(...a)=>a};
for(const name of ['push','pop','fill','noStroke','noFill','stroke','strokeWeight','text','rect','textAlign','textFont','textSize','ellipse','quad','triangle','beginShape','vertex','endShape','smooth','line'])sandbox[name]=()=>{};
vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../modules/first-wake-visual-stage.js'),'utf8'),sandbox);
function draw(){draws.length=0;sandbox.window.AetherFirstWakeVisual.draw(opening.currentScene(state),state,{now:3000});return draws;}
assert(draw().some(d=>d.kind==='authored'&&d.action==='walk'&&d.facing==='left'));
assert(draws.some(d=>d.kind==='fallback'&&d.speed>0&&d.facing==='left'),'existing fallback must receive walking motion');
opening.tickPresentation(state,12);
assert(draw().some(d=>d.kind==='authored'&&d.action==='idle'&&d.facing==='left'));
assert(draws.some(d=>d.kind==='fallback'&&d.speed===0));
opening.moveWake(state,0,-1);opening.tickPresentation(state,6);
opening.moveWake(state,0,-1);opening.tickPresentation(state,6);
assert(e.moving,'a fresh successful step must extend the walk pulse');
opening.tickPresentation(state,6);assert.strictEqual(e.moving,false);
// Boundary and invalid input must preserve the prior pose deadline as well as discovery.
for(let i=0;i<20;i++)opening.moveWake(state,-1,0);
const wall=JSON.stringify(state);opening.moveWake(state,-1,0);opening.moveWake(state,NaN,Infinity);
assert.strictEqual(JSON.stringify(state),wall);
// Reach an actual gate, then make sure its old motion deadline cannot leak into the next scene clock.
while(e.x<5)opening.moveWake(state,1,0);while(e.y>2)opening.moveWake(state,0,-1);
opening.interactWake(state);assert(e.anomalyTriggered);opening.advance(state);
assert.strictEqual(e.active,false);assert.strictEqual(e.moving,false);assert.strictEqual(e.movingUntilTick,0);
opening.advance(state);assert.strictEqual(e.active,true);assert.strictEqual(e.moving,false);
// Valid boundary-state fixture: a diagonal API request may move only vertically.
const edge=opening.createState({exploration:true});for(let i=0;i<6;i++)opening.advance(edge);
edge.wakeExploration.x=14;edge.wakeExploration.facing='left';
assert(opening.moveWake(edge,1,-1).moved);
assert.strictEqual(edge.wakeExploration.facing,'left','clamped horizontal component must not change facing');
console.log('Wake walk/idle state and supported facing: PASS');
