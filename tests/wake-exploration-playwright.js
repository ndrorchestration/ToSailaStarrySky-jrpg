'use strict';
const assert=require('assert');
const {chromium}=require('playwright');
const http=require('http'),fs=require('fs'),path=require('path');
const {throughLyra,throughCore,snapshot}=require('./helpers/wake-keyboard-route');
const root=path.resolve(__dirname,'..');
(async()=>{
  const server=http.createServer((req,res)=>{
    const file=path.resolve(root,'.'+decodeURIComponent(req.url.split('?')[0]));
    if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
    fs.readFile(file,(err,data)=>{res.writeHead(err?404:200,{'Content-Type':({'.js':'application/javascript','.png':'image/png','.css':'text/css'})[path.extname(file)]||'text/html'});res.end(err?'missing':data);});
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  let browser;
  try {
    browser=await chromium.launch({headless:true,...(process.env.AETHERWAKE_CHROMIUM?{executablePath:process.env.AETHERWAKE_CHROMIUM}:{}),args:['--no-sandbox']});
    const page=await browser.newPage({viewport:{width:960,height:640}}),errors=[];
    page.on('pageerror',e=>errors.push(e.message));
    await page.addInitScript(()=>{window.__wakeCanvasText=new Set();const original=CanvasRenderingContext2D.prototype.fillText;
      CanvasRenderingContext2D.prototype.fillText=function(value,...args){window.__wakeCanvasText.add(String(value));if(window.__wakePageText)window.__wakePageText.add(String(value));return original.call(this,value,...args);};});
    await page.goto('http://127.0.0.1:'+server.address().port+'/index-embedded.html',{waitUntil:'domcontentloaded'});
    await page.waitForFunction(()=>document.querySelector('canvas')&&window._firstWakeOpeningState);
    await page.evaluate(()=>{
      const original=window.AetherCharacterRenderer;
      window.__wakeMotionRecords=[];
      window.AetherCharacterRenderer={...original,draw(id,x,y,opts){
        const state=window._firstWakeOpeningState;
        if(id==='ender'&&state.wakeExploration&&state.wakeExploration.active){
          window.__wakeMotionRecords.push({speed:opts.speed,facing:opts.facing});
          if(window.__wakeMotionRecords.length>600)window.__wakeMotionRecords.shift();
        }
        return original.draw(id,x,y,opts);
      }};
    });
    await page.keyboard.press('Enter');
    const runs=[];
    for(let replay=0;replay<2;replay++) {
      if(replay===1) {
        const reset=await page.evaluate(()=>{
          const previous=window._firstWakeOpeningState,roster=window.ROSTER,members=window.ROSTER.slice(),active=window.ACTIVE_PARTY;
          // Invoke the production New Game entrypoint; do not assign game/scene state.
          window.startGame();
          const state=window._firstWakeOpeningState,e=state.wakeExploration;
          window.__wakeMotionRecords=[];window.__wakeCanvasText.clear();window.__wakePageText=new Set();window.__wakeNarrativePages=[];
          return {freshOpening:state!==previous&&state.sceneIndex===0&&!state.complete&&state.appliedJoinIds.length===0,
            freshExploration:!e.active&&!e.moving&&e.narrativeOffset===0&&e.clues.length===0&&!e.anomalyTriggered&&!e.wrongSongAcknowledged&&!e.ioniaFound&&!e.coreUnlocked&&!e.coreEntered&&e.steps===0&&e.x===3&&e.y===5,
            canonicalReferences:roster===window.ROSTER&&active===window.ACTIVE_PARTY&&members.every((c,i)=>c===window.ROSTER[i]),
            playable:window.ROSTER.map(c=>Boolean(c.playable)),party:window.ACTIVE_PARTY.map(c=>c.id)};
        });
        assert(reset.freshOpening&&reset.freshExploration&&reset.canonicalReferences,'replay failed to reset opening state while retaining canonical references');
        assert.deepStrictEqual(reset.playable,[true,false,false,false,false]);assert.deepStrictEqual(reset.party,['ender']);
      }
    await throughLyra(page,{checkMotion:true});await throughCore(page);
    const final=await snapshot(page);
    assert.deepStrictEqual(errors,[]);
    const text=await page.evaluate(()=>[...window.__wakeCanvasText]);
    assert(text.includes('ARROWS / WASD   MOVE     E   INSPECT'),'exploration controls missing from actual canvas');
    assert(text.some(t=>t==='FIND LYRA'),'actual exploration objective missing');
    const motion=await page.evaluate(()=>({walking:window.__wakeMotionRecords.some(p=>p.speed>0),idle:window.__wakeMotionRecords.some(p=>p.speed===0),left:window.__wakeMotionRecords.some(p=>p.facing==='left')}));
    assert(motion.walking&&motion.idle&&motion.left,'existing rendered fallback must receive walk, settled idle and left-facing states');
    const narrativePages=await page.evaluate(()=>window.__wakeNarrativePages);
    assert.deepStrictEqual(narrativePages.filter(p=>p.scene==='lyra_join').map(p=>p.lineCount),[3,1],'all four Lyra scene lines must reach separate canvas pages');
    assert.deepStrictEqual(final.playable,[true,true,false,false,false]);
    runs.push({run:replay+1,motion,narrativePages,final});
    }
    console.log(JSON.stringify({result:'PASS',route:'two physical-keyboard opening routes; replay triggered by production startGame call',source:process.env.AETHERWAKE_SOURCE_SHA||'local candidate',runs,pageErrors:errors}));
  } finally {if(browser)await browser.close();await new Promise(resolve=>server.close(resolve));}
})().catch(e=>{console.error(e);process.exitCode=1;});
