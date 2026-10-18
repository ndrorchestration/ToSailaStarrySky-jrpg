/* ============================================================
   Aetherwake — Preview 0.1 world presentation
   Scenic sky backdrop + cached pixel-tile map + shared character sprites.
   This module changes presentation only; movement and quest state stay in World.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.3.0';
  const CELL = 16;
  const MAP = 32;
  const PIXEL_WORLD_BACKGROUND = 'assets/preview/aetherwake-preview-world-pixelart-v2.png';
  const USE_PAINTED_WORLD_BACKDROP = true;
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
    fill(tone[0], tone[1], tone[2], 235);
    beginShape();
    vertex(x + w * 0.06, y + h * 0.18);
    vertex(x + w * 0.2, y + h * 0.03);
    vertex(x + w * 0.78, y);
    vertex(x + w * 0.96, y + h * 0.16);
    vertex(x + w * 0.84, y + h * 0.42);
    vertex(x + w * 0.64, y + h * 0.62);
    vertex(x + w * 0.51, y + h * 0.96);
    vertex(x + w * 0.38, y + h * 0.64);
    vertex(x + w * 0.18, y + h * 0.46);
    endShape(CLOSE);

    fill(66, 139, 87, 220);
    ellipse(x + w * 0.36, y + h * 0.13, w * 0.46, h * 0.18);
    ellipse(x + w * 0.68, y + h * 0.12, w * 0.28, h * 0.13);

    fill(205, 238, 245, 150);
    const fallX = x + w * 0.63;
    rect(fallX, y + h * 0.15, Math.max(2, w * 0.018), h * 0.64, 2);
    fill(205, 238, 245, 45);
    ellipse(fallX, y + h * 0.84, w * 0.12, h * 0.1);

    fill(222, 169, 88, 180);
    ellipse(x + w * 0.3, y + h * 0.22, 4, 4);
    ellipse(x + w * 0.76, y + h * 0.18, 3, 3);
  }

  function drawBackdrop(w, h, now) {
    if (USE_PAINTED_WORLD_BACKDROP && !pixelWorldBackgroundRequested && typeof loadImage === 'function') {
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
    if (USE_PAINTED_WORLD_BACKDROP && pixelWorldBackgroundReady && pixelWorldBackground) {
      push();
      noSmooth();
      const cover = Math.max(w / pixelWorldBackground.width, h / pixelWorldBackground.height);
      const drawWidth = pixelWorldBackground.width * cover;
      const drawHeight = pixelWorldBackground.height * cover;
      image(pixelWorldBackground, (w - drawWidth) / 2, (h - drawHeight) / 2, drawWidth, drawHeight);
      pop();
      // Keep the projected playable island legible over the high-detail plate.
      noStroke();
      fill(42, 72, 82, 24);
      rect(0, 0, w, h);
      fill(245, 211, 153, 10);
      rect(0, Math.round(h * 0.45), w, Math.round(h * 0.55));
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

    // Layered cloud masses move gently at different depths.
    smooth();
    for (let layer = 0; layer < 3; layer++) {
      const y = h * (0.18 + layer * 0.17);
      const drift = (now * (0.004 + layer * 0.002)) % 230;
      fill(245, 253, 255, 115 - layer * 20);
      for (let x = -260; x < w + 260; x += 220) {
        const xx = x + drift;
        ellipse(xx, y, 150, 32);
        ellipse(xx + 52, y - 10, 105, 34);
        ellipse(xx + 102, y + 6, 135, 27);
      }
    }
    fill(255, 226, 147, 210);
    ellipse(w * 0.84, h * 0.11, 42, 42);
    fill(255, 244, 194, 70);
    ellipse(w * 0.84, h * 0.11, 88, 88);
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
      textFont('Trebuchet MS');
      text(name, x + 8, spriteTop - 8);
    }
    return true;
  }

  function projectWorldPoint(worldX, worldY, focusX, focusY, w, h) {
    const centerX = w * 0.5;
    const centerY = h * 0.69;
    const dx = worldX - focusX;
    const dy = worldY - focusY;
    // Close three-quarter camera: only the local neighborhood is visible.
    // Logical map edges stay off-screen so the world reads as a place,
    // not a board displayed in its entirety.
    return {
      x: centerX + dx * 2.85 + dy * 0.34,
      y: centerY - dx * 0.10 + dy * 1.38,
    };
  }

  function drawProjectedSprite(id, tileX, tileY, name, focusX, focusY, w, h, scale, frame) {
    const authored = root.AetherAuthoredCharacterArt;
    const characters = root.AetherCharacterRenderer;
    const sprites = root.AetherPixelSprites;
    const worldX = tileX * CELL + CELL / 2;
    const worldY = tileY * CELL + CELL;
    const p = projectWorldPoint(worldX, worldY, focusX, focusY, w, h);
    const depth = Math.max(0.12, Math.min(0.95, 0.55 + (p.y - h * 0.58) / 620));
    const protagonist = ['ender','reson','aepex','ionia','lyra'].includes(id);

    // Production-facing exploration now prefers the reviewed pixel candidate sheets
    // as an explicitly provisional fallback until full 64x96 field packs are admitted.
    // This changes presentation only; readiness remains NOT_READY.
    let provisionalDrawn = false;
    if (protagonist && authored && typeof authored.drawProvisionalFieldCharacter === 'function') {
      provisionalDrawn = authored.drawProvisionalFieldCharacter(id, p.x, p.y, {
        anchor: 'bottom-center',
        scale: Math.max(1.6, scale * 1.55),
        action: frame ? 'walk' : 'idle',
        frame: frame || 0,
      });
    }

    const modernCharacter = !provisionalDrawn && characters && characters.validate && characters.validate() && protagonist;
    if (modernCharacter) {
      characters.draw(id, p.x, p.y, {
        scale: Math.max(0.76, scale * 0.78),
        depth,
        now: typeof millis === 'function' ? millis() : 0,
        speed: frame ? 0.72 : 0,
        facing: 'right',
        highlight: name === 'Ender',
      });
    } else if (!provisionalDrawn && sprites && typeof sprites.draw === 'function') {
      const spriteScale = scale * Math.max(0.86, Math.min(1.16, 1 + (p.y - h * 0.58) / 900));
      if (typeof sprites.drawShadow === 'function') {
        sprites.drawShadow(p.x, p.y, spriteScale, sprites.PREVIEW_WIDTH || SPRITE_WIDTH);
      }
      const drawPreview = sprites.drawPreview || sprites.draw;
      drawPreview.call(sprites, id, p.x, p.y, {
        anchor: 'bottom-center', scale: spriteScale, frame: frame || 0,
      });
    } else if (!provisionalDrawn) {
      return false;
    }

    // Protagonists are identified by portrait/sprite continuity, not floating debug-style nameplates.
    if (name && !protagonist) {
      noStroke();
      fill(9, 13, 24, 190);
      rect(p.x - 34, p.y - 96, 68, 15, 3);
      fill(238, 228, 207, 235);
      textAlign(CENTER, CENTER);
      textSize(10);
      textFont('sans-serif');
      text(name, p.x, p.y - 88);
    }
    return true;
  }

  function drawProjectedTerrainMass(focusX, focusY, w, h, reducedDetail = false) {
    const corners = [
      projectWorldPoint(0, 0, focusX, focusY, w, h),
      projectWorldPoint(MAP * CELL, 0, focusX, focusY, w, h),
      projectWorldPoint(MAP * CELL, MAP * CELL, focusX, focusY, w, h),
      projectWorldPoint(0, MAP * CELL, focusX, focusY, w, h),
    ];
    const drop = 52;

    // Only the near/right cliff faces are drawn. The logical map remains flat;
    // these faces are a visual extrusion that gives the island measurable mass.
    noStroke();
    fill(29, 40, 49, 220);
    beginShape();
    vertex(corners[2].x, corners[2].y);
    vertex(corners[3].x, corners[3].y);
    vertex(corners[3].x, corners[3].y + drop);
    vertex(corners[2].x, corners[2].y + drop);
    endShape(CLOSE);

    fill(20, 31, 42, 225);
    beginShape();
    vertex(corners[1].x, corners[1].y);
    vertex(corners[2].x, corners[2].y);
    vertex(corners[2].x, corners[2].y + drop);
    vertex(corners[1].x, corners[1].y + drop);
    endShape(CLOSE);

    // Broken vertical strata and aether seams stop the extrusion reading as a
    // single flat slab while remaining independent of collision geometry.
    stroke(105, 92, 72, 95);
    strokeWeight(2);
    for (let i = 1; i < 7; i++) {
      const t = i / 7;
      const x = corners[3].x + (corners[2].x - corners[3].x) * t;
      const y = corners[3].y + (corners[2].y - corners[3].y) * t;
      line(x, y + 4, x, y + drop - 5);
    }
    stroke(42, 255, 181, 58);
    strokeWeight(1);
    line(corners[3].x + 34, corners[3].y + 17, corners[3].x + 34, corners[3].y + drop - 7);
    line(corners[2].x - 58, corners[2].y + 11, corners[2].x - 58, corners[2].y + drop - 10);
    noStroke();

    if (!reducedDetail) {
      // Non-benchmark horizon integration: a thin grass lip, broken stone shelf,
      // and sparse hanging growth soften the projected crown/painterly-sky seam.
      const left = corners[3];
      const right = corners[2];
      stroke(118, 154, 92, 125);
      strokeWeight(3);
      line(left.x, left.y - 1, right.x, right.y - 1);
      stroke(189, 198, 151, 55);
      strokeWeight(1);
      for (let i = 1; i < 10; i++) {
        const t = i / 10;
        const x = left.x + (right.x - left.x) * t;
        const y = left.y + (right.y - left.y) * t;
        const len = 6 + (i % 3) * 4;
        line(x, y + 3, x + ((i % 2) ? 2 : -2), y + len);
      }
      noStroke();
      for (let i = 0; i < 5; i++) {
        const t = (i + 0.7) / 5.8;
        const x = left.x + (right.x - left.x) * t;
        const y = left.y + (right.y - left.y) * t;
        fill(57, 71, 62, 105);
        quad(x - 18, y + 9, x + 16, y + 7, x + 11, y + 15, x - 14, y + 17);
        fill(93, 123, 77, 78);
        ellipse(x, y + 4, 22, 7);
      }
    }
  }

  function drawProjectedForeground(w, h, now) {
    // Close cloud wisps and dark structural silhouettes establish a camera-side
    // layer. They never alter logical world coordinates or hide the center path.
    const drift = Math.round((now * 0.009) % 150);
    noStroke();
    fill(226, 239, 242, 40);
    for (let x = -170; x < w + 170; x += 190) {
      const xx = x + drift;
      if (xx > w * 0.33 && xx < w * 0.67) continue;
      rect(xx, h - 104, 126, 9);
      rect(xx + 28, h - 115, 72, 8);
      rect(xx + 51, h - 93, 98, 6);
    }

    fill(7, 11, 18, 170);
    beginShape();
    vertex(0, h);
    vertex(0, h - 72);
    vertex(28, h - 98);
    vertex(61, h - 57);
    vertex(92, h);
    endShape(CLOSE);
    beginShape();
    vertex(w, h);
    vertex(w, h - 66);
    vertex(w - 24, h - 91);
    vertex(w - 58, h - 54);
    vertex(w - 88, h);
    endShape(CLOSE);

    // Camera-side vegetation and masonry silhouettes create a third depth plane
    // without touching the dock benchmark path or logical collision geometry.
    const clumps = [
      [34, h-48, 54, 25], [102, h-31, 68, 20], [w-42, h-45, 58, 24], [w-115, h-28, 72, 18]
    ];
    for (let i = 0; i < clumps.length; i++) {
      const [cx,cy,cw,ch] = clumps[i];
      fill(17, 35, 28, 185);
      ellipse(cx, cy, cw, ch);
      fill(53, 86, 54, 105);
      ellipse(cx + (i % 2 ? -10 : 9), cy - 7, cw * 0.56, ch * 0.62);
    }
    fill(41, 48, 52, 205);
    rect(0, h - 18, 138, 18);
    rect(w - 126, h - 16, 126, 16);
    fill(113, 105, 84, 80);
    rect(12, h - 21, 94, 3);
    rect(w - 104, h - 19, 82, 3);

    // Sparse foreground aether motes bridge the playable plane to the painted sky.
    const motePulse = 0.5 + 0.5 * Math.sin((Number(now) || 0) * 0.003);
    fill(42, 255, 181, 34 + motePulse * 22);
    for (const [mx,my] of [[76,h-126],[148,h-92],[w-92,h-118],[w-166,h-82]]) {
      ellipse(mx, my, 3, 3);
    }
  }

  function drawDimensionalGround(input, now, reducedDetail = false) {
    const ground = input.groundLayer || [];
    const t = Number(now) || 0;

    const island = [
      [CELL*1.1,CELL*5.1],[CELL*3.2,CELL*2.0],[CELL*8.4,CELL*1.25],
      [CELL*13.2,CELL*2.15],[CELL*18.7,CELL*1.0],[CELL*24.8,CELL*2.2],
      [CELL*30.3,CELL*5.4],[CELL*30.9,CELL*11.7],[CELL*29.6,CELL*17.4],
      [CELL*30.6,CELL*24.8],[CELL*27.5,CELL*29.8],[CELL*21.2,CELL*30.5],
      [CELL*16.4,CELL*29.1],[CELL*11.0,CELL*30.6],[CELL*5.1,CELL*28.8],
      [CELL*1.7,CELL*24.2],[CELL*2.4,CELL*18.3],[CELL*0.9,CELL*12.2]
    ];

    // Dark under-rim first, then the green playable crown. Logical tiles remain
    // authoritative; this is only a continuous 2.5D skin over them.
    noStroke();
    fill(41, 49, 47);
    beginShape();
    for (const [x,y] of island) vertex(x, y + CELL*0.75);
    endShape(CLOSE);

    if (reducedDetail) fill(53, 61, 61);
    else fill(74, 111, 80);
    beginShape();
    for (const [x,y] of island) vertex(x, y);
    endShape(CLOSE);

    // Sun-facing crown highlight and shaded far shelf. Benchmark/dock mode uses
    // reclaimed slate/timber tones so the playable plane reads as a working port,
    // not a giant green board laid over the authored sky world.
    if (reducedDetail) fill(126, 111, 82, 54);
    else fill(105, 139, 93, 86);
    beginShape();
    vertex(CELL*3.0,CELL*6.2); vertex(CELL*8.5,CELL*2.3);
    vertex(CELL*18.7,CELL*2.1); vertex(CELL*26.9,CELL*4.4);
    vertex(CELL*24.2,CELL*8.0); vertex(CELL*12.0,CELL*7.4);
    endShape(CLOSE);
    if (reducedDetail) fill(28, 39, 43, 96);
    else fill(42, 78, 62, 75);
    beginShape();
    vertex(CELL*2.0,CELL*22.4); vertex(CELL*8.0,CELL*26.8);
    vertex(CELL*17.2,CELL*28.8); vertex(CELL*27.9,CELL*25.4);
    vertex(CELL*28.6,CELL*29.1); vertex(CELL*12.0,CELL*31.0);
    endShape(CLOSE);

    // Low-cost material breakup: authored grass shelves, stone service pads,
    // and cliff-edge flecks stop the playable crown reading as one flat green polygon.
    // Counts are intentionally bounded so the projected world remains inside the visual budget.
    const grassPatches = reducedDetail ? 0 : 12;
    noStroke();
    for (let i = 0; i < grassPatches; i++) {
      const gx = CELL * (3.4 + ((i * 7) % 25));
      const gy = CELL * (4.1 + ((i * 11) % 23));
      const gw = CELL * (2.0 + (i % 4) * 0.55);
      const gh = CELL * (0.65 + (i % 3) * 0.18);
      fill(96 + (i % 3) * 6, 137 + (i % 4) * 5, 88 + (i % 2) * 5, reducedDetail ? 30 : 42);
      ellipse(gx, gy, gw, gh);
    }

    // Three stone/service islands add hard material contrast near travel routes.
    const pads = [
      [CELL*8.0,CELL*19.6,CELL*4.5,CELL*1.4],
      [CELL*18.4,CELL*10.8,CELL*4.2,CELL*1.25],
      [CELL*24.2,CELL*21.1,CELL*3.8,CELL*1.15],
    ];
    for (let i = 0; i < pads.length; i++) {
      const [px,py,pw,ph] = pads[i];
      fill(74,84,78,reducedDetail ? 48 : 64); ellipse(px,py,pw,ph);
      fill(137,139,116,reducedDetail ? 28 : 40); ellipse(px-CELL*0.35,py-CELL*0.10,pw*0.58,ph*0.40);
    }

    // Broken rim accents imply grass over stone without tracing every edge.
    stroke(133,145,108,reducedDetail ? 36 : 52);
    strokeWeight(1.2);
    const rimMarks = reducedDetail ? 5 : 14;
    for (let i = 0; i < rimMarks; i++) {
      const x = CELL * (2.2 + ((i * 13) % 28));
      const y = CELL * (27.2 + ((i * 5) % 3));
      line(x,y,x+CELL*(0.45+(i%3)*0.12),y-CELL*0.12);
    }
    noStroke();

    // Curved travel routes read like worn ground rather than rectangular strips.
    noFill();
    stroke(111, 91, 65, 190);
    strokeWeight(CELL*1.55);
    bezier(CELL*2.8,CELL*26.3, CELL*8.5,CELL*21.4, CELL*18.4,CELL*19.2, CELL*29.0,CELL*7.1);
    bezier(CELL*4.0,CELL*8.2, CELL*10.0,CELL*12.0, CELL*21.3,CELL*12.9, CELL*28.0,CELL*23.2);
    stroke(201, 177, 129, 82);
    strokeWeight(CELL*0.36);
    bezier(CELL*2.8,CELL*26.3, CELL*8.5,CELL*21.4, CELL*18.4,CELL*19.2, CELL*29.0,CELL*7.1);
    bezier(CELL*4.0,CELL*8.2, CELL*10.0,CELL*12.0, CELL*21.3,CELL*12.9, CELL*28.0,CELL*23.2);

    // Raised garden terraces give local landmarks and vertical rhythm.
    noStroke();
    const terraces = reducedDetail ? [] : [
      [CELL*5.2,CELL*7.1,CELL*6.2,CELL*3.0],
      [CELL*20.6,CELL*6.2,CELL*6.0,CELL*3.4],
      [CELL*22.0,CELL*22.0,CELL*5.4,CELL*3.1]
    ];
    for (let i=0;i<terraces.length;i++) {
      const [x,y,tw,th]=terraces[i];
      fill(48,65,55,145); ellipse(x,y+CELL*0.36,tw,th);
      fill(83 + i*5,128 + i*4,83,170); ellipse(x,y,tw,th);
      fill(137,167,99,78); ellipse(x-CELL*0.45,y-CELL*0.18,tw*0.56,th*0.42);
    }

    // Broad vegetation patches and tree clusters break the open platform read.
    noStroke();
    for (let i = 0; i < (reducedDetail ? 0 : 24); i++) {
      const x = CELL * (2.8 + ((i * 11) % 26));
      const y = CELL * (3.1 + ((i * 17) % 25));
      const sway = Math.sin(t * 0.0018 + i) * 2;
      fill(46 + (i % 3) * 7, 104 + (i % 4) * 7, 64 + (i % 2) * 9, 115);
      ellipse(x + sway, y, 30 + (i % 5) * 6, 15 + (i % 4) * 4);
    }
    const trees = reducedDetail ? [] : [[4,5],[7,6],[24,5],[27,8],[5,24],[25,25],[28,21],[10,27]];
    for (let i=0;i<trees.length;i++) {
      const [tx,ty]=trees[i]; const x=tx*CELL, y=ty*CELL;
      fill(77,62,45,210); rect(x-2,y-10,4,12,1);
      fill(48,95,61,220); ellipse(x,y-13,18,14);
      fill(76,128,74,170); ellipse(x-4,y-17,11,9);
      fill(104,148,84,110); ellipse(x+4,y-18,9,7);
    }

    // Render semantically special logical cells as dimensional authored props.
    for (let y = 1; y < Math.min(MAP - 1, ground.length); y++) {
      const row = ground[y] || [];
      for (let x = 1; x < Math.min(MAP - 1, row.length); x++) {
        const type = Number(row[x] && row[x].type !== undefined ? row[x].type : row[x]);
        // The dedicated dock kit already supplies authored service props. Suppress
        // duplicate logical-cell debris there to reduce clutter and render cost;
        // retain only the story-bearing signal crystal.
        if (reducedDetail && type !== 6) continue;
        const px = x * CELL + CELL * 0.5;
        const py = y * CELL + CELL * 0.5;
        const environmentKit = root.AetherEnvironmentVisualKit;
        if (type === 3 && environmentKit && typeof environmentKit.drawCargoCrate === 'function') {
          environmentKit.drawCargoCrate(px, py, 0.72, (x + y) % 3);
        } else if (type === 4 && environmentKit && typeof environmentKit.drawAetherStone === 'function') {
          environmentKit.drawAetherStone(px, py, 0.78, (x * 3 + y) % 2);
        } else if (type === 5 && environmentKit && typeof environmentKit.drawSkyPool === 'function') {
          environmentKit.drawSkyPool(px, py, 0.78, t);
        } else if (type === 6 && environmentKit && typeof environmentKit.drawSignalCrystal === 'function') {
          environmentKit.drawSignalCrystal(px, py, 0.82, t);
        } else if (type === 3) {
          fill(118,79,48); rect(px-7,py-9,14,12,2);
        } else if (type === 4) {
          fill(129,145,132,180); ellipse(px,py,18,11);
        } else if (type === 5) {
          fill(45,129,154,110); ellipse(px,py,24,12);
        } else if (type === 6) {
          const pulse = 0.5 + 0.5 * Math.sin(t * 0.004 + x + y);
          fill(95,224,210,38+pulse*70); ellipse(px,py,21+pulse*8,11+pulse*4);
        }
      }
    }

    // Wind-driven grass silhouettes create motion at character scale.
    stroke(57, 91, 57, 175);
    strokeWeight(1.5);
    for (let i = 0; i < (reducedDetail ? 0 : 42); i++) {
      const x = CELL * (2 + ((i * 19) % 28));
      const y = CELL * (2 + ((i * 13) % 28));
      const wind = Math.sin(t * 0.003 + i * 0.7) * 3;
      line(x, y, x + wind, y - 8 - (i % 5));
    }
    noStroke();
  }
  function drawProjectedAtmosphere(now, w, h) {
    const t = Number(now) || 0;
    noStroke();

    // Far cloud ribbons move slowly, establishing depth without obscuring play.
    for (let i = 0; i < 7; i++) {
      const drift = ((t * (0.008 + i * 0.0009)) + i * 173) % (w + 260) - 130;
      const y = h * (0.16 + i * 0.075);
      fill(220, 235, 239, 12 + i * 3);
      ellipse(drift, y, 190 + i * 24, 24 + i * 3);
      ellipse(drift + 72, y - 5, 115 + i * 14, 18 + i * 2);
    }

    // Warm vertical light shafts keep the environment tied to the sky.
    const pulse = 0.5 + 0.5 * Math.sin(t * 0.0007);
    fill(255, 211, 145, 10 + pulse * 8);
    quad(w * 0.12, 0, w * 0.24, 0, w * 0.43, h, w * 0.29, h);
    fill(180, 225, 235, 8 + (1 - pulse) * 6);
    quad(w * 0.67, 0, w * 0.76, 0, w * 0.65, h, w * 0.55, h);

    // Near-plane vapor travels faster to create parallax.
    const near = (t * 0.028) % (w + 320) - 160;
    fill(205, 229, 235, 20);
    ellipse(near, h * 0.82, 280, 42);
    ellipse(near + 310, h * 0.86, 340, 48);
    ellipse(near + 690, h * 0.80, 250, 38);
  }

  function drawBenchmarkDockPlane(w, h, now) {
    // Screen-space dock plane for the hero benchmark: a real location, not the
    // generic projected island crown. It deliberately preserves the authored sky.
    const topLeftY = Math.round(h * 0.51);
    const topRightY = Math.round(h * 0.46);
    noStroke();
    fill(38, 43, 45, 232);
    beginShape();
    vertex(0, topLeftY);
    vertex(w, topRightY);
    vertex(w, h);
    vertex(0, h);
    endShape(CLOSE);

    // Reclaimed timber lanes lead the eye toward the Dragonfly.
    stroke(101, 82, 60, 190);
    strokeWeight(11);
    line(-30, h * 0.84, w * 0.79, h * 0.48);
    line(w * 0.12, h, w * 0.67, h * 0.49);
    stroke(204, 174, 117, 92);
    strokeWeight(2);
    line(-30, h * 0.84, w * 0.79, h * 0.48);
    line(w * 0.12, h, w * 0.67, h * 0.49);

    // Sparse panel seams imply constructed deck depth without becoming a grid.
    stroke(85, 91, 88, 105);
    strokeWeight(1);
    for (let i = 1; i < 6; i++) {
      const y = topLeftY + i * ((h - topLeftY) / 6);
      line(0, y, w, y - i * 6);
    }
    noStroke();

    // Upper safety rail and small aether lamps separate dock from open sky.
    stroke(22, 28, 31, 220);
    strokeWeight(4);
    line(0, topLeftY + 2, w, topRightY + 2);
    stroke(170, 135, 76, 150);
    strokeWeight(1);
    for (let x = 40; x < w; x += 112) {
      const t = x / w;
      const railY = topLeftY + (topRightY - topLeftY) * t;
      line(x, railY - 22, x, railY + 7);
      noStroke();
      fill(42, 255, 181, 80 + Math.sin((now || 0) * 0.004 + x) * 28);
      rect(x - 2, railY - 25, 4, 4, 1);
      stroke(170, 135, 76, 150);
    }
    noStroke();
  }

  function drawDialogueTerrace(w, h, now) {
    // Conversation staging should occupy only the lower play plane. The painted
    // sky remains the dominant composition instead of being covered by a dark board.
    const topY = Math.round(h * 0.56);
    noStroke();
    fill(72, 76, 64, 205);
    beginShape();
    vertex(-20, topY + 20);
    vertex(w * 0.18, topY - 5);
    vertex(w * 0.40, topY + 5);
    vertex(w * 0.61, topY - 8);
    vertex(w * 0.80, topY + 3);
    vertex(w + 24, topY - 12);
    vertex(w + 24, h);
    vertex(-20, h);
    endShape(CLOSE);

    // Narrow masonry lip gives the actors a believable floor edge without
    // rebuilding the generic projected terrain shelf.
    stroke(132, 121, 94, 150);
    strokeWeight(5);
    line(-10, topY + 18, w + 10, topY - 8);
    stroke(205, 187, 145, 70);
    strokeWeight(1);
    line(-10, topY + 14, w + 10, topY - 12);
    noStroke();

    // Small planted pockets carry the solarpunk material language at prop scale.
    const environment = root.AetherEnvironmentVisualKit;
    if (environment && typeof environment.drawPlanter === 'function') {
      environment.drawPlanter(w * 0.18, topY + 58, 0.82, now);
      environment.drawPlanter(w * 0.82, topY + 43, 0.72, now);
    }
    fill(74, 112, 74, 92);
    ellipse(w * 0.30, topY + 72, 118, 24);
    ellipse(w * 0.68, topY + 62, 136, 26);

    const pulse = 0.5 + 0.5 * Math.sin((now || 0) * 0.003);
    fill(42, 255, 181, 22 + pulse * 18);
    rect(w * 0.43, topY + 38, 30, 3, 2);
    rect(w * 0.58, topY + 46, 34, 3, 2);
  }

  function drawProjectedWorld(input, w, h, now, player, npcs, focusX, focusY) {
    const centerX = w * 0.5;
    const centerY = h * 0.69;

    // Close camera deliberately keeps island/map boundaries outside the frame.
    // Benchmark mode uses a dedicated dock plane instead of the generic island crown.
    if (input.dockBenchmark) {
      drawBenchmarkDockPlane(w, h, now);
    } else if (input.dialogueActive) {
      drawDialogueTerrace(w, h, now);
    } else {
      drawProjectedTerrainMass(focusX, focusY, w, h, false);
      push();
      const a = 2.85;
      const b = -0.10;
      const c = 0.34;
      const d = 1.38;
      const e = centerX - a * focusX - c * focusY;
      const f = centerY - b * focusX - d * focusY;
      applyMatrix(a, b, c, d, e, f);
      smooth();
      drawDimensionalGround(input, now, false);
      pop();
      drawProjectedAtmosphere(now, w, h);
    }

    // Benchmark dock service geometry belongs below actors, not over them.
    if (input.dockBenchmark) {
      const kit = root.AetherEnvironmentVisualKit;
      if (kit && typeof kit.drawDockSurface === 'function') kit.drawDockSurface({ width: w, height: h, now });
      if (kit && typeof kit.drawDockMidground === 'function') kit.drawDockMidground({ width: w, height: h, now });
    }

    // Add a low atmospheric veil where the projected island meets the cloud sea.
    fill(205, 225, 230, 24);
    rect(0, Math.round(h * 0.73), w, Math.round(h * 0.08));

    const actors = [];
    const dialogueActive = Boolean(input.dialogueActive);
    const activeDialogueNpcId = input.dialogueNpcId || null;
    const playerTileX = Number.isFinite(player.tileX) ? player.tileX : Math.round((player.px || 0) / CELL);
    actors.push({
      id: 'ender',
      // Dialogue composition gets a small presentation-only separation so the
      // speaker and player read as two figures rather than one overlapped sprite.
      tileX: playerTileX + (dialogueActive ? -0.85 : 0),
      tileY: Number.isFinite(player.tileY) ? player.tileY : Math.round((player.py || 0) / CELL),
      name: dialogueActive ? '' : 'Ender',
      frame: playerWalkFrame(player, now),
      // Dialogue can reposition the actor, but must not change physical stature.
      scale: 2.55,
      questMarker: false,
    });
    for (const npc of npcs) {
      if (!npc || !Number.isFinite(npc.tileX) || !Number.isFinite(npc.tileY)) continue;
      actors.push({
        id: SPRITE_IDS[npc.id] || 'settler',
        tileX: npc.tileX + (dialogueActive && npc.id === activeDialogueNpcId ? 0.85 : 0),
        tileY: npc.tileY,
        name: dialogueActive ? '' : (npc.id === 'elder_farmer' ? 'Ionia' : ''),
        frame: 0,
        // NPC stature remains stable between exploration and dialogue.
        scale: 2.45,
        questMarker: Boolean(npc.id === 'elder_farmer' && npc.flags && npc.flags.questMarker && !npc.flags.met),
      });
    }
    actors.sort((a, b) => (a.tileX + a.tileY) - (b.tileX + b.tileY));

    for (const actor of actors) {
      drawProjectedSprite(
        actor.id, actor.tileX, actor.tileY, actor.name,
        focusX, focusY, w, h, actor.scale, actor.frame
      );
      if (actor.questMarker) {
        const p = projectWorldPoint(
          actor.tileX * CELL + CELL / 2,
          actor.tileY * CELL + CELL,
          focusX, focusY, w, h
        );
        fill(255, 211, 72, 230);
        noStroke();
        beginShape();
        vertex(p.x, p.y - 92);
        vertex(p.x - 6, p.y - 103);
        vertex(p.x + 6, p.y - 103);
        endShape(CLOSE);
      }
    }

    if (!input.dockBenchmark && !input.dialogueActive) drawProjectedForeground(w, h, now);

    // Near-plane framing makes the world read as a photographed space, not a board.
    fill(7, 10, 18, 120);
    rect(0, h - 28, w, 28);
    fill(42, 255, 181, 28);
    rect(0, h - 31, w, 2);
    return true;
  }

  function draw(input) {
    if (!root.AetherPixelTiles || !root.AetherPixelSprites) return false;
    const w = input.width || width;
    const h = input.height || height;
    const now = input.now || 0;
    if (!input.skipBackdrop) drawBackdrop(w, h, now);

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

    // Real browser/runtime path: project the deterministic logical map into a
    // three-quarter 2.5D presentation while keeping the legacy raster path as
    // a non-rotating fallback for deterministic/headless compatibility.
    if (typeof rotate === 'function' && typeof beginShape === 'function') {
      return drawProjectedWorld(input, w, h, now, player, npcs, focusX, focusY);
    }

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
