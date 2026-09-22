/* ============================================================
   Aetherwake — Dragonfly Dusk Dock Benchmark Presentation
   modules/visual-benchmark.js

   Presentation only. This module must not mutate gameplay topology,
   quest state, party state, save state, or navigation state.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';

  function isActive(player, airNavigationState) {
    if (!player || !airNavigationState) return false;
    if (airNavigationState.mooredLandmarkId !== 'wake-dock') return false;
    return player.tileX >= 18 && player.tileY >= 9 && player.tileY <= 24;
  }

  function duskFactor(dayTime) {
    const t = Number.isFinite(dayTime) ? dayTime : 0.78;
    const dist = Math.min(Math.abs(t - 0.78), Math.abs((t + 1) - 0.78), Math.abs(t - (0.78 + 1)));
    return Math.max(0.55, 1 - dist * 2.2);
  }

  function drawBackdrop(ctx) {
    const w = ctx.width;
    const h = ctx.height;
    const now = ctx.now || 0;
    const dusk = duskFactor(ctx.dayTime);

    noStroke();

    // Banded dusk gradient: deliberately pixel-authored rather than a smooth
    // vector gradient. The map remains the playable plane over this sky.
    const bands = [
      [16, 18, 38],
      [28, 31, 61],
      [47, 54, 88],
      [73, 82, 116],
      [105, 102, 132],
      [155, 116, 126],
      [205, 138, 105],
    ];
    const bandH = Math.ceil(h / bands.length);
    for (let i = 0; i < bands.length; i++) {
      const c = bands[i];
      const mix = 0.72 + dusk * 0.28;
      fill(Math.round(c[0] * mix), Math.round(c[1] * mix), Math.round(c[2] * mix));
      rect(0, i * bandH, w, bandH + 1);
    }

    // Distant luminous cloud sea.
    for (let layer = 0; layer < 4; layer++) {
      const baseY = h * (0.56 + layer * 0.075);
      const speed = 0.0025 + layer * 0.0014;
      const offset = Math.round((now * speed + layer * 97) % 180);
      const alpha = 34 + layer * 14;
      fill(180 + layer * 8, 190 + layer * 8, 212 + layer * 6, alpha);
      for (let x = -220; x < w + 220; x += 120) {
        const xx = x + offset;
        rect(xx, Math.round(baseY), 88, 8 + layer * 3);
        rect(xx + 18, Math.round(baseY - 6), 48, 6);
        rect(xx + 42, Math.round(baseY + 7), 70, 5);
      }
    }

    // Distant floating-island silhouettes and warm settlement pin-lights.
    const islands = [
      [0.61, 0.35, 70, 22],
      [0.73, 0.29, 46, 15],
      [0.84, 0.39, 92, 28],
      [0.94, 0.24, 38, 13],
    ];
    for (let i = 0; i < islands.length; i++) {
      const [nx, ny, iw, ih] = islands[i];
      const x = Math.round(w * nx);
      const y = Math.round(h * ny);
      fill(24, 31, 48, 215);
      rect(x, y, iw, ih);
      rect(x + Math.floor(iw * 0.18), y + ih, Math.floor(iw * 0.65), 5);
      rect(x + Math.floor(iw * 0.34), y + ih + 5, Math.floor(iw * 0.31), 4);
      fill(244, 174, 91, 150);
      rect(x + 10, y + 5, 2, 2);
      if (iw > 50) rect(x + 24, y + 9, 2, 2);
      if (iw > 70) rect(x + 43, y + 5, 2, 2);
    }

    // Tiny distant air traffic: slow enough to read as scale, not UI noise.
    for (let i = 0; i < 3; i++) {
      const x = Math.round((now * (0.008 + i * 0.003) + 120 + i * 220) % (w + 80)) - 40;
      const y = Math.round(h * (0.22 + i * 0.08));
      fill(205, 225, 230, 110);
      rect(x, y, 6, 1);
      fill(42, 255, 181, 90);
      rect(x - 2, y, 1, 1);
    }

    // First stars emerge in the upper atmosphere.
    fill(224, 232, 245, 110);
    const stars = [[71,54],[132,89],[218,46],[321,74],[417,39],[542,82],[646,51],[778,97],[889,48]];
    for (const [sx, sy] of stars) rect(sx % w, sy, 1, 1);
  }

  function drawDragonfly(ctx) {
    const now = ctx.now || 0;
    const x = ctx.x;
    const y = ctx.y;
    const pulse = 0.75 + Math.sin(now * 0.004) * 0.25;
    const wing = Math.round(Math.sin(now * 0.0022) * 3);

    push();
    translate(Math.round(x), Math.round(y));

    // Mooring shadow / dock contact.
    noStroke();
    fill(10, 12, 22, 75);
    rect(-48, 19, 102, 8);

    // Lower wings: translucent layered membrane with structural spars.
    fill(78, 126, 151, 70);
    rect(-22, -27 - wing, 48, 14);
    rect(-22, 22 + wing, 48, 14);
    fill(124, 200, 232, 52);
    rect(-17, -23 - wing, 38, 7);
    rect(-17, 25 + wing, 38, 7);

    stroke(124, 200, 232, 105);
    strokeWeight(1);
    line(-20, -20 - wing, 18, -15 - wing);
    line(-20, 29 + wing, 18, 24 + wing);
    noStroke();

    // Compact reinforced hull — roughly shipping-container proportions.
    fill(36, 43, 55);
    rect(-42, -12, 76, 25);
    fill(77, 68, 63);
    rect(-34, -16, 58, 5);
    fill(118, 83, 58);
    rect(-38, 10, 67, 5);

    // Forward observation/helm glazing.
    fill(38, 71, 86);
    rect(24, -8, 17, 16);
    fill(124, 200, 232, 135);
    rect(28, -5, 10, 5);

    // Articulated tail / stabilizer.
    fill(47, 51, 61);
    rect(-57, -5, 17, 10);
    rect(-62, -11, 5, 22);
    fill(124, 200, 232, 70);
    rect(-63, -14, 2, 28);

    // Aether core and shield nodes.
    fill(42, 255, 181, Math.round(70 * pulse));
    rect(-17, -7, 22, 14);
    fill(205, 245, 232, Math.round(175 * pulse));
    rect(-10, -3, 8, 6);
    fill(42, 255, 181, Math.round(180 * pulse));
    rect(10, -14, 3, 3);
    rect(10, 12, 3, 3);
    rect(-33, -14, 3, 3);
    rect(-33, 12, 3, 3);

    // Propulsion wake at idle — restrained, not a full thrust plume.
    const wake = 8 + Math.round(Math.sin(now * 0.006) * 3);
    fill(124, 200, 232, 60);
    rect(-57 - wake, -2, wake, 4);
    fill(42, 255, 181, 45);
    rect(-55 - Math.floor(wake / 2), -1, Math.floor(wake / 2), 2);

    // Warm lived-in windows.
    fill(241, 174, 96, 155);
    rect(-27, -7, 4, 3);
    rect(-20, -7, 4, 3);

    // Mooring lines tie visual hero object back to the real dock.
    stroke(94, 75, 58, 170);
    strokeWeight(1);
    line(-22, 14, -40, 32);
    line(18, 14, 36, 33);
    noStroke();

    pop();
  }

  function drawLighting(ctx) {
    const w = ctx.width;
    const h = ctx.height;
    const dusk = duskFactor(ctx.dayTime);
    noStroke();
    fill(28, 31, 62, Math.round(28 + dusk * 18));
    rect(0, 0, w, h);
    // Preserve warm human-scale light against the cool dusk grade.
    fill(245, 167, 82, 18);
    rect(360, 180, 188, 210);
  }

  function drawDockLights(ctx) {
    const now = ctx.now || 0;
    const lamps = [
      [402, 238], [435, 270], [472, 306], [504, 337]
    ];
    for (let i = 0; i < lamps.length; i++) {
      const [x, y] = lamps[i];
      const pulse = 0.85 + Math.sin(now * 0.003 + i) * 0.15;
      noStroke();
      fill(244, 169, 82, Math.round(45 * pulse));
      rect(x - 5, y - 5, 10, 10);
      fill(255, 207, 126, Math.round(190 * pulse));
      rect(x - 1, y - 2, 3, 4);
      fill(68, 55, 46, 220);
      rect(x, y + 2, 1, 11);
    }
  }

  function drawForeground(ctx) {
    const w = ctx.width;
    const h = ctx.height;
    const now = ctx.now || 0;

    // Near railing/cable silhouette creates a foreground depth band.
    noStroke();
    fill(12, 15, 26, 195);
    rect(0, h - 31, w, 31);
    for (let x = 18; x < w; x += 64) rect(x, h - 54, 4, 27);
    rect(0, h - 50, w, 3);

    // Hanging rope/cable sway.
    stroke(58, 49, 43, 180);
    strokeWeight(2);
    for (let i = 0; i < 4; i++) {
      const x = 90 + i * 210;
      const sway = Math.round(Math.sin(now * 0.0018 + i) * 5);
      line(x, h - 50, x + sway, h - 23);
    }
    noStroke();

    // Windborne seeds/dust in the near plane.
    fill(224, 211, 165, 100);
    for (let i = 0; i < 9; i++) {
      const x = Math.round((now * (0.011 + i * 0.0004) + i * 107) % (w + 20)) - 10;
      const y = Math.round(h * 0.45 + ((i * 53) % 180) + Math.sin(now * 0.002 + i) * 8);
      rect(x, y, 2, 1);
    }
  }

  const api = Object.freeze({
    VERSION,
    isActive,
    drawBackdrop,
    drawDragonfly,
    drawLighting,
    drawDockLights,
    drawForeground,
  });

  root.AetherVisualBenchmark = api;
})(typeof window !== 'undefined' ? window : globalThis);
