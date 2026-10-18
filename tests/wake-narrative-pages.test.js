'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path'),vm=require('vm');
const opening=require('../modules/first-wake-opening.js');
const state=opening.createState({exploration:true});
for(let i=0;i<6;i++)opening.advance(state);
function visit(x,y){while(state.wakeExploration.x!==x)opening.moveWake(state,Math.sign(x-state.wakeExploration.x),0);while(state.wakeExploration.y!==y)opening.moveWake(state,0,Math.sign(y-state.wakeExploration.y));return opening.interactWake(state);}
visit(5,2);opening.advance(state);
const scene=opening.currentScene(state);assert.strictEqual(scene.id,'lyra_join');
assert.strictEqual(scene.lines.length,4);
const calls=[];
const sandbox={window:{AetherFirstWakeOpening:opening},width:960,height:640,CENTER:'center',LEFT:'left',TOP:'top',BOTTOM:'bottom',CLOSE:'close',
  text(value){calls.push(String(value));},textWidth:s=>String(s).length*8,color:(...a)=>a};
for(const name of ['push','pop','fill','rect','noStroke','noFill','stroke','strokeWeight','textAlign','textFont','textSize','ellipse','quad','triangle','beginShape','vertex','endShape','smooth','line'])sandbox[name]=()=>{};
vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../modules/first-wake-visual-stage.js'),'utf8'),sandbox);
function draw(){calls.length=0;const before=JSON.stringify(state);sandbox.window.AetherFirstWakeVisual.draw(scene,state,{now:3000});assert.strictEqual(JSON.stringify(state),before,'rendering must not consume dialogue or change progression');}
draw();for(const line of scene.lines.slice(0,3))assert(calls.includes(line));assert(!calls.includes(scene.lines[3]));
assert(calls.includes('ENTER   NEXT'));
delete state.wakeExploration.narrativeOffset; // Compatibility with a state constructed before pagination.
const clock=state.presentationTicks;
const next=opening.advance(state);
assert.strictEqual(state.wakeExploration.active,false,'confirmation must reveal the remaining authored line before exploration');
assert.strictEqual(next.event.type,'narrative-page');assert.strictEqual(opening.currentScene(state).id,'lyra_join');
assert.strictEqual(state.presentationTicks,clock,'changing dialogue page must preserve the current scene clock');
assert.strictEqual(opening.narrativeView(state).hasMore,false);
draw();assert(calls.includes(scene.lines[3]),'fourth authored line must reach the renderer');assert(!calls.includes(scene.lines[0]));assert(calls.includes('ENTER   CONTINUE'));
assert.deepStrictEqual(state.appliedJoinIds,[],'reading all pages must not recruit Lyra');
opening.advance(state);assert(state.wakeExploration.active);
opening.advance(state);assert.strictEqual(opening.currentScene(state).id,'lyra_join','all pages read must not bypass acknowledgement');
visit(7,3);const join=opening.advance(state);assert.strictEqual(join.event.type,'party-join');assert.strictEqual(join.event.characterId,'lyra');
assert.strictEqual(opening.currentScene(state).id,'ionia_practical');assert.strictEqual(state.wakeExploration.narrativeOffset,0,'new scene must start at its first page');
assert.deepStrictEqual(opening.narrativeView(state).lines,opening.currentScene(state).lines.slice(0,3));
console.log('Wake complete authored narrative pagination: PASS');
