/* ============================================================
   Aetherwake ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â First Wake Visual Stage
   modules/first-wake-visual-stage.js

   Presentation-only renderer for Sequences 00ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“09.
   Reuses shared sprite and Dragonfly authorities; does not own story state.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.4.0';

  function bandedSky(top, mid, low) {
    const bands = [top, mid, low];
    const bh = Math.ceil(height / bands.length);
    noStroke();
    for (let i = 0; i < bands.length; i++) {
      const c = bands[i];
      fill(c[0], c[1], c[2]);
      rect(0, i * bh, width, bh + 1);
    }
  }

  function cloudBands(now, yBase, palette, alphaBase) {
    noStroke();
    for (let layer = 0; layer < 3; layer++) {
      const y = Math.round(yBase + layer * 38);
      const off = Math.round((now * (0.004 + layer * 0.002) + layer * 79) % 170);
      fill(palette[0], palette[1], palette[2], alphaBase + layer * 14);
      for (let x = -220; x < width + 220; x += 136) {
        rect(x + off, y, 92, 7 + layer * 2);
        rect(x + off + 18, y - 5, 44, 5);
        rect(x + off + 50, y + 6, 67, 4);
      }
    }
  }

  function drawDock(scene, state, now) {
    const cinematicRatio = scene.cinematic && Number.isFinite(scene.minimumTicks) && scene.minimumTicks > 0
      ? Math.max(0, Math.min(1, (state.sceneTicks || 0) / scene.minimumTicks))
      : 1;
    const settle = cinematicRatio * cinematicRatio * (3 - 2 * cinematicRatio);

    bandedSky([12, 22, 45], [52, 78, 111], [190, 132, 108]);

    // Far atmospheric depth and cloud strata.
    cloudBands(now, 300, [212, 224, 229], 34);
    cloudBands(now * 0.72, 365, [235, 235, 222], 48);

    noStroke();
    fill(22, 31, 47, 185);
    rect(72, 212, 132, 24);
    rect(95, 236, 86, 9);
    rect(685, 178, 164, 28);
    rect(721, 206, 94, 10);
    fill(48, 63, 77, 155);
    rect(248, 250, 88, 16);
    rect(774, 267, 66, 12);

    // Distant warm lights establish inhabited scale.
    fill(243, 176, 96, 135);
    rect(105, 221, 3, 3);
    rect(138, 226, 3, 3);
    rect(704, 188, 3, 3);
    rect(748, 192, 3, 3);
    rect(802, 187, 3, 3);

    // Vertical dock pylons and gantry.
    fill(18, 25, 34);
    rect(44, 270, 18, 180);
    rect(width - 70, 246, 20, 204);
    rect(44, 272, width - 94, 12);
    fill(82, 98, 105, 90);
    rect(51, 280, 3, 158);
    rect(width - 62, 257, 3, 180);

    // Perspective deck bands: wider toward camera, narrower toward horizon.
    for (let i = 0; i < 9; i++) {
      const y = 330 + i * 27;
      const inset = Math.max(18, 128 - i * 13);
      fill(30 + i * 3, 37 + i * 3, 43 + i * 3);
      rect(inset, y, width - inset * 2, 29);
      fill(78, 88, 89, 95);
      rect(inset, y, width - inset * 2, 2);
    }

    // Perspective seams and rails pull the eye toward the ship.
    stroke(111, 125, 127, 85);
    strokeWeight(1);
    line(width / 2, 330, width / 2, height);
    line(width / 2 - 105, 330, 145, height);
    line(width / 2 + 105, 330, width - 145, height);
    line(115, 348, 45, 570);
    line(width - 115, 348, width - 45, 570);
    noStroke();

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
        scale: scene.sequence <= 1 ? 1.38 + settle * 0.34 : 1.48,
      });
    }

    const sprites = root.AetherPixelSprites;
    if (sprites && sprites.validate() && scene.sequence >= 1) {
      let progress = 0;
      if (scene.id === 'dock_walk' && state && state.dockWalk) {
        progress = state.dockWalk.max > 0 ? state.dockWalk.x / state.dockWalk.max : 0;
      } else if (scene.sequence > 2) {
        progress = 1;
      }
      const arrivalOffset = scene.sequence === 1 ? Math.round((1 - settle) * -48) : 0;
      const ioniaOffset = scene.sequence === 1 ? Math.round((1 - settle) * 34) : 0;
      const enderX = Math.round(145 + progress * 405 + arrivalOffset);
      const enderY = Math.round(442 + progress * -16);
      sprites.drawShadow(enderX, enderY, 2);
      sprites.draw('ender', enderX, enderY, {
        anchor: 'bottom-center',
        scale: 2,
        frame: Math.floor(now / 240) % 2,
      });

      sprites.drawShadow(612 + ioniaOffset, 416, 2);
      sprites.draw('ionia', 612 + ioniaOffset, 416, {
        anchor: 'bottom-center',
        scale: 2,
        frame: Math.floor(now / 300) % 2,
      });
    }

    // Closed-route board and foreground cable silhouettes.
    fill(37, 43, 48);
    rect(246, 338, 84, 58);
    fill(181, 103, 91, 180);
    for (let i = 0; i < 26; i++) {
      rect(258 + i * 2, 349 + Math.floor(i / 13) * 22, 2, 2);
    }
    stroke(181, 103, 91, 190);
    strokeWeight(3);
    line(258, 347, 318, 383);
    line(318, 347, 258, 383);
    stroke(8, 12, 18, 170);
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

  function drawInterior(scene, state, now) {
    noStroke();
    fill(14, 20, 29);
    rect(0, 0, width, height);

    // Structural ribs and deck planes.
    fill(32, 40, 48);
    rect(74, 98, width - 148, height - 166);
    fill(52, 58, 61);
    rect(91, 116, width - 182, height - 202);
    fill(25, 31, 37);
    rect(0, 420, width, 220);
    drawInteriorDepthFrame(now, 420);

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

    if (scene.id === 'wrong_song') {
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

    const sprites = root.AetherPixelSprites;
    if (sprites && sprites.validate() && scene.sequence >= 1) {
      const positions = {
        berth_task: [['ender', 305], ['ionia', 535]],
        lyra_family: [['ender', 285], ['lyra', 455], ['ionia', 590]],
        wrong_song: [['ender', 315], ['lyra', 514]],
        ionia_practical: [['ender', 270], ['lyra', 438], ['ionia', 596]],
        core_walk: [['ender', 310], ['lyra', 470]],
      };
      const actors = positions[scene.id] || [['ender', 310]];
      for (const [id, x] of actors) {
        sprites.drawShadow(x, 420, 2);
        sprites.draw(id, x, 420, {
          anchor: 'bottom-center',
          scale: 2,
          frame: Math.floor(now / 260) % 2,
        });
      }
    }

    if (scene.id === 'berth_task' && state.berthTask) {
      const step = state.berthTask.step;
      fill(42, 255, 181, 45 + step * 35);
      rect(185, 338, Math.max(8, step * 54), 4);
      fill(232, 220, 198, 180);
      textAlign(LEFT, TOP);
      textFont('VT323');
      textSize(14);
      text('BERTH WORK // ' + step + ' / ' + state.berthTask.max, 185, 383);
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
      fill(232, 220, 198, 180);
      textAlign(LEFT, TOP);
      textFont('VT323');
      textSize(14);
      text('TALEN // ' + talenStep + ' / ' + (state.talenBeat ? state.talenBeat.max : 2), 423, 392);
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
    textFont('VT323');
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

    noStroke();
    fill(8, 13, 20);
    rect(0, 0, width, height);

    // Hull frame.
    fill(24, 31, 38);
    rect(70, 94, width - 140, 432);
    fill(49, 54, 55);
    rect(90, 114, width - 180, 392);
    fill(31, 37, 42);
    rect(108, 132, width - 216, 354);

    // Connected interior floor ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â intentionally one readable space, not a corridor of cards.
    fill(72, 64, 54);
    rect(122, 145, 690, 330);
    fill(42, 47, 49);
    rect(136, 159, 662, 302);
    drawInteriorDepthFrame(now, 461);

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

    // Wrong Song distortion: small errors in otherwise stable architecture.
    if (scene.id === 'wrong_song' || e.anomalyTriggered) {
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

    const sprites = root.AetherPixelSprites;
    if (sprites && sprites.validate() && scene.sequence >= 1) {
      const ep = wakeMapPoint(e.x, e.y);
      sprites.drawShadow(ep.x, ep.y, 2);
      sprites.draw('ender', ep.x, ep.y, {
        anchor: 'bottom-center',
        scale: 2,
        frame: Math.floor(now / 220) % 2,
      });

      const lp = wakeMapPoint(7, 3);
      sprites.drawShadow(lp.x, lp.y, 2);
      sprites.draw('lyra', lp.x, lp.y, {
        anchor: 'bottom-center',
        scale: 2,
        frame: Math.floor(now / 310) % 2,
      });

      const ip = wakeMapPoint(12, 2);
      sprites.drawShadow(ip.x, ip.y, 2);
      sprites.draw('ionia', ip.x, ip.y, {
        anchor: 'bottom-center',
        scale: 2,
        frame: Math.floor(now / 290) % 2,
      });
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

    drawWakeRoomLabel('BERTH', 145, 443, view.zone === 'berth');
    drawWakeRoomLabel('TABLE', 145, 282, view.zone === 'shared-table');
    drawWakeRoomLabel('LYRA', 392, 282, view.zone === 'lyra-space');
    drawWakeRoomLabel('NAV', 590, 282, view.zone === 'navigation');
    drawWakeRoomLabel('MAINT', 392, 443, view.zone === 'maintenance');
    drawWakeRoomLabel('CORE', 651, 443, view.zone === 'core-approach');

    // Exploration HUD: objective, not a cutscene card.
    fill(5, 8, 13, 205);
    rect(84, 36, width - 168, 65);
    textAlign(LEFT, TOP);
    textFont('Press Start 2P');
    textSize(10);
    fill(42, 255, 181);
    text(view.objective, 108, 55, width - 216, 28);

    fill(5, 8, 13, 215);
    rect(106, 535, width - 212, 65);
    textFont('VT323');
    textSize(17);
    fill(232, 220, 198);
    text(view.lastMessage || 'Explore.', 128, 548, width - 256, 27);
    fill(185, 158, 116);
    textSize(14);
    const clueText = scene.id === 'core_walk'
      ? 'CLUES ' + e.clues.length + ' / 3  //  2 REQUIRED'
      : 'WASD / ARROWS MOVE   E INSPECT';
    text(clueText, 128, 575, width - 256, 20);

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
    if (scene.sequence <= 2) {
      drawDock(scene, state, now);
      return;
    }
    drawInterior(scene, state, now);
  }

  function draw(scene, state, ctx) {
    const now = ctx.now || 0;

    if (scene.sequence >= 5 && scene.sequence <= 8) {
      drawWakeExploration(scene, state, now);
      return true;
    }

    drawFrame(scene, state, now);

    // Cinematic framing.
    noStroke();
    fill(5, 8, 13, 150);
    rect(0, 0, width, 24);
    rect(0, height - 24, width, 24);

    const textPanelY = scene.chapterCard ? 92 : 58;
    fill(6, 9, 14, scene.chapterCard ? 150 : 152);
    rect(86, textPanelY, width - 172, scene.chapterCard ? 138 : 72);

    textAlign(CENTER, TOP);
    textFont('Press Start 2P');
    textSize(scene.chapterCard ? 24 : 12);
    fill(42, 255, 181);
    text(scene.title, width / 2, textPanelY + 24);

    if (scene.subtitle) {
      textSize(10);
      fill(124, 200, 232);
      text(scene.subtitle, width / 2, textPanelY + 65);
    }

    if (!scene.chapterCard) {
      fill(6, 9, 14, 218);
      rect(112, 468, width - 224, 124);

      textAlign(LEFT, TOP);
      textFont('VT323');
      textSize(18);
      fill(232, 220, 198);
      let y = 486;
      for (const line of scene.lines.slice(0, 3)) {
        text(line, 136, y, width - 272, 27);
        y += 30;
      }
    } else {
      textAlign(CENTER, TOP);
      textFont('VT323');
      textSize(20);
      fill(232, 220, 198, 220);
      text(scene.lines.join('   ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢   '), width / 2, 330, width - 250, 120);
    }

    textAlign(LEFT, BOTTOM);
    textFont('VT323');
    textSize(13);
    fill(185, 158, 116, 210);
    text('SEQUENCE ' + String(scene.sequence).padStart(2, '0'), 28, height - 31);

    textAlign(CENTER, BOTTOM);
    textSize(14);
    fill(185, 158, 116);
    text(
      'ACTIVE PARTY // ' + root.AetherFirstWakeOpening.expectedPartyIds(state).map(id => id.toUpperCase()).join(' + '),
      width / 2,
      height - 52
    );

    fill(42, 255, 181);
    const presentationReady = typeof root.AetherFirstWakeOpening.presentationReady === 'function'
      ? root.AetherFirstWakeOpening.presentationReady(state)
      : true;
    if (scene.id === 'dock_walk' && state.dockWalk && !state.dockWalk.ready) {
      text('A / D OR LEFT / RIGHT ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â WALK TO THE DRAGONFLY', width / 2, height - 29);
    } else if (scene.id === 'dock_walk') {
      text('ENTER ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â BOARD THE DRAGONFLY', width / 2, height - 29);
    } else if (scene.id === 'berth_task' && state.berthTask && !state.berthTask.ready) {
      text('E ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â WORK ON THE BERTH', width / 2, height - 29);
    } else if (scene.id === 'talen_staying' && state.talenBeat && !state.talenBeat.ready) {
      text('E ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â RESPOND TO TALEN', width / 2, height - 29);
    } else if (scene.cinematic && !presentationReady) {
      text('', width / 2, height - 29);
    } else {
      text('ENTER / SPACE ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â CONTINUE', width / 2, height - 29);
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
  });
})(typeof window !== 'undefined' ? window : globalThis);
