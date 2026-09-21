const { chromium } = require('playwright');

const PORT = Number(process.env.AETHERWAKE_CDP_PORT || 9223);
const ENDPOINT = 'http://127.0.0.1:' + PORT;

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function waitForEndpoint() {
  const deadline = Date.now() + 60000;
  let lastError = null;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(ENDPOINT + '/json/version');
      if (response.ok) return;
      lastError = new Error('CDP HTTP ' + response.status);
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
          if (url && url.includes('index-embedded.html')) {
            page = candidate;
            break;
          }
        }
        if (page) break;
      }
      if (!page) await new Promise(resolve => setTimeout(resolve, 250));
    }

    assert(page, 'Packaged NW.js application page not found over CDP');

    await page.waitForFunction(() =>
      typeof window._setupOrder === 'string' &&
      window._setupOrder.includes('setup-done') &&
      !window.__aetherwakeInitFailed &&
      !window.__awLaunchFailure &&
      document.querySelector('canvas') &&
      document.querySelector('canvas').width === 960 &&
      document.querySelector('canvas').height === 640,
      undefined,
      { timeout: 30000 }
    );

    await page.waitForTimeout(1200);

    const result = await page.evaluate(() => {
      const canvas = document.querySelector('canvas');
      const rect = canvas.getBoundingClientRect();
      const ctx = canvas.getContext('2d');
      const image = ctx.getImageData(0, 0, canvas.width, canvas.height).data;

      const colors = new Set();
      let opaque = 0;
      let nonBackground = 0;
      const bg = [26, 16, 46];

      for (let y = 16; y < canvas.height; y += 16) {
        for (let x = 16; x < canvas.width; x += 16) {
          const i = (y * canvas.width + x) * 4;
          const r = image[i], g = image[i + 1], b = image[i + 2], a = image[i + 3];
          colors.add(r + ',' + g + ',' + b + ',' + a);
          if (a > 0) opaque++;
          if (Math.abs(r-bg[0]) + Math.abs(g-bg[1]) + Math.abs(b-bg[2]) > 12) {
            nonBackground++;
          }
        }
      }

      return {
        href: location.href,
        title: document.title,
        setupOrder: window._setupOrder,
        gameState: window.gameState,
        loadingDone: Boolean(window.__awLoadingDone),
        launchFailure: window.__awLaunchFailure || null,
        initFailed: Boolean(window.__aetherwakeInitFailed),
        width: canvas.width,
        height: canvas.height,
        cssWidth: rect.width,
        cssHeight: rect.height,
        uniqueSampleColors: colors.size,
        opaqueSamples: opaque,
        nonBackgroundSamples: nonBackground,
      };
    });

    assert(result.loadingDone, 'Loading screen never completed');
    assert(!result.initFailed, 'Runtime reports initialization failure');
    assert(!result.launchFailure, 'Runtime reports launch failure');
    assert(result.cssWidth > 0 && result.cssHeight > 0, 'Canvas has no visible area');
    assert(result.opaqueSamples > 500, 'Canvas lacks opaque rendered pixels');
    assert(result.uniqueSampleColors >= 8,
      'Canvas is internally uniform/blank: ' + result.uniqueSampleColors + ' colors');
    assert(result.nonBackgroundSamples >= 30,
      'Canvas contains too little content beyond the navy background: ' +
      result.nonBackgroundSamples);

    console.log('AETHERWAKE_PACKAGED_CANVAS_RENDER=PASS');
    console.log(JSON.stringify(result));
  } finally {
    await browser.close();
  }
})().catch(error => {
  console.error(error.stack || error.message);
  process.exit(1);
});
