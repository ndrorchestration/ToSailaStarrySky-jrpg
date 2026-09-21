/* ============================================================
   Aetherwake — Pixel Tile Foundation
   modules/pixel-tiles.js

   Data-driven 16×16 terrain/prop tiles for the playable world slice.
   ============================================================ */
(function (root) {
  'use strict';

  const TRANSPARENT = '.';

  const PALETTE = Object.freeze({
    N: [20, 18, 31],
    M: [46, 47, 54],
    R: [118, 58, 33],
    D: [72, 35, 26],
    O: [176, 105, 58],
    T: [184, 163, 119],
    G: [82, 121, 68],
    g: [112, 151, 82],
    B: [47, 97, 127],
    b: [72, 138, 167],
    C: [124, 200, 232],
    A: [42, 255, 181],
    W: [205, 225, 230],
    Y: [255, 196, 91],
    P: [103, 85, 116],
    F: [29, 72, 52],
    L: [139, 184, 88],
    S: [230, 210, 151],
    K: [91, 68, 61],
    H: [211, 239, 241],
  });

  function freezeFrame(rows) {
    return Object.freeze(rows.slice());
  }

  const TILES = Object.freeze({
    hull: Object.freeze({
      id: 'hull',
      frames: Object.freeze([
        freezeFrame([
          'RRRRRRRRRRRRRRRR',
          'RDDDDDDDDDDDDDDR',
          'RDMMMMMMMMMMMMDR',
          'RDMRRRRRRRRRRMDR',
          'RDMRDDDDDDDDRMDR',
          'RDMRDMMMMMMDRMDR',
          'RDMRDMRRRRMDRMDR',
          'RDMRDMRAARMDRMDR',
          'RDMRDMRAARMDRMDR',
          'RDMRDMRRRRMDRMDR',
          'RDMRDMMMMMMDRMDR',
          'RDMRDDDDDDDDRMDR',
          'RDMRRRRRRRRRRMDR',
          'RDMMMMMMMMMMMMDR',
          'RDDDDDDDDDDDDDDR',
          'RRRRRRRRRRRRRRRR',
        ]),
      ]),
    }),

    grass: Object.freeze({
      id: 'grass',
      frames: Object.freeze([
        freezeFrame([
          'TTTTTTTTTTTTTTTT',
          'TTTTTTTTTTTTTTTT',
          'TTgTTTTTTTTTTgTT',
          'TTGTTTTgTTTTTGTT',
          'TTGTTTTGTTTTTGTT',
          'TTTTTTTGTTTTTTTT',
          'TTTTTTTTTTTTTTTT',
          'TTTTgTTTTTTTTTTT',
          'TTTTGTTTTgTTTTTT',
          'TTTTGTTTTGTTTTTT',
          'TTTTTTTTTGTTTTTT',
          'TTTTTTTTTTTTTTTT',
          'TgTTTTTTTTTTTgTT',
          'TGTTTTgTTTTTTGTT',
          'TGTTTTGTTTTTTGTT',
          'TTTTTTGTTTTTTTTT',
        ]),
        freezeFrame([
          'TTTTTTTTTTTTTTTT',
          'TTTTgTTTTTTTTTTT',
          'TTTTGTTTTTTgTTTT',
          'TTTTGTTTTTTGTTTT',
          'TTTTTTTTTTTGTTTT',
          'TTTTTTTTTTTTTTTT',
          'TgTTTTTTTTTTTTTT',
          'TGTTTTTTTgTTTTTT',
          'TGTTTTTTTGTTTTTT',
          'TTTTTTTTTGTTTTTT',
          'TTTTTTTTTTTTTTTT',
          'TTTTTTgTTTTTTgTT',
          'TTTTTTGTTTTTTGTT',
          'TTgTTTGTTTTTTGTT',
          'TTGTTTTTTTTTTTTT',
          'TTGTTTTTTTTTTTTT',
        ]),
        freezeFrame([
          'TTTTTTTTTTTTTTTT',
          'TgTTTTTTTTTTTgTT',
          'TGTTTTTTTTTTTGTT',
          'TGTTTTgTTTTTTGTT',
          'TTTTTTGTTTTTTTTT',
          'TTTTTTGTTTTTTTTT',
          'TTTTTTTTTTTTTTTT',
          'TTTTTTTTTgTTTTTT',
          'TTTTgTTTTGTTTTTT',
          'TTTTGTTTTGTTTTTT',
          'TTTTGTTTTTTTTTTT',
          'TTTTTTTTTTTTTTTT',
          'TTgTTTTTTTTTTTTT',
          'TTGTTTTTTTTgTTTT',
          'TTGTTTTTTTTGTTTT',
          'TTTTTTTTTTTGTTTT',
        ]),
      ]),
    }),

    forest: Object.freeze({
      id: 'forest',
      frames: Object.freeze([freezeFrame([
        'TTTTTTTTTTTTTTTT','TTTTTFFTTFFTTTTT','TTTFFGFFFFFFTTTT','TTFFFGGGFFFFFTTT',
        'TFFFGgGGGFFFFFTT','TFFGGGGGGGFFFFTT','FFGGgGGGGGGFFFFT','FFGGGGGGGGGFFFFT',
        'TFFGGGGGGGFFFFTT','TTFFGGGGGFFFFTTT','TTTFFFGFFFFFTTTT','TTTTFFKFFFTTTTTT',
        'TTTTTKKKTTTTTTTT','TTTTTKKKTTTTTTTT','TTTTTTKTTTTTTTTT','TTTTTTTTTTTTTTTT',
      ])]),
    }),

    cliff: Object.freeze({
      id: 'cliff',
      frames: Object.freeze([freezeFrame([
        'GGGGGGGGGGGGGGGG','TTTTTTTTTTTTTTTT','OOOOOOOOOOOOOOOO','ODDDOODDDDOODDDO',
        'DDOODDDDOODDDDOO','DOODDDOODDDOODDD','DDDDOODDDDOODDDD','ODDDDOODDDDOODDD',
        'DDOODDDDOODDDDOO','DOODDDOODDDOODDD','DDDDOODDDDOODDDD','ODDDDOODDDDOODDD',
        'DDOODDDDOODDDDOO','DOODDDOODDDOODDD','DDDDDDDDDDDDDDDD','NNNNNNNNNNNNNNNN',
      ])]),
    }),

    shore: Object.freeze({
      id: 'shore',
      frames: Object.freeze([freezeFrame([
        'SSSSSSSSSSSSSSSS','SSSSSSSSSSSSSSSS','SSSSSSSSSSSSSSSS','SSSSSSSSSSSSSSSS',
        'SSSSSSSSSSSSSSSS','SSSSSSSSSSSSSSSS','SSSSSSSSSSSSSSSS','SSSSSSSSSSSSSSSS',
        'SSSSSSSSSSSSSSSS','SSSSSSSSSSSSSSSS','SSSSSSSSSSSSSSSS','SSSSSSSSSSSSSSSS',
        'SSSSCCCCSSSSCCCC','SSCCCCCCCCCCCCCC','CCCCCbbbbCCCCCCC','BBBBBBBBBBBBBBBB',
      ])]),
    }),

    mountain: Object.freeze({
      id: 'mountain',
      frames: Object.freeze([freezeFrame([
        '.......H........','......HHH.......','.....HWWWH......','....HWWWWWK.....',
        '...HWWWKKKKK....','..HWWKKKKKKKK...','.HWWKKKKKKKKKK..','HWWKKKKKKKKKKKK.',
        'WWKKKKKKKKKKKKKK','WKKKKKKKKKKKKKKK','KKKKKKKKKKKKKKKK','KKKKKKKKKKKKKKKK',
        'KKKKKKKKKKKKKKKK','KKKKKKKKKKKKKKKK','KKKKKKKKKKKKKKKK','KKKKKKKKKKKKKKKK',
      ])]),
    }),

    path: Object.freeze({
      id: 'path',
      frames: Object.freeze([freezeFrame([
        'TTTTTTSSSSTTTTTT','TTTTTSSSSSSTTTTT','TTTTSSSSSSSSTTTT','TTTTSSSSSSSSTTTT',
        'TTTTTSSSSSSTTTTT','TTTTTTSSSSTTTTTT','TTTTTTSSSSTTTTTT','TTTTTSSSSSSTTTTT',
        'TTTTSSSSSSSSTTTT','TTTTSSSSSSSSTTTT','TTTTTSSSSSSTTTTT','TTTTTTSSSSTTTTTT',
        'TTTTTTSSSSTTTTTT','TTTTTSSSSSSTTTTT','TTTTSSSSSSSSTTTT','TTTTSSSSSSSSTTTT',
      ])]),
    }),

    crate: Object.freeze({
      id: 'crate',
      frames: Object.freeze([
        freezeFrame([
          'DDDDDDDDDDDDDDDD',
          'DOOOOOOOOOOOOODD',
          'DODDDDDDDDDDOODD',
          'DODOOOOOOOODOODD',
          'DODOODDDDOODOODD',
          'DODOODRRDOODOODD',
          'DODOODRRDOODOODD',
          'DODDDDRRDDDDOODD',
          'DODDDDRRDDDDOODD',
          'DODOODRRDOODOODD',
          'DODOODRRDOODOODD',
          'DODOODDDDOODOODD',
          'DODOOOOOOOODOODD',
          'DODDDDDDDDDDOODD',
          'DOOOOOOOOOOOOODD',
          'DDDDDDDDDDDDDDDD',
        ]),
      ]),
    }),

    float: Object.freeze({
      id: 'float',
      frames: Object.freeze([
        freezeFrame([
          'gggggggggggggggg',
          'GGGGGGGGGGGGGGGG',
          'TTTTTTTTTTTTTTTT',
          'TTTTTTTTTTTTTTTT',
          'TTDDTTTTTTTTDDTT',
          'TDDDDTTTTTTDDDDT',
          'DDDDDDTTTTDDDDDD',
          'DDDDDDDDDDDDDDDD',
          '.DDDDDDDDDDDDDD.',
          '.DDDDDDDDDDDDDD.',
          '..DDDDDDDDDDDD..',
          '..DDDDDDDDDDDD..',
          '...DDDDDDDDDD...',
          '....DDDDDDDD....',
          '.....DDDDDD.....',
          '.......DD.......',
        ]),
      ]),
    }),

    water: Object.freeze({
      id: 'water',
      frames: Object.freeze([
        freezeFrame([
          'BBBBBBBBBBBBBBBB',
          'BBBBBBBBBBBBBBBB',
          'BBBBbbBBBBBBBBBB',
          'BBBbbbbBBBBBBBBB',
          'BBBBbbBBBBBBbbBB',
          'BBBBBBBBBBBbbbbB',
          'BBbbBBBBBBBBbbBB',
          'BbbbbBBBBBBBBBBB',
          'BBbbBBBBBBbbBBBB',
          'BBBBBBBBBbbbbBBB',
          'BBBBBBBBBBbbBBBB',
          'BBBbbBBBBBBBBBBB',
          'BBbbbbBBBBBBBBBB',
          'BBBbbBBBBBBbbBBB',
          'BBBBBBBBBbbbbBBB',
          'BBBBBBBBBBbbBBBB',
        ]),
        freezeFrame([
          'BBBBBBBBBBBBBBBB',
          'BBBBBBBBbbBBBBBB',
          'BBBBBBBbbbbBBBBB',
          'BBbbBBBBbbBBBBBB',
          'BbbbbBBBBBBBBBBB',
          'BBbbBBBBBBBBbbBB',
          'BBBBBBBBBBBbbbbB',
          'BBBBbbBBBBBBbbBB',
          'BBBbbbbBBBBBBBBB',
          'BBBBbbBBBBBBBBBB',
          'BBBBBBBBbbBBBBBB',
          'BBBBBBBbbbbBBBBB',
          'BBBBBBBBbbBBBBBB',
          'BBbbBBBBBBBBBBBB',
          'BbbbbBBBBBBBBBBB',
          'BBbbBBBBBBBBBBBB',
        ]),
      ]),
    }),

    loreUnknown: Object.freeze({
      id: 'loreUnknown',
      frames: Object.freeze([
        freezeFrame([
          'MMMMMMMMMMMMMMMM',
          'MNNNNNNNNNNNNNNM',
          'MNPPPPPPPPPPPPNM',
          'MNPNNNNNNNNNNPNM',
          'MNPNNCCCCCCNNPNM',
          'MNPNCCNNNNCCNPNM',
          'MNPNNNNNNCCNNPNM',
          'MNPNNNNNCCNNNPNM',
          'MNPNNNNCCNNNNPNM',
          'MNPNNNCCNNNNNPNM',
          'MNPNNNNNNNNNNPNM',
          'MNPNNNCCNNNNNPNM',
          'MNPNNNCCNNNNNPNM',
          'MNPNNNNNNNNNNPNM',
          'MNNNNNNNNNNNNNNM',
          'MMMMMMMMMMMMMMMM',
        ]),
      ]),
    }),

    loreKnown: Object.freeze({
      id: 'loreKnown',
      frames: Object.freeze([
        freezeFrame([
          'MMMMMMMMMMMMMMMM',
          'MNNNNNNNNNNNNNNM',
          'MNAAAAAAAAAAAANM',
          'MNANNNNNNNNNNANM',
          'MNANNNNAANNNNANM',
          'MNANNNAAAANNNANM',
          'MNANNAAAAAANNANM',
          'MNANAAAAAAAAAANM',
          'MNANAAAAAAAAAANM',
          'MNANNAAAAAANNANM',
          'MNANNNAAAANNNANM',
          'MNANNNNAANNNNANM',
          'MNANNNNNNNNNNANM',
          'MNAAAAAAAAAAAANM',
          'MNNNNNNNNNNNNNNM',
          'MMMMMMMMMMMMMMMM',
        ]),
      ]),
    }),

    cloud: Object.freeze({
      id: 'cloud',
      frames: Object.freeze([
        freezeFrame([
          '................',
          '................',
          '................',
          '.....CCCC.......',
          '...CCCCCCCC.....',
          '..CCWWCCCCCC....',
          '.CCWWWWCCCCCC...',
          'CCWWWWWWCCCCCC..',
          'CCWWWWWWCCCCCC..',
          '.CCWWWWCCCCCC...',
          '..CCCCCCCCCC....',
          '...CCCCCCCC.....',
          '.....CCCC.......',
          '................',
          '................',
          '................',
        ]),
      ]),
    }),

    astro: Object.freeze({
      id: 'astro',
      frames: Object.freeze([
        freezeFrame([
          '................',
          '.......C........',
          '....C..C..C.....',
          '.....C.C.C......',
          '..C...CCC...C...',
          '...C.CAAAC.C....',
          '....CAAWAAAC....',
          '.CCCCAWWWACCCC..',
          '....CAAWAAAC....',
          '...C.CAAAC.C....',
          '..C...CCC...C...',
          '.....C.C.C......',
          '....C..C..C.....',
          '.......C........',
          '................',
          '................',
        ]),
      ]),
    }),
  });

  function validateTile(tile) {
    return Boolean(
      tile &&
      Array.isArray(tile.frames) &&
      tile.frames.length > 0 &&
      tile.frames.every(frame =>
        frame.length === 16 &&
        frame.every(row =>
          typeof row === 'string' &&
          row.length === 16 &&
          Array.from(row).every(token =>
            token === TRANSPARENT || Object.prototype.hasOwnProperty.call(PALETTE, token)
          )
        )
      )
    );
  }

  function validate() {
    return Object.keys(TILES).every(id => validateTile(TILES[id]));
  }

  function get(id) {
    return TILES[id] || null;
  }

  function draw(id, x, y, options) {
    const tile = TILES[id];
    if (!tile) return false;
    const opts = options || {};
    const frame = tile.frames[Math.abs(Math.floor(opts.frame || 0)) % tile.frames.length];
    const scale = Math.max(1, Math.floor(opts.scale || 1));
    const ox = Math.round(x);
    const oy = Math.round(y);

    noStroke();
    for (let ty = 0; ty < 16; ty++) {
      const row = frame[ty];
      for (let tx = 0; tx < 16; tx++) {
        const token = row[tx];
        if (token === TRANSPARENT) continue;
        const rgb = PALETTE[token];
        fill(rgb[0], rgb[1], rgb[2]);
        rect(ox + tx * scale, oy + ty * scale, scale, scale);
      }
    }
    return true;
  }

  const api = Object.freeze({
    VERSION: '0.2.0',
    TILE_SIZE: 16,
    PALETTE,
    TILES,
    get,
    draw,
    validate,
  });

  if (!validate()) {
    throw new Error('AETHER_PIXEL_TILES_INVALID');
  }

  root.AetherPixelTiles = api;
})(typeof window !== 'undefined' ? window : globalThis);
