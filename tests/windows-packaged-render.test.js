const { chromium } = require('playwright');

const PORT = Number(process.env.AETHERWAKE_CDP_PORT || 9223);
const ENDPOINT = 'http://127.0.0.1:' + PORT;

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function waitForEndpoint() {
  const deadline = Date.now() + 45000;
  let lastError = null;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(ENDPOINT + '/json/version');
      if (response.ok) return;
      lastError = new Error('CDP returned HTTP ' + response.status);
    } catch (error) {
      lastError = error;
    }
    await new Promise(resolve => setTimeout(resolve, 500));
  }
  throw new Error('NW.js CDP endpoint did not become ready: ' +
    (lastError ? lastError.message : 'unknown error'));
}

(async () => {
  await waitForEndpoint();
  const browser = await chromium.connectOverCDP(ENDPOINT);
  try {
    const deadline = Date.now() + 30000;
    let page = null;
    while (Date.now() < deadline && !page) {
      for (const context of browser.contexts()) {
        for (const candidate of context.pages()) {
          const url = candidate.url();
          if (url && !url.startsWith('devtools://')) {
            page = candidate;
            break;
          }
        }
        if (page) break;
      }
      if (!page) await new Promise(resolve => setTimeout(resolve, 250));
    }
    assert(page, 'No packaged NW.js application page was exposed over CDP');

    await page.waitForFunction(() =>
      typeof window._setupOrder === 'string' &&
      window._setupOrder.includes('setup-done') &&
      !window.__aetherwakeInitFailed &&
      !window.__awLaunchFailure &&
      document.querySelector('canvas') &&
      document.querySelector('canvas').width === 960 &&
      document.querySelector('canvas').height === 640
    , undefined, { timeout: 30000 });

    await page.waitForTimeout(1000);

    const result = await page.evaluate(() => {
      const canvas = document.querySelector('canvas');
      const rect = canvas.getBoundingClientRect();
      const ctx = canvas.getContext('2d');
      const pixels = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
      const colors = new Set();
      let opaqueSamples = 0;

      for (let y = 16; y < canvas.height; y += 32) {
        for (let x = 16; x < canvas.width; x += 32) {
          const i = (y * canvas.width + x) * 4;
          const r = pixels[i];
          const g = pixels[i + 1];
          const b = pixels[i + 2];
          const a = pixels[i + 3];
          if (a > 0) opaqueSamples++;
          colors.add(r + ',' + g + ',' + b + ',' + a);
        }
      }

      return {
        url: location.href,
        title: document.title,
        setupOrder: window._setupOrder,
        gameState: window.gameState,
        loadingDone: Boolean(window.__awLoadingDone),
        initFailed: Boolean(window.__aetherwakeInitFailed),
        launchFailure: window.__awLaunchFailure || null,
        canvasWidth: canvas.width,
        canvasHeight: canvas.height,
        cssWidth: rect.width,
        cssHeight: rect.height,
        uniqueSampleColors: colors.size,
        opaqueSamples,
      };
    });

    assert(result.loadingDone === true,
      'Packaged loading overlay never completed');
    assert(result.initFailed === false,
      'Packaged runtime reported initialization failure');
    assert(result.launchFailure === null,
      'Packaged launch wrapper reported a failure');
    assert(result.cssWidth > 0 && result.cssHeight > 0,
      'Packaged canvas has no visible CSS area');
    assert(result.opaqueSamples > 100,
      'Packaged canvas did not contain enough opaque rendered samples');
    assert(result.uniqueSampleColors >= 4,
      'Packaged canvas is visually uniform/blank: only ' +
      result.uniqueSampleColors + ' sampled colors');

    console.log('Aetherwake packaged render PASS:', JSON.stringify(result));
  } finally {
    await browser.close();
  }
})().catch(error => {
  console.error(error.stack || error.message);
  process.exit(1);
});
