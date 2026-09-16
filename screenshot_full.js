const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext({ viewport: { width: 960, height: 640 } });
  const page = await ctx.newPage();
  
  const errors = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('pageerror', e => errors.push('PAGE ERROR: ' + e.message));
  
  await page.goto('http://127.0.0.1:8080/', { waitUntil: 'networkidle', timeout: 15000 });
  
  // 1. BOOT (wait for auto-transition to menu)
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'sc_boot.png', fullPage: false });
  let gs = await page.evaluate(() => window.gameState);
  console.log('BOOT→ 대기 후 state:', gs);
  
  // If still boot after 3s, wait more for auto-transition
  if (gs === 'boot') {
    await page.waitForTimeout(8000);
    gs = await page.evaluate(() => window.gameState);
    console.log('BOOT→ 8초 후 state:', gs);
  }
  
  // 2. MENU screenshot
  await page.screenshot({ path: 'sc_menu.png', fullPage: false });
  const mp = await page.evaluate(() => window._world ? window._world.player : null);
  console.log('MENU player:', mp ? `px=${mp.px} py=${mp.py}` : 'none');
  
  // 3. WORLD — press N
  if (gs === 'menu' || gs === 'boot') {
    await page.keyboard.press('KeyN');
    await page.waitForTimeout(1500);
  }
  gs = await page.evaluate(() => window.gameState);
  console.log('WORLD state:', gs);
  await page.screenshot({ path: 'sc_world.png', fullPage: false });
  const wp = await page.evaluate(() => window._world ? window._world.player : null);
  console.log('WORLD player:', wp ? `px=${wp.px} py=${wp.py} tx=${wp.tileX} ty=${wp.tileY}` : 'none');
  
  // 4. Move toward Old Haru (tile 7,7) and open dialogue
  if (gs === 'world') {
    // Move left and up toward tile 7,7 from 16,16
    for (let i = 0; i < 9; i++) { await page.keyboard.press('ArrowLeft'); await page.waitForTimeout(80); }
    for (let i = 0; i < 9; i++) { await page.keyboard.press('ArrowUp'); await page.waitForTimeout(80); }
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'sc_world_nav.png', fullPage: false });
    
    // Press E to talk
    await page.keyboard.press('KeyE');
    await page.waitForTimeout(1500);
    gs = await page.evaluate(() => window.gameState);
    console.log('DIALOGUE state:', gs);
    await page.screenshot({ path: 'sc_dialogue.png', fullPage: false });
    
    const dt = await page.evaluate(() => window.UI.dialogueText);
    const dn = await page.evaluate(() => window.UI.dialogueNPC ? window.UI.dialogueNPC.name : 'none');
    console.log('Dialogue NPC:', dn, '| Text:', dt ? dt.substring(0,80) : 'none');
    
    // Advance dialogue a couple lines
    for (let i = 0; i < 2; i++) {
      await page.keyboard.press('KeyE');
      await page.waitForTimeout(800);
    }
    await page.screenshot({ path: 'sc_dialogue_adv.png', fullPage: false });
  }
  
  // 5. COMBAT — press C
  if (gs === 'dialogue') {
    // Close dialogue first
    await page.keyboard.press('KeyE');
    await page.waitForTimeout(500);
  }
  await page.keyboard.press('KeyC');
  await page.waitForTimeout(2000);
  gs = await page.evaluate(() => window.gameState);
  console.log('COMBAT state:', gs);
  await page.screenshot({ path: 'sc_combat.png', fullPage: false });
  
  // Combat panel verification
  if (gs === 'combat') {
    const cs = await page.evaluate(() => {
      const c = window._combat;
      if (!c || !c.getState) return null;
      const s = c.getState();
      return {
        turn: s.turn,
        enemy: s.enemy ? s.enemy.name : 'none',
        playerVit: s.player.vit,
        playerLevel: s.player.level,
        playerXp: s.player.xp,
        hasNewEnemy: s.enemy && (s.enemy.name.includes('Wind') || s.enemy.name.includes('Aether')),
      };
    });
    console.log('Combat state:', JSON.stringify(cs));
  }
  
  console.log('\n=== ERRORS (' + errors.length + ') ===');
  if (errors.length === 0) console.log('NONE — clean!');
  else errors.slice(0,8).forEach(e => console.log('  ' + e.substring(0, 200)));
  
  await browser.close();
  console.log('\n=== SCREENSHOTS ===');
  const fs = require('fs');
  ['sc_boot.png','sc_menu.png','sc_world.png','sc_world_nav.png','sc_dialogue.png','sc_dialogue_adv.png','sc_combat.png']
    .forEach(f => { try { const s = fs.statSync(f); console.log('  ' + f + ' (' + s.size + ' bytes)'); } catch(e) {} });
})().catch(e => { console.error('FATAL:', e.message); process.exit(1); });
