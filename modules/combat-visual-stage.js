/* ============================================================
   Aetherwake — Representative Combat Visual Stage
   modules/combat-visual-stage.js

   Presentation-only combat staging. No combat resolution, resources,
   turn order, eligibility, or progression state lives here.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';

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

    noStroke();

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

    // Battle plane: three value bands create foreground depth.
    fill(67, 52, 43);
    rect(0, s.horizonY, w, h - s.horizonY);
    fill(53, 43, 39);
    rect(0, Math.round(h * 0.66), w, Math.round(h * 0.34));
    fill(30, 29, 34);
    rect(0, Math.round(h * 0.83), w, Math.round(h * 0.17));

    // Perspective deck/terrain seams.
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

  function drawPlayer(ctx) {
    const sprites = root.AetherPixelSprites;
    if (!sprites || typeof sprites.draw !== 'function' || !sprites.validate()) return false;
    const x = Math.round(ctx.x);
    const y = Math.round(ctx.y + (ctx.dodgeBob || 0));
    const pulse = 0.75 + Math.sin((ctx.now || 0) * 0.004) * 0.25;

    noStroke();
    fill(42, 255, 181, Math.round(22 * pulse));
    rect(x - 30, y - 54, 60, 58);

    sprites.drawShadow(x, y + 5, 3);
    sprites.draw('ender', x, y + 5, {
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
    const hpRatio = enemy.maxHp > 0 ? Math.max(0, enemy.hp / enemy.maxHp) : 0;
    const danger = 1 - hpRatio;

    // Grounding shadow.
    noStroke();
    fill(0, 0, 0, 70);
    rect(x - 34, y + 25, 68, 7);

    const spriteId = enemySpriteId(enemy);
    if (spriteId && sprites && typeof sprites.draw === 'function' && sprites.validate()) {
      const scale = spriteId === 'skyPredator' ? 4 : 3;
      sprites.draw(spriteId, x, y + 25, {
        anchor: 'bottom-center',
        scale,
        frame: Math.floor(now / 180) % 2,
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
    text('TURN ' + turn + (enemy ? '  //  ' + enemy.name.toUpperCase() : ''), w / 2, 26);
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
