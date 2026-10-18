'use strict';
const assert=require('assert'),vm=require('vm'),fs=require('fs'),path=require('path');
const source=fs.readFileSync(path.join(__dirname,'../modules/first-wake-visual-stage.js'),'utf8');
for(const painted of [false,true]) {
  let ink;const brackets=[];
  const sandbox={window:{AetherFirstWakeOpening:{
    wakeExplorationView:()=>({zone:'lyra-space',objective:'Find Lyra.',lastMessage:'Inspect Lyra.'}),
    nearbyWakeHotspot:()=>({x:7,y:3}),
  }},width:960,height:640,CENTER:'center',LEFT:'left',TOP:'top',BOTTOM:'bottom',CLOSE:'close',
  textWidth:s=>String(s).length*8,color:(...a)=>a,
  fill(...a){ink=a;},rect(x,y,w,h){if(w===36&&h===3&&String(ink)==='42,255,181,130')brackets.push({x,y});},
  };
  for(const name of ['push','pop','noStroke','noFill','stroke','strokeWeight','text','textAlign','textFont','textSize','ellipse','quad','triangle','beginShape','vertex','endShape','smooth','noSmooth','line','image','tint','noTint'])sandbox[name]=()=>{};
  if(painted)sandbox.loadImage=(file,ready)=>{ready();return {width:960,height:640};};
  vm.runInNewContext(source,sandbox);
  sandbox.window.AetherFirstWakeVisual.draw({id:'lyra_join',sequence:6,lines:[]},
    {wakeExploration:{active:true,x:7,y:3,clues:[],anomalyTriggered:false}}, {now:3000});
  assert.deepStrictEqual(brackets,[{x:404,y:(painted?420:250)-42}],
    'inspection cue must use the same floor projection as the hotspot ('+(painted?'painted':'procedural')+')');
}
console.log('Wake inspection cue floor projection: PASS');
