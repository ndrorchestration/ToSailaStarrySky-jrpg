const {chromium}=require('playwright');
const path=require('path');
(async()=>{
 const browser=await chromium.launch({headless:true});
 const page=await browser.newPage({viewport:{width:1200,height:860}});
 await page.goto('file:///'+path.resolve(__dirname,'../tests/ender-ionia-walk-review.html').replace(/\\/g,'/'));
 await page.waitForFunction(()=>document.querySelector('#state') && imgIonia.complete && imgEnder.complete);
 const baseline=await page.evaluate(()=>({e:imgEnder.naturalWidth,i:imgIonia.naturalWidth,v:loadedVariant}));
 if(baseline.e!==384 || baseline.i!==384 || baseline.v!=='nearest')throw Error('initial load failed '+JSON.stringify(baseline));
 await page.selectOption('#variant','lanczos');
 await page.waitForFunction(()=>loadedVariant==='lanczos'&&imgEnder.complete&&imgEnder.naturalWidth===384);
 await page.selectOption('#variant','bicubic');
 await page.waitForFunction(()=>loadedVariant==='bicubic'&&imgEnder.complete&&imgEnder.naturalWidth===384);
 await page.screenshot({path:path.resolve(__dirname,'../art-staging/field/ender/review-alt/ender-ionia-walk-review-page.png')});
 await browser.close();
 console.log('END-IONIA SIDE-BY-SIDE REVIEW=PASS',baseline);
})().catch(e=>{console.error(e);process.exit(1)});
