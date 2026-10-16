'use strict';
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const crypto = require('crypto');
const path = require('path');
const opening = require('../modules/first-wake-opening.js');
assert.strictEqual(crypto.createHash('sha256').update(JSON.stringify(opening.SCENES)).digest('hex'),
  'b3b5e1b132932c039e8ce121abc424b1b7ff7c6bccc003262e7679f16c5e2fcb','current authored scene records must remain unchanged');
const source = fs.readFileSync(path.join(__dirname,'../aetherwake.js'),'utf8');
function body(name,next) {
  const start=source.indexOf('function '+name+'('), end=source.indexOf('function '+next+'(',start+1);
  assert(start>=0 && end>start); return source.slice(start,end);
}
const joins=[];
const context={window:{AetherFirstWakeOpening:opening,AetherPartyState:{setActivePartyIds(){},recruitCharacter(id){joins.push(id);}}},
  STATE:Object.fromEntries(['OPENING','WORLD','MENU','BOOT','CHARCREATE','DIALOGUE','AIRSHIP','COMBAT','SHOP'].map(x=>[x,x])),
  gameState:'MENU',prevState:null,menuAutoStartTimer:0,keys:{},keysPressed:{},keyCode:0,key:'',
  ENTER:13,UP_ARROW:38,DOWN_ARROW:40,LEFT_ARROW:37,RIGHT_ARROW:39,millis:()=>1000,C:{},showToast(){}};
vm.createContext(context);
vm.runInContext(body('keyPressed','keyReleased')+body('handleInput','handleWorldInput')+
  body('startFirstWakeOpening','advanceFirstWakeOpening')+body('advanceFirstWakeOpening','drawFirstWakeOpening'),context);
context.startFirstWakeOpening();
const state=context.window._firstWakeOpeningState;
assert(state.wakeExploration,'New Game must enable the recovered exploration contract');
assert.strictEqual(typeof opening.moveWake,'function');
function press(code){context.keyCode=code;context.keyPressed();assert(!context.keysPressed[code],'opening key edge must be consumed');}
function scene(){return opening.currentScene(state).id;}
press(13); assert.strictEqual(state.sceneIndex,0,'arrival must retain presentation hold');
opening.tickPresentation(state,240);
for(let i=0;i<5;i++)press(13);
assert.strictEqual(scene(),'lyra_family');
assert.strictEqual(state.wakeExploration.active,false,'authored narrative must precede exploration');
const before=JSON.stringify(state.wakeExploration); press(39);press(69);
assert.strictEqual(JSON.stringify(state.wakeExploration),before,'narrative phase must not consume exploration actions');
press(13); assert.strictEqual(state.wakeExploration.active,true);
press(13); assert.strictEqual(scene(),'lyra_family','anomaly gate must block confirmation');
function visit(x,y){let budget=30;while(state.wakeExploration.x!==x || state.wakeExploration.y!==y){assert(budget-->0);if(state.wakeExploration.x!==x)press(state.wakeExploration.x<x?39:37);else press(state.wakeExploration.y<y?40:38);}press(69);}
visit(5,2); assert(state.wakeExploration.anomalyTriggered);press(13);
assert.strictEqual(scene(),'lyra_join'); assert.deepStrictEqual(joins,[]);
assert.strictEqual(state.wakeExploration.active,false);
press(13);press(13);assert.strictEqual(scene(),'lyra_join','Lyra acknowledgement gate must hold');
visit(7,3);assert(state.wakeExploration.wrongSongAcknowledged);press(13);
assert.strictEqual(scene(),'ionia_practical');assert.deepStrictEqual(joins,['lyra']);
press(13);press(13);assert.strictEqual(scene(),'ionia_practical','Ionia gate must hold');
visit(12,2);press(13);assert.strictEqual(scene(),'core_walk');
press(13);visit(13,5);assert(!state.wakeExploration.coreEntered);press(13);
assert.strictEqual(scene(),'core_walk','locked Core must block progression');
visit(5,2);visit(5,2);assert.deepStrictEqual(state.wakeExploration.clues,['structural'],'duplicate clue must not unlock');
visit(13,5);assert(!state.wakeExploration.coreUnlocked);
visit(9,6);assert(state.wakeExploration.coreUnlocked);
press(13);assert.strictEqual(scene(),'core_walk','unlocking alone must not enter Core');
visit(13,5);assert(state.wakeExploration.coreEntered);press(13);
assert.strictEqual(scene(),'first_wake_card');press(13);assert(state.complete);
assert.strictEqual(context.gameState,'WORLD','chapter card must hand off through production runtime');
assert.deepStrictEqual(joins,['lyra']);assert.deepStrictEqual(opening.expectedPartyIds(state),['ender','lyra']);
const ended=JSON.stringify(state);opening.moveWake(state,1,0);opening.interactWake(state);opening.advance(state);
assert.strictEqual(JSON.stringify(state),ended,'completed state must not accept exploration mutation');
// Existing default construction remains a narrative-only compatibility mode.
const legacy=opening.createState();assert(!legacy.wakeExploration);
for(let i=0;i<10;i++)opening.advance(legacy);assert(legacy.complete);
const bounded=opening.createState({exploration:true});
for(let i=0;i<6;i++)opening.advance(bounded);
for(let i=0;i<20;i++)opening.moveWake(bounded,1,1);
assert.strictEqual(bounded.wakeExploration.x,14);assert.strictEqual(bounded.wakeExploration.y,7);
const wall=JSON.stringify(bounded);
assert.strictEqual(opening.moveWake(bounded,1,0).moved,false,'clamped movement must not count as a step');
opening.moveWake(bounded,NaN,Infinity);
assert.strictEqual(JSON.stringify(bounded),wall,'wall and invalid movement must not mutate discovery state');
console.log('Wake controller/input integration: PASS');
