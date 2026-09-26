/* ============================================================
   Aetherwake — Pixel Sprite Foundation
   modules/pixel-sprites.js

   Shared code-authored fallback sprites plus a generated atlas for Preview 0.1.
   Other runtime surfaces retain the compact cell sprites; the opening and
   exploration scenes use the higher-detail atlas when its local asset loads.
   ============================================================ */
(function (root) {
  'use strict';

  const TRANSPARENT = '.';
  const PREVIEW_ATLAS_PATH = 'assets/preview/aetherwake-preview-party-atlas-v2.png';
  const BATTLE_ENEMY_ATLAS_PATH = 'assets/preview/aetherwake-sky-predator-battle.png';
  const PREVIEW_COLUMNS = Object.freeze({
    ender: 0,
    lyra: 1,
    ionia: 2,
  });
  const PREVIEW_WIDTH = 28;
  const PREVIEW_HEIGHT = 36;
  const BATTLE_ENEMY_WIDTH = 42;
  const BATTLE_ENEMY_HEIGHT = 36;
  const ENDER_FIELD_PREVIEW_PARAM = 'aetherwakeFieldArtPreview';
  const ENDER_FIELD_CANDIDATE_PATH = 'assets/characters/v1/ender/field-idle-walk-candidate.png';
  const ENDER_FIELD_CELL_WIDTH = 28;
  const ENDER_FIELD_CELL_HEIGHT = 36;
  let previewAtlas = null;
  let previewAtlasState = 'idle';
  let battleEnemyAtlas = null;
  let battleEnemyAtlasState = 'idle';

  const PALETTES = Object.freeze({
    ender: Object.freeze({
      H: [38, 30, 42],       // hair / outline
      S: [218, 184, 150],    // skin
      G: [42, 255, 181],     // goggles / aether
      C: [31, 74, 66],       // coat
      A: [124, 200, 232],    // coat accent
      L: [45, 48, 62],       // trousers
      B: [24, 25, 31],       // boots
      K: [118, 105, 92],     // staff
    }),
    lyra: Object.freeze({
      H: [82, 52, 91],
      S: [214, 181, 158],
      G: [124, 200, 232],
      C: [96, 70, 118],
      A: [42, 255, 181],
      L: [54, 47, 72],
      B: [28, 25, 35],
      K: [185, 158, 116],
    }),
    ionia: Object.freeze({
      H: [70, 43, 35],
      S: [205, 171, 140],
      G: [255, 179, 71],
      C: [46, 76, 88],
      A: [42, 255, 181],
      L: [36, 45, 55],
      B: [22, 26, 31],
      K: [150, 112, 66],
    }),
    skyPredator: Object.freeze({
      D: [24, 29, 42],
      B: [48, 76, 96],
      W: [92, 142, 166],
      T: [42, 255, 181],
      E: [255, 179, 71],
      H: [175, 218, 230],
    }),
    settler: Object.freeze({
      H: [57, 43, 35],
      S: [201, 174, 143],
      C: [105, 126, 83],
      A: [185, 158, 116],
      L: [67, 63, 54],
      B: [35, 31, 28],
    }),
    engineSpirit: Object.freeze({
      D: [30, 67, 76],
      A: [42, 255, 181],
      C: [124, 200, 232],
      W: [205, 245, 232],
    }),
    corporateSalvager: Object.freeze({
      H: [38, 39, 45],
      S: [181, 170, 158],
      C: [92, 96, 104],
      A: [42, 255, 181],
      L: [58, 61, 68],
      B: [24, 25, 30],
    }),
  });

  const SPRITES = Object.freeze({
    ender: Object.freeze({
      id: 'ender',
      width: 16,
      height: 16,
      frames: Object.freeze([
        Object.freeze([
          '.....HHHH.......',
          '....HHHHHH......',
          '....HSSSSH......',
          '...HSGGGGSH.....',
          '...HSGGGGSH.K...',
          '....SSSSSS..K...',
          '....CCCCCC..K...',
          '...CCACACCC.K...',
          '...CCCCCCCC.K...',
          '...C.CCCC.C.K...',
          '...C.CCCC.C.K...',
          '....CCCCCC..K...',
          '....LL..LL..K...',
          '...LLL..LLL.K...',
          '...BB....BB.K...',
          '..BBB....BBB....',
        ]),
        Object.freeze([
          '.....HHHH.......',
          '....HHHHHH......',
          '....HSSSSH......',
          '...HSGGGGSH.....',
          '...HSGGGGSH.K...',
          '....SSSSSS..K...',
          '....CCCCCC..K...',
          '...CCACACCC.K...',
          '...CCCCCCCC.K...',
          '...C.CCCC.C.K...',
          '....CCCCCC..K...',
          '...CC....CC.K...',
          '...LL....LL.K...',
          '..LLL....LLL....',
          '..BB......BB....',
          '.BBB......BBB...',
        ]),
      ]),
    }),

    lyra: Object.freeze({
      id: 'lyra',
      width: 16,
      height: 16,
      frames: Object.freeze([
        Object.freeze([
          '.....HHHH.......',
          '....HHHHHH......',
          '....HSSSSH......',
          '....HSGGSH......',
          '....SSSSSS......',
          '....CCCCCC......',
          '...CCGCCCCC.....',
          '...CCACACCC.....',
          '...CCCCCCCC.....',
          '...C.CCCC.C.....',
          '...C.CCCC.C.....',
          '....CCCCCC......',
          '....LL..LL......',
          '...LLL..LLL.....',
          '...BB....BB.....',
          '..BBB....BBB....',
        ]),
        Object.freeze([
          '.....HHHH.......',
          '....HHHHHH......',
          '....HSSSSH......',
          '....HSGGSH......',
          '....SSSSSS......',
          '....CCCCCC......',
          '...CCGCCCCC.....',
          '...CCACACCC.....',
          '...CCCCCCCC.....',
          '....CCCCCC......',
          '...CC....CC.....',
          '...LL....LL.....',
          '..LLL....LLL....',
          '..BB......BB....',
          '.BBB......BBB...',
          '................',
        ]),
      ]),
    }),

    ionia: Object.freeze({
      id: 'ionia',
      width: 16,
      height: 16,
      frames: Object.freeze([
        Object.freeze([
          '....HHHHHH......',
          '...HHHHHHHH.....',
          '...HSSSSSSH.....',
          '...HSG..GSH.....',
          '....SSSSSS......',
          '....CCCCCC......',
          '...CCACACCC.....',
          '...CCCCCCCC.....',
          '...CCGCCCCC.....',
          '...C.CCCC.C.....',
          '...C.CCCC.C.....',
          '....CCCCCC......',
          '....LL..LL......',
          '...LLL..LLL.....',
          '...BB....BB.....',
          '..BBB....BBB....',
        ]),
        Object.freeze([
          '....HHHHHH......',
          '...HHHHHHHH.....',
          '...HSSSSSSH.....',
          '...HSG..GSH.....',
          '....SSSSSS......',
          '....CCCCCC......',
          '...CCACACCC.....',
          '...CCCCCCCC.....',
          '...CCGCCCCC.....',
          '....CCCCCC......',
          '...CC....CC.....',
          '...LL....LL.....',
          '..LLL....LLL....',
          '..BB......BB....',
          '.BBB......BBB...',
          '................',
        ]),
      ]),
    }),

    skyPredator: Object.freeze({
      id: 'skyPredator',
      width: 16,
      height: 16,
      frames: Object.freeze([
        Object.freeze([
          '................',
          '.....WWWW.......',
          '...WWWBBWWW.....',
          '..WWBBBBBBWW....',
          '.WWBBBBBBBBWW...',
          'WWBBBBDDBBBBWW..',
          'WBBBBDDDDDBBBBW.',
          '.WBBBDDTEDDBBBW.',
          '..WBBBDDDDDBBW..',
          '...WBBBBBBBBW...',
          '..TTWBBBBBBWTT..',
          '.T..WWBBBBWW.T..',
          '....HWWWWWH.....',
          '.....H..H.......',
          '....H....H......',
          '................',
        ]),
        Object.freeze([
          '................',
          '..WW........WW..',
          '.WWWW......WWWW.',
          '..WWBBBBBBBBWW..',
          '...WBBBBBBBBW...',
          '..WBBBBDDBBBBW..',
          '.WBBBBDDDDDBBBBW',
          '..WBBBDDTEDDBBW.',
          '...WBBBDDDDDBW..',
          '....WBBBBBBW....',
          '..TTWWBBBBWWTT..',
          '.T...WWBBWW..T..',
          '.....HWWWW.H....',
          '......H..H......',
          '.....H....H.....',
          '................',
        ]),
      ]),
    }),

    settler: Object.freeze({
      id: 'settler',
      width: 16,
      height: 16,
      frames: Object.freeze([
        Object.freeze([
          '.....HHHH.......','....HHHHHH......','....HSSSSH......','....HS..SH......',
          '....SSSSSS......','....CCCCCC......','...CCACACCC.....','...CCCCCCCC.....',
          '...CCCCCCCC.....','...C.CCCC.C.....','...C.CCCC.C.....','....CCCCCC......',
          '....LL..LL......','...LLL..LLL.....','...BB....BB.....','..BBB....BBB....',
        ]),
        Object.freeze([
          '.....HHHH.......','....HHHHHH......','....HSSSSH......','....HS..SH......',
          '....SSSSSS......','....CCCCCC......','...CCACACCC.....','...CCCCCCCC.....',
          '....CCCCCC......','...CC....CC.....','...LL....LL.....','..LLL....LLL....',
          '..BB......BB....','.BBB......BBB...','................','................',
        ]),
      ]),
    }),

    engineSpirit: Object.freeze({
      id: 'engineSpirit',
      width: 16,
      height: 16,
      frames: Object.freeze([
        Object.freeze([
          '................',
          '.......A........',
          '....A..C..A.....',
          '.....CCCCC......',
          '...CCAAAAACC....',
          '..CCAAWWWAAACC..',
          '..CAAWWWWWAAAC..',
          '.ACAAWWWWWAAACA.',
          '..CAAWWWWWAAAC..',
          '..CCAAWWWAAACC..',
          '...CCAAAAACC....',
          '.....CCCCC......',
          '....A..C..A.....',
          '.......A........',
          '................',
          '................',
        ]),
        Object.freeze([
          '................',
          '....A......A....',
          '......CCCC......',
          '...A.CAAAAC.A...',
          '....CAAWWAAC....',
          '..CCAAWWWWAACC..',
          '..CAAWWWWWWAAC..',
          '..CAAWWWWWWAAC..',
          '..CCAAWWWWAACC..',
          '....CAAWWAAC....',
          '...A.CAAAAC.A...',
          '......CCCC......',
          '....A......A....',
          '................',
          '................',
          '................',
        ]),
      ]),
    }),

    corporateSalvager: Object.freeze({
      id: 'corporateSalvager',
      width: 16,
      height: 16,
      frames: Object.freeze([
        Object.freeze([
          '.....HHHH.......',
          '....HHHHHH......',
          '....HSSSSH......',
          '....HS..SH......',
          '....SSSSSS......',
          '...CCCCCCCC.....',
          '..CCCACACCCC....',
          '..CCCCCCCCCC....',
          '..CCCCCCCCCC....',
          '...C.CCCC.C.....',
          '...C.CCCC.C.....',
          '....CCCCCC......',
          '....LL..LL......',
          '...LLL..LLL.....',
          '...BB....BB.....',
          '..BBB....BBB....',
        ]),
        Object.freeze([
          '.....HHHH.......',
          '....HHHHHH......',
          '....HSSSSH......',
          '....HS..SH......',
          '....SSSSSS......',
          '...CCCCCCCC.....',
          '..CCCACACCCC....',
          '..CCCCCCCCCC....',
          '..CCCCCCCCCC....',
          '....CCCCCC......',
          '...CC....CC.....',
          '...LL....LL.....',
          '..LLL....LLL....',
          '..BB......BB....',
          '.BBB......BBB...',
          '................',
        ]),
      ]),
    }),
  });

  // Preview-only adult fallbacks keep the existing compact 16×16 sprites for
  // legacy drawing surfaces while using a taller 14×18 grid at Preview scale 2.
  const PREVIEW_FALLBACKS = Object.freeze({
    settler: Object.freeze({
      width: 14,
      height: 18,
      frames: Object.freeze([
        Object.freeze([
          '.....HHHH.....',
          '....HHHHHH....',
          '...HHSSSSHH...',
          '...HSSSSSSH...',
          '..HHSS..SSHH..',
          '...HSSSSSSH...',
          '....HSSSSH....',
          '.....SSSS.....',
          '....CCCCCC....',
          'CC..CCCCCC..CC',
          'CC..CCACAC..CC',
          'CC..CCCCCC..CC',
          '...CCCCCCCC...',
          '...CC....CC...',
          '....LL..LL....',
          '...LLL..LLL...',
          '...BB....BB...',
          '..BBB....BBB..',
        ]),
        Object.freeze([
          '.....HHHH.....',
          '....HHHHHH....',
          '...HHSSSSHH...',
          '...HSSSSSSH...',
          '..HHSS..SSHH..',
          '...HSSSSSSH...',
          '....HSSSSH....',
          '.....SSSS.....',
          '....CCCCCC....',
          'CC..CCCCCC..CC',
          'CC..CCACAC..CC',
          'CC..CCCCCC..CC',
          '...CCCCCCCC...',
          '...CC....CC...',
          '....LL...LL...',
          '...LLL...LLL..',
          '...BB.....BB..',
          '..BBB.....BBB.',
        ]),
      ]),
    }),
    corporateSalvager: Object.freeze({
      width: 14,
      height: 18,
      frames: Object.freeze([
        Object.freeze([
          '.....HHHH.....',
          '....HHHHHH....',
          '...HHSSSSHH...',
          '...HSSSSSSH...',
          '..HHSS..SSHH..',
          '...HSSSSSSH...',
          '....HSSSSH....',
          '.....SSSS.....',
          '....CCCCCC....',
          'CC.CCCCCCCC.CC',
          'CC.CCAACCCC.CC',
          'CC.CCCACCCC.CC',
          '..CCCCCCCCCC..',
          '...CC....CC...',
          '....LL..LL....',
          '...LLL..LLL...',
          '...BB....BB...',
          '..BBB....BBB..',
        ]),
        Object.freeze([
          '.....HHHH.....',
          '....HHHHHH....',
          '...HHSSSSHH...',
          '...HSSSSSSH...',
          '..HHSS..SSHH..',
          '...HSSSSSSH...',
          '....HSSSSH....',
          '.....SSSS.....',
          '....CCCCCC....',
          'CC.CCCCCCCC.CC',
          'CC.CCAACCCC.CC',
          'CC.CCCACCCC.CC',
          '..CCCCCCCCCC..',
          '...CC....CC...',
          '....LL...LL...',
          '...LLL...LLL..',
          '....BB...BB...',
          '...BBB...BBB..',
        ]),
      ]),
    }),
  });

  function validateSprite(sprite, palette) {
    if (!sprite || sprite.width !== 16 || sprite.height !== 16) return false;
    if (!Array.isArray(sprite.frames) || sprite.frames.length < 1) return false;
    return sprite.frames.every(frame =>
      frame.length === sprite.height &&
      frame.every(row =>
        typeof row === 'string' &&
        row.length === sprite.width &&
        Array.from(row).every(cell => cell === TRANSPARENT || palette[cell])
      )
    );
  }

  function validatePreviewFallback(sprite, palette) {
    if (!sprite || sprite.width !== 14 || sprite.height !== 18) return false;
    if (!Array.isArray(sprite.frames) || sprite.frames.length < 2) return false;
    return sprite.frames.every(frame =>
      frame.length === sprite.height &&
      frame.every(row =>
        typeof row === 'string' &&
        row.length === sprite.width &&
        Array.from(row).every(cell => cell === TRANSPARENT || palette[cell])
      )
    );
  }

  function validate() {
    return Object.keys(SPRITES).every(id => validateSprite(SPRITES[id], PALETTES[id])) &&
      Object.keys(PREVIEW_FALLBACKS).every(id => validatePreviewFallback(PREVIEW_FALLBACKS[id], PALETTES[id]));
  }

  function get(id) {
    return SPRITES[id] || null;
  }

  function drawPixelSprite(sprite, palette, x, y, options) {
    if (!sprite || !palette) return false;

    const opts = options || {};
    const scale = Math.max(1, Math.floor(opts.scale || 1));
    const frameIndex = Math.abs(Math.floor(opts.frame || 0)) % sprite.frames.length;
    const frame = sprite.frames[frameIndex];
    const anchor = opts.anchor || 'top-left';

    let ox = x;
    let oy = y;
    if (anchor === 'center') {
      ox -= (sprite.width * scale) / 2;
      oy -= (sprite.height * scale) / 2;
    } else if (anchor === 'bottom-center') {
      ox -= (sprite.width * scale) / 2;
      oy -= sprite.height * scale;
    }

    ox = Math.round(ox);
    oy = Math.round(oy);

    noStroke();
    for (let sy = 0; sy < sprite.height; sy++) {
      const row = frame[sy];
      for (let sx = 0; sx < sprite.width; sx++) {
        const token = row[sx];
        if (token === TRANSPARENT) continue;
        const rgb = palette[token];
        fill(rgb[0], rgb[1], rgb[2]);
        rect(ox + sx * scale, oy + sy * scale, scale, scale);
      }
    }
    return true;
  }

  function draw(id, x, y, options) {
    return drawPixelSprite(SPRITES[id], PALETTES[id], x, y, options);
  }

  let enderFieldCandidate = null;
  let enderFieldCandidateState = 'idle';

  function isEnderFieldCandidateRequested() {
    const search = root.location && root.location.search ? root.location.search : '';
    try {
      return new URLSearchParams(search).get(ENDER_FIELD_PREVIEW_PARAM) === 'ender';
    } catch (error) {
      return false;
    }
  }

  function drawEnderFieldCandidate(x, y, options) {
    if (!isEnderFieldCandidateRequested()) return false;
    if (enderFieldCandidateState === 'idle') {
      if (typeof loadImage !== 'function') {
        enderFieldCandidateState = 'unavailable';
      } else {
        enderFieldCandidateState = 'loading';
        try {
          enderFieldCandidate = loadImage(
            ENDER_FIELD_CANDIDATE_PATH,
            (loaded) => {
              enderFieldCandidate = loaded || enderFieldCandidate;
              enderFieldCandidateState = enderFieldCandidate &&
                enderFieldCandidate.width === ENDER_FIELD_CELL_WIDTH * 2 &&
                enderFieldCandidate.height === ENDER_FIELD_CELL_HEIGHT
                ? 'ready'
                : 'failed';
            },
            () => {
              enderFieldCandidate = null;
              enderFieldCandidateState = 'failed';
            }
          );
        } catch (error) {
          enderFieldCandidate = null;
          enderFieldCandidateState = 'failed';
        }
      }
    }

    if (enderFieldCandidateState !== 'ready' || !enderFieldCandidate ||
        typeof image !== 'function') return false;

    const opts = options || {};
    const scale = Math.max(1, Math.floor(opts.scale || 1));
    const frameIndex = Math.abs(Math.floor(opts.frame || 0)) % 2;
    const anchor = opts.anchor || 'top-left';
    let ox = x;
    let oy = y;
    if (anchor === 'center') {
      ox -= (ENDER_FIELD_CELL_WIDTH * scale) / 2;
      oy -= (ENDER_FIELD_CELL_HEIGHT * scale) / 2;
    } else if (anchor === 'bottom-center') {
      ox -= (ENDER_FIELD_CELL_WIDTH * scale) / 2;
      oy -= ENDER_FIELD_CELL_HEIGHT * scale;
    }
    if (typeof noSmooth === 'function') noSmooth();
    image(
      enderFieldCandidate,
      Math.round(ox),
      Math.round(oy),
      ENDER_FIELD_CELL_WIDTH * scale,
      ENDER_FIELD_CELL_HEIGHT * scale,
      frameIndex * ENDER_FIELD_CELL_WIDTH,
      0,
      ENDER_FIELD_CELL_WIDTH,
      ENDER_FIELD_CELL_HEIGHT
    );
    return true;
  }

  function isFieldArtCandidateRequested(id) {
    return id === 'ender' && isEnderFieldCandidateRequested();
  }

  function drawFieldCandidate(id, x, y, options) {
    return id === 'ender' ? drawEnderFieldCandidate(x, y, options) : false;
  }

  function drawPreview(id, x, y, options) {
    if (id === 'ender' && drawEnderFieldCandidate(x, y, options)) return true;
    const column = PREVIEW_COLUMNS[id];
    if (column === undefined || !SPRITES[id]) {
      const previewFallback = PREVIEW_FALLBACKS[id];
      return previewFallback
        ? drawPixelSprite(previewFallback, PALETTES[id], x, y, options)
        : draw(id, x, y, options);
    }

    if (previewAtlasState === 'idle') {
      if (typeof loadImage !== 'function') {
        previewAtlasState = 'unavailable';
      } else {
        previewAtlasState = 'loading';
        try {
          previewAtlas = loadImage(
            PREVIEW_ATLAS_PATH,
            () => { previewAtlasState = 'ready'; },
            () => { previewAtlas = null; previewAtlasState = 'failed'; }
          );
        } catch (error) {
          previewAtlas = null;
          previewAtlasState = 'failed';
        }
      }
    }

    if (previewAtlasState !== 'ready' || !previewAtlas || typeof image !== 'function') {
      return draw(id, x, y, options);
    }

    const opts = options || {};
    const scale = Math.max(1, Math.floor(opts.scale || 1));
    const frameIndex = Math.abs(Math.floor(opts.frame || 0)) % 2;
    const anchor = opts.anchor || 'top-left';
    let ox = x;
    let oy = y;
    if (anchor === 'center') {
      ox -= (PREVIEW_WIDTH * scale) / 2;
      oy -= (PREVIEW_HEIGHT * scale) / 2;
    } else if (anchor === 'bottom-center') {
      ox -= (PREVIEW_WIDTH * scale) / 2;
      oy -= PREVIEW_HEIGHT * scale;
    }

    const cellWidth = previewAtlas.width / 4;
    const cellHeight = previewAtlas.height / 2;
    const sourceWidth = Math.min(cellWidth, cellHeight * 0.76);
    const sourceX = column * cellWidth + (cellWidth - sourceWidth) / 2;
    const sourceY = frameIndex * cellHeight;
    if (typeof noSmooth === 'function') noSmooth();
    image(
      previewAtlas,
      Math.round(ox),
      Math.round(oy),
      PREVIEW_WIDTH * scale,
      PREVIEW_HEIGHT * scale,
      sourceX,
      sourceY,
      sourceWidth,
      cellHeight
    );
    return true;
  }

  function drawBattleEnemy(id, x, y, options) {
    if (id !== 'skyPredator') return drawPreview(id, x, y, options);

    if (battleEnemyAtlasState === 'idle') {
      if (typeof loadImage !== 'function') {
        battleEnemyAtlasState = 'unavailable';
      } else {
        battleEnemyAtlasState = 'loading';
        try {
          battleEnemyAtlas = loadImage(
            BATTLE_ENEMY_ATLAS_PATH,
    ENDER_FIELD_PREVIEW_PARAM,
    ENDER_FIELD_CANDIDATE_PATH,
            () => { battleEnemyAtlasState = 'ready'; },
            () => { battleEnemyAtlas = null; battleEnemyAtlasState = 'failed'; }
          );
        } catch (error) {
          battleEnemyAtlas = null;
          battleEnemyAtlasState = 'failed';
        }
      }
    }

    if (battleEnemyAtlasState !== 'ready' || !battleEnemyAtlas || typeof image !== 'function') {
      return draw(id, x, y, options);
    }

    const opts = options || {};
    const scale = Math.max(1, Math.floor(opts.scale || 1));
    const frameIndex = Math.abs(Math.floor(opts.frame || 0)) % 2;
    const anchor = opts.anchor || 'top-left';
    let ox = x;
    let oy = y;
    if (anchor === 'center') {
      ox -= (BATTLE_ENEMY_WIDTH * scale) / 2;
      oy -= (BATTLE_ENEMY_HEIGHT * scale) / 2;
    } else if (anchor === 'bottom-center') {
      ox -= (BATTLE_ENEMY_WIDTH * scale) / 2;
      oy -= BATTLE_ENEMY_HEIGHT * scale;
    }

    const cellWidth = battleEnemyAtlas.width / 2;
    if (typeof noSmooth === 'function') noSmooth();
    image(
      battleEnemyAtlas,
      Math.round(ox),
      Math.round(oy),
      BATTLE_ENEMY_WIDTH * scale,
      BATTLE_ENEMY_HEIGHT * scale,
      frameIndex * cellWidth,
      0,
      cellWidth,
      battleEnemyAtlas.height
    );
    return true;
  }

  function drawShadow(x, y, scale, spriteWidth = 10) {
    const s = Math.max(1, Number(scale) || 1);
    const width = Math.max(1, Number(spriteWidth) || 10);
    noStroke();
    fill(0, 0, 0, 80);
    rect(
      Math.round(x - (width * s) / 2),
      Math.round(y - 2 * s),
      Math.round(width * s),
      Math.max(1, Math.round(2 * s))
    );
  }

  const api = Object.freeze({
    ENDER_FIELD_PREVIEW_PARAM,
    ENDER_FIELD_CANDIDATE_PATH,
    isFieldArtCandidateRequested,
    drawFieldCandidate,
    VERSION: '0.3.0',
    CELL_SIZE: 1,
    PREVIEW_ATLAS_PATH,
    PREVIEW_WIDTH,
    PREVIEW_HEIGHT,
    BATTLE_ENEMY_ATLAS_PATH,
    SPRITES,
    PALETTES,
    get,
    draw,
    drawPreview,
    drawBattleEnemy,
    drawShadow,
    validate,
  });

  if (!validate()) {
    throw new Error('AETHER_PIXEL_SPRITES_INVALID');
  }

  root.AetherPixelSprites = api;
})(typeof window !== 'undefined' ? window : globalThis);
