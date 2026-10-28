#!/usr/bin/env node
'use strict';
// Exact pipeline proof: Node planetary tile planner -> versioned JSON fixture
// -> native Godot-only admission validator. No game saves or production exports.
const fs=require('node:fs');
const path=require('node:path');
const handoff=require('../modules/planetary-surface-handoff.js');
const R=6371; // TEST FIXTURE, NOT a canonical world radius
const cases=[
  {id:'coastal-high',observer:{latDeg:25,lonDeg:-82,altitudeKm:2},quality:'high'},
  {id:'antimeridian-high',observer:{latDeg:0,lonDeg:179.9,altitudeKm:10},quality:'high'},
  {id:'north-pole-high',observer:{latDeg:89.7,lonDeg:40,altitudeKm:20},quality:'high'},
  {id:'south-pole-low',observer:{latDeg:-89.7,lonDeg:-140,altitudeKm:100},quality:'low'},
];
function createFixture(){
  return {
    schema:'planetary-surface-admission/v1',
    fixtureOnly:true,
    authority:'NONE',
    cases:cases.map(({id,observer,quality})=>({
      id,quality,
      plan:handoff.planVisibleSurface(observer,R,{maxTiles:64,quality})
    }))
  };
}
if(require.main===module){
  const args=process.argv.slice(2);
  if(args.length!==2||args[0]!=='--out')throw new Error('USAGE: --out output.json');
  const fixture=createFixture();
  const p=path.resolve(args[1]);
  fs.mkdirSync(path.dirname(p),{recursive:true});
  fs.writeFileSync(p,JSON.stringify(fixture,null,2)+'\n');
  console.log('PLANETARY_SURFACE_MANIFEST_WRITTEN cases='+fixture.cases.length+
    ' tiles='+fixture.cases.reduce((n,c)=>n+c.plan.tileCount,0));
}
module.exports={createFixture};
