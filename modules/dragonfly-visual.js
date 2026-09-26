/* ============================================================
   Aetherwake ? Shared Dragonfly Visual Authority
   modules/dragonfly-visual.js

   2.5D hero-object renderer for docked and open-sky presentation.
   Presentation only; no navigation, combat, quest, or persistence mutation.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.5.0';
  const PROPORTIONS = Object.freeze({
    adultHeightUnits: 1,
    bodyLengthAdultHeights: 3.0,
    wingSpanBodyLengths: 2.4,
    runtimeBodyLengthPx: 164,
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
    // Four swept translucent sail-wings preserve the Dragonfly identity while
    // matching the visual-bible airship silhouette more closely than insect paddles.
    const beatRate = mode === 'flight' ? 0.0035 + speed * 0.0007 : 0.0016;
    const beat = Math.sin(now * beatRate);
    const flare = mode === 'flight' ? 1.0 : 0.90;
    const vertical = beat * (mode === 'flight' ? 3.2 : 1.4);
    const bankBias = bank * 3.2;

    const drawSide = sign => {
      const rootY = sign * (12 + bankBias * sign);
      const foreTipY = sign * (45 + vertical * sign);
      const aftTipY = sign * (31 - vertical * 0.55 * sign);

      // Forward sail: long leading spar, broad translucent fabric, tapered tip.
      membrane([
        [-8, rootY], [24, sign * 18], [102 * flare, foreTipY],
        [83 * flare, sign * 9], [19, sign * 6]
      ], mode === 'flight' ? 92 : 80, false, true);

      // Aft sail: slightly shorter/lower and visually subordinate.
      membrane([
        [-16, sign * 8], [14, sign * 14], [82 * flare, aftTipY],
        [65 * flare, sign * 5], [-4, sign * 3]
      ], mode === 'flight' ? 70 : 62, true, true);

      // Dark spars + brass root sleeve make the wing read as engineered sailcloth.
      stroke(47,58,59,175); strokeWeight(1.35);
      line(-7,rootY,101*flare,foreTipY);
      line(-14,sign*8,81*flare,aftTipY);
      stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],145);
      strokeWeight(0.8);
      line(18,sign*7,81*flare,sign*10);
      noStroke();
    };

    drawSide(-1);
    drawSide(1);

    fill(...PALETTE.brass);
    ellipse(-8,-11,6,6); ellipse(-8,11,6,6);
    ellipse(-16,-7,5,5); ellipse(-16,7,5,5);
  }

  function drawHull(pulse, mode) {
    // Visual-bible hull: elongated reclaimed-wood/brass airship with a pointed
    // prow, continuous blue glazing and tapered stern. It keeps the Dragonfly's
    // aether core and maintainable machinery but reads first as a lived-in ship.
    noStroke();

    // Deep lower hull establishes the long nautical profile.
    fill(...PALETTE.hullDark);
    beginShape();
    vertex(-82,-8); vertex(-62,-16); vertex(20,-18); vertex(58,-13);
    vertex(82,-5); vertex(97,0); vertex(82,6); vertex(57,14);
    vertex(18,19); vertex(-60,15); vertex(-86,7);
    endShape(CLOSE);

    // Warm reclaimed-wood side panels are the primary material identity.
    fill(109,76,48);
    beginShape();
    vertex(-67,-11); vertex(18,-14); vertex(55,-10); vertex(78,-4);
    vertex(66,2); vertex(20,6); vertex(-68,4);
    endShape(CLOSE);
    fill(148,104,58,185);
    beginShape();
    vertex(-58,-8); vertex(9,-11); vertex(45,-8); vertex(61,-4);
    vertex(43,-2); vertex(5,1); vertex(-58,0);
    endShape(CLOSE);

    // Brass chine and ribs bind the wood skin to the darker lower hull.
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],180);
    strokeWeight(1.2);
    line(-67,4,66,2);
    for (const rx of [-49,-30,-10,13,36,58]) line(rx,-10,rx,7);
    noStroke();

    // Continuous Scioto-blue window band: strongest compendium recognition cue.
    fill(PALETTE.canopy[0],PALETTE.canopy[1],PALETTE.canopy[2],218);
    beginShape();
    vertex(-45,-7); vertex(26,-9); vertex(59,-7); vertex(77,-3);
    vertex(61,0); vertex(24,-1); vertex(-45,1);
    endShape(CLOSE);
    fill(PALETTE.glassLight[0],PALETTE.glassLight[1],PALETTE.glassLight[2],80);
    beginShape();
    vertex(-40,-6); vertex(23,-8); vertex(51,-6); vertex(63,-4);
    vertex(45,-3); vertex(10,-3); vertex(-40,-1);
    endShape(CLOSE);
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],145);
    strokeWeight(0.8);
    for (const wx of [-34,-18,-2,14,30,46,60]) line(wx,-8,wx,0);
    noStroke();

    // Pointed prow / helm glazing pushes the silhouette forward like the compendium ship.
    fill(PALETTE.canopy[0],PALETTE.canopy[1],PALETTE.canopy[2],225);
    triangle(63,-7,99,0,64,7);
    fill(PALETTE.glassLight[0],PALETTE.glassLight[1],PALETTE.glassLight[2],115);
    triangle(73,-4,92,0,73,3);
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],180);
    strokeWeight(1.1); line(64,-7,64,7); line(79,-4,79,4); noStroke();

    // Aether-heart window is retained as the technology/identity anchor.
    noFill();
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],195);
    strokeWeight(2); ellipse(10,8,27,20); noStroke();
    fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],Math.round(95+pulse*75));
    ellipse(10,8,17,13);
    fill(218,250,239,Math.round(160+pulse*90)); ellipse(10,8,6,6);

    // Warm lower-deck lamps make the hull inhabited at dock and in flight.
    fill(PALETTE.cabin[0],PALETTE.cabin[1],PALETTE.cabin[2],mode === 'flight' ? 175 : 220);
    for (const lx of [-48,-28,-8,31,50]) rect(lx,7,7,2,1);

    // Tapered stern replaces bead-like segmentation with one clean tail boom.
    fill(62,65,61);
    beginShape();
    vertex(-82,-6); vertex(-105,-4); vertex(-125,-1); vertex(-132,0);
    vertex(-125,2); vertex(-104,5); vertex(-82,6);
    endShape(CLOSE);
    fill(...PALETTE.reclaimedBronze);
    quad(-88,-4,-111,-3,-119,0,-89,2);
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],145);
    strokeWeight(1); line(-100,-4,-100,4); line(-114,-3,-114,3); noStroke();

    // Tail pressure vane / rudder echoes the sail geometry without adding bulk.
    fill(PALETTE.aetherBlue[0],PALETTE.aetherBlue[1],PALETTE.aetherBlue[2],125);
    beginShape();
    vertex(-124,-2); vertex(-140,-14); vertex(-136,0); vertex(-140,14); vertex(-124,2);
    endShape(CLOSE);

    // Dorsal service deck and compact solar awning keep the solarpunk language.
    fill(74,61,48); quad(-36,-14,20,-17,42,-11,-20,-9);
    stroke(205,178,126,145); strokeWeight(1);
    line(-24,-14,-14,-28); line(12,-16,20,-27); line(-14,-28,20,-27); noStroke();
    fill(132,198,190,mode === 'flight' ? 155 : 125);
    quad(-13,-28,26,-27,37,-21,-3,-22);
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
    vertex(-132,-3); vertex(-132-wake,-2); vertex(-140-Math.round(wake*1.15),0);
    vertex(-132-wake,2); vertex(-132,3);
    endShape(CLOSE);
    fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],mode === 'flight' ? 64 : 36);
    rect(-133-Math.round(wake*0.82),-1,Math.round(wake*0.82),2);
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
      noStroke(); fill(5,8,15,90); ellipse(-12,27,202,18);
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
