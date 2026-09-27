/* ============================================================
   Aetherwake — Title Visual Stage
   modules/title-visual-stage.js

   Presentation-only title renderer. Reuses shared Dragonfly authority.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.3.0';
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
    // The painted title authority already contains its own hero airship.
    // Do not composite the procedural Dragonfly over that finished key art.
    if (titleBackgroundReady && titleBackground) return true;
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
    const uiVisual = root.AetherUIVisualSystem;
    const layout = uiVisual && typeof uiVisual.layoutTitle === 'function'
      ? uiVisual.layoutTitle(width, height)
      : { panel: { x: 64, y: 84, w: 448, h: 216 } };
    const panel = layout.panel;
    const left = panel.x + 24;
    const top = panel.y + 24;
    const pulse = 0.5 + Math.sin(now * 0.004) * 0.5;

    // Layered glass-and-brass title card: substantial enough to read over the vista,
    // but transparent enough that the world remains the hero image.
    noStroke();
    fill(4, 9, 18, 150);
    rect(panel.x, panel.y, panel.w, panel.h, 10);
    fill(21, 48, 59, 42);
    rect(panel.x + 4, panel.y + 4, panel.w - 8, panel.h - 8, 8);
    fill(5, 10, 18, 88);
    rect(panel.x, panel.y + panel.h - 62, panel.w, 62, 0, 0, 10, 10);

    // JRPG logo lockup: horizontal rule, central aether glyph, and small brass endcaps.
    fill(42, 255, 181, 145);
    rect(left, top - 8, 136, 2);
    fill(197, 151, 78, 190);
    rect(left - 2, top - 11, 4, 8);
    rect(left + 134, top - 11, 4, 8);
    fill(124, 220, 232, 120 + Math.round(pulse * 75));
    rect(left + 66, top - 14, 6, 14);
    fill(42, 255, 181, 40 + Math.round(pulse * 30));
    rect(left + 61, top - 9, 16, 4);

    textAlign(LEFT, TOP);
    textFont('Trebuchet MS');
    textSize(31);
    fill(238, 226, 198, 245);
    text('AETHERWAKE', left, top);
    fill(42, 255, 181, 170);
    rect(left + 1, top + 38, 204, 2);

    textFont('Segoe UI Semibold');
    textSize(10);
    fill(151, 219, 229, 230);
    text('THE LAST SOLARPUNK AIRSHIP', left + 2, top + 47);

    textFont('Trebuchet MS');
    textSize(15);
    fill(237, 222, 199, 225);
    text('A small ship. A broken world. A song beginning to fail.', left + 2, top + 73);

    // Primary action reads as a selectable JRPG command instead of another line of copy.
    const actionY = top + 111;
    fill(42, 255, 181, 25 + Math.round(pulse * 20));
    rect(left, actionY - 5, 248, 28, 4);
    fill(42, 255, 181, 185 + Math.round(pulse * 55));
    rect(left, actionY - 5, 3, 28, 2);
    textFont('Segoe UI Semibold');
    textSize(12);
    fill(238, 226, 198, 235);
    text('NEW GAME  //  N OR ENTER', left + 12, actionY);

    textFont('Trebuchet MS');
    textSize(12);
    fill(198, 160, 93, 215);
    text('ENTER THE FIRST WAKE', left + 12, top + 145);

    // Keep controls quiet and secondary; the title screen should sell the world first.
    textSize(10);
    fill(151, 213, 226, 170);
    text('WASD / ARROWS move   •   E interact   •   ESC back', left + 2, top + 178);
  }

  function drawFooter() {
    textAlign(CENTER, BOTTOM);
    textFont('Segoe UI Semibold');
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
