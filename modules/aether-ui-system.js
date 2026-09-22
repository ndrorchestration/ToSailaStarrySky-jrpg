/* ============================================================
   Aetherwake — Premium UI System
   modules/aether-ui-system.js

   Presentation-only visual primitives for Aetherwake menus.
   Keeps Memories-derived interaction behavior while replacing its
   prototype panel treatment with an Aetherwake-specific visual grammar.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.2.0';

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

  function clamp01(value) {
    return Math.max(0, Math.min(1, Number(value) || 0));
  }

  function easeOutCubic(t) {
    const x = 1 - clamp01(t);
    return 1 - x * x * x;
  }

  function easeInOutCubic(t) {
    const x = clamp01(t);
    return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
  }

  function enter(now, duration) {
    const d = Math.max(1, duration || 240);
    return easeOutCubic((Number(now) || 0) / d);
  }

  function pulse(now, speed, floor) {
    const lo = floor == null ? 0.28 : clamp01(floor);
    const hz = speed == null ? 0.0032 : speed;
    return lo + (1 - lo) * (Math.sin((Number(now) || 0) * hz) * 0.5 + 0.5);
  }

  const motion = Object.freeze({
    clamp01,
    easeOutCubic,
    easeInOutCubic,
    enter,
    pulse
  });

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
    const p = opts.pulse == null ? 1 : clamp01(opts.pulse);

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
      fill(...alphaColor(THEME.teal, Math.round(20 + 34 * p)));
      rect(x + 3, y + 3, w - 6, h - 6);
      fill(...alphaColor(THEME.brass, 150));
      rect(x + 10, y + h - 5, 32 + Math.round(10 * p), 2);

      // Selected-command locator. Small, readable, and cheap to render.
      fill(...alphaColor(THEME.ivory, Math.round(155 + 80 * p)));
      rect(x - 7, y + Math.floor(h / 2) - 2, 3, 5);
      rect(x - 3, y + Math.floor(h / 2) - 1, 2, 3);
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

  function keyHint(key, label, x, y, options) {
    const opts = options || {};
    const keyText = String(key || '').toUpperCase();
    const body = label == null ? '' : String(label);
    const keyW = Math.max(22, 12 + keyText.length * 7);
    const a = opts.alpha == null ? 190 : opts.alpha;

    noStroke();
    fill(...alphaColor(THEME.shadow, Math.min(230, a)));
    rect(x, y, keyW, 20);
    stroke(...alphaColor(opts.warm ? THEME.brass : THEME.scioto, Math.min(220, a)));
    strokeWeight(1);
    noFill();
    rect(x, y, keyW, 20);

    noStroke();
    textAlign(CENTER, CENTER);
    textFont('Press Start 2P');
    textSize(6);
    fill(...alphaColor(THEME.ivory, Math.min(245, a + 30)));
    text(keyText, x + Math.floor(keyW / 2), y + 11);

    if (body) {
      textAlign(LEFT, CENTER);
      textFont('VT323');
      textSize(13);
      fill(...alphaColor(THEME.muted, a));
      text(body, x + keyW + 8, y + 11);
    }
    return keyW;
  }

  function meter(x, y, w, value, maxValue, options) {
    const opts = options || {};
    const max = Math.max(1, Number(maxValue) || 1);
    const ratio = clamp01((Number(value) || 0) / max);
    const h = opts.height || 7;
    const warm = opts.warm === true;

    noStroke();
    fill(...alphaColor(THEME.shadow, 220));
    rect(x, y, w, h);
    fill(...alphaColor(warm ? THEME.brass : THEME.teal, 205));
    rect(x + 1, y + 1, Math.max(0, Math.round((w - 2) * ratio)), Math.max(1, h - 2));

    stroke(...alphaColor(THEME.scioto, 80));
    strokeWeight(1);
    noFill();
    rect(x, y, w, h);
    return ratio;
  }

  function statRow(label, value, x, y, w, options) {
    const opts = options || {};
    textAlign(LEFT, TOP);
    textFont('VT323');
    textSize(opts.size || 14);
    fill(...alphaColor(THEME.muted, 205));
    text(String(label || ''), x, y);
    textAlign(RIGHT, TOP);
    fill(...alphaColor(opts.warm ? THEME.brass : THEME.ivory, 235));
    text(String(value == null ? '' : value), x + w, y);
    textAlign(LEFT, TOP);
  }

  root.AetherUI = Object.freeze({
    VERSION,
    THEME,
    motion,
    panel,
    primaryButton,
    sectionLabel,
    divider,
    keyHint,
    meter,
    statRow
  });
})(typeof window !== 'undefined' ? window : globalThis);
