'use strict';

const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const BASE = path.resolve(__dirname, '..');
const PORT = Number(process.env.AETHERWAKE_ACCESSIBILITY_MATRIX_PORT || 8095);
const OUTPUT = path.resolve(
  process.env.AETHERWAKE_ACCESSIBILITY_MATRIX_DIR ||
  path.join(BASE, 'artifacts', 'accessibility-visual-matrix')
);

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function createServer() {
  return http.createServer((req, res) => {
    const parsed = new URL(req.url, `http://127.0.0.1:${PORT}`);
    let requested = decodeURIComponent(parsed.pathname);
    if (requested === '/') requested = '/index-embedded.html';

    const relative = requested.replace(/^\/+/, '');
    const fullPath = path.resolve(BASE, relative);
    if (!fullPath.startsWith(BASE + path.sep) && fullPath !== BASE) {
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
      const mime = {
        '.html': 'text/html; charset=utf-8',
        '.js': 'application/javascript; charset=utf-8',
        '.css': 'text/css; charset=utf-8',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.mp3': 'audio/mpeg',
        '.svg': 'image/svg+xml',
      }[path.extname(fullPath).toLowerCase()] || 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': mime });
      res.end(data);
    });
  });
}

async function applySettings(page, patch) {
  await page.evaluate(nextPatch => {
    const next = window.AetherUserSettings.update(window._userSettings, nextPatch);
    if (typeof persistUserSettings !== 'function') {
      throw new Error('persistUserSettings unavailable');
    }
    if (!persistUserSettings(next)) {
      throw new Error('persistUserSettings failed');
    }
  }, patch);
  await page.waitForTimeout(80);
}

async function prepareSurface(page, surface) {
  await page.evaluate(name => {
    function setState(next) {
      gameState = next;
      window.gameState = gameState;
      prevState = null;
    }

    if (typeof closeWorldDialogue === 'function') closeWorldDialogue();
    if (window.UI) {
      window.UI.dialogueOpen = false;
      window.UI.dialogueNPC = null;
      window.UI.dialogueText = '';
      window.UI.openness = 255;
      window.UI.opening = false;
    }

    switch (name) {
      case 'title':
        setState(STATE.MENU);
        titleVisible = 1;
        menuAutoStartTimer = millis();
        break;
      case 'settings':
        setState(STATE.MENU);
        openUserSettingsMenu();
        break;
      case 'controls':
        setState(STATE.MENU);
        openUserSettingsMenu();
        openControlsMenu();
        break;
      case 'world':
        setState(STATE.WORLD);
        quest.state = QUEST_STATES.SIGNAL;
        quest.act = 'signal';
        break;
      case 'choice':
        setState(STATE.WORLD);
        quest.state = QUEST_STATES.CHOICE;
        quest.act = 'choice';
        quest.choiceMade = null;
        quest._choiceHover = 1;
        break;
      case 'questlog':
        setState(STATE.WORLD);
        openState(STATE.QUESTLOG);
        window.UI.openness = 255;
        break;
      case 'charsheet':
        setState(STATE.WORLD);
        openState(STATE.CHARSHEET);
        window.UI.openness = 255;
        break;
      case 'saveload':
        setState(STATE.WORLD);
        openSaveLoadMenu('save');
        break;
      case 'airship':
        setState(STATE.WORLD);
        enterAirNavigation();
        break;
      case 'combat':
        setState(STATE.WORLD);
        startCombat('skyPredator');
        break;
      case 'dialogue': {
        setState(STATE.WORLD);
        const p = window._world.player;
        p.tileX = 7; p.tileY = 7; p.x = 7; p.y = 7;
        p.px = 7 * 16; p.py = 7 * 16;
        window.interactionKey = 'e';
        window._world.interact();
        window.interactionKey = null;
        if (window.UI) window.UI.openness = 255;
        break;
      }
      default:
        throw new Error('UNKNOWN_VISUAL_MATRIX_SURFACE:' + name);
    }
  }, surface);
  await page.waitForTimeout(120);
}

async function capture(page, fileName) {
  const target = path.join(OUTPUT, fileName);
  await page.screenshot({ path: target, fullPage: false });
  return target;
}

