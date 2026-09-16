const { chromium } = require('playwright');
const path = require('path');
const http = require('http');
const fs = require('fs');
const { URL } = require('url');

(async () => {
  const server = http.createServer((req, res) => {
    const parsed = new URL(req.url, 'http://127.0.0.1:' + PORT);
    let filePath = parsed.pathname;
    if (filePath === '/') filePath = '/index.html';
    filePath = filePath.replace(/^\//, '');
    const fullPath = path.resolve(BASE, filePath);
    if (!fullPath.startsWith(BASE)) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }
    fs.readFile(fullPath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      const ext = path.extname(fullPath);
      const mime = {
        '.html': 'text/html',
        '.js': 'application/javascript',
        '.css': 'text/css',
        '.ttf': 'font/ttf',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
      }[ext] || 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': mime });
      res.end(data);
    });
  });

  const PORT = 8090;
  const BASE = __dirname;
  await new Promise(resolve => server.listen(PORT, '127.0.0.1', resolve));
  console.log('HTTP server on http://127.0.0.1:' + PORT);

  const b = await chromium.launch({ headless: true });
  const ctx = await b.newContext({
    viewport: { width: 960, height: 640 },
    javaScriptEnabled: true,
  });
  const p = await ctx.newPage();

  const errors = [];
  p.on('pageerror', e => errors.push('PAGE ERROR: ' + e.message));

  const url = 'http://127.0.0.1:' + PORT + '/index.html';
  console.log('Loading:', url);
  const resp = await p.goto(url, { waitUntil: 'domcontentloaded', timeout: 15000 });
  console.log('HTTP status:', resp ? resp.status() : 'no response');

  // Wait for the full boot sequence to complete (1200ms load + 9000ms preamble + title reveal)
  // Then wait a bit more for the title to be fully visible
  console.log('Waiting for boot sequence (12s+)...');
  await p.waitForTimeout(12500);

  // Check state
  const state = await p.evaluate(() => ({
    gameState: window.gameState,
    isBoot: window.gameState === 'boot',
    isMenu: window.gameState === 'menu',
    titleVisible: window.titleVisible,
    elapsed: window.bootTime ? Math.floor((Date.now() - window.bootTime)) : 0,
    bootTime: window.bootTime,
    canvasPresent: !!document.querySelector('canvas'),
    canvasSize: document.querySelector('canvas') ? [
      document.querySelector('canvas').width,
      document.querySelector('canvas').height
    ] : [0, 0],
  }));
  console.log('State after boot:', JSON.stringify(state));

  // Full pixel analysis
  const pixels = await p.evaluate(() => {
    const c = document.querySelector('canvas');
    if (!c) return { teal: 0, navy: 0, soil: 0, parchment: 0, scioto: 0, rust: 0 };
    const ctx = c.getContext('2d');
    const d = ctx.getImageData(0, 0, c.width, c.height).data;
    let teal = 0, navy = 0, soil = 0, parchment = 0, scioto = 0, rust = 0;
    for (let i = 0; i < d.length; i += 4) {
      const r = d[i], g = d[i+1], b = d[i+2];
      if (g > 150 && b > 100 && r < 100 && g > r) teal++;
      else if (r < 40 && g < 30 && b < 60) navy++;
      else if (r > 80 && g > 60 && b < 80 && r > g && r < 160) soil++;
      else if (r > 180 && g > 180 && b > 150 && r > b) parchment++;
      else if (r > 80 && g > 150 && b > 180 && b > r) scioto++;
      else if (r > 120 && g < 100 && b < 60) rust++;
    }
    return { teal, navy, soil, parchment, scioto, rust };
  });
  console.log('Pixels:', JSON.stringify(pixels));

  // Sample specific areas: title text region, island region
  const regions = await p.evaluate(() => {
    const c = document.querySelector('canvas');
    if (!c) return {};
    const ctx = c.getContext('2d');
    
    // Title center: (480, 270) — where "AETHERWAKE" would be
    const titleRegion = ctx.getImageData(380, 200, 200, 120).data;
    let titleTeal = 0, titleNavy = 0;
    for (let i = 0; i < titleRegion.length; i += 4) {
      const r = titleRegion[i], g = titleRegion[i+1], b = titleRegion[i+2];
      if (g > 150 && b > 100 && r < 100) titleTeal++;
      else if (r < 40 && g < 30 && b < 60) titleNavy++;
    }
    
    // Island region: upper area (400, 100) — where parallax islands float
    const islandRegion = ctx.getImageData(200, 50, 300, 120).data;
    let islandSoil = 0, islandTeal = 0, islandNavy = 0;
    for (let i = 0; i < islandRegion.length; i += 4) {
      const r = islandRegion[i], g = islandRegion[i+1], b = islandRegion[i+2];
      if (r > 80 && g > 60 && b < 80 && r > g) islandSoil++;
      else if (g > 150 && b > 100 && r < 100) islandTeal++;
      else if (r < 40 && g < 30 && b < 60) islandNavy++;
    }
    
    return { titleTeal, titleNavy, islandSoil, islandTeal, islandNavy };
  });
  console.log('Regions:', JSON.stringify(regions));

  // Take screenshot
  const shotPath = path.join(__dirname, 'screenshot_boot.png');
  await p.screenshot({ path: shotPath, fullPage: false });
  console.log('Screenshot:', shotPath);

  await b.close();
  server.close();

  console.log('\n=== Verdict ===');
  const canvasOk = state.canvasPresent && state.canvasSize[0] === 960 && state.canvasSize[1] === 640;
  const stateActive = state.isBoot || state.isMenu;
  const visibleContent = pixels.teal > 500 || pixels.parchment > 100 || regions.titleTeal > 100;
  const islandsVisible = regions.islandSoil > 20 || regions.islandTeal > 50;
  
  console.log('  Canvas 960×640:', canvasOk ? 'YES' : 'NO');
  console.log('  State active (boot/menu):', stateActive ? 'YES' : 'NO');
  console.log('  Visible content (teal/parchment):', visibleContent ? 'YES' : 'NO');
  console.log('  Islands visible in sky:', islandsVisible ? 'YES' : 'NO');
  console.log('  Title area teal pixels:', regions.titleTeal);
  console.log('  Errors:', errors.length ? errors.join('; ') : 'NONE');
  console.log('  OVERALL:', (canvasOk && stateActive && visibleContent && islandsVisible && errors.length === 0) ? 'PASS' : 'FAIL');
})();
