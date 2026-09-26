/* ============================================================
   Aetherwake — Representative Combat Visual Stage
   modules/combat-visual-stage.js

   Presentation-only combat staging. No combat resolution, resources,
   turn order, eligibility, or progression state lives here.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.3.0';
  const SKY_BATTLE_BACKGROUND_PATH = 'assets/preview/aetherwake-preview-battle-pixelart-v2.png';
  let skyBattleBackground = null;
  let skyBattleBackgroundRequested = false;
  let skyBattleBackgroundReady = false;

  function stage(width, height) {
    return Object.freeze({
      playerX: Math.round(width * 0.34),
      playerY: Math.round(height * 0.58),
      enemyX: Math.round(width * 0.72),
      enemyY: Math.round(height * 0.50),
      horizonY: Math.round(height * 0.47),
    });
  }

  function drawBackdrop(ctx) {
    const w = ctx.width;
    const h = ctx.height;
    const now = ctx.now || 0;
    const s = stage(w, h);
    const domain = ctx.domain === 'sky' ? 'sky' : 'ground';
    const weatherId = ctx.weatherId || 'clear';
    const altitude = ctx.altitude || 'cruise';

    noStroke();

    if (!skyBattleBackgroundRequested && typeof loadImage === 'function') {
      skyBattleBackgroundRequested = true;
      try {
        skyBattleBackground = loadImage(
          SKY_BATTLE_BACKGROUND_PATH,
          () => { skyBattleBackgroundReady = true; },
          () => { skyBattleBackground = null; }
        );
      } catch (error) {
        skyBattleBackground = null;
      }
    }
    const skyPredatorEncounter = ctx.enemy && ctx.enemy.type === 'skyPredator';
    if (skyBattleBackgroundReady && skyBattleBackground &&
        typeof image === 'function' && (domain === 'sky' || skyPredatorEncounter)) {
      push();
      noSmooth();
      const cover = Math.max(w / skyBattleBackground.width, h / skyBattleBackground.height);
      const drawWidth = skyBattleBackground.width * cover;
      const drawHeight = skyBattleBackground.height * cover;
      image(skyBattleBackground, (w - drawWidth) / 2, (h - drawHeight) / 2, drawWidth, drawHeight);
      pop();

      if (weatherId === 'crosswind') {
        stroke(205, 240, 244, 110);
        strokeWeight(1);
        for (let i = 0; i < 12; i++) {
          const yy = 92 + i * 38;
          const xx = Math.round((now * 0.06 + i * 101) % (w + 90)) - 45;
          line(xx, yy, xx + 48, yy - 7);
        }
        noStroke();
      } else if (weatherId === 'aether-squall') {
        fill(42, 255, 181, 110);
        for (let i = 0; i < 22; i++) {
          const xx = Math.round((i * 83 + now * 0.019) % w);
          const yy = 46 + ((i * 67) % Math.round(h * 0.78));
          rect(xx, yy, 2, 3);
        }
      }
      if (altitude === 'high') {
        fill(14, 21, 38, 35);
        rect(0, 0, w, Math.round(h * 0.22));
      } else if (altitude === 'low') {
        fill(205, 225, 230, 18);
        rect(0, Math.round(h * 0.42), w, Math.round(h * 0.2));
      }
      return;
    }

    // Pixel-banded sky gives the encounter a composed horizon rather than a
    // flat prototype field.
    const bands = [
      [15, 18, 37],
      [25, 31, 55],
      [39, 51, 76],
      [57, 75, 99],
      [76, 99, 121],
    ];
    const bandH = Math.ceil(s.horizonY / bands.length);
    for (let i = 0; i < bands.length; i++) {
      const c = bands[i];
      fill(c[0], c[1], c[2]);
      rect(0, i * bandH, w, bandH + 1);
    }

    // Far cloud banks.
    for (let layer = 0; layer < 3; layer++) {
      const y = Math.round(s.horizonY - 54 + layer * 28);
      const offset = Math.round((now * (0.002 + layer * 0.001) + layer * 71) % 150);
      fill(124 + layer * 16, 155 + layer * 12, 178 + layer * 10, 28 + layer * 14);
      for (let x = -160; x < w + 160; x += 120) {
        rect(x + offset, y, 82, 5 + layer * 2);
        rect(x + offset + 18, y - 4, 43, 4);
      }
    }

    // Distant island silhouettes make the battlefield belong to the same sky.
    fill(18, 24, 38, 205);
    rect(Math.round(w * 0.54), Math.round(h * 0.26), 72, 18);
    rect(Math.round(w * 0.57), Math.round(h * 0.26) + 18, 40, 5);
    rect(Math.round(w * 0.86), Math.round(h * 0.32), 58, 15);
    rect(Math.round(w * 0.88), Math.round(h * 0.32) + 15, 29, 4);

    if (domain === 'sky') {
      // Open-sky combat keeps the characters suspended above layered cloud seas.
      fill(86, 111, 134, 88);
      rect(0, s.horizonY, w, h - s.horizonY);
      fill(148, 169, 183, 55);
      rect(0, Math.round(h * 0.69), w, Math.round(h * 0.31));
      fill(205, 225, 230, 38);
      rect(0, Math.round(h * 0.82), w, Math.round(h * 0.18));

      if (weatherId === 'crosswind') {
        stroke(205, 225, 230, 72);
        strokeWeight(1);
        for (let i = 0; i < 12; i++) {
          const yy = 92 + i * 38;
          const xx = Math.round((now * 0.06 + i * 101) % (w + 90)) - 45;
          line(xx, yy, xx + 48, yy - 7);
        }
        noStroke();
      } else if (weatherId === 'aether-squall') {
        fill(42, 255, 181, 75);
        for (let i = 0; i < 22; i++) {
          const xx = Math.round((i * 83 + now * 0.019) % w);
          const yy = 46 + ((i * 67) % Math.round(h * 0.78));
          rect(xx, yy, 2, 3);
        }
      }

      // Altitude changes atmospheric openness.
      if (altitude === 'high') {
        fill(14, 21, 38, 42);
        rect(0, 0, w, Math.round(h * 0.34));
      } else if (altitude === 'low') {
        fill(205, 225, 230, 24);
        rect(0, Math.round(h * 0.42), w, Math.round(h * 0.26));
      }
    } else {
      // Ground encounter stage.
      fill(67, 52, 43);
      rect(0, s.horizonY, w, h - s.horizonY);
      fill(53, 43, 39);
      rect(0, Math.round(h * 0.66), w, Math.round(h * 0.34));
      fill(30, 29, 34);
      rect(0, Math.round(h * 0.83), w, Math.round(h * 0.17));

      stroke(118, 83, 58, 75);
      strokeWeight(1);
      for (let i = -2; i <= 7; i++) {
        const x = Math.round(w * 0.5 + i * 105);
        line(Math.round(w * 0.5), s.horizonY, x, h);
      }
      for (let y = s.horizonY + 28; y < h; y += 42) {
        line(0, y, w, y);
      }
      noStroke();
    }

    // Sparse stars/aether motes remain pixel blocks.
    fill(205, 225, 230, 90);
    for (let i = 0; i < 15; i++) {
      const x = Math.round((i * 137 + now * 0.004) % w);
      const y = 28 + ((i * 61) % Math.max(30, s.horizonY - 70));
      rect(x, y, 1, 1);
    }
  }

  function enemySpriteId(enemy) {
    if (!enemy) return null;
    if (enemy.type === 'skyPredator') return 'skyPredator';
    if (enemy.type === 'corporateSalvager') return 'corporateSalvager';
    if (enemy.type === 'engine_spirit') return 'engineSpirit';
    return null;
  }

  function drawSkyPredatorPulse(x, y, now, spriteFrame) {
    const phase = Math.floor((now || 0) / 260) % 4;
    const radius = 7 + phase * 2;
    // The eye sits at cell pixels (9,13) and (4,10) in the two 42×36
    // frames. Map those through the 2× bottom-center sprite draw origin.
    const centerX = x + (spriteFrame === 0 ? -23 : -33);
    const centerY = y + (spriteFrame === 0 ? -20 : -26);
    const points = [
      [0, -radius], [radius - 2, -radius], [radius, -radius + 2],
      [radius, 0], [radius, radius - 2], [radius - 2, radius],
      [0, radius], [-radius + 2, radius], [-radius, radius - 2],
      [-radius, 0], [-radius, -radius + 2], [-radius + 2, -radius],
    ];

    noStroke();
    fill(24, 29, 42, 220);
    for (const point of points) {
      rect(centerX + point[0] - 2, centerY + point[1] - 2, 4, 4);
    }

    fill(42, 255, 181, Math.round(220 - phase * 28));
    for (const point of points) {
      rect(centerX + point[0] - 1, centerY + point[1] - 1, 2, 2);
    }

    if (phase === 1 || phase === 3) {
      fill(255, 179, 71, 230);
      rect(centerX + radius - 1, centerY - 1, 2, 2);
      rect(centerX - radius - 1, centerY - 1, 2, 2);
    }
  }

  function drawPlayer(ctx) {
    const characters = root.AetherCharacterRenderer;
    const sprites = root.AetherPixelSprites;
    const x = Math.round(ctx.x);
    const y = Math.round(ctx.y + (ctx.dodgeBob || 0));
    const pulse = 0.75 + Math.sin((ctx.now || 0) * 0.004) * 0.25;

    // Grounded combat focus: a low elliptical contact pool and narrow rim light
    // frame Ender without placing a large translucent rectangle over the arena art.
    noStroke();
    fill(4, 9, 16, 78);
    ellipse(x, y + 8, 96, 18);
    fill(42, 255, 181, Math.round(12 * pulse));
    ellipse(x, y - 26, 78, 118);
    stroke(42, 255, 181, Math.round(55 * pulse));
    strokeWeight(1);
    line(x - 28, y + 3, x + 28, y + 3);
    noStroke();

    if (characters && characters.validate && characters.validate()) {
      characters.draw('ender', x, y + 7, {
        scale: 1.96,
        depth: 0.90,
        now: ctx.now || 0,
        speed: 0,
        facing: 'right',
        action: ctx.attacking ? 'attack' : (ctx.focused ? 'focus' : 'idle'),
        highlight: true,
      });
      return true;
    }

    if (!sprites || typeof (sprites.drawPreview || sprites.draw) !== 'function' || !sprites.validate()) return false;
    sprites.drawShadow(x, y + 5, 3, sprites.PREVIEW_WIDTH || 22);
    const drawPreview = sprites.drawPreview || sprites.draw;
    drawPreview.call(sprites, 'ender', x, y + 5, {
      anchor: 'bottom-center',
      scale: 3,
      frame: Math.floor((ctx.now || 0) / 220) % 2,
    });
    return true;
  }

  function drawEnemy(ctx) {
    const enemy = ctx.enemy;
    if (!enemy) return false;
    const sprites = root.AetherPixelSprites;
    const x = Math.round(ctx.x);
    const y = Math.round(ctx.y);
    const now = ctx.now || 0;
    const spriteFrame = Math.floor(now / 180) % 2;
    const hpRatio = enemy.maxHp > 0 ? Math.max(0, enemy.hp / enemy.maxHp) : 0;
    const danger = 1 - hpRatio;

    // Grounding shadow.
    noStroke();
    fill(0, 0, 0, 70);
    const shadowWidth = enemy.type === 'skyPredator' ? 92 : 68;
    rect(x - shadowWidth / 2, y + 25, shadowWidth, 7);

    const spriteId = enemySpriteId(enemy);
    const hasSpriteRenderer = sprites && (
      typeof sprites.drawBattleEnemy === 'function' ||
      typeof sprites.drawPreview === 'function' ||
      typeof sprites.draw === 'function'
    );
    if (spriteId && hasSpriteRenderer && sprites.validate()) {
      const scale = spriteId === 'skyPredator' ? 2 : 3;
      const drawEnemySprite = spriteId === 'skyPredator' && typeof sprites.drawBattleEnemy === 'function'
        ? sprites.drawBattleEnemy
        : (sprites.drawPreview || sprites.draw);
      drawEnemySprite.call(sprites, spriteId, x, y + 25, {
        anchor: 'bottom-center',
        scale,
        frame: spriteFrame,
      });
    } else if (enemy.type === 'windShear') {
      // Pixel pressure ribbons for the non-humanoid elemental.
      fill(124, 200, 232, 120);
      for (let i = 0; i < 5; i++) {
        const wobble = Math.round(Math.sin(now * 0.006 + i) * 7);
        rect(x - 34 + i * 10 + wobble, y - 28 + i * 10, 42 - i * 4, 4);
      }
      fill(205, 239, 241, 160);
      rect(x - 8, y - 8, 16, 16);
    } else {
      // Aether-wraith / compatibility fallback: intentionally block-authored.
      fill(42, 255, 181, 55);
      rect(x - 27, y - 31, 54, 57);
      fill(47, 97, 127, 170);
      rect(x - 17, y - 22, 34, 36);
      fill(124, 200, 232, 170);
      rect(x - 8, y - 13, 16, 17);
    }

    if (enemy.type === 'skyPredator') {
      drawSkyPredatorPulse(x, y, now, spriteFrame);
    }

    // Low-health fracture accents, visual only.
    if (danger > 0.5) {
      fill(255, 179, 71, Math.round(80 + danger * 80));
      rect(x - 21, y - 25, 2, 7);
      rect(x + 18, y - 6, 2, 9);
    }

    return true;
  }

  function drawTurnRail(ctx) {
    const w = ctx.width;
    const enemy = ctx.enemy;
    const turn = ctx.turn || 1;
    const domain = ctx.domain === 'sky' ? 'sky' : 'ground';
    const weatherId = ctx.weatherId || 'clear';
    const altitude = ctx.altitude || null;
    const pressure = Number.isFinite(ctx.encounterPressure) ? ctx.encounterPressure : 0;

    noStroke();
    fill(10, 13, 23, 205);
    rect(Math.round(w / 2 - 150), 18, 300, 33);
    fill(42, 255, 181, 135);
    rect(Math.round(w / 2 - 136), 27, 58, 2);
    rect(Math.round(w / 2 + 78), 27, 58, 2);

    textAlign(CENTER, TOP);
    textFont('Press Start 2P');
    textSize(8);
    fill(232, 220, 198, 210);
    const encounterLabel = domain === 'sky' ? 'SKY ENCOUNTER' : 'GROUND ENCOUNTER';
    text(encounterLabel + '  //  TURN ' + turn + (enemy ? '  //  ' + enemy.name.toUpperCase() : ''), w / 2, 26);

    if (domain === 'sky') {
      textFont('VT323');
      textSize(11);
      fill(124, 200, 232, 195);
      const telemetry = 'ALT ' + String(altitude || 'cruise').toUpperCase() +
        '  //  ' + String(weatherId).toUpperCase().replace('-', ' ') +
        '  //  PRESSURE ' + pressure;
      text(telemetry, w / 2, 43);
    }
    textAlign(LEFT, TOP);
  }

  const api = Object.freeze({
    VERSION,
    stage,
    drawBackdrop,
    drawPlayer,
    drawEnemy,
    drawTurnRail,
    enemySpriteId,
  });

  root.AetherCombatVisual = api;
})(typeof window !== 'undefined' ? window : globalThis);
