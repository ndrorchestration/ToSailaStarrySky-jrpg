'use strict';
const assert = require('assert');
async function snapshot(page) {
  return page.evaluate(() => {
    const o=window.AetherFirstWakeOpening,s=window._firstWakeOpeningState;
    return {scene:o.currentScene(s).id,sequence:o.currentScene(s).sequence,
      exploration:s.wakeExploration ? JSON.parse(JSON.stringify(s.wakeExploration)):null,
      party:window.ACTIVE_PARTY.map(c=>c.id),playable:window.ROSTER.map(c=>Boolean(c.playable)),complete:s.complete};
  });
}
async function narrative(page,id) {
  await page.waitForFunction(id => {
    const o=window.AetherFirstWakeOpening,s=window._firstWakeOpeningState;
    return o.currentScene(s).id===id && !s.wakeExploration.active && s.presentationTicks>=40;
  },id,{timeout:10000});
  const observeCanvas=await page.evaluate(()=>!!window.__wakeCanvasText);
  let entered=false;
  for(let budget=0;budget<10;budget++) {
    const view=await page.evaluate(()=>window.AetherFirstWakeOpening.narrativeView(window._firstWakeOpeningState));
    if(observeCanvas) {
      await page.evaluate(()=>{window.__wakePageText=new Set();});
      await page.waitForFunction(({lines,prompt})=>lines.every(line=>window.__wakePageText.has(line))&&window.__wakePageText.has(prompt),
        {lines:view.lines,prompt:view.hasMore?'ENTER   NEXT':'ENTER   CONTINUE'});
      await page.evaluate(({id,lines,hasMore})=>{
        window.__wakeNarrativePages=window.__wakeNarrativePages||[];
        window.__wakeNarrativePages.push({scene:id,lineCount:lines.length,hasMore});
      },{id,lines:view.lines,hasMore:view.hasMore});
    }
    const s=await snapshot(page);
    await page.keyboard.press('ArrowRight');await page.keyboard.press('e');
    assert.deepStrictEqual((await snapshot(page)).exploration,s.exploration,id+': narrative keys changed exploration');
    await page.keyboard.press('Enter');
    const after=await snapshot(page);
    assert.strictEqual(after.scene,id,id+': reading a page changed the scene');
    if(view.hasMore) {assert(!after.exploration.active,id+': exploration began before remaining dialogue');continue;}
    assert(after.exploration.active,id+': final confirmation did not enter exploration');entered=true;break;
  }
  assert(entered,id+': bounded dialogue pages did not reach exploration');
  if (observeCanvas && id === 'lyra_join') {
    // Let the live renderer present its objective before walking away from this scene.
    // The physical-keyboard route can otherwise cross the cue between canvas frames.
    await page.waitForFunction(() => window.__wakeCanvasText.has('FIND LYRA'),
      undefined, { timeout: 10000 });
  }
  if(observeCanvas)assert(await page.evaluate(()=>window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState).lines.every(line=>window.__wakeCanvasText.has(line))),id+': some authored lines never reached the canvas');
  // Attempting to skip the interaction must hold at the same scene.
  await page.keyboard.press('Enter');
  assert.strictEqual((await snapshot(page)).scene,id,id+': interaction gate was bypassed');
}
async function visit(page,x,y) {
  for(let budget=0;budget<30;budget++) {
    const e=(await snapshot(page)).exploration;
    if(e.x===x && e.y===y){await page.keyboard.press('e');return;}
    await page.keyboard.press(e.x!==x ? (e.x<x?'ArrowRight':'ArrowLeft') : (e.y<y?'ArrowDown':'ArrowUp'));
  }
  throw Error('Keyboard route failed to reach '+x+','+y);
}
async function reachLyra(page,{checkMotion=false}={}) {
  await page.waitForFunction(()=>window.AetherFirstWakeOpening.canAdvancePresentation(window._firstWakeOpeningState),undefined,{timeout:10000});
  for(let i=0;i<5;i++)await page.keyboard.press('Enter');
  await narrative(page,'lyra_family');
  if(checkMotion) {
    await page.keyboard.press('ArrowLeft');
    await page.waitForFunction(()=>window.__wakeMotionRecords.some(p=>p.speed>0&&p.facing==='left'));
    await page.waitForFunction(()=>{
      const records=window.__wakeMotionRecords,last=records[records.length-1];
      return !window._firstWakeOpeningState.wakeExploration.moving&&last&&last.speed===0&&last.facing==='left';
    });
    await page.keyboard.press('ArrowUp');
    assert.strictEqual((await snapshot(page)).exploration.facing,'left','vertical input must retain supported lateral facing');
    await page.waitForFunction(()=>{const records=window.__wakeMotionRecords,p=records[records.length-1];return p&&p.speed>0&&p.facing==='left';});
  }
  await visit(page,5,2);await page.keyboard.press('Enter');
  await narrative(page,'lyra_join');
  assert.deepStrictEqual((await snapshot(page)).party,['ender'],'Lyra joined before acknowledgement');
  assert.deepStrictEqual((await snapshot(page)).playable,[true,false,false,false,false],'unjoined companions became playable before acknowledgement');
}
async function acknowledgeLyra(page) {
  await visit(page,7,3);await page.keyboard.press('Enter');
  assert.deepStrictEqual((await snapshot(page)).party,['ender','lyra']);
}
async function throughLyra(page,options) {await reachLyra(page,options);await acknowledgeLyra(page);}
async function throughCore(page) {
  await narrative(page,'ionia_practical');await visit(page,12,2);await page.keyboard.press('Enter');
  await narrative(page,'core_walk');await visit(page,13,5);await page.keyboard.press('Enter');
  assert.strictEqual((await snapshot(page)).scene,'core_walk');
  await visit(page,5,2);await visit(page,5,2);
  assert.deepStrictEqual((await snapshot(page)).exploration.clues,['structural']);
  await visit(page,13,5);assert(!(await snapshot(page)).exploration.coreUnlocked);
  await visit(page,9,6);await page.keyboard.press('Enter');
  assert.strictEqual((await snapshot(page)).scene,'core_walk','unlocking bypassed threshold');
  await visit(page,13,5);await page.keyboard.press('Enter');
  assert.strictEqual((await snapshot(page)).scene,'first_wake_card');
  assert.deepStrictEqual((await snapshot(page)).party,['ender','lyra']);
  await page.keyboard.press('Enter');
  assert((await snapshot(page)).complete);
}
module.exports={snapshot,reachLyra,acknowledgeLyra,throughLyra,throughCore};
