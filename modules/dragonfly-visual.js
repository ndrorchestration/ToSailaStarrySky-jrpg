/* ============================================================
   Aetherwake — Shared Dragonfly Visual Authority
   modules/dragonfly-visual.js

   2.5D hero-object renderer for docked and open-sky presentation.
   Presentation only; no navigation, combat, quest, or persistence mutation.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.2.0';

  function wingMembrane(x0, y0, length, widthPx, sweep, alpha, warm) {
    push();
    translate(x0, y0);
    rotate(sweep);
    noStroke();
    fill(warm ? 205 : 124, warm ? 225 : 200, warm ? 190 : 232, alpha);
    beginShape();
    vertex(0, -2);
    vertex(length * 0.34, -widthPx);
    vertex(length, -Math.round(widthPx * 0.45));
    vertex(length * 0.82, Math.round(widthPx * 0.35));
    vertex(length * 0.22, Math.round(widthPx * 0.58));
    endShape(CLOSE);
    stroke(205, 235, 238, Math.min(175, alpha + 45));
    strokeWeight(1);
    line(3, 0, length - 3, -Math.round(widthPx * 0.28));
    line(Math.round(length * 0.25), 0, Math.round(length * 0.54), -Math.round(widthPx * 0.68));
    noStroke();
    pop();
  }

  function drawWingPair(now, mode, speed, bank) {
    const beatRate = mode === 'flight' ? 0.005 + speed * 0.0012 : 0.0022;
    const beat = Math.sin(now * beatRate);
    const spread = mode === 'flight' ? 1 : 0.82;
    const foreSweep = -0.12 + beat * 0.035;
    const aftSweep = 0.16 - beat * 0.025;
    const upperBias = Math.round(bank * 2);
    const lowerBias = Math.round(-bank * 2);

    wingMembrane(-11, -11 + upperBias, 69 * spread, 17, foreSweep, 88, false);
    wingMembrane(-14, -5 + upperBias, 58 * spread, 13, aftSweep, 67, true);

    push();
    scale(1, -1);
    wingMembrane(-11, -11 + lowerBias, 69 * spread, 17, foreSweep, 88, false);
    wingMembrane(-14, -5 + lowerBias, 58 * spread, 13, aftSweep, 67, true);
    pop();
  }

  function drawHull(pulse, mode) {
    // Tapered lived-in fuselage: broad cabin, narrow tail, pointed helm.
    noStroke();
    fill(25, 34, 45);
    beginShape();
    vertex(-60, -6);
    vertex(-42, -14);
    vertex(15, -16);
    vertex(48, -9);
    vertex(60, 0);
    vertex(48, 9);
    vertex(15, 16);
    vertex(-42, 14);
    endShape(CLOSE);

    fill(64, 58, 52);
    beginShape();
    vertex(-38, -12);
    vertex(13, -13);
    vertex(34, -7);
    vertex(28, -2);
    vertex(-34, -3);
    endShape(CLOSE);

    // Helm glazing.
    fill(75, 122, 145, 175);
    beginShape();
    vertex(34, -7);
    vertex(50, -5);
    vertex(56, 0);
    vertex(50, 5);
    vertex(34, 7);
    vertex(27, 0);
    endShape(CLOSE);
    fill(195, 230, 235, 115);
    beginShape();
    vertex(38, -4);
    vertex(48, -3);
    vertex(52, 0);
    vertex(47, 1);
    vertex(37, 0);
    endShape(CLOSE);

    // Warm cabin windows make the ship feel inhabited.
    fill(243, 176, 96, mode === 'flight' ? 175 : 205);
    rect(-25, -8, 6, 3);
    rect(-15, -8, 6, 3);
    rect(-5, -8, 6, 3);
    fill(243, 176, 96, 105);
    rect(-22, 6, 5, 2);
    rect(-12, 6, 5, 2);

    // Aether core heart.
    fill(42, 255, 181, Math.round(80 + pulse * 55));
    ellipse(7, 0, 20, 20);
    fill(205, 245, 232, Math.round(150 + pulse * 95));
    ellipse(7, 0, 8, 8);

    // Tail boom and pressure vane.
    fill(40, 47, 57);
    beginShape();
    vertex(-60, -5);
    vertex(-82, -3);
    vertex(-88, 0);
    vertex(-82, 3);
    vertex(-60, 5);
    endShape(CLOSE);
    fill(124, 200, 232, 120);
    rect(-86, -13, 3, 26);
    fill(181, 103, 91, 150);
    rect(-81, -9, 8, 3);
    rect(-81, 6, 8, 3);
  }

  function drawWake(now, mode, speed) {
    const wake = mode === 'flight'
      ? Math.round(18 + speed * 25 + Math.sin(now * 0.008) * 4)
      : 8 + Math.round(Math.sin(now * 0.006) * 3);
    noStroke();
    fill(124, 200, 232, mode === 'flight' ? 74 : 45);
    beginShape();
    vertex(-82, -4);
    vertex(-82 - wake, -2);
    vertex(-91 - Math.round(wake * 1.25), 0);
    vertex(-82 - wake, 2);
    vertex(-82, 4);
    endShape(CLOSE);
    fill(42, 255, 181, mode === 'flight' ? 62 : 38);
    rect(-83 - Math.round(wake * 0.82), -1, Math.round(wake * 0.82), 2);
  }

  function draw(ctx) {
    const x = Math.round(ctx.x);
    const y = Math.round(ctx.y);
    const now = ctx.now || 0;
    const mode = ctx.mode === 'flight' ? 'flight' : 'dock';
    const heading = Number.isFinite(ctx.heading) ? ctx.heading : 0;
    const speed = Math.max(0, Number(ctx.speed) || 0);
    const shipScale = Number.isFinite(ctx.scale) && ctx.scale > 0 ? ctx.scale : 1;
    const pulse = 0.72 + Math.sin(now * 0.005) * 0.28;
    const bank = mode === 'flight' ? Math.sin(heading) * Math.min(1, speed * 0.6 + 0.25) : 0;

    push();
    translate(x, y);
    if (mode === 'flight') rotate(heading);
    if (shipScale !== 1) scale(shipScale);

    if (mode === 'dock') {
      noStroke();
      fill(5, 8, 15, 95);
      ellipse(-4, 25, 132, 18);
    } else {
      noFill();
      stroke(42, 255, 181, Math.round(24 + pulse * 18));
      strokeWeight(1);
      ellipse(0, 0, 142, 72);
      noStroke();
    }

    drawWake(now, mode, speed);
    drawWingPair(now, mode, speed, bank);
    drawHull(pulse, mode);

    // Docking struts disappear into the hull in flight.
    if (mode === 'dock') {
      stroke(94, 75, 58, 190);
      strokeWeight(2);
      line(-28, 13, -42, 30);
      line(20, 13, 37, 30);
      line(-42, 30, -52, 30);
      line(37, 30, 47, 30);
      noStroke();
    }

    pop();
    return true;
  }

  root.AetherDragonflyVisual = Object.freeze({ VERSION, draw });
})(typeof window !== 'undefined' ? window : globalThis);
