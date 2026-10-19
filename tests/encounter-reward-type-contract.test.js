'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const src=fs.readFileSync(path.join(__dirname,'../aetherwake.js'),'utf8');
const start=src.indexOf('      const enemyXP = Object.freeze(');
const end=src.indexOf("      if (r.outcome === 'success' && action.type === 'attack')",start);
assert(start>0&&end>start);
const block=src.slice(start,end);
function reward(enemy){
 const context={state:{enemy},Object};
 vm.createContext(context);
 return vm.runInContext(block+'xpReward',context);
}
for(const [type,name,expected] of [
 ['windShear','Harmonic Shear Elemental',20],
 ['aetherLeak','Aether Leak Wraith',18],
 ['skyPredator','Sky-Predator',15],
 ['corporateSalvager','Corporate Salvager',12],
 ['engine_spirit','Engine Spirit',14],
 ['child_prophet','Child Prophet',10],
 ['elder_farmer','Elder Farmer',22],
 ['futureNewEnemy','Any New Name',10],
])assert.equal(reward({type,name}),expected,type);
assert.equal(reward({type:'windShear',name:'localized renamed encounter'}),20);
console.log('Encounter XP type binding and display-name independence: PASS');
