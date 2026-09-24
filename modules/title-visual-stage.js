/* ============================================================
   Aetherwake — Title Visual Stage
   modules/title-visual-stage.js

   Presentation-only title renderer. Reuses shared Dragonfly authority.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';
  const TITLE_BACKGROUND_PATH = 'assets/preview/aetherwake-preview-world-pixelart-v2.png';
  let titleBackground = null;
  let titleBackgroundRequested = false;
  let titleBackgroundReady = false;

  function drawSky(now) {
    if (!titleBackgroundRequested && typeof loadImage === 'function') {
      titleBackgroundRequested = true;
      try {
        titleBackground = loadImage(
          TITLE_BACKGROUND_PATH,
          () => { titleBackgroundReady = true; },
          () => { titleBackground = null; }
        );
      } catch (error) {
        titleBackground = null;
      }
    }
    if (titleBackgroundReady && titleBackground && typeof image === 'function') {
      push();
      noSmooth();
      const cover = Math.max(width / titleBackground.width, height / titleBackground.height);
      const drawWidth = titleBackground.width * cover;
      const drawHeight = titleBackground.height * cover;
      image(titleBackground, (width - drawWidth) / 2, (height - drawHeight) / 2, drawWidth, drawHeight);
      pop();
      return;
    }

    const bands = [
      [8, 12, 24],
      [15, 24, 43],
      [29, 45, 68],
      [50, 72, 94],
      [86, 97, 112],
      [146, 105, 107],
      [197, 127, 94],
    ];
    const bh = Math.ceil(height / bands.length);
    noStroke();
    for (let i = 0; i < bands.length; i++) {
      const c = bands[i];
      fill(c[0], c[1], c[2]);
      rect(0, i * bh, width, bh + 1);
    }

    // Cloud ocean with four pixel-authored parallax planes.
    for (let layer = 0; layer < 4; layer++) {
      const y = Math.round(height * (0.56 + layer * 0.07));
      const off = Math.round((now * (0.004 + layer * 0.0016) + layer * 83) % 190);
      fill(188 + layer * 8, 198 + layer * 7, 211 + layer * 4, 28 + layer * 14);
      for (let x = -240; x < width + 240; x += 142) {
        rect(x + off, y, 96, 7 + layer * 2);
        rect(x + off + 18, y - 6, 51, 6);
        rect(x + off + 58, y + 6, 72, 5);
      }
    }

    // Distant floating islands — block silhouettes, not smooth ellipses.
    const islands = [
      [0.08, 0.28, 64, 18],
      [0.23, 0.20, 36, 12],
      [0.76, 0.25, 92, 25],
      [0.90, 0.17, 42, 13],
    ];
    for (let i = 0; i < islands.length; i++) {
      const [nx, ny, iw, ih] = islands[i];
      const drift = Math.round(Math.sin(now * 0.0005 + i) * 4);
      const x = Math.round(width * nx) + drift;
      const y = Math.round(height * ny);
      fill(17, 24, 38, 210);
      rect(x, y, iw, ih);
      rect(x + Math.floor(iw * 0.2), y + ih, Math.floor(iw * 0.62), 4);
      rect(x + Math.floor(iw * 0.36), y + ih + 4, Math.floor(iw * 0.28), 4);
      fill(244, 174, 91, 115);
      rect(x + 10, y + 5, 2, 2);
      if (iw > 70) rect(x + 36, y + 9, 2, 2);
    }

    // First stars.
    fill(222, 231, 244, 110);
    const stars = [[63,48],[121,81],[201,42],[315,68],[404,37],[529,79],[651,49],[771,91],[888,44]];
    for (const [x,y] of stars) rect(x % width, y, 1, 1);
  }

  function drawHero(now) {
    const dragonfly = root.AetherDragonflyVisual;
    if (!dragonfly || typeof dragonfly.draw !== 'function') return false;

    dragonfly.draw({
      mode: 'flight',
      x: Math.round(width * 0.72),
      y: Math.round(height * 0.44 + Math.sin(now * 0.0012) * 5),
      now,
      heading: -0.08,
      speed: 1.15,
      scale: 1.45,
    });

    return true;
  }

  function drawTitleCopy(now) {
    const left = 88;
    const top = 118;

    noStroke();
    fill(4, 7, 13, 145);
    rect(left - 22, top - 31, 512, 245);

    fill(42, 255, 181, 105);
    rect(left, top - 12, 112, 2);
    for (let i = 0; i < 7; i++) rect(left + i * 18, top - 16, 1, 10);

    textAlign(LEFT, TOP);
    textFont('Press Start 2P');
    textSize(30);
    fill(42, 255, 181);
    text('AETHERWAKE', left, top);

    textSize(10);
    fill(124, 200, 232, 220);
    text('THE LAST SOLARPUNK AIRSHIP', left + 2, top + 48);

    textFont('VT323');
    textSize(17);
    fill(232, 220, 198, 215);
    text('A small ship. A broken world. A song beginning to fail.', left + 2, top + 79);

    textFont('Press Start 2P');
    textSize(9);
    const pulse = 150 + Math.round((Math.sin(now * 0.004) * 0.5 + 0.5) * 90);
    fill(232, 220, 198, pulse);
    text('NEW GAME  //  N OR ENTER', left + 2, top + 126);

    textFont('VT323');
    textSize(13);
    fill(185, 158, 116, 195);
    text('ENTER THE FIRST WAKE', left + 2, top + 157);

    // Minimal controls; deeper instructions belong in gameplay, not the hero screen.
    textSize(12);
    fill(124, 200, 232, 145);
    text('WASD / ARROWS move   •   E interact   •   ESC back', left + 2, top + 185);
  }

  function drawFooter() {
    textAlign(CENTER, BOTTOM);
    textFont('Press Start 2P');
    textSize(7);
    fill(42, 255, 181, 115);
    text('THE DRAGONFLY // FIRST WAKE', width / 2, height - 18);
    textAlign(LEFT, TOP);
  }

  function draw(ctx) {
    const now = ctx && ctx.now ? ctx.now : 0;
    drawSky(now);
    drawHero(now);
    drawTitleCopy(now);
    drawFooter();
    return true;
  }

  root.AetherTitleVisual = Object.freeze({
    VERSION,
    draw,
    drawSky,
    drawHero,
    drawTitleCopy,
  });
})(typeof window !== 'undefined' ? window : globalThis);
