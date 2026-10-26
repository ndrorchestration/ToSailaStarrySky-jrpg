/* ============================================================
   Aetherwake — live Dragonfly interior presentation
   Presentation only: gameplay/quest/party state remain external.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';
  const INTERIOR_PATH = 'assets/preview/aetherwake-preview-interior-pixelart-v1.png';

  let interiorImage = null;
  let requested = false;
  let ready = false;

  function requestInterior() {
    if (requested || typeof loadImage !== 'function') return;
    requested = true;
    try {
      interiorImage = loadImage(
        INTERIOR_PATH,
        () => { ready = true; },
        () => { ready = false; interiorImage = null; }
      );
    } catch (_) {
      ready = false;
      interiorImage = null;
    }
  }

  function drawPaintedInterior() {
    requestInterior();
    if (!ready || !interiorImage || typeof image !== 'function') return false;

    const iw = interiorImage.width || width;
    const ih = interiorImage.height || height;
    const scale = Math.max(width / iw, height / ih);
    const dw = Math.ceil(iw * scale);
    const dh = Math.ceil(ih * scale);
    image(interiorImage, Math.floor((width - dw) / 2), Math.floor((height - dh) / 2), dw, dh);

    // Keep the authored plate readable while unifying it with the live runtime grade.
    noStroke();
    fill(8, 18, 32, 22);
    rect(0, 0, width, height);
    return true;
  }

  function drawWakeheart(now) {
    const cx = Math.round(width * 0.51);
    const cy = Math.round(height * 0.49);
    const pulse = 0.78 + Math.sin(now * 0.004) * 0.16;

    noStroke();
    fill(42, 255, 181, Math.round(18 * pulse));
    ellipse(cx, cy, 112, 72);
    fill(116, 209, 224, Math.round(26 * pulse));
    ellipse(cx, cy, 70, 44);
    fill(42, 255, 181, Math.round(92 * pulse));
    ellipse(cx, cy, 24, 15);
    fill(232, 220, 198, Math.round(150 * pulse));
    ellipse(cx - 3, cy - 3, 7, 5);
  }

  function drawCrew(party, now) {
    const authored = root.AetherAuthoredCharacterArt;
    if (!authored || typeof authored.drawProvisionalFieldCharacter !== 'function') return;

    const ids = Array.isArray(party)
      ? party.map(member => member && member.id).filter(Boolean)
      : ['ender'];

    const positions = {
      ender: [0.42, 0.72, 'up', 1.72],
      lyra: [0.28, 0.64, 'right', 1.60],
      ionia: [0.66, 0.61, 'left', 1.68],
      reson: [0.73, 0.73, 'left', 1.70],
      aepex: [0.56, 0.68, 'up', 1.70],
    };

    ids.forEach((id, index) => {
      const slot = positions[id] || [0.38 + index * 0.08, 0.72, 'up', 1.65];
      authored.drawProvisionalFieldCharacter(
        id,
        Math.round(width * slot[0]),
        Math.round(height * slot[1]),
        {
          anchor: 'bottom-center',
          scale: slot[3],
          action: 'idle',
          frame: Math.floor(now / 260),
          facing: slot[2],
        }
      );
    });
  }

  function drawInteractionCue() {
    const ui = root.AetherUIVisualSystem;
    const panel = ui && typeof ui.panelRGBA === 'function'
      ? ui.panelRGBA()
      : [11, 16, 33, 176];

    noStroke();
    fill(panel[0], panel[1], panel[2], Math.min(panel[3] || 176, 176));
    rect(width / 2 - 112, height - 38, 224, 24, 7);

    textAlign(CENTER, CENTER);
    textFont('VT323');
    textSize(14);
    fill(232, 220, 198, 210);
    text('L / ESC   DISEMBARK', width / 2, height - 26);
  }

  function draw(ctx) {
    const now = ctx && Number.isFinite(ctx.now) ? ctx.now : 0;
    const party = ctx && Array.isArray(ctx.party) ? ctx.party : [];

    if (!drawPaintedInterior()) return false;
    drawWakeheart(now);
    drawCrew(party, now);
    drawInteractionCue();
    return true;
  }

  root.AetherShipInteriorVisual = Object.freeze({
    VERSION,
    INTERIOR_PATH,
    draw,
  });
})(typeof window !== 'undefined' ? window : globalThis);
