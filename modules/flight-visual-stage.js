/* ============================================================
   Aetherwake — Dragonfly Flight Visual Stage
   modules/flight-visual-stage.js

   Presentation-only open-sky rendering. Reads air-navigation state and travel
   profile but does not mutate navigation, encounter, route, story, or save state.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.2.0';

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

    // Clear the full frame opaquely first. The previous renderer only painted
    // opaque bands above the horizon, allowing old dialogue/toast pixels to
    // persist under translucent lower cloud layers during state transitions.
    fill(palette.low[0], palette.low[1], palette.low[2]);
    rect(0, 0, w, h);

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

    drawFarLandmarks(ctx, horizonY, palette);

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

    // Near-plane cloud banks and cliff silhouettes create a strong parallax
    // frame around the hero ship without obscuring the navigation corridor.
    fill(palette.cloud[0], palette.cloud[1], palette.cloud[2], 54);
    const nearDrift = Math.round((now * 0.018 * Math.max(0.35, ctx.travel.effectiveSpeed || 0.35)) % 120);
    for (let x = -160; x < w + 160; x += 190) {
      const xx = x + nearDrift;
      rect(xx, h - 92, 132, 18);
      rect(xx + 26, h - 105, 78, 15);
      rect(xx + 57, h - 72, 116, 11);
    }

    fill(12, 18, 29, 185);
    beginShape();
    vertex(0, h);
    vertex(0, h - 122);
    vertex(54, h - 146);
    vertex(104, h - 116);
    vertex(138, h - 78);
    vertex(166, h);
    endShape(CLOSE);
    beginShape();
    vertex(w, h);
    vertex(w, h - 104);
    vertex(w - 43, h - 132);
    vertex(w - 94, h - 108);
    vertex(w - 126, h - 67);
    vertex(w - 151, h);
    endShape(CLOSE);

    fill(42, 255, 181, 34);
    rect(39, h - 111, 3, 36);
    rect(w - 64, h - 99, 3, 29);
  }

  function drawFarLandmarks(ctx, horizonY, palette) {
    const w = ctx.width;
    const h = ctx.height;
    const now = ctx.now || 0;
    const speed = Math.max(0.2, ctx.travel.effectiveSpeed || 0.2);
    const drift = Math.round((now * 0.0018 * speed) % 90);

    // Distant vertical silhouettes give scale and route identity without
    // becoming gameplay geometry. They live behind the Dragonfly.
    noStroke();
    fill(16, 25, 39, 138);
    const towers = [
      [0.18, -12, 18, 66],
      [0.37, 18, 13, 46],
      [0.68, -24, 22, 82],
      [0.84, 11, 12, 38],
    ];
    for (let i = 0; i < towers.length; i++) {
      const [nx, offsetY, tw, th] = towers[i];
      const x = Math.round(w * nx) + (i % 2 ? drift : -drift) * 0.12;
      const y = horizonY + offsetY - th;
      rect(x, y, tw, th);
      rect(x - 9, y + th - 9, tw + 18, 9);
      fill(244, 174, 91, 72 + i * 10);
      rect(x + Math.floor(tw / 2), y + 8, 2, 2);
      fill(16, 25, 39, 138);
    }

    // Suspended route arches echo the dimensional sky-lane infrastructure.
    noFill();
    stroke(palette.accent[0], palette.accent[1], palette.accent[2], 30);
    strokeWeight(2);
    for (let i = 0; i < 3; i++) {
      const cx = Math.round(w * (0.27 + i * 0.24));
      const ry = horizonY + 18 + i * 6;
      arc(cx, ry, 92 + i * 24, 32 + i * 5, Math.PI, Math.PI * 2);
    }
    noStroke();
  }

  function drawForeground(ctx) {
    const w = ctx.width;
    const h = ctx.height;
    const now = ctx.now || 0;
    const palette = weatherPalette(ctx.travel.weather.id);
    const speed = Math.max(0.25, ctx.travel.effectiveSpeed || 0.25);
    const heading = ctx.state.heading || 0;
    const dir = Math.cos(heading) >= 0 ? 1 : -1;

    // Near cloud volume deliberately crosses the hero-object plane. The gap in
    // the center keeps controls readable while producing intermittent occlusion.
    noStroke();
    fill(palette.cloud[0], palette.cloud[1], palette.cloud[2], 78);
    const drift = Math.round((now * 0.028 * speed * dir) % 230);
    for (let i = -2; i < 7; i++) {
      const xx = i * 210 + drift - 180;
      const y = h - 106 + (i % 2) * 18;
      if (xx > w * 0.36 && xx < w * 0.64) continue;
      rect(xx, y, 162, 22);
      rect(xx + 31, y - 15, 93, 18);
      rect(xx + 68, y + 17, 128, 13);
    }

    // Close cliff fragments frame aggressive low-altitude flying and reinforce
    // parallax; high altitude suppresses most of this near geometry.
    if (ctx.state.altitude !== 'high') {
      fill(8, 13, 22, ctx.state.altitude === 'low' ? 225 : 150);
      beginShape();
      vertex(0, h);
      vertex(0, h - 82);
      vertex(32, h - 112);
      vertex(64, h - 74);
      vertex(96, h - 42);
      vertex(122, h);
      endShape(CLOSE);
      beginShape();
      vertex(w, h);
      vertex(w, h - 74);
      vertex(w - 31, h - 102);
      vertex(w - 70, h - 73);
      vertex(w - 102, h - 36);
      vertex(w - 126, h);
      endShape(CLOSE);
    }

    // Speed streaks live in the foreground, becoming visible only once travel
    // speed is high enough to communicate acceleration rather than idle noise.
    if (speed > 0.72) {
      stroke(205, 235, 238, Math.round(28 + Math.min(1, speed - 0.72) * 60));
      strokeWeight(1);
      const streakLength = Math.round(24 + speed * 30);
      for (let i = 0; i < 12; i++) {
        const sy = 100 + ((i * 47 + Math.round(now * 0.018)) % Math.max(120, h - 190));
        const sx = (i * 127 + Math.round(now * 0.06 * dir)) % (w + 120) - 60;
        line(sx, sy, sx - streakLength * dir, sy + Math.sin(heading) * 8);
      }
      noStroke();
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
      heading: ctx.state ? ctx.state.heading : 0,
      scale: 2.05
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
    drawForeground,
    drawRouteOverlay,
    drawLandmarkBeacons,
  });

  root.AetherFlightVisual = api;
})(typeof window !== 'undefined' ? window : globalThis);
