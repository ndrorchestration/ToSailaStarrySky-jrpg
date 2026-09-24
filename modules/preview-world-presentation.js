/* ============================================================
   Aetherwake — Preview 0.1 world presentation
   Scenic sky backdrop + cached pixel-tile map + shared character sprites.
   This module changes presentation only; movement and quest state stay in World.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';
  const CELL = 16;
  const MAP = 32;
  const TILE_IDS = Object.freeze({ 1: 'cliff', 2: 'meadow', 3: 'crate', 4: 'forest', 5: 'shore', 6: 'ruins' });
  const SPRITE_IDS = Object.freeze({
    elder_farmer: 'ionia', engine_spirit: 'engineSpirit',
    corporate_salvager: 'corporateSalvager', child_prophet: 'settler',
  });

  let cachedGround = null;
  let cachedMap = null;

  function drawIsland(x, y, w, h, tone) {
    noStroke();
    fill(tone[0], tone[1], tone[2]);
    rect(x, y, w, Math.max(4, h * 0.38));
    rect(x + w * 0.12, y + h * 0.38, w * 0.76, h * 0.2);
    rect(x + w * 0.28, y + h * 0.58, w * 0.44, h * 0.2);
    rect(x + w * 0.42, y + h * 0.78, w * 0.16, h * 0.16);
    fill(76, 176, 78);
    rect(x + w * 0.14, y - 3, w * 0.34, 4);
    rect(x + w * 0.57, y - 2, w * 0.22, 3);
    fill(91, 215, 235, 190);
    rect(x + w * 0.26, y + h * 0.55, Math.max(2, w * 0.035), h * 0.8);
  }

  function drawBackdrop(w, h, now) {
    noStroke();
    const bands = [
      [67, 174, 244], [91, 197, 249], [145, 224, 250],
      [207, 244, 251], [229, 247, 242],
    ];
    const bh = Math.ceil(h / bands.length);
    bands.forEach((c, i) => {
      fill(c[0], c[1], c[2]);
      rect(0, i * bh, w, bh + 1);
    });

    // Far islands and waterfalls establish the sky-island setting behind play.
    drawIsland(w * 0.06, h * 0.19, w * 0.25, h * 0.3, [113, 135, 166]);
    drawIsland(w * 0.65, h * 0.12, w * 0.28, h * 0.36, [117, 143, 172]);
    drawIsland(w * 0.4, h * 0.34, w * 0.14, h * 0.19, [135, 154, 175]);

    // Layered block clouds move gently, retaining crisp pixel edges.
    for (let layer = 0; layer < 3; layer++) {
      const y = Math.round(h * (0.17 + layer * 0.16));
      const drift = Math.round((now * (0.004 + layer * 0.002)) % 190);
      fill(245, 253, 255, 180 - layer * 24);
      for (let x = -210; x < w + 210; x += 185) {
        const xx = x + drift;
        rect(xx, y, 78, 9);
        rect(xx + 18, y - 6, 52, 7);
        rect(xx + 41, y + 8, 58, 5);
      }
    }
    fill(255, 231, 138, 190);
    rect(w * 0.83, h * 0.08, 34, 34);
    fill(255, 246, 192, 130);
    rect(w * 0.83 - 7, h * 0.08 - 7, 48, 48);
  }

  function resolveTile(value) {
    if (value && typeof value === 'object' && Number.isFinite(value.type)) value = value.type;
    return TILE_IDS[value] || 'meadow';
  }

  function tilePixels(image, tileId, dx, dy, tiles) {
    const tile = tiles.get(tileId) || tiles.get('meadow');
    if (!tile) return;
    const frame = tile.frames[0];
    for (let y = 0; y < CELL; y++) {
      for (let x = 0; x < CELL; x++) {
        const token = frame[y][x];
        if (token === '.') continue;
        const rgb = tiles.PALETTE[token];
        if (!rgb) continue;
        const at = ((dy + y) * image.width + dx + x) * 4;
        image.pixels[at] = rgb[0];
        image.pixels[at + 1] = rgb[1];
        image.pixels[at + 2] = rgb[2];
        image.pixels[at + 3] = 255;
      }
    }
  }

  function buildMap(ground) {
    const tiles = root.AetherPixelTiles;
    if (!tiles || typeof createImage !== 'function') return null;
    const img = createImage(MAP * CELL, MAP * CELL);
    img.loadPixels();
    for (let y = 0; y < MAP; y++) {
      for (let x = 0; x < MAP; x++) {
        const cell = ground[y] && ground[y][x];
        tilePixels(img, resolveTile(cell), x * CELL, y * CELL, tiles);
      }
    }

    // A readable stepping-stone route guides the first walk toward Ionia.
    for (let i = 0; i <= 8; i++) {
      const x = 15 - i;
      const y = 15 - i;
      tilePixels(img, 'path', x * CELL, y * CELL, tiles);
    }
    img.updatePixels();
    return img;
  }

  function drawSprite(id, x, y, name, scale) {
    const sprites = root.AetherPixelSprites;
    if (!sprites || typeof sprites.draw !== 'function') return false;
    sprites.draw(id, x + CELL / 2, y + CELL, {
      anchor: 'bottom-center',
      scale,
      frame: Math.floor(frameCount / 14) % 2,
    });
    if (name) {
      noStroke();
      fill(20, 42, 57, 220);
      rect(x - 10, y - 11, 36, 9);
      fill(255, 250, 222);
      textAlign(CENTER, CENTER);
      textSize(8);
      textFont('VT323');
      text(name, x + 8, y - 7);
    }
    return true;
  }

  function draw(input) {
    if (!root.AetherPixelTiles || !root.AetherPixelSprites) return false;
    const w = input.width || width;
    const h = input.height || height;
    const now = input.now || 0;
    drawBackdrop(w, h, now);

    if (!cachedMap || cachedGround !== input.groundLayer) {
      cachedMap = buildMap(input.groundLayer || []);
      cachedGround = input.groundLayer;
    }
    if (!cachedMap) return false;

    const zoom = 1.25;
    const player = input.player || { px: 16 * CELL, py: 16 * CELL };
    const focusX = Number.isFinite(player.px) ? player.px + CELL / 2 : 16 * CELL;
    const focusY = Number.isFinite(player.py) ? player.py + CELL / 2 : 16 * CELL;
    const cameraX = Math.round(w / 2 - focusX * zoom);
    const cameraY = Math.round(h / 2 - focusY * zoom);

    push();
    translate(cameraX, cameraY);
    scale(zoom);
    noSmooth();
    image(cachedMap, 0, 0, MAP * CELL, MAP * CELL);
    const field = input.covenantField;
    if (field && field.planted) {
      const cx = field.x * CELL + 8;
      const cy = field.y * CELL + 8;
      fill(63, 255, 190, 190);
      for (let i = 0; i < 12; i++) {
        const angle = (i / 12) * Math.PI * 2 + now * 0.0004;
        const r = 12 + Math.sin(now * 0.004 + i) * 2;
        rect(Math.round(cx + Math.cos(angle) * r), Math.round(cy + Math.sin(angle) * r), 2, 2);
      }
    }
    drawSprite('ender', player.px || 0, player.py || 0, 'Ender', 2);

    for (const npc of input.npcs || []) {
      if (!npc || !Number.isFinite(npc.tileX) || !Number.isFinite(npc.tileY)) continue;
      const id = SPRITE_IDS[npc.id] || 'settler';
      const x = npc.tileX * CELL;
      const y = npc.tileY * CELL;
      drawSprite(id, x, y, npc.id === 'elder_farmer' ? 'Ionia' : '', 2);
      if (npc.flags && npc.flags.questMarker) {
        noStroke();
        fill(255, 211, 72);
        rect(x + 5, y - 20, 7, 7);
        fill(255, 248, 205);
        rect(x + 7, y - 18, 3, 3);
      }
    }
    pop();
    return true;
  }

  function invalidate() {
    cachedGround = null;
    cachedMap = null;
  }

  root.AetherPreviewWorldPresentation = Object.freeze({
    VERSION,
    draw,
    drawScenicBackdrop: (w, h, now) => drawBackdrop(w || width, h || height, now || 0),
    invalidate,
  });
})(typeof window !== 'undefined' ? window : globalThis);
