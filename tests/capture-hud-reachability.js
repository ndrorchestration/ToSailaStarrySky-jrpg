'use strict';
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'evidence/hud-reachability-20261016');
fs.mkdirSync(out, {recursive:true});
(async () => {
  const server = http.createServer((request,response) => {
    const file = path.resolve(root, '.' + decodeURIComponent(request.url.split('?')[0]));
    if (!file.startsWith(root + path.sep)) {response.writeHead(403); response.end(); return;}
    fs.readFile(file,(error,data) => {
      response.writeHead(error ? 404 : 200, {'Content-Type': ({'.js':'application/javascript','.png':'image/png','.css':'text/css'})[path.extname(file)] || 'text/html'});
      response.end(error ? 'missing' : data);
    });
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const browser = await chromium.launch({headless:true,
    ...(process.env.AETHERWAKE_CHROMIUM ? {executablePath:process.env.AETHERWAKE_CHROMIUM}:{}),
    args:['--no-sandbox']});
  try {
    const page = await browser.newPage({viewport:{width:960,height:640}});
    const pageErrors = [];
    page.on('pageerror', error => pageErrors.push(error.message));
    await page.goto('http://127.0.0.1:' + server.address().port + '/index-embedded.html', {waitUntil:'domcontentloaded'});
    await page.waitForFunction(() => document.querySelector('canvas') && window._firstWakeOpeningState);
    await page.evaluate(() => {noLoop(); window.__hudText=[]; const original=window.text;
      window.text=function(value,...args) {window.__hudText.push({value:String(value),args});return original(value,...args);};});
    const probes=[];
    for (const sequence of [5,6,7,8]) {
      const probe = await page.evaluate(sequence => {
        const opening=window.AetherFirstWakeOpening, state=opening.createState();
        while (opening.currentScene(state).sequence < sequence) {
          opening.tickPresentation(state,10000); opening.advance(state);
        }
        opening.tickPresentation(state,180);
        window.__hudProbeState=state; window.__hudText=[];
        window.AetherFirstWakeVisual.draw(opening.currentScene(state),state,{now:3000});
        return {sequence,sceneId:opening.currentScene(state).id,
          controllerVersion:opening.VERSION, controllerKeys:Object.keys(opening),
          stateKeys:Object.keys(state),hasExplorationState:!!state.wakeExploration,
          viewAPI:typeof opening.wakeExplorationView,hotspotAPI:typeof opening.nearbyWakeHotspot,
          renderedText:window.__hudText};
      },sequence);
      probes.push(probe);
    }
    // Settle the actual admitted interior plate and sprite loads before capture.
    await page.waitForTimeout(1200);
    for (const night of [false,true]) {
      await page.evaluate(night => {window._isNight=night;window.__hudText=[];
        const o=window.AetherFirstWakeOpening,s=window.__hudProbeState;
        background(0);window.AetherFirstWakeVisual.draw(o.currentScene(s),s,{now:3000});drawVignette();},night);
      await page.locator('canvas').screenshot({path:path.join(out,night?'core-walk-night.png':'core-walk-day.png')});
    }
    const manifest={sourceSha:'44a63ea03b8874cb427b81f2f62c1763231cde0b',
      capturedAt:new Date().toISOString(),viewport:{width:960,height:640},
      browser:browser.version(),environment:'Linux scratch; RDC devices offline',
      method:'Production index-embedded modules; real controller createState/advance; direct renderer probe at settled tick180. Day/night _isNight vignette flag only, not authored distinct scenes.',
      probes,pageErrors,
      result:'BLOCKED_MISSING_LIVE_HUD_CONTROLLER',
      limitation:'Partial exact-ref materialization includes loaded JS and interior/sprite assets, not every optional asset. No invented objective/feedback or clue state. Cannot establish longest-authored-copy containment.',
      VISUAL_ACCEPTANCE:'PENDING',HUMAN_PLAYER_ACCEPTANCE:'PENDING',PROMOTION:'NOT_AUTHORIZED'};
    fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
    console.log(JSON.stringify(manifest,null,2));
  } finally {await browser.close();await new Promise(resolve=>server.close(resolve));}
})().catch(error=>{console.error(error);process.exitCode=1;});
