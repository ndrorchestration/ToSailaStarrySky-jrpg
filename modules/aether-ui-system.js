/* ============================================================
   Aetherwake — Premium UI System
   modules/aether-ui-system.js

   Presentation-only visual primitives for Aetherwake menus.
   Keeps Memories-derived interaction behavior while replacing its
   prototype panel treatment with an Aetherwake-specific visual grammar.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';

  const THEME = Object.freeze({
    shadow: [7, 10, 20],
    glass: [16, 24, 38],
    glassSoft: [24, 36, 52],
    teal: [42, 255, 181],
    scioto: [124, 200, 232],
    ivory: [232, 220, 198],
    brass: [208, 160, 91],
    copper: [180, 90, 50],
    muted: [138, 153, 169]
  });

  function alphaColor(rgb, alpha) {
    return [rgb[0], rgb[1], rgb[2], alpha];
  }

  function panel(x, y, w, h, options) {
    const opts = options || {};
    const a = opts.alpha == null ? 245 : opts.alpha;
    const rail = opts.rail !== false;

    noStroke();
    fill(...alphaColor(THEME.shadow, Math.min(255, a)));
    rect(x + 3, y + 5, w, h);

    fill(...alphaColor(THEME.glass, a));
    rect(x, y, w, h);

    fill(...alphaColor(THEME.scioto, Math.round(a * 0.075)));
    rect(x + 4, y + 4, w - 8, h - 8);

    stroke(...alphaColor(THEME.scioto, Math.round(a * 0.22)));
    strokeWeight(1);
    noFill();
    rect(x + 1, y + 1, w - 2, h - 2);

    stroke(...alphaColor(THEME.brass, Math.round(a * 0.34)));
    rect(x + 5, y + 5, w - 10, h - 10);

    if (rail) {
      noStroke();
      fill(...alphaColor(THEME.teal, Math.round(a * 0.56)));
      rect(x + 14, y + 12, Math.max(28, w - 28), 2);
      for (let i = 0; i < 7; i++) {
        const px = x + 22 + i * Math.max(16, Math.floor((w - 44) / 6));
        rect(px, y + 9, 1, 8);
      }
    }
  }

  function primaryButton(label, x, y, w, h, options) {
    const opts = options || {};
    const active = opts.active !== false;
    const pulse = opts.pulse == null ? 1 : opts.pulse;

    noStroke();
    fill(...alphaColor(THEME.shadow, 210));
    rect(x + 2, y + 3, w, h);

    fill(...alphaColor(active ? THEME.glassSoft : THEME.glass, 236));
    rect(x, y, w, h);

    stroke(...alphaColor(active ? THEME.teal : THEME.muted, active ? 210 : 110));
    strokeWeight(active ? 2 : 1);
    noFill();
    rect(x, y, w, h);

    if (active) {
      noStroke();
      fill(...alphaColor(THEME.teal, Math.round(24 + 34 * pulse)));
      rect(x + 3, y + 3, w - 6, h - 6);
      fill(...alphaColor(THEME.brass, 150));
      rect(x + 10, y + h - 5, 32, 2);
    }

    textAlign(LEFT, CENTER);
    textFont('Press Start 2P');
    textSize(9);
    fill(...alphaColor(active ? THEME.ivory : THEME.muted, 245));
    text(label, x + 16, y + Math.floor(h / 2) + 1);
  }

  function sectionLabel(label, x, y, options) {
    const opts = options || {};
    textAlign(LEFT, TOP);
    textFont('Press Start 2P');
    textSize(opts.size || 7);
    fill(...alphaColor(opts.warm ? THEME.brass : THEME.scioto, opts.alpha || 180));
    text(label, x, y);
  }

  function divider(x, y, w, warm) {
    noStroke();
    fill(...alphaColor(warm ? THEME.brass : THEME.scioto, 88));
    rect(x, y, w, 1);
  }

  root.AetherUI = Object.freeze({
    VERSION,
    THEME,
    panel,
    primaryButton,
    sectionLabel,
    divider
  });
})(typeof window !== 'undefined' ? window : globalThis);
