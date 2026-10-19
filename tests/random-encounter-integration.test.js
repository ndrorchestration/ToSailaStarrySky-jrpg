'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const full=fs.readFileSync(path.join(__dirname,'../aetherwake.js'),'utf8');
const first=full.indexOf('const randomEncounterReview =');
const last=full.indexOf('\nfunction checkLoreTile(',first);
assert(first>0&&last>first);
const code=full.slice(first,last);
const Encounter=require('../modules/random-encounter-director.js');
function run({enabled,blocked=false,hazard=false,state='crossing',startX=0,startY=0,oscillate=false}){
 let starts=0,checks=0,discovered=0,steps=0,lastEnemy=null;
 const p={tileX:startX,tileY:startY,px:0,py:0};
 const sandbox={window:{location:{search:enabled?'?randomEncounters=1':''},AetherRandomEncounterDirector:Encounter},
   gameOver:false,player:p,gameState:'world',STATE:{WORLD:'world'},
   quest:{state},QUEST_STATES:{CROSSING:'crossing'},pendingHazardIndex:null,
   isWalkableTile:()=>!blocked,
   checkHazardProximity:()=>{checks++;return hazard;},
   checkLoreTile:()=>{discovered++;},
   startCombat:(enemy,returnState)=>{assert(['aetherLeak','windShear'].includes(enemy));assert.equal(returnState,'world');lastEnemy=enemy;starts++;sandbox.gameState='combat';}};
 vm.createContext(sandbox);vm.runInContext(code,sandbox);
 for(let i=0;i<30;i++){vm.runInContext(oscillate && steps%2 ? 'movePlayer(-1,0)' : 'movePlayer(1,0)',sandbox);steps++;if(sandbox.gameState==='combat')break;}
 return {starts,checks,discovered,steps,player:p,lastEnemy};
}
assert.equal(run({enabled:false}).starts,0,'normal play must never enable random battles');
assert.equal(run({enabled:true,blocked:true}).starts,0,'blocked steps must never start encounters');
assert.equal(run({enabled:true,hazard:true}).starts,0,'scripted hazard takes precedence');
assert.equal(run({enabled:true,state:'opening'}).starts,0,'no random battle during story opening');
const reached=run({enabled:true});assert.equal(reached.starts,1,'crossing walking should trigger bounded encounter');
assert(reached.steps>=12 && reached.steps<=26,'encounter must respect pacing bounds');
assert.equal(run({enabled:true,startX:9,startY:23,oscillate:true}).lastEnemy,'windShear',
 'low crossing approach should select wind shear');
assert.equal(run({enabled:true,startX:20,startY:23}).lastEnemy,'aetherLeak',
 'eastern crossing should select aether leak');
console.log('Real movePlayer random-encounter integration, guards and bounds: PASS');