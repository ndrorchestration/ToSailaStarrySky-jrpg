/* ============================================================
   Aetherwake — Title Visual Stage
   modules/title-visual-stage.js

   Premium title renderer built from shared Aetherwake world/UI authority.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.2.0';

  function drawSky(now) {
    const bands = [
      [7, 10, 22],
      [12, 20, 36],
      [23, 37, 58],
      [40, 60, 82],
      [72, 87, 105],
      [128, 101, 111],
      [190, 126, 92]
    ];
    const bh = Math.ceil(height / bands.length);
    noStroke();
    for (let i = 0; i < bands.length; i++) {
      fill(...bands[i]);
      rect(0, i * bh, width, bh + 1);
    }

    // Dusk horizon glow.
    for (let i = 0; i < 5; i++) {
      fill(236, 166, 96, 11 - i);
      rect(0, Math.round(height * 0.48) + i * 6, width, 6);
    }

    // Four cloud-depth planes.
    for (let layer = 0; layer < 4; layer++) {
      const y = Math.round(height * (0.55 + layer * 0.07));
      const off = Math.round((now * (0.003 + layer * 0.0014) + layer * 91) % 190);
      fill(186 + layer * 9, 198 + layer * 7, 211 + layer * 4, 26 + layer * 14);
      for (let x = -240; x < width + 240; x += 142) {
        rect(x + off, y, 98, 7 + layer * 2);
        rect(x + off + 18, y - 6, 54, 6);
        rect(x + off + 61, y + 6, 70, 5);
      }
    }

    // Floating geography.
    const islands = [
      [0.07, 0.28, 66, 18],
      [0.22, 0.18, 38, 12],
      [0.77, 0.24, 94, 26],
      [0.91, 0.16, 44, 13]
    ];
    for (let i = 0; i < islands.length; i++) {
      const [nx, ny, iw, ih] = islands[i];
      const drift = Math.round(Math.sin(now * 0.00045 + i) * 4);
      const x = Math.round(width * nx) + drift;
      const y = Math.round(height * ny);
      fill(15, 22, 34, 220);
      rect(x, y, iw, ih);
      rect(x + Math.floor(iw * 0.18), y + ih, Math.floor(iw * 0.64), 4);
      rect(x + Math.floor(iw * 0.36), y + ih + 4, Math.floor(iw * 0.28), 4);
      fill(236, 166, 96, 120);
      rect(x + 10, y + 5, 2, 2);
      if (iw > 70) rect(x + 36, y + 9, 2, 2);
    }

    // First stars with restrained twinkle.
    const stars = [[63,48],[121,81],[201,42],[315,68],[404,37],[529,79],[651,49],[771,91],[888,44],[742,132],[476,111]];
    for (let i = 0; i < stars.length; i++) {
      const [x,y] = stars[i];
      const a = 72 + Math.round((Math.sin(now * 0.0015 + i * 1.7) * 0.5 + 0.5) * 70);
      fill(226, 235, 245, a);
      rect(x % width, y, i % 4 === 0 ? 2 : 1, 1);
    }
  }

  function drawHero(now) {
    const dragonfly = root.AetherDragonflyVisual;
    if (!dragonfly || typeof dragonfly.draw !== 'function') return false;

    // Quiet propulsion wake to anchor motion before the ship itself.
    noStroke();
    for (let i = 0; i < 6; i++) {
      const drift = (now * 0.018 + i * 34) % 180;
      fill(42, 255, 181, Math.max(0, 54 - i * 7));
      rect(Math.round(width * 0.69 - drift), Math.round(height * 0.455 + i * 2), 20 + i * 8, 2);
    }

    dragonfly.draw({
      mode: 'flight',
      x: Math.round(width * 0.73),
      y: Math.round(height * 0.43 + Math.sin(now * 0.00115) * 5),
      now,
      heading: -0.08,
      speed: 1.15,
      scale: 1.58
    });
    return true;
  }

  function drawTitleCopy(now) {
    const ui = root.AetherUI;
    const left = 74;
    const top = 94;
    const panelW = 430;
    const panelH = 318;
    const pulse = Math.sin(now * 0.0032) * 0.5 + 0.5;

    if (ui && typeof ui.panel === 'function') {
      ui.panel(left - 20, top - 26, panelW, panelH, { alpha: 232 });
      ui.sectionLabel('THE AUREATE WAKE // FLIGHT DECK', left, top - 11, { warm: true });
    } else {
      noStroke();
      fill(7, 10, 20, 228);
      rect(left - 20, top - 26, panelW, panelH);
    }

    // Logo lockup.
    textAlign(LEFT, TOP);
    textFont('Press Start 2P');
    textSize(31);
    fill(42, 255, 181);
    text('AETHERWAKE', left, top + 12);

    fill(232, 220, 198, 235);
    textSize(8);
    text('A SOLARPUNK SKY-FANTASY JRPG', left + 2, top + 57);

    noStroke();
    fill(208, 160, 91, 150);
    rect(left + 2, top + 77, 168, 2);
    fill(124, 200, 232, 72);
    rect(left + 174, top + 77, 176, 1);

    textFont('VT323');
    textSize(17);
    fill(232, 220, 198, 220);
    text('A small ship. A broken world. A song beginning to fail.', left + 2, top + 94);

    textSize(13);
    fill(124, 200, 232, 165);
    text('THE FIRST WAKE', left + 2, top + 124);

    // Premium primary action: visually reads as a real menu command.
    if (ui && typeof ui.primaryButton === 'function') {
      ui.primaryButton('NEW GAME', left + 2, top + 153, 278, 42, { pulse });
    } else {
      fill(16, 24, 38, 245);
      rect(left + 2, top + 153, 278, 42);
      stroke(42, 255, 181, 210);
      noFill();
      rect(left + 2, top + 153, 278, 42);
      noStroke();
      textFont('Press Start 2P');
      textSize(9);
      fill(232, 220, 198);
      text('NEW GAME', left + 18, top + 169);
    }

    textFont('VT323');
    textSize(13);
    fill(138, 153, 169, 210);
    text('ENTER / N  confirm', left + 299, top + 167);

    // Operational hints are quiet and separated from the hero action.
    if (ui && typeof ui.divider === 'function') ui.divider(left + 2, top + 216, 350, false);
    textFont('Press Start 2P');
    textSize(6);
    fill(124, 200, 232, 135);
    text('KEYBOARD', left + 2, top + 230);
    textFont('VT323');
    textSize(13);
    fill(232, 220, 198, 175);
    text('WASD / ARROWS  move     E  interact     ESC  back', left + 2, top + 245);

    fill(208, 160, 91, 145);
    text('Alt+Enter / F11  fullscreen', left + 2, top + 267);
  }

  function drawAmbientFrame(now) {
    // Edge vignette and subtle navigation marks.
    noFill();
    stroke(7, 10, 20, 118);
    strokeWeight(14);
    rect(7, 7, width - 14, height - 14);

    noStroke();
    fill(42, 255, 181, 55);
    const tick = 26 + Math.round((Math.sin(now * 0.001) * 0.5 + 0.5) * 10);
    rect(width - 86, 28, 52, 1);
    rect(width - tick, 24, 1, 9);
    fill(208, 160, 91, 75);
    rect(28, height - 34, 78, 1);
  }

  function drawFooter() {
    textAlign(RIGHT, BOTTOM);
    textFont('Press Start 2P');
    textSize(6);
    fill(124, 200, 232, 105);
    text('DRAGONFLY SYSTEMS // READY', width - 28, height - 22);
    textAlign(LEFT, TOP);
  }

  function draw(ctx) {
    const now = ctx && ctx.now ? ctx.now : 0;
    drawSky(now);
    drawHero(now);
    drawAmbientFrame(now);
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
    drawAmbientFrame
  });
})(typeof window !== 'undefined' ? window : globalThis);
