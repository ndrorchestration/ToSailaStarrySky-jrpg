/* ============================================================
   Aetherwake — Dragonfly Flight Visual Stage
   modules/flight-visual-stage.js

   Presentation-only open-sky rendering. Reads air-navigation state and travel
   profile but does not mutate navigation, encounter, route, story, or save state.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';

  function altitudeProfile(altitude) {
    if (altitude === 'high') return { horizon: 0.60, cloudBase: 0.72, haze: 0.18 };
    if (altitude === 'low') return { horizon: 0.48, cloudBase: 0.58, haze: 0.42 };
    return { horizon: 0.54, cloudBase: 0.65, haze: 0.28 };
  }

  function weatherPalette(weatherId) {
    if (weatherId === 'aether-squall') {
      return {
        top: [24, 21, 48],
        mid: [50, 49, 82],
        low: [83, 86, 112],
        cloud: [98, 112, 137],
        accent: [124, 200, 232],
      };
    }
    if (weatherId === 'crosswind') {
      return {
        top: [22, 31, 54],
        mid: [47, 70, 91],
        low: [88, 108, 125],
        cloud: [150, 169, 181],
        accent: [205, 225, 230],
      };
    }
    return {
      top: [18, 33, 58],
      mid: [47, 82, 112],
      low: [105, 137, 155],
      cloud: [190, 206, 213],
      accent: [124, 200, 232],
    };
  }

  function drawBackdrop(ctx) {
    const w = ctx.width;
    const h = ctx.height;
    const now = ctx.now || 0;
    const state = ctx.state;
    const profile = altitudeProfile(state.altitude);
    const palette = weatherPalette(ctx.travel.weather.id);
    const horizonY = Math.round(h * profile.horizon);

    noStroke();

    const bands = [palette.top, palette.mid, palette.low];
    const bandH = Math.ceil(horizonY / bands.length);
    for (let i = 0; i < bands.length; i++) {
      const c = bands[i];
      fill(c[0], c[1], c[2]);
      rect(0, i * bandH, w, bandH + 1);
    }

    // Horizon haze line.
    fill(205, 225, 230, Math.round(30 + profile.haze * 80));
    rect(0, horizonY - 4, w, 8);

    // Multiple cloud planes move at different rates to make speed legible.
    for (let layer = 0; layer < 4; layer++) {
      const y = Math.round(h * (profile.cloudBase + layer * 0.055));
      const speed = Math.max(0.2, ctx.travel.effectiveSpeed || 0.2);
      const dir = Math.cos(state.heading || 0) >= 0 ? 1 : -1;
      const offset = Math.round((now * (0.01 + layer * 0.005) * speed * dir + layer * 89) % 180);
      const alpha = 35 + layer * 16;
      fill(palette.cloud[0], palette.cloud[1], palette.cloud[2], alpha);
      for (let x = -240; x < w + 240; x += 140) {
        const xx = x + offset;
        rect(xx, y, 94, 8 + layer * 2);
        rect(xx + 20, y - 6, 48, 6);
        rect(xx + 55, y + 7, 72, 5);
      }
    }

    // Floating-island silhouettes at different depths.
    const islands = [
      [0.10, 0.30, 78, 22, 0.25],
      [0.27, 0.21, 48, 15, 0.18],
      [0.76, 0.26, 104, 30, 0.35],
      [0.90, 0.17, 42, 13, 0.14],
    ];
    for (let i = 0; i < islands.length; i++) {
      const [nx, ny, iw, ih, drift] = islands[i];
      const shift = Math.round(Math.sin(now * 0.0004 + i) * 7 * drift);
      const x = Math.round(w * nx) + shift;
      const y = Math.round(h * ny);
      fill(22, 30, 46, 205);
      rect(x, y, iw, ih);
      rect(x + Math.floor(iw * 0.18), y + ih, Math.floor(iw * 0.64), 5);
      rect(x + Math.floor(iw * 0.34), y + ih + 5, Math.floor(iw * 0.30), 4);
      fill(244, 174, 91, 120);
      if (i !== 1) rect(x + 12, y + 6, 2, 2);
      if (iw > 70) rect(x + 36, y + 10, 2, 2);
    }

    // Weather-specific motion cues.
    if (ctx.travel.weather.id === 'crosswind') {
      stroke(palette.accent[0], palette.accent[1], palette.accent[2], 55);
      strokeWeight(1);
      for (let i = 0; i < 10; i++) {
        const y = 70 + i * 43;
        const x = Math.round((now * 0.06 + i * 113) % (w + 120)) - 60;
        line(x, y, x + 50, y - 8);
      }
      noStroke();
    }

    if (ctx.travel.weather.id === 'aether-squall') {
      fill(42, 255, 181, 70);
      for (let i = 0; i < 18; i++) {
        const x = Math.round((i * 97 + now * 0.018) % w);
        const y = 36 + ((i * 71) % Math.round(h * 0.58));
        rect(x, y, 2, 3);
      }
    }
  }

  function drawDragonfly(ctx) {
    const visual = root.AetherDragonflyVisual;
    if (!visual || typeof visual.draw !== 'function') {
      throw new Error('AETHER_DRAGONFLY_VISUAL_UNAVAILABLE');
    }
    return visual.draw({
      mode: 'flight',
      x: ctx.x,
      y: ctx.y,
      now: ctx.now || 0,
      speed: ctx.travel ? ctx.travel.effectiveSpeed : 0,
      heading: ctx.state ? ctx.state.heading : 0
    });
  }

  function drawRouteOverlay(ctx) {
    const w = ctx.width;
    const h = ctx.height;
    const travel = ctx.travel;
    const state = ctx.state;

    // Keep HUD diegetic and compact: route ribbon, not a giant debug map.
    noStroke();
    fill(9, 13, 24, 205);
    rect(22, 20, Math.min(550, w - 44), 62);

    fill(42, 255, 181, 120);
    rect(34, 31, 112, 2);

    textAlign(LEFT, TOP);
    textFont('Press Start 2P');
    textSize(8);
    fill(232, 220, 198, 220);
    text('OPEN-SKY FLIGHT', 34, 39);

    textFont('VT323');
    textSize(13);
    fill(124, 200, 232, 220);
    text(
      'ALT ' + state.altitude.toUpperCase() +
      '  WEATHER ' + travel.weather.label +
      '  SPEED ' + travel.effectiveSpeed.toFixed(2) +
      '  PRESSURE ' + travel.encounterPressure,
      34, 56
    );

    if (travel.route && travel.route.route) {
      const progress = Math.round(travel.route.progress * 100);
      fill(205, 225, 230, 185);
      text('ROUTE ' + travel.route.route.label + '  //  ' + progress + '%', 290, 39);
      fill(31, 44, 63, 230);
      rect(290, 60, 218, 6);
      fill(42, 255, 181, 170);
      rect(291, 61, Math.round(216 * travel.route.progress), 4);
    }

    textAlign(RIGHT, TOP);
    textFont('Press Start 2P');
    textSize(7);
    fill(232, 220, 198, 130);
    text('ARROWS STEER  Q/E ALT  D DOCK  L/ESC LAND', w - 28, 24);
    textAlign(LEFT, TOP);
  }

  function drawLandmarkBeacons(ctx) {
    const nav = ctx.nav;
    const state = ctx.state;
    const w = ctx.width;
    const h = ctx.height;

    // Compact edge beacons preserve navigation awareness without reverting to
    // the old full-screen map visualization.
    const nearest = nav.nearestLandmark ? nav.nearestLandmark(state) : null;
    const approach = ctx.travel.approach;

    if (nearest && nearest.landmark) {
      noStroke();
      fill(9, 13, 24, 190);
      rect(w - 268, h - 74, 246, 48);
      textAlign(LEFT, TOP);
      textFont('Press Start 2P');
      textSize(7);
      fill(42, 255, 181, 180);
      text('NEAREST SIGNAL', w - 254, h - 62);
      textFont('VT323');
      textSize(13);
      fill(232, 220, 198, 215);
      text(nearest.landmark.label + '  ' + nearest.distance.toFixed(1), w - 254, h - 47);
    }

    if (approach && approach.active && approach.landmark) {
      fill(244, 174, 91, 180);
      rect(w / 2 - 72, h - 31, 144, 3);
      textAlign(CENTER, TOP);
      textFont('Press Start 2P');
      textSize(7);
      fill(244, 174, 91, 200);
      text(
        approach.berthAvailable ? 'BERTH AVAILABLE // D TO DOCK' : 'APPROACH // ' + approach.landmark.label,
        w / 2, h - 24
      );
      textAlign(LEFT, TOP);
    }
  }

  const api = Object.freeze({
    VERSION,
    altitudeProfile,
    weatherPalette,
    drawBackdrop,
    drawDragonfly,
    drawRouteOverlay,
    drawLandmarkBeacons,
  });

  root.AetherFlightVisual = api;
})(typeof window !== 'undefined' ? window : globalThis);
