/* ============================================================
   Aetherwake ? Shared Dragonfly Visual Authority
   modules/dragonfly-visual.js

   2.5D hero-object renderer for docked and open-sky presentation.
   Presentation only; no navigation, combat, quest, or persistence mutation.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.4.0';
  const PROPORTIONS = Object.freeze({
    adultHeightUnits: 1,
    bodyLengthAdultHeights: 3.0,
    wingSpanBodyLengths: 2.4,
    runtimeBodyLengthPx: 146,
    runtimeWingSpanPx: 350,
    normalFlightMaxScreenWidthRatio: 0.28,
    combatMaxScreenWidthRatio: 0.25,
  });

  const PALETTE = Object.freeze({
    hullDark: [43, 48, 47],
    hullMid: [69, 73, 68],
    reclaimedBronze: [121, 91, 57],
    brass: [182, 131, 64],
    canopy: [65, 121, 145],
    glassLight: [196, 232, 235],
    aether: [42, 255, 181],
    aetherBlue: [124, 200, 232],
    cabin: [243, 176, 96],
    navRed: [255, 111, 88],
  });

  function membrane(points, alpha, warm, detailed = true) {
    noStroke();
    const c = warm ? [205,225,190] : PALETTE.aetherBlue;
    fill(c[0], c[1], c[2], alpha);
    beginShape();
    for (const point of points) vertex(point[0], point[1]);
    endShape(CLOSE);

    stroke(205, 235, 238, Math.min(185, alpha + 55));
    strokeWeight(0.8);
    for (let i = 1; i < points.length - 1; i += (detailed ? 1 : 2)) {
      line(points[0][0], points[0][1], points[i][0], points[i][1]);
    }
    noStroke();
  }

  function drawWingPair(now, mode, speed, bank) {
    // Four long translucent wings are the primary Dragonfly recognition cue.
    const beatRate = mode === 'flight' ? 0.0048 + speed * 0.0011 : 0.0021;
    const beat = Math.sin(now * beatRate);
    const flare = mode === 'flight' ? 1.0 : 0.83;
    const vertical = beat * (mode === 'flight' ? 5.5 : 2.5);
    const bankBias = bank * 5;

    const drawSide = sign => {
      const y = sign * (11 + bankBias * sign);
      const foreTipY = sign * (34 + vertical * sign);
      const aftTipY = sign * (28 - vertical * 0.65 * sign);
      membrane([
        [-12, y], [26, sign * 17], [94 * flare, foreTipY], [74 * flare, sign * 7], [8, sign * 5]
      ], mode === 'flight' ? 88 : 72, false, mode === 'flight');
      membrane([
        [-17, sign * 7], [18, sign * 13], [78 * flare, aftTipY], [61 * flare, sign * 4], [-5, sign * 2]
      ], mode === 'flight' ? 68 : 58, true, mode === 'flight');
      // Dark structural spar and bright leading edge give the membrane thickness
      // and make each wing read as engineered, not just translucent geometry.
      if (mode === 'flight') {
        stroke(54,67,66,145); strokeWeight(1.25);
        line(-10, y, 92*flare, foreTipY);
        stroke(PALETTE.glassLight[0],PALETTE.glassLight[1],PALETTE.glassLight[2],90);
        strokeWeight(0.7);
        line(7, sign*5, 73*flare, sign*7);
        noStroke();
      }
    };

    drawSide(-1);
    drawSide(1);

    // Wing roots and articulation pivots.
    fill(...PALETTE.brass);
    ellipse(-10, -10, 5, 5);
    ellipse(-10, 10, 5, 5);
    ellipse(-17, -6, 4, 4);
    ellipse(-17, 6, 4, 4);
  }

  function drawHull(pulse, mode) {
    // Long, narrow fuselage with a distinct thorax/cabin and segmented tail.
    noStroke();
    fill(...PALETTE.hullDark);
    beginShape();
    vertex(-56,-7); vertex(-35,-15); vertex(6,-18); vertex(30,-14);
    vertex(57,-7); vertex(72,0); vertex(57,7); vertex(30,14);
    vertex(6,18); vertex(-35,15); vertex(-56,7);
    endShape(CLOSE);

    // Reclaimed upper shell and thorax cap.
    fill(...PALETTE.reclaimedBronze);
    beginShape();
    vertex(-34,-13); vertex(8,-15); vertex(31,-11); vertex(40,-6);
    vertex(19,-3); vertex(-31,-4);
    endShape(CLOSE);

    // Lower hull shadow and brass chine create a readable 2.5D body volume.
    fill(26,31,31,180);
    beginShape();
    vertex(-44,5); vertex(4,10); vertex(33,7); vertex(54,3);
    vertex(39,10); vertex(5,16); vertex(-35,13); vertex(-53,7);
    endShape(CLOSE);
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],145);
    strokeWeight(1.15);
    line(-34,11,28,10); line(28,10,49,5); noStroke();

    // Distinct forward helm glazing.
    fill(PALETTE.canopy[0],PALETTE.canopy[1],PALETTE.canopy[2],205);
    beginShape();
    vertex(39,-9); vertex(59,-6); vertex(70,0); vertex(59,6); vertex(39,9); vertex(29,0);
    endShape(CLOSE);
    fill(PALETTE.glassLight[0],PALETTE.glassLight[1],PALETTE.glassLight[2],105);
    beginShape();
    vertex(43,-5); vertex(57,-4); vertex(64,0); vertex(53,1); vertex(39,0);
    endShape(CLOSE);
    // Framed canopy panes make the helm feel constructed and habitable.
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],150);
    strokeWeight(0.9);
    line(42,-8,42,8); line(52,-6,52,6); line(61,-4,61,4); noStroke();

    // Thorax ring visually separates cabin/core from the abdomen-like tail.
    noFill();
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],190);
    strokeWeight(2);
    ellipse(4,0,31,36);
    noStroke();

    // Aether core heart.
    fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],Math.round(92 + pulse * 70));
    ellipse(7,0,22,22);
    fill(218,250,239,Math.round(160 + pulse * 90));
    ellipse(7,0,8,8);

    // Warm cabin windows make the ship feel inhabited.
    fill(PALETTE.cabin[0],PALETTE.cabin[1],PALETTE.cabin[2],mode === 'flight' ? 185 : 215);
    rect(-28,-8,7,3,1); rect(-17,-9,7,3,1); rect(-6,-9,6,3,1);
    fill(PALETTE.cabin[0],PALETTE.cabin[1],PALETTE.cabin[2],105);
    rect(-25,6,6,2,1); rect(-14,7,5,2,1);

    // Segmented tail boom: narrower than the hull and unmistakably insect-like.
    const tail = [
      [-56,0,18,9],[-72,0,15,7],[-85,0,13,6],[-96,0,10,5]
    ];
    for (let i = 0; i < tail.length; i++) {
      const [cx,cy,w,h] = tail[i];
      fill(i % 2 ? 61 : 72, i % 2 ? 66 : 72, i % 2 ? 64 : 68);
      ellipse(cx,cy,w,h);
      fill(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],135);
      rect(cx - w*0.08, -h*0.5, Math.max(1,w*0.12), h);
    }

    // Dorsal service spine adds a small handcrafted silhouette break.
    fill(...PALETTE.reclaimedBronze);
    quad(-50,-5,-25,-8,-20,-5,-48,-2);
    fill(...PALETTE.brass);
    rect(-39,-8,2,4,0.5); rect(-30,-9,2,4,0.5);

    // Tail pressure vane / rudder.
    fill(PALETTE.aetherBlue[0],PALETTE.aetherBlue[1],PALETTE.aetherBlue[2],125);
    beginShape();
    vertex(-101,-2); vertex(-111,-12); vertex(-108,0); vertex(-111,12); vertex(-101,2);
    endShape(CLOSE);
  }

  function drawMechanicalDetail(now, mode, pulse) {
    const spin = now * 0.018;

    // Twin articulated engine pods beneath/above the thorax.
    for (const side of [-1,1]) {
      const py = side * 18;
      fill(63,66,61);
      ellipse(-1,py,23,10);
      fill(131,109,76);
      ellipse(-1,py,12,7);
      noFill();
      stroke(94,225,211,95 + pulse*65);
      strokeWeight(1.1);
      arc(-1,py,17,17,spin,spin + PI*1.35);
      noStroke();
    }

    // Brass ribs and service seams.
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],155);
    strokeWeight(1);
    line(-38,-11,-38,11); line(-26,-14,-26,14); line(23,-12,23,12);
    noFill();
    rect(-12,-10,15,20,3);
    noStroke();

    // Four shield nodes are a canonical technology cue.
    const nodes=[[-20,-15],[-20,15],[23,-12],[23,12]];
    for (const [x,y] of nodes) {
      fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],150 + pulse*70);
      ellipse(x,y,3.5,3.5);
    }

    // Navigation lamps.
    fill(PALETTE.navRed[0],PALETTE.navRed[1],PALETTE.navRed[2],180 + pulse*50);
    ellipse(-48,-9,3,3);
    fill(79,231,188,180 + pulse*50);
    ellipse(-48,9,3,3);

    // Small exposed conduit ties the aether core to the helm and reinforces
    // the handmade/maintainable solarpunk machinery language.
    stroke(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],95 + pulse*45);
    strokeWeight(1);
    line(17,-6,33,-5); line(17,6,33,5); noStroke();

    // Deck canopy and light solar strip keep the craft handmade/solarpunk.
    fill(71,64,54,235);
    quad(-23,-17,12,-19,28,-13,-10,-12);
    stroke(205,178,126,145);
    strokeWeight(1);
    line(-18,-17,-10,-31); line(7,-18,14,-30); line(-10,-31,14,-30);
    noStroke();
    fill(132,198,190,mode === 'flight' ? 160 : 130);
    quad(-9,-31,27,-30,36,-24,-1,-25);
  }

  function drawWake(now, mode, speed) {
    const wake = mode === 'flight'
      ? Math.round(22 + speed*27 + Math.sin(now*0.008)*4)
      : 9 + Math.round(Math.sin(now*0.006)*3);
    noStroke();
    fill(PALETTE.aetherBlue[0],PALETTE.aetherBlue[1],PALETTE.aetherBlue[2],mode === 'flight' ? 72 : 42);
    beginShape();
    vertex(-102,-3); vertex(-102-wake,-2); vertex(-110-Math.round(wake*1.15),0);
    vertex(-102-wake,2); vertex(-102,3);
    endShape(CLOSE);
    fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],mode === 'flight' ? 64 : 36);
    rect(-103-Math.round(wake*0.82),-1,Math.round(wake*0.82),2);
  }

  function draw(ctx) {
    const x = Math.round(ctx.x);
    const y = Math.round(ctx.y);
    const now = ctx.now || 0;
    const mode = ctx.mode === 'flight' ? 'flight' : 'dock';
    const heading = Number.isFinite(ctx.heading) ? ctx.heading : 0;
    const speed = Math.max(0,Number(ctx.speed)||0);
    const shipScale = Number.isFinite(ctx.scale) && ctx.scale > 0 ? ctx.scale : 1;
    const pulse = 0.72 + Math.sin(now*0.005)*0.28;
    const bank = mode === 'flight' ? Math.sin(heading)*Math.min(1,speed*0.6+0.25) : 0;

    push();
    translate(x,y);
    if (mode === 'flight') rotate(heading);
    if (shipScale !== 1) scale(shipScale);

    if (mode === 'dock') {
      noStroke(); fill(5,8,15,90); ellipse(-9,27,152,18);
    } else {
      noFill();
      stroke(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],Math.round(22+pulse*20));
      strokeWeight(1);
      ellipse(-4,0,168,78);
      noStroke();
    }

    drawWake(now,mode,speed);
    drawWingPair(now,mode,speed,bank);
    drawHull(pulse,mode);
    drawMechanicalDetail(now,mode,pulse);

    if (mode === 'dock') {
      stroke(94,75,58,190); strokeWeight(2);
      line(-31,13,-45,31); line(24,13,41,31);
      line(-45,31,-55,31); line(41,31,51,31);
      noStroke();
    }

    pop();
    return true;
  }

  root.AetherDragonflyVisual = Object.freeze({ VERSION, PROPORTIONS, PALETTE, draw });
})(typeof window !== 'undefined' ? window : globalThis);
