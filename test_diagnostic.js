const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext({ viewport: { width: 960, height: 640 } });
  const page = await ctx.newPage();
  
  const errors = [];
  page.on('pageerror', e => errors.push('ERROR: ' + e.name + ': ' + e.message + '\nStack: ' + e.stack));
  page.on('console', msg => { if (msg.type() === 'error') errors.push('CONSOLE ERROR: ' + msg.text()); });
  
  await page.goto('http://127.0.0.1:8080/', { waitUntil: 'networkidle', timeout: 15000 });
  await page.waitForTimeout(12000); // Wait for auto-transition to menu
  
  // Press N to go to world
  await page.keyboard.press('KeyN');
  await page.waitForTimeout(2000);
  
  const ws = await page.evaluate(() => window.gameState);
  console.log('gameState after N:', ws);
  
  if (ws === 'world') {
    // Move toward Old Haru at 7,7 (player at 16,16)
    for (let i = 0; i < 9; i++) await page.keyboard.press('ArrowLeft');
    for (let i = 0; i < 9; i++) await page.keyboard.press('ArrowUp');
    await page.waitForTimeout(500);
    
    // Press E to talk
    await page.keyboard.press('KeyE');
    await page.waitForTimeout(2000);
    
    const ds = await page.evaluate(() => window.gameState);
    console.log('gameState after E:', ds);
    
    if (ds === 'dialogue') {
      const dt = await page.evaluate(() => window.UI.dialogueText);
      console.log('dialogueText:', dt ? dt.substring(0, 100) : 'null');
      const de = await page.evaluate(() => window.UI.dialogueNPC ? window.UI.dialogueNPC.name : 'null');
      console.log('NPC:', de);
    }
  }
  
  // Press C for combat
  await page.keyboard.press('KeyC');
  await page.waitForTimeout(2000);
  
  const cs = await page.evaluate(() => window.gameState);
  console.log('gameState after C:', cs);
  
  await page.screenshot({ path: 'shot_debug.png', fullPage: false });
  
  console.log('\n=== ERRORS ===');
  if (errors.length === 0) console.log('No errors!');
  else errors.slice(0, 5).forEach(e => console.log(e.substring(0, 300)));
  
  await browser.close();
})().catch(e => { console.error('FATAL:', e.message); process.exit(1); });
