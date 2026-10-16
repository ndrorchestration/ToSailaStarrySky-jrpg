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
      CanvasRenderingContext2D.prototype.fillText=function(value,...args){window.__wakeCanvasText.add(String(value));return original.call(this,value,...args);};});
    await page.goto('http://127.0.0.1:'+server.address().port+'/index-embedded.html',{waitUntil:'domcontentloaded'});
    await page.waitForFunction(()=>document.querySelector('canvas')&&window._firstWakeOpeningState);
    await page.keyboard.press('Enter');
    await throughLyra(page);await throughCore(page);
    const final=await snapshot(page);
    assert.deepStrictEqual(errors,[]);
    const text=await page.evaluate(()=>[...window.__wakeCanvasText]);
    assert(text.includes('ARROWS / WASD   MOVE     E   INSPECT'),'exploration controls missing from actual canvas');
    assert(text.some(t=>t==='FIND LYRA'),'actual exploration objective missing');
    console.log(JSON.stringify({result:'PASS',route:'physical keyboard from New Game through Core and world handoff',source:process.env.AETHERWAKE_SOURCE_SHA||'local candidate',final,pageErrors:errors}));
  } finally {if(browser)await browser.close();await new Promise(resolve=>server.close(resolve));}
})().catch(e=>{console.error(e);process.exitCode=1;});
