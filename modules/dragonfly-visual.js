/* ============================================================
   Aetherwake — Shared Dragonfly Visual Authority
   modules/dragonfly-visual.js

   One hero-object renderer for docked and open-sky presentation.
   Presentation only; no navigation, combat, quest, or persistence mutation.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';

  function draw(ctx) {
    const x = Math.round(ctx.x);
    const y = Math.round(ctx.y);
    const now = ctx.now || 0;
    const mode = ctx.mode === 'flight' ? 'flight' : 'dock';
    const heading = Number.isFinite(ctx.heading) ? ctx.heading : 0;
    const speed = Math.max(0, Number(ctx.speed) || 0);
    const shipScale = Number.isFinite(ctx.scale) && ctx.scale > 0 ? ctx.scale : 1;
    const wingAmp = mode === 'flight' ? 5 : 3;
    const wingRate = mode === 'flight' ? (0.004 + speed * 0.001) : 0.0022;
    const wing = Math.round(Math.sin(now * wingRate) * wingAmp);
    const pulse = 0.72 + Math.sin(now * 0.005) * 0.28;

    push();
    translate(x, y);
    if (mode === 'flight') rotate(heading);
    if (shipScale !== 1) scale(shipScale);

    if (mode === 'dock') {
      noStroke();
      fill(10, 12, 22, 75);
      rect(-48, 19, 102, 8);
    } else {
      noFill();
      stroke(42, 255, 181, Math.round(38 + pulse * 20));
      strokeWeight(1);
      rect(-52, -34, 104, 68);
      noStroke();
    }

    fill(78, 126, 151, mode === 'flight' ? 78 : 70);
    rect(-20, -35 - wing, 56, 17);
    rect(-20, 18 + wing, 56, 17);
    fill(124, 200, 232, 55);
    rect(-13, -31 - wing, 42, 8);
    rect(-13, 23 + wing, 42, 8);
    stroke(124, 200, 232, 100);
    line(-18, -27 - wing, 27, -22 - wing);
    line(-18, 27 + wing, 27, 22 + wing);
    noStroke();

    fill(35, 42, 55);
    rect(-42, -13, 78, 27);
    fill(78, 66, 58);
    rect(-36, -17, 60, 5);
    fill(120, 82, 56);
    rect(-38, 11, 67, 5);

    fill(37, 70, 85);
    rect(25, -9, 18, 18);
    fill(124, 200, 232, 150);
    rect(29, -5, 10, 6);

    fill(48, 52, 64);
    rect(-58, -5, 17, 10);
    rect(-64, -12, 6, 24);
    fill(124, 200, 232, 85);
    rect(-64, -14, 2, 28);

    fill(42, 255, 181, Math.round(75 * pulse));
    rect(-16, -7, 23, 14);
    fill(205, 245, 232, Math.round(190 * pulse));
    rect(-9, -3, 8, 6);
    fill(42, 255, 181, Math.round(185 * pulse));
    for (const [nx, ny] of [[12,-15],[12,13],[-34,-15],[-34,13]]) rect(nx, ny, 3, 3);

    fill(243, 176, 96, 165);
    rect(-28, -8, 4, 3);
    rect(-21, -8, 4, 3);

    const wake = mode === 'flight'
      ? Math.round(12 + speed * 18 + Math.sin(now * 0.008) * 3)
      : 8 + Math.round(Math.sin(now * 0.006) * 3);
    fill(124, 200, 232, mode === 'flight' ? 72 : 60);
    rect(-58 - wake, -3, wake, 6);
    fill(42, 255, 181, mode === 'flight' ? 55 : 45);
    rect(-55 - Math.floor(wake * 0.72), -1, Math.floor(wake * 0.72), 2);

    if (mode === 'dock') {
      stroke(94, 75, 58, 170);
      strokeWeight(1);
      line(-22, 14, -40, 32);
      line(18, 14, 36, 33);
      noStroke();
    }

    pop();
    return true;
  }

  root.AetherDragonflyVisual = Object.freeze({ VERSION, draw });
})(typeof window !== 'undefined' ? window : globalThis);
