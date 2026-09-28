/* ============================================================
   Aetherwake ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â First Wake Visual Stage
   modules/first-wake-visual-stage.js

   Presentation-only renderer for Sequences 00ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“09.
   Reuses shared sprite and Dragonfly authorities; does not own story state.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '1.2.0';
  const OPENING_WORLD_PATH = 'assets/preview/aetherwake-preview-world-pixelart-v2.png';
  const OPENING_INTERIOR_PATH = 'assets/preview/aetherwake-preview-interior-pixelart-v1.png';
  let openingWorld = null;
  let openingWorldRequested = false;
  let openingWorldReady = false;
  let openingInterior = null;
  let openingInteriorRequested = false;
  let openingInteriorReady = false;

  function bandedSky(top, mid, low) {
    noStroke();
    if (typeof drawingContext !== 'undefined' && drawingContext.createLinearGradient) {
      const gradient = drawingContext.createLinearGradient(0, 0, 0, height);
      gradient.addColorStop(0, 'rgb(' + top.join(',') + ')');
      gradient.addColorStop(0.54, 'rgb(' + mid.join(',') + ')');
      gradient.addColorStop(1, 'rgb(' + low.join(',') + ')');
      drawingContext.save();
      drawingContext.fillStyle = gradient;
      drawingContext.fillRect(0, 0, width, height);
      drawingContext.restore();
      return;
    }
    const count = 56;
    const bh = Math.ceil(height / count);
    for (let i = 0; i < count; i++) {
      const t = i / (count - 1);
      const a = t < 0.55 ? top : mid;
      const b = t < 0.55 ? mid : low;
      const u = t < 0.55 ? t / 0.55 : (t - 0.55) / 0.45;
      fill(
        Math.round(a[0] + (b[0] - a[0]) * u),
        Math.round(a[1] + (b[1] - a[1]) * u),
        Math.round(a[2] + (b[2] - a[2]) * u)
      );
      rect(0, i * bh, width, bh + 1);
    }
  }

  function cloudBands(now, yBase, palette, alphaBase) {
    noStroke();
    smooth();
    for (let layer = 0; layer < 3; layer++) {
      const y = yBase + layer * 42;
      const off = (now * (0.004 + layer * 0.002) + layer * 97) % 220;
      fill(palette[0], palette[1], palette[2], alphaBase + layer * 14);
      for (let x = -260; x < width + 260; x += 210) {
        const xx = x + off;
        ellipse(xx, y, 145 + layer * 18, 28 + layer * 6);
        ellipse(xx + 52, y - 10, 105 + layer * 13, 30 + layer * 5);
        ellipse(xx + 104, y + 7, 132 + layer * 12, 24 + layer * 4);
      }
    }
  }

  function drawDistantIsland(cx, cy, iw, ih, now, detail) {
    const sway = Math.sin(now * 0.00035 + cx * 0.01) * 3;
    const x = cx + sway;
    const topY = cy;

    noStroke();
    fill(53, 72, 75, 205);
    beginShape();
    vertex(x - iw * 0.48, topY + ih * 0.08);
    vertex(x - iw * 0.34, topY - ih * 0.05);
    vertex(x + iw * 0.36, topY - ih * 0.03);
    vertex(x + iw * 0.49, topY + ih * 0.10);
    vertex(x + iw * 0.24, topY + ih * 0.38);
    vertex(x + iw * 0.10, topY + ih);
    vertex(x - iw * 0.08, topY + ih * 0.72);
    vertex(x - iw * 0.25, topY + ih * 0.36);
    endShape(CLOSE);

    fill(73, 111, 78, 215);
    ellipse(x, topY, iw * 0.96, ih * 0.27);
    fill(114, 149, 91, 130);
    ellipse(x - iw * 0.08, topY - ih * 0.02, iw * 0.64, ih * 0.14);

    // Long waterfalls disappear into the cloud sea.
    fill(176, 224, 235, 118);
    const falls = detail ? [-0.22, 0.08, 0.27] : [-0.12, 0.16];
    for (let i = 0; i < falls.length; i++) {
      const fx = x + iw * falls[i];
      const fh = ih * (0.34 + i * 0.10);
      rect(fx, topY + ih * 0.02, Math.max(2, iw * 0.018), fh);
      fill(220, 244, 244, 48);
      ellipse(fx, topY + fh + ih * 0.04, iw * 0.13, ih * 0.09);
      fill(176, 224, 235, 118);
    }

    // Distant architecture reads as a city silhouette, not geometry blocks.
    fill(39, 53, 61, 220);
    const towerCount = detail ? 7 : 4;
    for (let i = 0; i < towerCount; i++) {
      const tx = x - iw * 0.30 + (iw * 0.60) * (i / Math.max(1, towerCount - 1));
      const th = ih * (0.15 + ((i * 37) % 5) * 0.035);
      const tw = Math.max(3, iw * 0.035);
      rect(tx - tw / 2, topY - th - ih * 0.04, tw, th);
      triangle(tx - tw, topY - th - ih * 0.04, tx, topY - th - ih * 0.12, tx + tw, topY - th - ih * 0.04);
    }

    fill(247, 183, 101, 145);
    for (let i = 0; i < (detail ? 6 : 3); i++) {
      const wx = x - iw * 0.23 + i * iw * 0.085;
      rect(wx, topY - ih * 0.09 - (i % 2) * 4, 2, 2);
    }
  }

  function drawPaintedDockBackdrop(scene, now) {
    if (!openingWorldRequested && typeof loadImage === 'function') {
      openingWorldRequested = true;
      try {
        openingWorld = loadImage(
          OPENING_WORLD_PATH,
          () => { openingWorldReady = true; },
          () => { openingWorld = null; openingWorldReady = false; }
        );
      } catch (error) {
        openingWorld = null;
        openingWorldReady = false;
      }
    }
    if (!openingWorldReady || !openingWorld || typeof image !== 'function') return false;

    push();
    noSmooth();
    const cover = Math.max(width / openingWorld.width, height / openingWorld.height);
    const dw = openingWorld.width * cover;
    const dh = openingWorld.height * cover;
    const pan = scene && scene.sequence <= 1 ? -18 : 0;
    image(openingWorld, (width - dw) / 2 + pan, (height - dh) / 2, dw, dh);
    pop();

    // First Wake starts cooler and quieter than free-flight daylight. The grade
    // keeps continuity with title key art while preserving room for warm dock practicals.
    noStroke();
    fill(32, 48, 74, scene && scene.sequence <= 1 ? 64 : 48);
    rect(0, 0, width, height);
    fill(235, 170, 104, 18);
    rect(0, Math.round(height * 0.52), width, Math.round(height * 0.48));

    // Slow distant traffic prevents the painted plate from reading as a static splash.
    for (let i = 0; i < 3; i++) {
      const x = Math.round((now * (0.006 + i * 0.002) + 140 + i * 260) % (width + 90)) - 45;
      const y = Math.round(height * (0.20 + i * 0.065));
      fill(225, 238, 242, 110); rect(x, y, 8, 1);
      fill(42, 255, 181, 80); rect(x - 2, y, 1, 1);
    }
    return true;
  }

  function drawDockSkyportArchitecture(now) {
    noStroke();
    // Keep added skyport forms subordinate to the authored background: open canopies,
    // signal masts, hanging cloth and service rails instead of flat building blocks.
    fill(45, 58, 60, 220);
    rect(108, 337, 8, 78);
    rect(266, 324, 7, 92);
    fill(91, 76, 57, 205);
    rect(105, 337, 171, 7);

    // Solar-cloth canopy with a warm reclaimed-brass edge.
    fill(64, 132, 126, 205);
    quad(116, 344, 265, 331, 250, 360, 124, 366);
    fill(201, 150, 78, 190);
    quad(124, 365, 250, 359, 248, 364, 125, 370);
    fill(118, 190, 169, 38);
    quad(127, 349, 252, 338, 243, 350, 132, 358);

    // Suspended repair pennants establish wind and inhabited scale without hiding the vista.
    const flutter = Math.sin(now * 0.003) * 6;
    fill(190, 103, 82, 210);
    beginShape();
    vertex(284, 314); vertex(320, 318 + flutter * 0.12);
    vertex(309, 337 + flutter); vertex(284, 332); endShape(CLOSE);
    fill(231, 188, 108, 200);
    beginShape();
    vertex(322, 318); vertex(350, 322 - flutter * 0.08);
    vertex(340, 340 - flutter * 0.7); vertex(322, 335); endShape(CLOSE);

    // Slender signal mast and aether beacon echo the richer background architecture.
    fill(46, 58, 60, 230);
    rect(360, 284, 6, 98);
    fill(190, 148, 78, 230);
    rect(354, 297, 18, 4);
    fill(42, 255, 181, 150);
    ellipse(363, 285, 11, 11);
    fill(42, 255, 181, 22);
    ellipse(363, 285, 36, 36);
  }

  function drawDockLivingDetails(now) {
    noStroke();
    // Planters, flowers and warm lamps are deliberate solarpunk signals.
    const planters = [[108,468],[250,451],[842,456]];
    for (let i = 0; i < planters.length; i++) {
      const x = planters[i][0], y = planters[i][1];
      fill(110, 78, 54, 245); rect(x, y, 54, 18);
      fill(65, 121, 76, 245); rect(x + 5, y - 11, 44, 12);
      fill(103, 169, 87, 230); ellipse(x + 12, y - 15, 15, 11);
      ellipse(x + 29, y - 18, 18, 13); ellipse(x + 43, y - 13, 13, 10);
      fill(242, 184, 94, 230); rect(x + 18, y - 20, 3, 3);
      fill(220, 125, 143, 220); rect(x + 37, y - 18, 3, 3);
    }
    const lamps = [[74,392],[366,405],[874,385]];
    for (const [x,y] of lamps) {
      fill(54, 63, 62, 245); rect(x, y, 6, 80);
      fill(248, 190, 91, 230); rect(x - 5, y + 4, 16, 12);
      fill(255, 214, 143, 28); ellipse(x + 3, y + 10, 58, 48);
    }
  }

  function drawHorizonEstablishing(scene, state, now) {
    const painted = drawPaintedDockBackdrop(scene, now);
    if (!painted) {
      bandedSky([38, 58, 91], [105, 146, 178], [238, 188, 126]);
      cloudBands(now * 0.72, 360, [235, 239, 232], 52);
      drawDistantIsland(210, 238, 138, 62, now, false);
      drawDistantIsland(724, 194, 196, 84, now * 0.84, true);
    }

    // Slow cinematic atmosphere only: no dock rails, prompts, characters, or debug geometry.
    noStroke();
    const ticks = state && Number.isFinite(state.sceneTicks) ? state.sceneTicks : 0;
    const fade = Math.max(0, 1 - ticks / 34);
    fill(3, 7, 14, Math.round(220 * fade));
    rect(0, 0, width, height);

    // Feathered lower haze gives the shot depth without turning into HUD chrome.
    fill(226, 236, 239, 24);
    rect(0, Math.round(height * 0.78), width, Math.round(height * 0.22));
    fill(6, 12, 20, 28);
    rect(0, 0, width, 26);
    rect(0, height - 26, width, 26);
    return true;
  }

  function drawDock(scene, state, now) {
    const cinematicRatio = scene.cinematic && Number.isFinite(scene.minimumTicks) && scene.minimumTicks > 0
      ? Math.max(0, Math.min(1, (state.sceneTicks || 0) / scene.minimumTicks))
      : 1;
    const settle = cinematicRatio * cinematicRatio * (3 - 2 * cinematicRatio);

    const paintedBackdrop = drawPaintedDockBackdrop(scene, now);
    if (!paintedBackdrop) {
      bandedSky([52, 73, 108], [117, 151, 176], [241, 185, 126]);

      // Far atmospheric depth and cloud strata fallback.
      noStroke();
      fill(255, 222, 156, 185);
      ellipse(width * 0.16, 118, 72, 72);
      fill(255, 239, 197, 62);
      ellipse(width * 0.16, 118, 150, 150);
      fill(255, 224, 172, 16);
      quad(70, 0, 220, 0, 470, height, 280, height);

      cloudBands(now, 300, [232, 238, 235], 38);
      cloudBands(now * 0.72, 365, [235, 235, 222], 48);

      // Dimensional floating settlements establish inhabited scale.
      drawDistantIsland(128, 205, 150, 70, now, false);
      drawDistantIsland(742, 166, 208, 92, now * 0.92, true);
      drawDistantIsland(302, 244, 92, 46, now * 0.78, false);
      drawDistantIsland(833, 254, 78, 38, now * 0.72, false);
    }

    drawDockSkyportArchitecture(now);

    // Slender dock gantry: enough foreground structure for depth without boxing in the vista.
    fill(45, 54, 56, paintedBackdrop ? 168 : 225);
    rect(52, 332, 8, 118);
    rect(width - 64, 316, 8, 134);
    rect(52, 332, width - 108, 6);
    fill(191, 144, 76, paintedBackdrop ? 110 : 165);
    rect(56, 337, 2, 102);
    rect(width - 61, 322, 2, 116);
    fill(42, 255, 181, paintedBackdrop ? 22 : 38);
    rect(60, 339, width - 120, 2);

    // Perspective deck occupies the lower third so the authored skyport remains dominant.
    for (let i = 0; i < 8; i++) {
      const y0 = 382 + i * 32;
      const y1 = y0 + 34;
      const t0 = i / 8;
      const t1 = (i + 1) / 8;
      const inset0 = 108 * (1 - t0);
      const inset1 = 108 * (1 - t1);
      fill(42 + i * 2, 50 + i * 2, 53 + i * 2, paintedBackdrop ? 54 : 245);
      quad(inset0, y0, width - inset0, y0, width - inset1, y1, inset1, y1);
      stroke(126, 137, 132, paintedBackdrop ? 24 : 52);
      strokeWeight(1);
      line(inset1, y1, width - inset1, y1);
      noStroke();
    }

    // A narrow reclaimed-timber lane anchors traversal without covering the painted dock.
    noStroke();
    fill(104, 80, 56, paintedBackdrop ? 72 : 165);
    quad(width / 2 - 64, 390, width / 2 + 64, 390, width / 2 + 238, height, width / 2 - 238, height);
    fill(191, 144, 76, paintedBackdrop ? 54 : 105);
    quad(width / 2 - 57, 392, width / 2 - 53, 392, width / 2 - 196, height, width / 2 - 203, height);
    quad(width / 2 + 53, 392, width / 2 + 57, 392, width / 2 + 203, height, width / 2 + 196, height);

    // Perspective seams and rails pull the eye toward the ship.
    stroke(111, 125, 127, paintedBackdrop ? 44 : 85);
    strokeWeight(1);
    line(width / 2, 390, width / 2, height);
    line(width / 2 - 92, 390, 145, height);
    line(width / 2 + 92, 390, width - 145, height);
    line(115, 401, 45, 570);
    line(width - 115, 401, width - 45, 570);
    // Reclaimed-brass service seams break the apron into intentional modules.
    stroke(183, 132, 64, paintedBackdrop ? 48 : 82);
    strokeWeight(2);
    line(172, 454, width - 132, 437);
    line(118, 516, width - 82, 505);
    noStroke();

    drawDockLivingDetails(now);

    // Reuse the shared dock prop language so the opening and playable dock feel
    // like the same working place rather than two unrelated presentation sets.
    const environment = root.AetherEnvironmentVisualKit;
    if (environment) {
      if (typeof environment.drawBollard === 'function') {
        environment.drawBollard(695, 446, 0.85);
        environment.drawBollard(765, 468, 0.72);
      }
      if (typeof environment.drawRopeCoil === 'function') {
        environment.drawRopeCoil(718, 485, 0.78);
      }
      if (typeof environment.drawRepairBench === 'function') {
        environment.drawRepairBench(826, 430, 0.78);
      }
      if (typeof environment.drawPlanter === 'function') {
        environment.drawPlanter(180, 469, 0.72, now);
      }
    }

    // Cloud drop below the deck makes altitude continuously visible.
    fill(210, 222, 226, 55);
    for (let x = -20; x < width; x += 118) {
      const drift = Math.round((now * 0.006 + x) % 44);
      rect(x + drift, 565, 88, 7);
      rect(x + drift + 21, 556, 46, 5);
    }

    const dragonfly = root.AetherDragonflyVisual;
    if (dragonfly && typeof dragonfly.draw === 'function') {
      dragonfly.draw({
        mode: 'dock',
        x: Math.round(width * (scene.sequence <= 1 ? 0.79 - settle * 0.07 : 0.72)),
        y: Math.round(scene.sequence <= 1 ? 404 - settle * 16 : 388),
        now,
        speed: 0,
        heading: 0,
        scale: scene.sequence <= 1 ? 1.38 + settle * 0.34 : 1.62,
      });
    }

    const characters = root.AetherCharacterRenderer;
    const sprites = root.AetherPixelSprites;
    if (scene.sequence >= 1) {
      let progress = 0;
      if (scene.id === 'dock_walk' && state && state.dockWalk) {
        progress = state.dockWalk.max > 0 ? state.dockWalk.x / state.dockWalk.max : 0;
      } else if (scene.sequence > 2) {
        progress = 1;
      }
      const cinematic = scene.sequence === 1;
      const arrivalOffset = cinematic ? Math.round((1 - settle) * -64) : 0;
      const ioniaOffset = cinematic ? Math.round((1 - settle) * 52) : 0;
      const enderX = cinematic
        ? Math.round(300 + settle * 34 + arrivalOffset)
        : Math.round(145 + progress * 405);
      const enderY = cinematic ? Math.round(500 - settle * 18) : Math.round(442 + progress * -16);
      const ioniaX = cinematic ? Math.round(660 - settle * 28 + ioniaOffset) : 612;
      const ioniaY = cinematic ? Math.round(493 - settle * 14) : 416;
      const moving = scene.id === 'dock_walk' && progress < 0.98;

      const authored = root.AetherAuthoredCharacterArt;
      const enderAction = moving ? 'walk' : (cinematic ? 'focus' : 'idle');
      const ioniaAction = cinematic || scene.id === 'ionia_practical' ? 'talk' : 'idle';
      const enderFrame = Math.floor(now / (moving ? 100 : 160));
      const ioniaFrame = Math.floor(now / 170);
      let enderAuthored = authored && typeof authored.drawFieldCharacter === 'function'
        ? authored.drawFieldCharacter('ender', enderX, enderY, {
            anchor: 'bottom-center', scale: cinematic ? 0.82 : 0.70,
            action: enderAction, frame: enderFrame,
          })
        : false;
      let ioniaAuthored = authored && typeof authored.drawFieldCharacter === 'function'
        ? authored.drawFieldCharacter('ionia', ioniaX, ioniaY, {
            anchor: 'bottom-center', scale: cinematic ? 0.78 : 0.66,
            action: ioniaAction, frame: ioniaFrame,
          })
        : false;
      // Until full 64x96 packs are admitted, the opening may use the existing
      // reviewed two-frame pixel sheets as a provisional visual fallback.
      // Readiness remains NOT_READY and the manifest is unchanged.
      if (!enderAuthored && authored && typeof authored.drawProvisionalFieldCharacter === 'function') {
        enderAuthored = authored.drawProvisionalFieldCharacter('ender', enderX, enderY, {
          anchor: 'bottom-center', scale: cinematic ? 2.55 : 2.20, action: enderAction, frame: enderFrame,
        });
      }
      if (!ioniaAuthored && authored && typeof authored.drawProvisionalFieldCharacter === 'function') {
        ioniaAuthored = authored.drawProvisionalFieldCharacter('ionia', ioniaX, ioniaY, {
          anchor: 'bottom-center', scale: cinematic ? 2.45 : 2.10, action: ioniaAction, frame: ioniaFrame,
        });
      }
      if (characters && characters.validate()) {
        if (!enderAuthored) characters.draw('ender', enderX, enderY, {
          scale: cinematic ? 1.72 : 1.42,
          depth: cinematic ? 0.78 : 0.64,
          now,
          speed: moving ? 0.72 : 0,
          facing: 'right',
          action: cinematic ? 'focus' : 'idle',
        });
        if (!ioniaAuthored) characters.draw('ionia', ioniaX, ioniaY, {
          scale: cinematic ? 1.62 : 1.34,
          depth: cinematic ? 0.76 : 0.62,
          now,
          speed: 0,
          facing: 'left',
          action: cinematic ? 'talk' : (scene.id === 'ionia_practical' ? 'talk' : 'idle'),
        });
      } else if (sprites && sprites.validate()) {
        sprites.drawShadow(enderX, enderY, 2);
        sprites.draw('ender', enderX, enderY, {
          anchor: 'bottom-center', scale: 2, frame: Math.floor(now / 240) % 2,
        });
        sprites.drawShadow(612 + ioniaOffset, 416, 2);
        sprites.draw('ionia', 612 + ioniaOffset, 416, {
          anchor: 'bottom-center', scale: 2, frame: Math.floor(now / 300) % 2,
        });
      }
    }

    // Closed-route board belongs to the walk/exploration beat, not the character-introduction cinematic.
    if (scene.id === 'dock_walk') {
      fill(37, 43, 48, 218);
      rect(246, 346, 74, 50, 3);
      fill(181, 103, 91, 176);
      for (let i = 0; i < 20; i++) {
        rect(257 + i * 2, 356 + Math.floor(i / 10) * 19, 2, 2);
      }
      stroke(181, 103, 91, 185);
      strokeWeight(2);
      line(257, 354, 309, 386);
      line(309, 354, 257, 386);
      noStroke();
    }
    // Foreground cable silhouettes retain depth without becoming an opaque frame.
    stroke(8, 12, 18, 150);
    strokeWeight(5);
    line(18, 0, 88, 182);
    line(width - 22, 0, width - 102, 198);
    noStroke();
  }

  function drawInteriorDepthFrame(now, floorY) {
    const fy = Number.isFinite(floorY) ? floorY : 420;

    // Hull windows expose the same sky world as the exterior scenes.
    noStroke();
    fill(16, 35, 58);
    rect(126, 126, 156, 64);
    rect(width - 306, 126, 156, 64);
    fill(102, 139, 162, 125);
    rect(132, 132, 144, 52);
    rect(width - 300, 132, 144, 52);
    fill(214, 226, 228, 55);
    const cloudShift = Math.round((now * 0.005) % 58);
    rect(139 + cloudShift, 158, 61, 4);
    rect(width - 286 + cloudShift, 151, 54, 4);

    // Structural ribs create foreground/midground overlap and hull curvature.
    for (let x = 86; x <= width - 86; x += 132) {
      fill(69, 61, 53);
      rect(x, 92, 11, fy - 92);
      fill(42, 255, 181, 28);
      rect(x + 3, 116, 3, 74);
    }

    // Perspective seams converge toward the rear center of the ship.
    stroke(116, 105, 88, 62);
    strokeWeight(1);
    line(width / 2, 248, width / 2, height);
    line(width / 2 - 72, 255, 218, height);
    line(width / 2 + 72, 255, width - 218, height);
    for (let y = fy + 18; y < height; y += 34) {
      line(106, y, width - 106, y);
    }
    noStroke();

    // Warm practical pools and cool aether strips establish mixed lighting.
    fill(243, 176, 96, 22);
    rect(150, 292, 228, 82);
    fill(42, 255, 181, 18);
    rect(width - 390, 274, 236, 96);
  }

  function drawPaintedInteriorBackdrop(now) {
    if (!openingInteriorRequested && typeof loadImage === 'function') {
      openingInteriorRequested = true;
      try {
        openingInterior = loadImage(
          OPENING_INTERIOR_PATH,
          () => { openingInteriorReady = true; },
          () => { openingInterior = null; openingInteriorReady = false; }
        );
      } catch (error) {
        openingInterior = null;
        openingInteriorReady = false;
      }
    }
    if (!openingInteriorReady || !openingInterior || typeof image !== 'function') return false;

    push();
    noSmooth();
    const cover = Math.max(width / openingInterior.width, height / openingInterior.height);
    const dw = openingInterior.width * cover;
    const dh = openingInterior.height * cover;
    image(openingInterior, (width - dw) / 2, (height - dh) / 2, dw, dh);
    pop();

    // Cool aether grade keeps the warm cabin plate inside Aetherwake's palette.
    noStroke();
    fill(19, 39, 55, 36);
    rect(0, 0, width, height);
    fill(245, 181, 103, 12);
    rect(0, Math.round(height * 0.52), width, Math.round(height * 0.48));
    return true;
  }

  function drawWrongSongSetPiece(now, intensity = 1) {
    const pulse = 0.5 + Math.sin(now * 0.007) * 0.5;
    const tremor = Math.sin(now * 0.021) * 2;

    // Cold aether wash interrupts the cabin's warm visual language.
    noStroke();
    fill(28, 104, 124, Math.round(22 * intensity + 24 * pulse * intensity));
    rect(0, 0, width, height);

    // Edge pressure keeps the center readable while making the room feel suddenly wrong.
    fill(5, 10, 20, Math.round(72 * intensity));
    rect(0, 0, 58, height);
    rect(width - 58, 0, 58, height);
    rect(0, 0, width, 34);
    rect(0, height - 42, width, 42);

    // Broken frequency rings radiate from the ship core side of frame.
    noFill();
    for (let i = 0; i < 5; i++) {
      const radius = 62 + i * 54 + pulse * 18;
      stroke(124, 218, 232, Math.max(18, 82 - i * 12));
      strokeWeight(2);
      ellipse(width - 178 + tremor, 278, radius * 1.5, radius);
    }
    noStroke();

    // Aether motes snap into short horizontal faults rather than drifting gently.
    for (let i = 0; i < 17; i++) {
      const xx = Math.round((i * 61 + now * (0.012 + (i % 3) * 0.004)) % width);
      const yy = 118 + ((i * 47) % 334);
      fill(i % 4 === 0 ? 238 : 124, i % 4 === 0 ? 179 : 220, i % 4 === 0 ? 91 : 232,
        78 + Math.round(pulse * 70));
      rect(xx, yy, 10 + (i % 5) * 4, 2);
    }

    // One restrained central flare gives the beat a memorable visual accent.
    fill(205, 245, 232, Math.round(34 + pulse * 46));
    ellipse(width - 178 + tremor, 278, 18 + pulse * 10, 18 + pulse * 10);
    fill(42, 255, 181, Math.round(28 + pulse * 35));
    ellipse(width - 178 + tremor, 278, 48 + pulse * 18, 48 + pulse * 18);
  }

  function drawInterior(scene, state, now) {
    const paintedInterior = drawPaintedInteriorBackdrop(now);
    noStroke();
    if (!paintedInterior) {
      fill(14, 20, 29);
      rect(0, 0, width, height);
      fill(32, 40, 48);
      rect(74, 98, width - 148, height - 166);
      fill(52, 58, 61);
      rect(91, 116, width - 182, height - 202);
      fill(25, 31, 37);
      rect(0, 420, width, 220);
      drawInteriorDepthFrame(now, 420);
    } else {
      // Runtime overlays stay translucent so authored cabin art remains the room.
      fill(14, 20, 29, 28);
      rect(72, 92, width - 144, height - 150);
      fill(42, 255, 181, 12);
      rect(96, 112, width - 192, 2);
    }

    if (!paintedInterior) {
    for (let x = 104; x < width - 90; x += 122) {
      fill(80, 70, 58);
      rect(x, 137, 8, 275);
      fill(42, 255, 181, 38);
      rect(x + 2, 151, 4, 56);
    }

    // Shared table / lived-in equipment.
    fill(101, 76, 57);
    rect(160, 351, 248, 25);
    fill(135, 102, 68);
    rect(177, 331, 62, 20);
    rect(266, 337, 45, 14);

    // Instrument bank.
    fill(31, 43, 52);
    rect(width - 330, 142, 190, 211);
    fill(42, 255, 181, 45);
    rect(width - 306, 166, 143, 4);
    fill(124, 200, 232, 65);
    rect(width - 306, 193, 102, 4);
    rect(width - 306, 220, 124, 4);
    }

    if (scene.id === 'wrong_song') {
      drawWrongSongSetPiece(now, 0.78);
      // Frequency mismatch rendered as pixel wavefronts.
      for (let i = 0; i < 8; i++) {
        const xx = 414 + i * 24;
        const yy = 175 + Math.round(Math.sin(now * 0.006 + i) * 10);
        fill(124, 200, 232, 90 + i * 8);
        rect(xx, yy, 16, 3);
        fill(42, 255, 181, 45);
        rect(xx + 6, yy + 11, 9, 2);
      }
    }

    if (scene.id === 'core_walk') {
      fill(8, 12, 19, 230);
      rect(width - 286, 119, 187, 319);
      fill(42, 255, 181, 36);
      rect(width - 267, 142, 149, 272);
      fill(205, 245, 232, 90);
      rect(width - 194, 181, 4, 191);
    }

    const characters = root.AetherCharacterRenderer;
    const sprites = root.AetherPixelSprites;
    if (scene.sequence >= 1) {
      const positions = {
        berth_task: [['ender', 305], ['ionia', 535]],
        lyra_family: [['ender', 285], ['lyra', 455], ['ionia', 590]],
        wrong_song: [['ender', 315], ['lyra', 514]],
        ionia_practical: [['ender', 270], ['lyra', 438], ['ionia', 596]],
        core_walk: [['ender', 310], ['lyra', 470]],
      };
      const actors = positions[scene.id] || [['ender', 310]];
      const authored = root.AetherAuthoredCharacterArt;
      for (const [id, x] of actors) {
        const action = scene.id === 'wrong_song' && id === 'lyra' ? 'focus' : 'idle';
        let authoredDrawn = authored && typeof authored.drawFieldCharacter === 'function'
          ? authored.drawFieldCharacter(id, x, 420, {
              anchor: 'bottom-center',
              scale: id === 'lyra' ? 0.68 : 0.72,
              action,
              frame: Math.floor(now / 160),
            })
          : false;
        if (!authoredDrawn && authored && typeof authored.drawProvisionalFieldCharacter === 'function') {
          authoredDrawn = authored.drawProvisionalFieldCharacter(id, x, 420, {
            anchor: 'bottom-center',
            scale: id === 'ionia' ? 2.2 : 2.3,
            action,
            frame: Math.floor(now / 160),
          });
        }
        if (!authoredDrawn && characters && characters.validate()) {
          characters.draw(id, x, 420, {
            scale: id === 'lyra' ? 0.88 : 0.98,
            depth: 0.7,
            now,
            speed: 0,
            facing: id === 'ionia' ? 'left' : 'right',
            action,
          });
        } else if (!authoredDrawn && sprites && sprites.validate()) {
          sprites.drawShadow(x, 420, 2);
          sprites.draw(id, x, 420, {
            anchor: 'bottom-center', scale: 2, frame: Math.floor(now / 260) % 2,
          });
        }
      }
    }

    if (scene.id === 'berth_task' && state.berthTask) {
      const step = state.berthTask.step;
      fill(6, 10, 16, 92);
      rect(172, 367, 164, 28, 6);
      fill(232, 220, 198, 195);
      textAlign(LEFT, TOP);
      textFont('Trebuchet MS');
      textSize(10);
      text('SETTLING IN', 184, 374);
      for (let i = 0; i < state.berthTask.max; i++) {
        fill(i < step ? color(42,255,181,190) : color(83,103,107,95));
        rect(266 + i * 14, 376, 8, 4, 1);
      }
    }

    if (scene.id === 'talen_staying') {
      const talenStep = state.talenBeat ? state.talenBeat.step : 0;
      if (talenStep >= 2) {
        fill(140, 104, 68);
        rect(423, 366, 44, 16);
        fill(76, 111, 121);
        rect(438, 352, 19, 14);
        fill(42, 255, 181, 80);
        rect(418, 373, 6, 3);
        rect(467, 373, 6, 3);
      }
      fill(6, 10, 16, 92);
      rect(409, 383, 178, 28, 6);
      fill(232, 220, 198, 195);
      textAlign(LEFT, TOP);
      textFont('Trebuchet MS');
      textSize(10);
      text('TALK WITH TALEN', 420, 390);
      const talenMax = state.talenBeat ? state.talenBeat.max : 2;
      for (let i = 0; i < talenMax; i++) {
        fill(i < talenStep ? color(42,255,181,190) : color(83,103,107,95));
        rect(542 + i * 14, 392, 8, 4, 1);
      }
    }
  }

  function wakeMapPoint(x, y) {
    return {
      x: Math.round(128 + (x - 1) * 49),
      y: Math.round(156 + (y - 1) * 47),
    };
  }

  function drawWakeRoomLabel(label, x, y, active) {
    noStroke();
    fill(active ? 42 : 185, active ? 255 : 158, active ? 181 : 116, active ? 178 : 72);
    rect(x, y, Math.max(54, label.length * 7 + 12), 18);
    fill(8, 12, 18, active ? 230 : 185);
    textAlign(LEFT, TOP);
    textFont('Trebuchet MS');
    textSize(13);
    text(label, x + 6, y + 2);
  }

  function drawWakeForegroundDepth(now) {
    // Near-camera ribs and hanging services deliberately pass in front of the
    // sprite plane. This is presentation-only occlusion: gameplay coordinates
    // remain untouched while the interior gains a real foreground layer.
    noStroke();
    fill(10, 15, 21, 220);
    rect(76, 468, 20, 118);
    rect(width - 96, 456, 20, 130);
    fill(55, 49, 43, 235);
    rect(82, 478, 7, 96);
    rect(width - 89, 466, 7, 108);

    stroke(12, 17, 23, 215);
    strokeWeight(5);
    line(116, 96, 151, 211);
    line(width - 120, 96, width - 164, 226);
    stroke(94, 75, 58, 145);
    strokeWeight(2);
    line(151, 211, 141, 326);
    line(width - 164, 226, width - 151, 344);
    noStroke();

    // A very low-opacity moving vapor sheet separates the close hull from the
    // play plane without softening pixel sprites.
    const drift = Math.round((now * 0.004) % 96);
    fill(124, 200, 232, 18);
    for (let x = -120; x < width + 120; x += 128) {
      rect(x + drift, 492, 82, 5);
      rect(x + drift + 24, 500, 48, 3);
    }
  }

  function drawWakeExploration(scene, state, now) {
    const opening = root.AetherFirstWakeOpening;
    const view = opening && typeof opening.wakeExplorationView === 'function'
      ? opening.wakeExplorationView(state)
      : null;
    const e = state.wakeExploration;
    if (!view || !e) {
      drawInterior(scene, state, now);
      return;
    }

    const paintedInterior = drawPaintedInteriorBackdrop(now);
    noStroke();
    if (!paintedInterior) {
      fill(8, 13, 20);
      rect(0, 0, width, height);
      fill(24, 31, 38);
      rect(70, 94, width - 140, 432);
      fill(49, 54, 55);
      rect(90, 114, width - 180, 392);
      fill(31, 37, 42);
      rect(108, 132, width - 216, 354);
      fill(72, 64, 54);
      rect(122, 145, 690, 330);
      fill(42, 47, 49);
      rect(136, 159, 662, 302);
      drawInteriorDepthFrame(now, 461);
    } else {
      // Keep the authored cabin visible; logical room zones become light-only overlays.
      fill(9, 15, 21, 24);
      rect(92, 110, width - 184, 376);
      fill(238, 181, 105, 14);
      rect(118, 320, 210, 151);
      fill(87, 179, 173, 12);
      rect(568, 150, 226, 156);
    }

    if (!paintedInterior) {
    // Soft architectural light pools replace debug-like room blocks. The floor
    // remains continuous; identity comes from props, structure, and lighting.
    fill(116, 82, 55, 56);   // berth practical warmth
    rect(136, 330, 172, 131);
    fill(126, 89, 61, 42);   // shared table / galley
    rect(136, 159, 220, 144);
    fill(106, 72, 101, 44);  // Lyra/Talen fabric and sensory light
    rect(374, 159, 182, 144);
    fill(53, 91, 111, 56);   // navigation cool instrumentation
    rect(574, 159, 224, 144);
    fill(67, 63, 58, 44);    // maintenance neutral work light
    rect(374, 330, 244, 131);
    fill(24, 37, 51, 82);    // core approach depth
    rect(636, 330, 162, 131);

    // Low walls, thresholds, and ribs make the zoning architectural instead of
    // diagrammatic while leaving the logical walk grid untouched.
    fill(83, 73, 63, 190);
    rect(356, 159, 8, 144);
    rect(556, 159, 8, 144);
    rect(356, 330, 8, 131);
    rect(618, 330, 8, 131);
    fill(118, 103, 83, 105);
    rect(356, 219, 8, 46);
    rect(556, 219, 8, 46);
    rect(356, 368, 8, 44);
    rect(618, 368, 8, 44);

    // Walkable connectors.
    fill(58, 58, 55);
    rect(308, 221, 66, 42);
    rect(556, 221, 18, 42);
    rect(308, 369, 66, 42);
    rect(618, 369, 18, 42);

    // Shared table and galley.
    fill(119, 86, 60);
    rect(176, 226, 126, 20);
    rect(190, 246, 10, 35);
    rect(278, 246, 10, 35);
    fill(149, 112, 72);
    rect(153, 181, 70, 20);
    fill(73, 100, 76);
    rect(237, 181, 28, 20);

    // Ender's berth and Talen's block-built Wake.
    fill(111, 91, 68);
    rect(164, 372, 112, 34);
    fill(151, 112, 72);
    rect(232, 422, 44, 16);
    fill(76, 111, 121);
    rect(247, 408, 19, 14);

    // Lyra's sensory objects and fabric.
    fill(142, 77, 74);
    rect(407, 180, 88, 7);
    fill(185, 116, 94, 120);
    rect(410, 190, 5, 72);
    rect(489, 190, 5, 72);
    fill(124, 200, 232, 75);
    rect(449, 254, 56, 3);

    // Navigation station.
    fill(27, 43, 52);
    rect(612, 179, 145, 80);
    fill(42, 255, 181, 70);
    rect(630, 195, 102, 4);
    fill(124, 200, 232, 70);
    rect(630, 214, 84, 4);
    rect(630, 233, 111, 4);

    // Maintenance wall and telemetry.
    fill(35, 42, 46);
    rect(420, 355, 148, 72);
    fill(185, 158, 116, 90);
    rect(441, 373, 40, 5);
    fill(42, 255, 181, e.clues.includes('frequency') ? 150 : 45);
    rect(493, 373, 52, 5);

    fill(31, 43, 52);
    rect(549, 397, 52, 38);
    fill(124, 200, 232, e.clues.includes('systems') ? 160 : 55);
    rect(558, 407, 34, 4);
    rect(558, 417, 26, 4);

    // Structural route chart.
    fill(46, 42, 39);
    rect(201, 172, 92, 42);
    fill(181, 103, 91, e.clues.includes('structural') ? 65 : 125);
    rect(214, 187, 62, 3);
    rect(236, 179, 3, 26);
    if (e.clues.includes('structural')) {
      fill(42, 255, 181, 140);
      rect(214, 201, 62, 3);
    }

    // Core threshold.
    fill(8, 12, 19);
    rect(713, 351, 58, 92);
    fill(e.coreUnlocked ? 42 : 98, e.coreUnlocked ? 255 : 108, e.coreUnlocked ? 181 : 116, e.coreUnlocked ? 120 : 70);
    rect(723, 361, 38, 72);
    if (e.coreUnlocked) {
      fill(205, 245, 232, 150);
      rect(741, 370, 3, 54);
    }
    }

    // Wrong Song distortion escalates from subtle architectural errors into a real set piece.
    if (scene.id === 'wrong_song' || e.anomalyTriggered) {
      drawWrongSongSetPiece(now, scene.id === 'wrong_song' ? 0.68 : 0.34);
      for (let i = 0; i < 8; i++) {
        const xx = 354 + i * 43;
        const yy = 118 + ((Math.floor(now / 120) + i * 7) % 9);
        fill(124, 200, 232, 35 + i * 5);
        rect(xx, yy, 29, 2);
        if (i % 2 === 0) {
          fill(42, 255, 181, 28);
          rect(xx + 7, yy + 8, 17, 2);
        }
      }
    }

    const authored = root.AetherAuthoredCharacterArt;
    const characters = root.AetherCharacterRenderer;
    const sprites = root.AetherPixelSprites;
    if (scene.sequence >= 1) {
      const ep = wakeMapPoint(e.x, e.y);
      const lp = wakeMapPoint(7, 3);
      const ip = wakeMapPoint(12, 2);

      // Keep interactive exploration in the same pixel character language as the
      // authored opening. Full field-pack readiness is unchanged and remains NOT_READY.
      const drawProvisional = (id, p, moving, facing) => {
        if (!authored || typeof authored.drawProvisionalFieldCharacter !== 'function') return false;
        return authored.drawProvisionalFieldCharacter(id, p.x, p.y, {
          anchor: 'bottom-center',
          scale: id === 'lyra' ? 2.15 : (id === 'ionia' ? 2.20 : 2.28),
          action: moving ? 'walk' : 'idle',
          frame: Math.floor(now / (moving ? 150 : 260)),
          facing,
        });
      };
      const enderPixel = drawProvisional('ender', ep, e.moving, e.facing || 'right');
      const lyraPixel = drawProvisional('lyra', lp, false, 'right');
      const ioniaPixel = drawProvisional('ionia', ip, false, 'left');

      if ((!enderPixel || !lyraPixel || !ioniaPixel) && characters && characters.validate()) {
        if (!enderPixel) characters.draw('ender', ep.x, ep.y, {
          scale: 0.92, depth: 0.64, now,
          speed: e.moving ? 0.8 : 0, facing: e.facing || 'right',
        });
        if (!lyraPixel) characters.draw('lyra', lp.x, lp.y, {
          scale: 0.82, depth: 0.62, now, speed: 0, facing: 'right',
        });
        if (!ioniaPixel) characters.draw('ionia', ip.x, ip.y, {
          scale: 0.89, depth: 0.63, now, speed: 0, facing: 'left',
        });
      } else if ((!enderPixel || !lyraPixel || !ioniaPixel) && sprites && sprites.validate()) {
        if (!enderPixel) {
          sprites.drawShadow(ep.x, ep.y, 2);
          sprites.draw('ender', ep.x, ep.y, {
            anchor: 'bottom-center', scale: 2, frame: Math.floor(now / 220) % 2,
          });
        }
        if (!lyraPixel) {
          sprites.drawShadow(lp.x, lp.y, 2);
          sprites.draw('lyra', lp.x, lp.y, {
            anchor: 'bottom-center', scale: 2, frame: Math.floor(now / 310) % 2,
          });
        }
        if (!ioniaPixel) {
          sprites.drawShadow(ip.x, ip.y, 2);
          sprites.draw('ionia', ip.x, ip.y, {
            anchor: 'bottom-center', scale: 2, frame: Math.floor(now / 290) % 2,
          });
        }
      }
    }

    drawWakeForegroundDepth(now);

    // Context cue only for what is close enough to inspect.
    const nearby = opening.nearbyWakeHotspot(state, 1);
    if (nearby) {
      const p = wakeMapPoint(nearby.x, nearby.y);
      fill(42, 255, 181, 130);
      rect(p.x - 18, p.y - 42, 36, 3);
      rect(p.x - 18, p.y - 42, 3, 10);
      rect(p.x + 15, p.y - 42, 3, 10);
    }

    // Painted interiors already communicate room identity visually. Keep labels only
    // on the procedural fallback so authored spaces do not become a debug map.
    if (!paintedInterior) {
      drawWakeRoomLabel('BERTH', 145, 443, view.zone === 'berth');
      drawWakeRoomLabel('TABLE', 145, 282, view.zone === 'shared-table');
      drawWakeRoomLabel('LYRA', 392, 282, view.zone === 'lyra-space');
      drawWakeRoomLabel('NAV', 590, 282, view.zone === 'navigation');
      drawWakeRoomLabel('MAINT', 392, 443, view.zone === 'maintenance');
      drawWakeRoomLabel('CORE', 651, 443, view.zone === 'core-approach');
    }

    // Exploration HUD is now a restrained JRPG objective cue rather than a map/debug card.
    // When a scene notice is already telling the player what changed, do not echo
    // the same objective directly underneath it.
    const hasSceneNotice = Array.isArray(root.toasts) && root.toasts.some(t =>
      t && t.kind !== 'system' && now - Number(t.startTime || 0) <= Number(t.duration || 0)
    );
    const objectiveW = 286;
    if (!hasSceneNotice) {
      fill(5, 8, 13, 118);
      rect(width / 2 - objectiveW / 2, 42, objectiveW, 30, 7);
      textAlign(CENTER, TOP);
      textFont('Segoe UI Semibold');
      textSize(9);
      fill(42, 255, 181, 215);
      text(String(view.objective || '').replace(/[.]$/, '').toUpperCase(), width / 2, 52);
    }

    const messageW = Math.min(690, width - 260);
    const messageX = width / 2 - messageW / 2;
    fill(5, 8, 13, 150);
    rect(messageX, 548, messageW, 46, 8);
    textFont('Trebuchet MS');
    textSize(16);
    fill(232, 220, 198, 225);
    textAlign(LEFT, TOP);
    text(view.lastMessage || 'Explore.', messageX + 16, 558, messageW - 32, 24);

    textFont('Segoe UI Semibold');
    textSize(9);
    textAlign(CENTER, TOP);
    fill(185, 158, 116, 185);
    if (scene.id === 'core_walk') {
      const pipX = width / 2 - 25;
      text('CLUES', pipX - 34, 580);
      for (let i = 0; i < 3; i++) {
        fill(i < e.clues.length ? color(42,255,181,190) : color(83,103,107,90));
        rect(pipX + i * 14, 581, 8, 4, 1);
      }
    } else if (nearby) {
      text('E   INSPECT', width / 2, 580);
    }

    textAlign(LEFT, TOP);
  }

  function drawChapter(now) {
    bandedSky([7, 10, 20], [14, 22, 37], [25, 43, 62]);
    noStroke();

    // Concentric pixel aether rings.
    for (let r = 220; r >= 70; r -= 25) {
      const alpha = 18 + Math.floor((220 - r) * 0.22);
      fill(42, 255, 181, alpha);
      rect(width / 2 - r / 2, height / 2 - 3, r, 6);
      fill(124, 200, 232, alpha);
      rect(width / 2 - 3, height / 2 - r / 4, 6, r / 2);
    }

    fill(205, 225, 230, 80);
    for (let i = 0; i < 24; i++) {
      const x = Math.round((i * 157 + now * 0.003) % width);
      const y = 40 + ((i * 89) % 370);
      rect(x, y, 1, 1);
    }
  }

  function drawFrame(scene, state, now) {
    if (scene.chapterCard) {
      drawChapter(now);
      return;
    }
    if (scene.id === 'arrival_horizon') {
      drawHorizonEstablishing(scene, state, now);
      return;
    }
    if (scene.sequence <= 2) {
      drawDock(scene, state, now);
      return;
    }
    drawInterior(scene, state, now);
  }

  function drawSceneTransition(scene, state) {
    const ticks = state && Number.isFinite(state.sceneTicks) ? state.sceneTicks : 999;
    const introTicks = scene && scene.chapterCard ? 30 : 18;
    if (ticks >= introTicks) return false;
    const t = Math.max(0, Math.min(1, ticks / introTicks));
    const eased = 1 - Math.pow(1 - t, 3);
    const alpha = Math.round((1 - eased) * 190);
    const sweepX = Math.round(width * eased);

    // Presentation-only scene handoff: a short dark veil and aether scan sweep
    // hide hard visual cuts without delaying input or mutating opening state.
    noStroke();
    fill(4, 7, 13, alpha);
    rect(0, 0, width, height);
    fill(42, 255, 181, Math.round((1 - t) * 100));
    rect(Math.max(0, sweepX - 2), 18, 2, height - 36);

    // No sequence/debug metadata in player-facing scene transitions.
    return true;
  }

  function draw(scene, state, ctx) {
    const now = ctx.now || 0;

    if (scene.sequence >= 5 && scene.sequence <= 8) {
      drawWakeExploration(scene, state, now);
      return true;
    }

    drawFrame(scene, state, now);
    drawSceneTransition(scene, state);

    // Cinematic framing.
    noStroke();
    fill(5, 8, 13, 42);
    rect(0, 0, width, 18);
    rect(0, height - 18, width, 18);

    const textPanelY = scene.chapterCard ? 92 : 50;
    const sceneTicks = state && Number.isFinite(state.sceneTicks) ? state.sceneTicks : 999;
    const showSceneTitle = scene.chapterCard ||
      (scene.id === 'arrival_horizon'
        ? sceneTicks >= 90 && sceneTicks < 160
        : (scene.cinematic || sceneTicks < 36));
    if (showSceneTitle) {
      const titlePanelW = scene.chapterCard ? width - 248 : Math.min(286, width - 420);
      const titlePanelH = scene.chapterCard ? 118 : 28;
      const titlePanelX = Math.round((width - titlePanelW) / 2);
      fill(6, 9, 14, scene.chapterCard ? 96 : 62);
      rect(titlePanelX, textPanelY, titlePanelW, titlePanelH, 8);
      if (!scene.chapterCard) {
        fill(42, 255, 181, 76);
        rect(titlePanelX + 46, textPanelY + titlePanelH - 2, titlePanelW - 92, 1);
        fill(191, 144, 76, 118);
        rect(titlePanelX + 14, textPanelY + 8, 20, 1);
        rect(titlePanelX + titlePanelW - 34, textPanelY + 8, 20, 1);
      }

      textAlign(CENTER, TOP);
      textFont('Segoe UI Semibold');
      textSize(scene.chapterCard ? 24 : 9);
      fill(scene.chapterCard ? 42 : 232, scene.chapterCard ? 255 : 220, scene.chapterCard ? 181 : 198);
      text(scene.title, width / 2, textPanelY + (scene.chapterCard ? 24 : 8));

      if (scene.subtitle) {
        textSize(10);
        fill(124, 200, 232);
        text(scene.subtitle, width / 2, textPanelY + 65);
      }
    }

    const showNarrative = !scene.chapterCard && (scene.id !== 'arrival_horizon' || sceneTicks >= 142);
    if (scene.id === 'arrival_horizon' && showNarrative) {
      const lineIndex = sceneTicks < 194 ? 0 : 1;
      const cinematicLine = scene.lines[Math.min(lineIndex, scene.lines.length - 1)];
      textAlign(CENTER, TOP);
      textFont('Trebuchet MS');
      textSize(18);
      fill(3, 8, 15, 170);
      text(cinematicLine, width / 2 + 2, height - 112 + 2);
      fill(244, 233, 210, 238);
      text(cinematicLine, width / 2, height - 112);
    } else if (showNarrative) {
      const visibleLines = scene.lines.slice(0, 3);
      const narrativePanelH = Math.min(98, 30 + visibleLines.length * 21);
      const narrativePanelY = height - 18 - 38 - narrativePanelH;
      const narrativePanelX = 148;
      const narrativePanelW = width - 296;
      fill(6, 9, 14, 122);
      rect(narrativePanelX, narrativePanelY, narrativePanelW, narrativePanelH, 10);
      fill(42,255,181,42);
      rect(narrativePanelX + 10, narrativePanelY + 8, narrativePanelW - 20, 2);

      const authored = root.AetherAuthoredCharacterArt;
      const speakerId = scene.speaker ? String(scene.speaker).toLowerCase() : null;
      const portraitSize = Math.min(72, narrativePanelH - 18);
      const portraitX = narrativePanelX + 12;
      const portraitY = narrativePanelY + 14;
      const portraitDrawn = speakerId && authored && typeof authored.drawPortrait === 'function'
        ? authored.drawPortrait(speakerId, portraitX, portraitY, portraitSize, { expression: 'talk' })
        : false;
      if (portraitDrawn) {
        noFill();
        stroke(42, 255, 181, 92);
        strokeWeight(1);
        rect(portraitX - 2, portraitY - 2, portraitSize + 4, portraitSize + 4, 5);
        noStroke();
        fill(232, 220, 198, 208);
        textAlign(LEFT, TOP);
        textFont('Segoe UI Semibold');
        textSize(10);
        text(scene.speaker, portraitX, narrativePanelY - 1);
      }

      const copyX = portraitDrawn ? portraitX + portraitSize + 16 : narrativePanelX + 10;
      const copyW = portraitDrawn ? narrativePanelW - (copyX - narrativePanelX) - 12 : narrativePanelW - 20;
      textAlign(LEFT, TOP);
      textFont('Trebuchet MS');
      textSize(15);
      fill(232, 220, 198);
      let y = narrativePanelY + 16;
      for (const line of visibleLines) {
        text(line, copyX, y, copyW, 22);
        y += 21;
      }
    } else {
      textAlign(CENTER, TOP);
      textFont('Trebuchet MS');
      textSize(20);
      fill(232, 220, 198, 220);
      text(scene.lines.join('   •   '), width / 2, 330, width - 250, 120);
    }

    // Player-facing opening keeps production metadata out of the cinematic.
    textAlign(CENTER, BOTTOM);
    textFont('Segoe UI Semibold');
    textSize(10);
    const presentationReady = typeof root.AetherFirstWakeOpening.presentationReady === 'function'
      ? root.AetherFirstWakeOpening.presentationReady(state)
      : true;
    let promptText = '';
    if (scene.id === 'dock_walk' && state.dockWalk && !state.dockWalk.ready) {
      promptText = '← / →   WALK';
    } else if (scene.id === 'dock_walk') {
      promptText = 'ENTER   BOARD';
    } else if (scene.id === 'berth_task' && state.berthTask && !state.berthTask.ready) {
      promptText = 'E   WORK';
    } else if (scene.id === 'talen_staying' && state.talenBeat && !state.talenBeat.ready) {
      promptText = 'E   RESPOND';
    } else if (scene.cinematic && !presentationReady) {
      promptText = '';
    } else {
      promptText = 'ENTER   CONTINUE';
    }
    if (promptText) {
      fill(5, 9, 15, 96);
      rect(width / 2 - 84, height - 43, 168, 24, 7);
      fill(235, 230, 214, 210);
      text(promptText, width / 2, height - 27);
    }

    textAlign(LEFT, TOP);
    return true;
  }

  root.AetherFirstWakeVisual = Object.freeze({
    VERSION,
    draw,
    drawDock,
    drawInterior,
    drawWakeExploration,
    drawChapter,
    drawSceneTransition,
  });
})(typeof window !== 'undefined' ? window : globalThis);
