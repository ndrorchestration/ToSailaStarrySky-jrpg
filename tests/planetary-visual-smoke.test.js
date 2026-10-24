'use strict';
/*
 * Browser-rendered, isolated world-map prototype checks. No game save state,
 * shipping artifact, visual sign-off or canonical geography is implied.
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const {chromium} = require('playwright');
const ROOT = path.resolve(__dirname, '..');

function serve() {
  return http.createServer((req,res)=>{
    let requestPath;
    try { requestPath = decodeURIComponent(new URL(req.url,'http://localhost').pathname); }
    catch { res.writeHead(400);res.end();return; }
    const full = path.resolve(ROOT, '.'+requestPath);
    if (!full.startsWith(ROOT+path.sep)) {res.writeHead(403);res.end();return;}
    fs.readFile(full,(err,bytes)=>{
      if(err){res.writeHead(404);res.end();return;}
      res.writeHead(200,{'Content-Type':full.endsWith('.js')?'application/javascript; charset=utf-8':'text/html; charset=utf-8'});
      res.end(bytes);
    });
  });
}
async function painted(page,id) {
  return page.evaluate(id=>{
    const canvas=document.getElementById(id),ctx=canvas.getContext('2d');
    const {data}=ctx.getImageData(0,0,canvas.width,canvas.height);
    let visible=0;const colors=new Set();
    for(let i=0;i<data.length;i+=4*113) {
      if(data[i+3]<48)continue;
      visible++;
      colors.add([data[i]>>4,data[i+1]>>4,data[i+2]>>4].join(':'));
    }
    return{visible,colors:colors.size};
  },id);
}
async function one(browser,base,name,width) {
  const page=await browser.newPage({viewport:{width,height:830}});
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
  try {
    const url=base+'/docs/prototypes/'+name+'.html';
    const response=await page.goto(url,{waitUntil:'domcontentloaded',timeout:20000});
    assert.ok(response?.ok(),url+' did not load');
    assert.ok((await page.title()).startsWith('To Sail the Starry Sky'));
    await page.waitForFunction(()=> {
      const el=document.querySelector('#horizonKm,#biome');
      return el && el.textContent && el.textContent.trim()!=='—';
    },{timeout:20000});
    const canvasId=name==='planetary-globe'?'globe':'pilot';
    const draw=await painted(page,canvasId);
    assert.ok(draw.visible>100 && draw.colors>8,
      name+' must render varied geographical imagery, not blank technical wireframe: '+JSON.stringify(draw));
    const overflow=await page.evaluate(()=>document.documentElement.scrollWidth-innerWidth);
    assert.ok(overflow<=2,name+' horizontally overflows at '+width+'px by '+overflow+'px');
    if(name==='planetary-globe'){
      const initial=Number((await page.locator('#horizonKm').textContent()).replace(/[^0-9]/g,''));
      await page.locator('button[data-alt="200"]').click();
      await page.waitForFunction((start)=>
        Number(document.querySelector('#horizonKm').textContent.replace(/[^0-9]/g,''))>start*2
      ,initial,{timeout:10000});
      const after=Number((await page.locator('#horizonKm').textContent()).replace(/[^0-9]/g,''));
      assert.ok(after>initial*2,'altitude must widen geometric horizon');
      assert.ok((await page.locator('.key').textContent()).includes('Coastal shelf'));
    }else{
      await page.locator('button[data-lat="89.7"]').click();
      await page.waitForFunction(()=>document.querySelector('#latitude').textContent.includes('89.70'),{timeout:10000});
      await page.locator('button[data-alt-only="200"]').click();
      await page.waitForFunction(()=>document.querySelector('#height').textContent.includes('200.0'),{timeout:10000});
      assert.ok((await page.locator('#biome').textContent()).length>2);
      assert.ok((await page.locator('.key').textContent()).includes('Forest'));
    }
    assert.deepEqual(errors,[],name+' generated browser console/page errors');
    return {name,width,visible:draw.visible,colors:draw.colors};
  } finally {await page.close();}
}
(async()=>{
  const server=serve();
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  let browser;
  try {
    browser=await chromium.launch({headless:true});
    const base='http://127.0.0.1:'+server.address().port;
    const proofs=[];
    for(const width of [1280,320]) {
      proofs.push(await one(browser,base,'planetary-globe',width));
      proofs.push(await one(browser,base,'planetary-flight',width));
    }
    console.log('PLANETARY_VISUAL_BROWSER_SMOKE=PASS '+JSON.stringify(proofs));
  }finally{
    if(browser)await browser.close();
    await new Promise(resolve=>server.close(resolve));
  }
})().catch(err=>{console.error(err);process.exitCode=1;});