(async () => {
  fs.mkdirSync(OUTPUT, { recursive: true });

  const server = createServer();
  await new Promise(resolve => server.listen(PORT, '127.0.0.1', resolve));

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 960, height: 640 } });
  const errors = [];
  const captures = [];

  page.on('pageerror', err => errors.push(`PAGE: ${err.message}`));
  page.on('console', msg => {
    if (msg.type() === 'error' && !msg.text().includes('Failed to load resource')) {
      errors.push(`CONSOLE: ${msg.text()}`);
    }
  });

  try {
    const response = await page.goto(
      `http://127.0.0.1:${PORT}/index-embedded.html`,
      { waitUntil: 'domcontentloaded', timeout: 20000 }
    );
    assert(response && response.ok(), 'accessibility visual matrix page failed to load');

    await page.waitForFunction(() =>
      window.__awRuntimeReady === true &&
      window.__awFirstFrame === true &&
      window.AetherUserSettings &&
      window._userSettings
    , undefined, { timeout: 15000 });

    // Freeze distracting motion for deterministic visual review.
    await applySettings(page, {
      reducedMotion: true,
      screenShake: 'off',
      textSpeed: 'instant',
      subtitles: true,
      subtitleSize: 'large',
      subtitleBackground: 'soft',
      speakerLabels: true,
      highContrastUI: false
    });

    const scaleSurfaces = [
      'title','settings','controls','world','choice','questlog',
      'charsheet','saveload','airship','combat','dialogue'
    ];

    for (const scale of ['100','125','150','175']) {
      await applySettings(page, { textScale: scale, highContrastUI: false });
      for (const surface of scaleSurfaces) {
        await prepareSurface(page, surface);
        captures.push(await capture(page, `scale-${scale}__${surface}.png`));
      }
    }

    // High-contrast review at a representative enlarged scale.
    await applySettings(page, { textScale: '150', highContrastUI: true });
    for (const surface of ['title','world','questlog','charsheet','combat','dialogue']) {
      await prepareSurface(page, surface);
      captures.push(await capture(page, `contrast-high__scale-150__${surface}.png`));
    }

    // Subtitle presentation combinations are visually evaluated in dialogue.
    const subtitleCases = [
      { id: 'medium-soft-labels', subtitles: true, subtitleSize: 'medium', subtitleBackground: 'soft', speakerLabels: true },
      { id: 'large-strong-labels', subtitles: true, subtitleSize: 'large', subtitleBackground: 'strong', speakerLabels: true },
      { id: 'extra-large-strong-no-label', subtitles: true, subtitleSize: 'extra-large', subtitleBackground: 'strong', speakerLabels: false },
      { id: 'off-audio-unavailable-failclosed', subtitles: false, subtitleSize: 'large', subtitleBackground: 'soft', speakerLabels: true }
    ];

    for (const item of subtitleCases) {
      await applySettings(page, {
        textScale: '150',
        highContrastUI: false,
        subtitles: item.subtitles,
        subtitleSize: item.subtitleSize,
        subtitleBackground: item.subtitleBackground,
        speakerLabels: item.speakerLabels
      });
      await prepareSurface(page, 'dialogue');
      if (item.id === 'off-audio-unavailable-failclosed') {
        await page.evaluate(() => {
          window.UI.dialogueAudioAvailable = false;
        });
        await page.waitForTimeout(50);
      }
      captures.push(await capture(page, `subtitle__${item.id}.png`));
    }

    const state = await page.evaluate(() => ({
      applied: window._appliedAccessibilitySettings,
      gameState: window.gameState,
      width,
      height
    }));
    assert(state.width === 960 && state.height === 640,
      'visual matrix must use the canonical logical surface');
    assert(captures.length === 54,
      'visual matrix capture count drifted: ' + captures.length);

    const manifest = {
      generatedAt: new Date().toISOString(),
      logicalSurface: { width: 960, height: 640 },
      captureCount: captures.length,
      captures: captures.map(file => path.relative(OUTPUT, file)),
      settingsBoundary: state.applied,
      reviewStatus: 'HUMAN_REVIEW_REQUIRED'
    };
    fs.writeFileSync(
      path.join(OUTPUT, 'manifest.json'),
      JSON.stringify(manifest, null, 2) + '\n'
    );

    if (errors.length) throw new Error('visual matrix browser errors:\n' + errors.join('\n'));

    console.log('Aetherwake accessibility visual matrix: PASS');
    console.log(JSON.stringify(manifest, null, 2));
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => {
  console.error('Aetherwake accessibility visual matrix: FAIL');
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
