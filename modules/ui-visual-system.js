/* ============================================================
   Aetherwake ? Shared UI Visual System
   modules/ui-visual-system.js

   Token and layout authority for player-facing HUD surfaces.
   Presentation only; no gameplay state mutation.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';
  const TOKENS = Object.freeze({
    gridPx: 8,
    safeMarginPx: 24,
    cornerRadiusPx: 8,
    strokePx: 2,
    panelOpacity: 0.84,
    minBodyContrast: 4.5,
    maxPrimaryPanels: 2,
    typography: Object.freeze({ h1: 28, h2: 18, body: 16, caption: 12, micro: 10 }),
  });

  function snap(value) {
    return Math.round(value / TOKENS.gridPx) * TOKENS.gridPx;
  }

  function layoutCombat(w, h, hasLog) {
    const safe = TOKENS.safeMarginPx;
    const leftWidth = snap(Math.min(208, Math.max(184, w * 0.205)));
    const leftHeight = snap(Math.min(h - safe * 2, 432));
    const logWidth = snap(Math.min(184, Math.max(160, w * 0.175)));
    const logHeight = snap(Math.min(184, Math.max(136, h * 0.22)));
    return Object.freeze({
      statusPanel: Object.freeze({ x: safe, y: safe, w: leftWidth, h: leftHeight }),
      logPanel: hasLog ? Object.freeze({ x: w - safe - logWidth, y: safe + 72, w: logWidth, h: logHeight }) : null,
      centerReserve: Object.freeze({
        x: safe + leftWidth + 16,
        y: safe + 48,
        w: w - (safe * 2 + leftWidth + (hasLog ? logWidth + 32 : 16)),
        h: h - safe * 2 - 48,
      }),
    });
  }

  function panelRGBA() {
    return [11, 16, 33, Math.round(255 * TOKENS.panelOpacity)];
  }

  root.AetherUIVisualSystem = Object.freeze({ VERSION, TOKENS, snap, layoutCombat, panelRGBA });
})(typeof window !== 'undefined' ? window : globalThis);
