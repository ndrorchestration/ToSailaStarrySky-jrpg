/* ============================================================
   Aetherwake ? Shared UI Visual System
   modules/ui-visual-system.js

   Token and layout authority for player-facing HUD surfaces.
   Presentation only; no gameplay state mutation.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.7.0';
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
    // Combat uses a compact lower-left JRPG command window rather than a full-height sidebar.
    const leftWidth = snap(Math.min(240, Math.max(224, w * 0.24)));
    const leftHeight = snap(Math.min(h - safe * 2, 240));
    const logWidth = snap(Math.min(184, Math.max(160, w * 0.175)));
    const logHeight = snap(Math.min(184, Math.max(136, h * 0.22)));
    return Object.freeze({
      statusPanel: Object.freeze({ x: safe, y: h - safe - leftHeight, w: leftWidth, h: leftHeight }),
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
    const panelH = 152;
    return Object.freeze({ x: Math.round((w - panelW) / 2), y: h - safe - panelH, w: panelW, h: panelH });
  }

  function layoutFlight(w, h) {
    const safe = TOKENS.safeMarginPx;
    const routeWidth = Math.min(456, w - safe * 2);
    const controlsWidth = 232;
    const signalWidth = 216;
    return Object.freeze({
      routeRibbon: Object.freeze({ x: safe, y: safe, w: routeWidth, h: 56 }),
      controlsHint: Object.freeze({ x: w - safe - controlsWidth, y: safe, w: controlsWidth, h: 24 }),
      nearestSignal: Object.freeze({ x: w - safe - signalWidth, y: h - safe - 44, w: signalWidth, h: 44 }),
      artReserve: Object.freeze({ x: safe, y: safe + 72, w: w - safe * 2, h: h - safe * 2 - 132 }),
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
