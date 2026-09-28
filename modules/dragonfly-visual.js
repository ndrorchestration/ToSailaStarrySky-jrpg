/* ============================================================
   Aetherwake ? Shared Dragonfly Visual Authority
   modules/dragonfly-visual.js

   2.5D hero-object renderer for docked and open-sky presentation.
   Presentation only; no navigation, combat, quest, or persistence mutation.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.6.0';
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

  function drawPixelWing(sign, fore, now, mode, speed) {
    const beatRate = mode === 'flight' ? 0.0038 + speed * 0.0006 : 0.0015;
    const flap = Math.round(Math.sin(now * beatRate) * (mode === 'flight' ? 3 : 1));
    const segments = fore ? 9 : 8;
    const x0 = fore ? -4 : 8;
    const stepX = fore ? 11 : -11;
    const stepY = fore ? 5 : 5;
    const baseY = fore ? 10 : 8;
    const alpha = fore ? (mode === 'flight' ? 184 : 148) : (mode === 'flight' ? 152 : 122);
    const c = fore ? PALETTE.aetherBlue : [205,225,190];

    // Broad translucent membrane establishes the unmistakable four-wing Dragonfly silhouette.
    // Pixel bars below add authored texture so the membrane does not read as a smooth vector paddle.
    noStroke();
    fill(c[0], c[1], c[2], fore ? (mode === 'flight' ? 102 : 76) : (mode === 'flight' ? 86 : 66));
    beginShape();
    if (fore) {
      vertex(-2, sign * 6);
      vertex(22, sign * 12);
      vertex(96, sign * (78 + flap));
      vertex(62, sign * 32);
      vertex(7, sign * 5);
    } else {
      vertex(5, sign * 5);
      vertex(-18, sign * 10);
      vertex(-82, sign * (68 + flap));
      vertex(-52, sign * 30);
      vertex(-5, sign * 4);
    }
    endShape(CLOSE);
    // Dark rim + bright leading spar keeps each membrane legible against blue sky.
    stroke(PALETTE.hullDark[0], PALETTE.hullDark[1], PALETTE.hullDark[2], mode === 'flight' ? 180 : 135);
    strokeWeight(2);
    if (fore) {
      line(-2, sign * 6, 96, sign * (78 + flap));
      line(96, sign * (78 + flap), 62, sign * 32);
    } else {
      line(5, sign * 5, -82, sign * (68 + flap));
      line(-82, sign * (68 + flap), -52, sign * 30);
    }
    stroke(220,245,244,fore ? 175 : 148);
    strokeWeight(1);
    if (fore) line(-2, sign * 6, 94, sign * (76 + flap));
    else line(4, sign * 5, -80, sign * (66 + flap));
    noStroke();

    for (let i = 0; i < segments; i++) {
      const x = x0 + i * stepX;
      const yAbs = baseY + i * stepY + flap;
      const y = sign < 0 ? -yAbs - 2 : yAbs;
      const w = Math.max(7, (fore ? 22 : 18) - i);
      fill(c[0], c[1], c[2], alpha);
      rect(x, y, w, 4);
      if (i < segments - 1) {
        fill(PALETTE.glassLight[0], PALETTE.glassLight[1], PALETTE.glassLight[2], Math.min(190, alpha + 38));
        rect(x + w - 3, y + (sign < 0 ? -1 : 4), 5, 1);
      }
    }

    // Pixel spars keep the membrane engineered instead of reading as magic wings.
    fill(47,58,59,190);
    for (let i = 0; i < segments - 1; i++) {
      const x = x0 + i * stepX + 4;
      const yAbs = baseY + i * stepY + flap;
      const y = sign < 0 ? -yAbs - 1 : yAbs + 1;
      rect(x, y, Math.max(3, Math.abs(stepX) - 2), 1);
    }
    fill(PALETTE.brass[0], PALETTE.brass[1], PALETTE.brass[2], 225);
    rect(x0 - 4, sign < 0 ? -baseY - 4 : baseY - 1, 8, 4);
    // Visible root arm helps the four-wing architecture survive small flight scale.
    rect(fore ? -2 : -10, sign < 0 ? -12 : 8, fore ? 24 : 20, 3);
  }

  function drawPixelHeroShip(now, mode, speed, pulse) {
    // Default production-facing Dragonfly presentation is deliberately pixel-built.
    // It keeps the canonical silhouette/material cues while matching the authored JRPG plates.
    drawPixelWing(-1, true, now, mode, speed);
    drawPixelWing(1, true, now, mode, speed);
    drawPixelWing(-1, false, now + 140, mode, speed);
    drawPixelWing(1, false, now + 140, mode, speed);

    if (mode === 'flight') {
      const wake = Math.round(18 + Math.min(1.8, speed) * 16);
      noStroke();
      fill(PALETTE.aetherBlue[0], PALETTE.aetherBlue[1], PALETTE.aetherBlue[2], 72);
      rect(-88 - wake, -2, wake, 2);
      fill(PALETTE.aether[0], PALETTE.aether[1], PALETTE.aether[2], 58);
      rect(-88 - Math.round(wake * 0.72), 2, Math.round(wake * 0.72), 1);
    }

    noStroke();
    // Dragonfly silhouette: segmented abdomen, deep inhabited thorax, compact helm/head.
    // The body is intentionally shorter than the wing span so flight reads as an
    // insect-inspired skyship rather than a horizontal bus with fins.
    fill(...PALETTE.hullDark);
    rect(-42, -7, 58, 14);      // abdomen root
    rect(-60, -5, 18, 10);
    rect(-74, -4, 14, 8);
    rect(-86, -3, 12, 6);
    rect(-24, -14, 52, 28);     // thorax / inhabited cabin
    rect(28, -8, 22, 16);       // neck
    rect(50, -7, 18, 14);       // helm/head
    rect(68, -4, 8, 8);         // nose

    // Reclaimed wood skin follows the insect anatomy: a darker segmented abdomen,
    // a deep bright thorax, then a compact tapered neck into the helm.
    fill(92,64,43);
    rect(-39, -4, 30, 8);
    rect(-55, -3, 16, 6);
    rect(-69, -2, 12, 4);
    fill(116,79,48,230);
    rect(-8, -6, 18, 12);
    fill(158,111,62,235);
    rect(-18, -11, 38, 22);
    rect(-14, -13, 30, 2);
    fill(128,88,52,220);
    rect(29, -5, 16, 10);
    rect(45, -4, 8, 8);
    fill(...PALETTE.brass);
    rect(-40, 4, 88, 2);
    rect(-20, -11, 2, 21);
    rect(1, -11, 2, 21);
    rect(21, -11, 2, 21);

    // Scioto-blue glazing concentrates in the thorax/helm, avoiding a train-window band.
    for (const wx of [-11, 7]) {
      fill(PALETTE.canopy[0], PALETTE.canopy[1], PALETTE.canopy[2], 238);
      rect(wx, -6, 11, 6);
      fill(PALETTE.glassLight[0], PALETTE.glassLight[1], PALETTE.glassLight[2], 130);
      rect(wx + 1, -5, 8, 1);
    }
    fill(PALETTE.canopy[0], PALETTE.canopy[1], PALETTE.canopy[2], 244);
    rect(50, -6, 17, 12);
    rect(67, -3, 8, 6);
    fill(PALETTE.glassLight[0], PALETTE.glassLight[1], PALETTE.glassLight[2], 165);
    rect(53, -5, 10, 2);
    rect(69, -2, 4, 2);

    // Aether heart: compact pixel cluster, not a smooth glowing ellipse.
    fill(PALETTE.brass[0], PALETTE.brass[1], PALETTE.brass[2], 240);
    rect(2, 7, 22, 11);
    fill(PALETTE.aether[0], PALETTE.aether[1], PALETTE.aether[2], Math.round(150 + pulse * 70));
    rect(5, 9, 16, 7);
    fill(224,255,242,Math.round(180 + pulse * 70));
    rect(10, 11, 6, 3);

    // Warm inhabited lower-deck lamps.
    fill(PALETTE.cabin[0], PALETTE.cabin[1], PALETTE.cabin[2], mode === 'flight' ? 190 : 235);
    for (const lx of [-36,-22,-8,30,41]) rect(lx, 7, 5, 2);

    // Dorsal service deck + compact solar awning.
    fill(72,61,49);
    rect(-31, -18, 57, 4);
    fill(PALETTE.brass[0], PALETTE.brass[1], PALETTE.brass[2], 220);
    rect(-21, -24, 2, 7); rect(15, -23, 2, 6);
    fill(132,198,190,170);
    rect(-19, -26, 39, 4);
    rect(20, -25, 10, 3);

    // Four shield/aether nodes preserve the canonical technology cue.
    const nodes = [[-20,-12],[-20,12],[27,-11],[27,11]];
    for (const [nx,ny] of nodes) {
      fill(PALETTE.aether[0], PALETTE.aether[1], PALETTE.aether[2], Math.round(155 + pulse * 65));
      rect(nx, ny, 3, 3);
    }

    // Tail vane and navigation lamps.
    fill(PALETTE.aetherBlue[0], PALETTE.aetherBlue[1], PALETTE.aetherBlue[2], 135);
    rect(-90, -10, 4, 20);
    rect(-94, -6, 4, 12);
    fill(PALETTE.navRed[0], PALETTE.navRed[1], PALETTE.navRed[2], 220);
    rect(-58, -11, 3, 3);
    fill(79,231,188,220);
    rect(-58, 9, 3, 3);

    // Distinct dock rig; absent in flight silhouette.
    if (mode === 'dock') {
      fill(73,61,49);
      rect(-40, 14, 3, 17); rect(31, 14, 3, 17);
      rect(-47, 29, 12, 3); rect(29, 29, 12, 3);
      fill(PALETTE.brass[0], PALETTE.brass[1], PALETTE.brass[2], 190);
      rect(-42, 20, 2, 7); rect(33, 20, 2, 7);
    }
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

    push();
    translate(x,y);
    if (mode === 'flight') rotate(heading);
    if (shipScale !== 1) scale(shipScale);

    if (mode === 'dock') {
      // Stepped dock shadow keeps the hero object inside the pixel-art grammar.
      noStroke();
      fill(5,8,15,72);
      rect(-102,27,180,5);
      rect(-84,32,144,4);
      rect(-61,36,98,3);
    } else {
      // Restrained rectangular shield envelope; active presentation only, not a permanent glow bubble.
      noFill();
      stroke(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],Math.round(18+pulse*16));
      strokeWeight(1);
      rect(-92,-86,184,172,5);
      noStroke();
    }

    drawPixelHeroShip(now,mode,speed,pulse);

    pop();
    return true;
  }

  root.AetherDragonflyVisual = Object.freeze({ VERSION, PROPORTIONS, PALETTE, draw });
})(typeof window !== 'undefined' ? window : globalThis);
