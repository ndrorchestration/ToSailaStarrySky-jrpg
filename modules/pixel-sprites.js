/* ============================================================
   Aetherwake — Pixel Sprite Foundation
   modules/pixel-sprites.js

   Data-driven 16×16 character sprites for the playable vertical slice.
   These are intentionally code-authored sprite cells rather than procedural
   silhouette geometry so every surface can share one visual authority.
   ============================================================ */
(function (root) {
  'use strict';

  const TRANSPARENT = '.';

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

  function validate() {
    return Object.keys(SPRITES).every(id => validateSprite(SPRITES[id], PALETTES[id]));
  }

  function get(id) {
    return SPRITES[id] || null;
  }

  function draw(id, x, y, options) {
    const sprite = SPRITES[id];
    const palette = PALETTES[id];
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

  function drawShadow(x, y, scale) {
    const s = Math.max(1, Number(scale) || 1);
    noStroke();
    fill(0, 0, 0, 80);
    rect(
      Math.round(x - 5 * s),
      Math.round(y - 2 * s),
      Math.round(10 * s),
      Math.max(1, Math.round(2 * s))
    );
  }

  const api = Object.freeze({
    VERSION: '0.2.0',
    CELL_SIZE: 1,
    SPRITES,
    PALETTES,
    get,
    draw,
    drawShadow,
    validate,
  });

  if (!validate()) {
    throw new Error('AETHER_PIXEL_SPRITES_INVALID');
  }

  root.AetherPixelSprites = api;
})(typeof window !== 'undefined' ? window : globalThis);
