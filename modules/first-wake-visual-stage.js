/* ============================================================
   Aetherwake — First Wake Visual Stage
   modules/first-wake-visual-stage.js

   Presentation-only renderer for Sequences 00–09.
   Reuses shared sprite and Dragonfly authorities; does not own story state.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';

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
    bandedSky([18, 24, 46], [55, 68, 101], [176, 125, 105]);
    cloudBands(now, 348, [212, 224, 229], 48);

    noStroke();
    fill(29, 35, 43);
    rect(0, 430, width, 210);
    fill(55, 65, 70);
    rect(0, 414, width, 20);

    for (let x = 34; x < width; x += 110) {
      fill(21, 26, 34);
      rect(x, 328, 10, 86);
      fill(92, 107, 111, 100);
      rect(x + 4, 332, 2, 82);
    }

    const dragonfly = root.AetherDragonflyVisual;
    if (dragonfly && typeof dragonfly.draw === 'function') {
      dragonfly.draw({
        mode: 'dock',
        x: Math.round(width * 0.72),
        y: 383,
        now,
        speed: 0,
        heading: 0
      });
    }

    const sprites = root.AetherPixelSprites;
    if (sprites && sprites.validate()) {
      let progress = 0;
      if (scene.id === 'dock_walk' && state && state.dockWalk) {
        progress = state.dockWalk.max > 0 ? state.dockWalk.x / state.dockWalk.max : 0;
      } else if (scene.sequence > 2) {
        progress = 1;
      }
      const enderX = Math.round(145 + progress * 405);
      sprites.drawShadow(enderX, 430, 2);
      sprites.draw('ender', enderX, 430, {
        anchor: 'bottom-center',
        scale: 2,
        frame: Math.floor(now / 240) % 2,
      });

      sprites.drawShadow(620, 430, 2);
      sprites.draw('ionia', 620, 430, {
        anchor: 'bottom-center',
        scale: 2,
        frame: Math.floor(now / 300) % 2,
      });
    }

    // Closed-route board — pixel-authored environmental storytelling.
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
    noStroke();
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
    if (sprites && sprites.validate()) {
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
    drawFrame(scene, state, now);

    // Cinematic framing.
    noStroke();
    fill(5, 8, 13, 150);
    rect(0, 0, width, 24);
    rect(0, height - 24, width, 24);

    const textPanelY = scene.chapterCard ? 92 : 52;
    fill(6, 9, 14, scene.chapterCard ? 150 : 205);
    rect(86, textPanelY, width - 172, scene.chapterCard ? 138 : 132);

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
      text(scene.lines.join('   •   '), width / 2, 330, width - 250, 120);
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
      text('A / D OR LEFT / RIGHT — WALK TO THE DRAGONFLY', width / 2, height - 29);
    } else if (scene.id === 'dock_walk') {
      text('ENTER — BOARD THE DRAGONFLY', width / 2, height - 29);
    } else if (scene.id === 'berth_task' && state.berthTask && !state.berthTask.ready) {
      text('E — WORK ON THE BERTH', width / 2, height - 29);
    } else if (scene.id === 'talen_staying' && state.talenBeat && !state.talenBeat.ready) {
      text('E — RESPOND TO TALEN', width / 2, height - 29);
    } else if (scene.cinematic && !presentationReady) {
      text('', width / 2, height - 29);
    } else {
      text('ENTER / SPACE — CONTINUE', width / 2, height - 29);
    }

    textAlign(LEFT, TOP);
    return true;
  }

  root.AetherFirstWakeVisual = Object.freeze({
    VERSION,
    draw,
    drawDock,
    drawInterior,
    drawChapter,
  });
})(typeof window !== 'undefined' ? window : globalThis);
