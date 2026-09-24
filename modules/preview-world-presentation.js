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
  const PIXEL_WORLD_BACKGROUND = 'assets/preview/aetherwake-preview-world-pixelart-v2.png';
  const PIXEL_WORLD_PROPS_ATLAS = 'assets/preview/aetherwake-preview-world-props-agent-v1.png';
  const PROP_CELL_SIZE = 64;
  const PROP_ATLAS_COLUMNS = 4;
  const PROP_ATLAS_ROWS = 3;
  const PROP_TILE_FOOTPRINT = PROP_CELL_SIZE / CELL;
  const SPRITE_WIDTH = 28;
  const SPRITE_HEIGHT = 36;
  const SPRITE_SCALE = 2;
  const TILE_IDS = Object.freeze({ 1: 'cliff', 2: 'meadow', 3: 'crate', 4: 'float', 5: 'water', 6: 'loreUnknown' });
  const INITIAL_ACTOR_CELLS = new Set(spriteFootprintCells(16, 16));
  const INITIAL_NPC_SPAWNS = Object.freeze([[7, 7], [22, 10], [8, 20], [26, 24]]);
  // Keep fixed opening spawn cells clear; props remain visible while actors walk through them.
  const FIXED_ACTOR_CELLS = new Set([
    ...INITIAL_ACTOR_CELLS,
    ...INITIAL_NPC_SPAWNS.flatMap(([x, y]) => spriteFootprintCells(x, y)),
  ]);
  const DECORATION_PATCHES = Object.freeze([
    Object.freeze({ x: 2, y: 10, width: 3, height: 3, tile: 'flowers' }),
    Object.freeze({ x: 5, y: 18, width: 3, height: 3, tile: 'grass' }),
    Object.freeze({ x: 17, y: 11, width: 3, height: 3, tile: 'flowers' }),
    Object.freeze({ x: 21, y: 18, width: 3, height: 3, tile: 'grass' }),
    Object.freeze({ x: 10, y: 24, width: 3, height: 3, tile: 'flowers' }),
    Object.freeze({ x: 25, y: 22, width: 3, height: 3, tile: 'grass' }),
  ]);
  const SCENIC_DETAILS = Object.freeze([
    // A small garden beside Lyra's northern story spot.
    Object.freeze({ x: 2, y: 7, tile: 'forest' }),
    Object.freeze({ x: 3, y: 7, tile: 'flowers' }),
    Object.freeze({ x: 4, y: 7, tile: 'forest' }),
    Object.freeze({ x: 2, y: 8, tile: 'flowers' }),
    Object.freeze({ x: 3, y: 8, tile: 'forest' }),
    Object.freeze({ x: 4, y: 8, tile: 'flowers' }),
    // A warm little sky-port landmark near the aether-core story point.
    Object.freeze({ x: 22, y: 12, tile: 'forest' }),
    Object.freeze({ x: 23, y: 12, tile: 'village' }),
    Object.freeze({ x: 24, y: 12, tile: 'forest' }),
    Object.freeze({ x: 22, y: 13, tile: 'flowers' }),
    Object.freeze({ x: 23, y: 13, tile: 'bridge' }),
    Object.freeze({ x: 24, y: 13, tile: 'flowers' }),
    // Frame the southern lore point with a forest ruin vignette.
    Object.freeze({ x: 10, y: 21, tile: 'forest' }),
    Object.freeze({ x: 11, y: 21, tile: 'ruins' }),
    Object.freeze({ x: 12, y: 21, tile: 'forest' }),
    Object.freeze({ x: 10, y: 22, tile: 'forest' }),
    Object.freeze({ x: 11, y: 22, tile: 'flowers' }),
    Object.freeze({ x: 12, y: 22, tile: 'forest' }),
  ]);
  const WORLD_PROPS = Object.freeze([
    Object.freeze({ x: 1, y: 25, column: 0, row: 0 }), // floating tree
    Object.freeze({ x: 27, y: 1, column: 2, row: 0 }), // ruin pillar
    Object.freeze({ x: 1, y: 18, column: 0, row: 1 }), // aether crystal
    Object.freeze({ x: 19, y: 25, column: 2, row: 1 }), // short bridge
    Object.freeze({ x: 26, y: 11, column: 0, row: 2 }), // lantern
    Object.freeze({ x: 11, y: 25, column: 2, row: 2 }), // mossy well
  ]);
  const TRANSPARENT_GROUND_TOKENS = new Set(['T']);
  const SPRITE_IDS = Object.freeze({
    elder_farmer: 'ionia', engine_spirit: 'engineSpirit',
    corporate_salvager: 'corporateSalvager', child_prophet: 'lyra',
  });

  let cachedGround = null;
  let cachedMap = null;
  let cachedNpcSignature = null;
  let lastPlayerTile = null;
  let lastPlayerMovementTime = -Infinity;
  let playerWalkStartedAt = null;
  let pixelWorldBackground = null;
  let pixelWorldBackgroundRequested = false;
  let pixelWorldBackgroundReady = false;
  let pixelWorldPropsAtlas = null;
  let pixelWorldPropsAtlasRequested = false;
  let pixelWorldPropsAtlasReady = false;

  function playerWalkFrame(player, now) {
    if (!Number.isFinite(player.tileX) || !Number.isFinite(player.tileY)) return 0;
    const tile = player.tileX + ',' + player.tileY;
    if (lastPlayerTile === null) {
      lastPlayerTile = tile;
      return 0;
    }
    if (tile !== lastPlayerTile) {
      const continuesWalking = now - lastPlayerMovementTime < 520;
      lastPlayerTile = tile;
      if (!continuesWalking || playerWalkStartedAt === null) {
        playerWalkStartedAt = now;
      }
      lastPlayerMovementTime = now;
    }
    if (now - lastPlayerMovementTime >= 520) {
      playerWalkStartedAt = null;
      return 0;
    }
    return playerWalkStartedAt === null
      ? 0
      : Math.floor((now - playerWalkStartedAt) / 130) % 2;
  }

  function drawIsland(x, y, w, h, tone) {
    noStroke();
    fill(tone[0], tone[1], tone[2]);
    rect(x, y, w, Math.max(4, h * 0.38));
    fill(Math.round(tone[0] * 0.82), Math.round(tone[1] * 0.82), Math.round(tone[2] * 0.88));
    rect(x + w * 0.12, y + h * 0.38, w * 0.76, h * 0.2);
    fill(37, 73, 117);
    rect(x + w * 0.28, y + h * 0.58, w * 0.44, h * 0.2);
    rect(x + w * 0.42, y + h * 0.78, w * 0.16, h * 0.16);
    fill(55, 187, 111);
    rect(x + w * 0.14, y - 3, w * 0.34, 4);
    rect(x + w * 0.57, y - 2, w * 0.22, 3);
    fill(174, 238, 172);
    rect(x + w * 0.2, y - 3, w * 0.08, 2);
    rect(x + w * 0.62, y - 2, w * 0.06, 2);
    // Warm hull seams and aether-light veins make each island feel inhabited.
    fill(223, 156, 77);
    rect(x + w * 0.31, y + h * 0.42, w * 0.19, 2);
    fill(60, 229, 218, 230);
    rect(x + w * 0.6, y + h * 0.63, Math.max(3, w * 0.025), h * 0.12);
    fill(111, 230, 247, 220);
    rect(x + w * 0.26, y + h * 0.55, Math.max(2, w * 0.035), h * 0.8);
  }

  function drawBackdrop(w, h, now) {
    if (!pixelWorldBackgroundRequested && typeof loadImage === 'function') {
      pixelWorldBackgroundRequested = true;
      try {
        pixelWorldBackground = loadImage(
          PIXEL_WORLD_BACKGROUND,
          () => { pixelWorldBackgroundReady = true; },
          () => { pixelWorldBackground = null; }
        );
      } catch (error) {
        pixelWorldBackground = null;
      }
    }
    if (pixelWorldBackgroundReady && pixelWorldBackground) {
      push();
      noSmooth();
      const cover = Math.max(w / pixelWorldBackground.width, h / pixelWorldBackground.height);
      const drawWidth = pixelWorldBackground.width * cover;
      const drawHeight = pixelWorldBackground.height * cover;
      image(pixelWorldBackground, (w - drawWidth) / 2, (h - drawHeight) / 2, drawWidth, drawHeight);
      pop();
      return;
    }

    noStroke();
    const bands = [
      [38, 88, 181], [43, 126, 216], [71, 180, 231],
      [177, 227, 237], [255, 222, 166],
    ];
    const bh = Math.ceil(h / bands.length);
    bands.forEach((c, i) => {
      fill(c[0], c[1], c[2]);
      rect(0, i * bh, w, bh + 1);
    });

    // Far islands and waterfalls establish the sky-island setting behind play.
    drawIsland(w * 0.06, h * 0.19, w * 0.25, h * 0.3, [98, 119, 190]);
    drawIsland(w * 0.65, h * 0.12, w * 0.28, h * 0.36, [56, 133, 166]);
    drawIsland(w * 0.4, h * 0.34, w * 0.14, h * 0.19, [127, 114, 190]);

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

  function tilePixels(image, tileId, dx, dy, tiles, frameIndex = 0, transparentTokens = null) {
    const tile = tiles.get(tileId) || tiles.get('meadow');
    if (!tile) return;
    const frame = tile.frames[frameIndex % tile.frames.length];
    for (let y = 0; y < CELL; y++) {
      for (let x = 0; x < CELL; x++) {
        const token = frame[y][x];
        if (token === '.' || (transparentTokens && transparentTokens.has(token))) continue;
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

  function terrainFrame(tileId, x, y, tiles) {
    const tile = tiles.get(tileId);
    if (!tile || tile.frames.length < 2) return 0;
    // Stable cell variation breaks up repeated grass and water without adding
    // randomness to route geometry or rebuilding the map every frame.
    let hash = Math.imul(x + 1, 374761393) ^ Math.imul(y + 1, 668265263);
    hash = Math.imul(hash ^ (hash >>> 13), 1274126177);
    return ((hash ^ (hash >>> 16)) >>> 0) % tile.frames.length;
  }

  function isObjectiveRouteBuffer(x, y) {
    for (let i = 0; i <= 8; i++) {
      const routeX = 15 - i;
      const routeY = 15 - i;
      if (Math.abs(x - routeX) <= 1 && Math.abs(y - routeY) <= 1) return true;
    }
    return false;
  }

  function spriteFootprintCells(tileX, tileY) {
    const cells = [];
    const width = SPRITE_WIDTH * SPRITE_SCALE;
    const height = SPRITE_HEIGHT * SPRITE_SCALE;
    const centerX = (tileX + 0.5) * CELL;
    const bottomY = (tileY + 1) * CELL;
    const left = Math.floor((centerX - width / 2) / CELL);
    const right = Math.floor((centerX + width / 2 - 1) / CELL);
    const top = Math.floor((bottomY - height) / CELL);
    const bottom = Math.floor((bottomY - 1) / CELL);
    for (let y = top; y <= bottom; y++) {
      for (let x = left; x <= right; x++) cells.push(x + ',' + y);
    }
    return cells;
  }

  function npcPositionSignature(npcs) {
    return (npcs || [])
      .filter(npc => npc && Number.isFinite(npc.tileX) && Number.isFinite(npc.tileY))
      .map(npc => (npc.id || '') + ':' + npc.tileX + ',' + npc.tileY)
      .sort()
      .join('|');
  }

  function actorCells(npcs) {
    const cells = new Set(INITIAL_ACTOR_CELLS);
    for (const npc of npcs || []) {
      if (!npc || !Number.isFinite(npc.tileX) || !Number.isFinite(npc.tileY)) continue;
      for (const key of spriteFootprintCells(npc.tileX, npc.tileY)) cells.add(key);
    }
    return cells;
  }

  function drawWorldProps(ground) {
    if (!pixelWorldPropsAtlasRequested && typeof loadImage === 'function') {
      pixelWorldPropsAtlasRequested = true;
      try {
        pixelWorldPropsAtlas = loadImage(
          PIXEL_WORLD_PROPS_ATLAS,
          () => { pixelWorldPropsAtlasReady = true; },
          () => { pixelWorldPropsAtlas = null; pixelWorldPropsAtlasReady = false; }
        );
      } catch (error) {
        pixelWorldPropsAtlas = null;
        pixelWorldPropsAtlasReady = false;
      }
    }
    if (!pixelWorldPropsAtlasReady || !pixelWorldPropsAtlas ||
        pixelWorldPropsAtlas.width !== PROP_ATLAS_COLUMNS * PROP_CELL_SIZE ||
        pixelWorldPropsAtlas.height !== PROP_ATLAS_ROWS * PROP_CELL_SIZE) return;

    noSmooth();
    for (const prop of WORLD_PROPS) {
      let safe = true;
      for (let y = prop.y; y < prop.y + PROP_TILE_FOOTPRINT && safe; y++) {
        for (let x = prop.x; x < prop.x + PROP_TILE_FOOTPRINT; x++) {
          const key = x + ',' + y;
          if (!ground[y] || resolveTile(ground[y][x]) !== 'meadow' ||
              FIXED_ACTOR_CELLS.has(key) || isObjectiveRouteBuffer(x, y)) {
            safe = false;
            break;
          }
        }
      }
      if (!safe) continue;
      image(
        pixelWorldPropsAtlas,
        prop.x * CELL, prop.y * CELL, PROP_CELL_SIZE, PROP_CELL_SIZE,
        prop.column * PROP_CELL_SIZE, prop.row * PROP_CELL_SIZE,
        PROP_CELL_SIZE, PROP_CELL_SIZE
      );
    }
  }

  function paintMeadowAccents(image, ground, tiles, protectedActorCells) {
    for (const patch of DECORATION_PATCHES) {
      const tile = tiles.get(patch.tile);
      if (!tile) continue;
      for (let y = patch.y; y < patch.y + patch.height; y++) {
        for (let x = patch.x; x < patch.x + patch.width; x++) {
          const key = x + ',' + y;
          const cell = ground[y] && ground[y][x];
          if (resolveTile(cell) !== 'meadow' || isObjectiveRouteBuffer(x, y) || protectedActorCells.has(key)) continue;
          const frame = (x + y) % tile.frames.length;
          tilePixels(image, patch.tile, x * CELL, y * CELL, tiles, frame, TRANSPARENT_GROUND_TOKENS);
        }
      }
    }
  }

  function paintScenicLandmarks(image, ground, tiles, protectedActorCells) {
    for (const detail of SCENIC_DETAILS) {
      const key = detail.x + ',' + detail.y;
      if (resolveTile(ground[detail.y] && ground[detail.y][detail.x]) !== 'meadow' ||
          isObjectiveRouteBuffer(detail.x, detail.y) || protectedActorCells.has(key)) continue;
      tilePixels(image, detail.tile, detail.x * CELL, detail.y * CELL, tiles, 0, TRANSPARENT_GROUND_TOKENS);
    }
  }

  function buildMap(ground, npcs) {
    const tiles = root.AetherPixelTiles;
    if (!tiles || typeof createImage !== 'function') return null;
    const img = createImage(MAP * CELL, MAP * CELL);
    img.loadPixels();
    for (let y = 0; y < MAP; y++) {
      for (let x = 0; x < MAP; x++) {
        const cell = ground[y] && ground[y][x];
        const tileId = resolveTile(cell);
        tilePixels(img, tileId, x * CELL, y * CELL, tiles, terrainFrame(tileId, x, y, tiles));
      }
    }

    const protectedActorCells = actorCells(npcs);
    // Add low-profile authored flowers and grass without changing collision or the Ionia route.
    paintMeadowAccents(img, ground, tiles, protectedActorCells);
    // Add small story landmarks from the shared tile set without changing collision.
    paintScenicLandmarks(img, ground, tiles, protectedActorCells);

    // A readable stepping-stone route guides the first walk toward Ionia.
    for (let i = 0; i <= 8; i++) {
      const x = 15 - i;
      const y = 15 - i;
      tilePixels(img, 'path', x * CELL, y * CELL, tiles);
    }
    img.updatePixels();
    return img;
  }

  function drawSprite(id, x, y, name, scale, frame = 0) {
    const sprites = root.AetherPixelSprites;
    if (!sprites || typeof sprites.draw !== 'function') return false;
    const spriteWidth = sprites.PREVIEW_WIDTH || SPRITE_WIDTH;
    const spriteHeight = sprites.PREVIEW_HEIGHT || SPRITE_HEIGHT;
    if (typeof sprites.drawShadow === 'function') {
      sprites.drawShadow(x + CELL / 2, y + CELL, scale, spriteWidth);
    }
    const drawPreview = sprites.drawPreview || sprites.draw;
    drawPreview.call(sprites, id, x + CELL / 2, y + CELL, {
      anchor: 'bottom-center',
      scale,
      frame,
    });
    if (name) {
      const spriteTop = y + CELL - spriteHeight * scale;
      noStroke();
      fill(20, 42, 57, 220);
      rect(x - 17, spriteTop - 14, 50, 12);
      fill(255, 250, 222);
      textAlign(CENTER, CENTER);
      textSize(9);
      textFont('VT323');
      text(name, x + 8, spriteTop - 8);
    }
    return true;
  }

  function draw(input) {
    if (!root.AetherPixelTiles || !root.AetherPixelSprites) return false;
    const w = input.width || width;
    const h = input.height || height;
    const now = input.now || 0;
    drawBackdrop(w, h, now);

    const npcs = input.npcs || [];
    const nextNpcSignature = npcPositionSignature(npcs);
    if (!cachedMap || cachedGround !== input.groundLayer || cachedNpcSignature !== nextNpcSignature) {
      cachedMap = buildMap(input.groundLayer || [], npcs);
      cachedGround = input.groundLayer;
      cachedNpcSignature = nextNpcSignature;
    }
    if (!cachedMap) return false;

    const zoom = 1.2;
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
    drawWorldProps(input.groundLayer || []);
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
    drawSprite('ender', player.px || 0, player.py || 0, 'Ender', 2, playerWalkFrame(player, now));

    for (const npc of npcs) {
      if (!npc || !Number.isFinite(npc.tileX) || !Number.isFinite(npc.tileY)) continue;
      const id = SPRITE_IDS[npc.id] || 'settler';
      const x = npc.tileX * CELL;
      const y = npc.tileY * CELL;
      drawSprite(id, x, y, npc.id === 'elder_farmer' ? 'Ionia' : '', 2);
      // Preview 0.1 opens on Ionia's first conversation; avoid duplicating the marker over every talkable NPC.
      if (npc.id === 'elder_farmer' && npc.flags && npc.flags.questMarker && !npc.flags.met) {
        const spriteHeight = root.AetherPixelSprites.PREVIEW_HEIGHT || SPRITE_HEIGHT;
        const markerY = y + CELL - spriteHeight * SPRITE_SCALE - 25;
        noStroke();
        fill(255, 211, 72);
        rect(x + 5, markerY, 7, 7);
        fill(255, 248, 205);
        rect(x + 7, markerY + 2, 3, 3);
      }
    }
    pop();
    return true;
  }

  function invalidate() {
    cachedGround = null;
    cachedMap = null;
    cachedNpcSignature = null;
  }

  root.AetherPreviewWorldPresentation = Object.freeze({
    VERSION,
    draw,
    drawScenicBackdrop: (w, h, now) => drawBackdrop(w || width, h || height, now || 0),
    invalidate,
  });
})(typeof window !== 'undefined' ? window : globalThis);
