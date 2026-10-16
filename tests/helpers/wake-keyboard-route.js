'use strict';
const assert = require('assert');
async function snapshot(page) {
  return page.evaluate(() => {
    const o=window.AetherFirstWakeOpening,s=window._firstWakeOpeningState;
    return {scene:o.currentScene(s).id,sequence:o.currentScene(s).sequence,
      exploration:s.wakeExploration ? JSON.parse(JSON.stringify(s.wakeExploration)):null,
      party:window.ACTIVE_PARTY.map(c=>c.id),complete:s.complete};
  });
}
async function narrative(page,id) {
  await page.waitForFunction(id => {
    const o=window.AetherFirstWakeOpening,s=window._firstWakeOpeningState;
    return o.currentScene(s).id===id && !s.wakeExploration.active && s.presentationTicks>=40;
  },id,{timeout:10000});
  if(await page.evaluate(()=>!!window.__wakeCanvasText)) {
    const probe=await page.evaluate(()=>({scene:window.AetherFirstWakeOpening.currentScene(window._firstWakeOpeningState),text:[...window.__wakeCanvasText]}));
    for(const line of probe.scene.lines.slice(0,3)) assert(probe.text.includes(line),id+': authored narrative missing on canvas');
    assert(probe.text.includes('ENTER   CONTINUE'),id+': narrative confirmation missing');
  }
  const s=await snapshot(page);
  await page.keyboard.press('ArrowRight');await page.keyboard.press('e');
  assert.deepStrictEqual((await snapshot(page)).exploration,s.exploration,id+': narrative keys changed exploration');
  await page.keyboard.press('Enter');
  assert((await snapshot(page)).exploration.active,id+': confirmation did not enter exploration');
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
async function reachLyra(page) {
  await page.waitForFunction(()=>window.AetherFirstWakeOpening.canAdvancePresentation(window._firstWakeOpeningState),undefined,{timeout:10000});
  for(let i=0;i<5;i++)await page.keyboard.press('Enter');
  await narrative(page,'lyra_family');await visit(page,5,2);await page.keyboard.press('Enter');
  await narrative(page,'lyra_join');
  assert.deepStrictEqual((await snapshot(page)).party,['ender'],'Lyra joined before acknowledgement');
}
async function acknowledgeLyra(page) {
  await visit(page,7,3);await page.keyboard.press('Enter');
  assert.deepStrictEqual((await snapshot(page)).party,['ender','lyra']);
}
async function throughLyra(page) {await reachLyra(page);await acknowledgeLyra(page);}
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
