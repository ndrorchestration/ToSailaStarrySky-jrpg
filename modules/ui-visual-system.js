/* ============================================================
   Aetherwake ? Shared UI Visual System
   modules/ui-visual-system.js

   Token and layout authority for player-facing HUD surfaces.
   Presentation only; no gameplay state mutation.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.3.0';
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

  function layoutDialogue(w, h) {
    const safe = TOKENS.safeMarginPx;
    const panelW = Math.min(820, w - safe * 2);
    const panelH = 128;
    return Object.freeze({ x: Math.round((w - panelW) / 2), y: h - safe - panelH, w: panelW, h: panelH });
  }

  function layoutFlight(w, h) {
    const safe = TOKENS.safeMarginPx;
    return Object.freeze({
      routeRibbon: Object.freeze({ x: safe, y: safe, w: Math.min(544, w - safe * 2), h: 64 }),
      nearestSignal: Object.freeze({ x: w - safe - 240, y: h - safe - 48, w: 240, h: 48 }),
    });
  }

  function layoutTitle(w, h) {
    const safe = TOKENS.safeMarginPx;
    const panelW = snap(Math.min(448, Math.max(400, w * 0.47)));
    const panelH = 216;
    const x = Math.max(safe, 64);
    const y = Math.max(safe, 84);
    return Object.freeze({
      panel: Object.freeze({ x, y, w: panelW, h: panelH }),
      artReserve: Object.freeze({ x: x + panelW + 24, y: safe, w: Math.max(0, w - (x + panelW + 48)), h: h - safe * 2 }),
    });
  }

  function panelRGBA() {
    return [11, 16, 33, Math.round(255 * TOKENS.panelOpacity)];
  }

  root.AetherUIVisualSystem = Object.freeze({ VERSION, TOKENS, snap, layoutCombat, layoutDialogue, layoutFlight, layoutTitle, panelRGBA });
})(typeof window !== 'undefined' ? window : globalThis);
