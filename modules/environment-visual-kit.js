/* ============================================================
   Aetherwake ? Shared Environment Visual Kit
   modules/environment-visual-kit.js

   Presentation-only reusable Chapter 1 environment grammar.
   No collision, quest, combat, persistence, or navigation mutation.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';
  const SCALE = Object.freeze({
    adultHeightUnits: 1,
    doorHeightAdultHeights: 1.35,
    crateHeightAdultHeights: 0.38,
    dockRailHeightAdultHeights: 0.55,
  });

  const PALETTE = Object.freeze({
    ink: [12, 16, 26],
    steel: [54, 67, 70],
    reclaimedWood: [111, 82, 55],
    woodLight: [159, 118, 71],
    brass: [183, 132, 64],
    copper: [171, 91, 61],
    moss: [71, 111, 73],
    foliage: [59, 125, 71],
    foliageLight: [102, 153, 83],
    aether: [42, 255, 181],
    aetherBlue: [124, 200, 232],
    lamp: [246, 177, 91],
    rope: [132, 112, 78],
  });

  function drawBollard(x, y, s = 1) {
    push(); translate(x,y); scale(s);
    noStroke();
    fill(...PALETTE.ink); ellipse(0,3,17,6);
    fill(...PALETTE.steel); rect(-4,-13,8,15,2);
    fill(...PALETTE.brass); rect(-7,-13,14,4,2);
    fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],120); rect(-1,-9,2,5);
    pop();
  }

  function drawRopeCoil(x, y, s = 1) {
    push(); translate(x,y); scale(s);
    noFill(); stroke(...PALETTE.rope); strokeWeight(2);
    ellipse(0,0,20,8); ellipse(0,0,14,6); ellipse(0,0,8,4);
    noStroke(); pop();
  }

  function drawPlanter(x, y, s = 1, now = 0) {
    push(); translate(x,y); scale(s);
    noStroke();
    fill(...PALETTE.reclaimedWood); quad(-12,1,12,1,9,10,-9,10);
    fill(...PALETTE.woodLight); rect(-10,-1,20,4,1);
    for (let i=0;i<5;i++) {
      const sway=Math.sin(now*0.002+i)*1.6;
      stroke(...PALETTE.foliage); strokeWeight(2);
      line(-8+i*4,0,-8+i*4+sway,-11-(i%2)*3);
      noStroke(); fill(...PALETTE.foliageLight);
      ellipse(-8+i*4+sway,-11-(i%2)*3,5,3);
    }
    pop();
  }

  function drawRepairBench(x, y, s = 1) {
    push(); translate(x,y); scale(s);
    noStroke();
    fill(...PALETTE.ink); rect(-19,9,38,4,1);
    fill(...PALETTE.reclaimedWood); rect(-18,0,36,8,2);
    fill(...PALETTE.woodLight); rect(-16,1,32,2,1);
    fill(...PALETTE.steel); rect(-15,8,3,11); rect(12,8,3,11);
    fill(...PALETTE.brass); rect(-9,-4,8,5,1);
    fill(...PALETTE.copper); rect(3,-6,3,7,1);
    fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],150); rect(8,-3,5,3,1);
    pop();
  }

  function drawWindVane(x, y, s = 1, now = 0) {
    push(); translate(x,y); scale(s);
    const turn=Math.sin(now*0.0012)*0.35;
    stroke(...PALETTE.steel); strokeWeight(2); line(0,10,0,-30);
    push(); translate(0,-27); rotate(turn);
    stroke(...PALETTE.brass); strokeWeight(1.5); line(-18,0,18,0); line(0,-18,0,18);
    noFill(); ellipse(0,0,25,25);
    fill(PALETTE.aetherBlue[0],PALETTE.aetherBlue[1],PALETTE.aetherBlue[2],115);
    noStroke(); triangle(18,0,10,-4,10,4);
    pop();
    noStroke();
    fill(...PALETTE.reclaimedWood); rect(-5,10,10,5,1);
    pop();
  }

  function drawRepairCanopy(x, y, s = 1, now = 0) {
    push(); translate(x,y); scale(s);
    const billow=Math.sin(now*0.0017)*2;
    stroke(...PALETTE.steel); strokeWeight(2);
    line(-34,18,-34,-24); line(34,18,34,-24);
    noStroke();
    fill(44,76,70,215);
    beginShape();
    vertex(-38,-24); vertex(-12,-29+billow); vertex(12,-27-billow); vertex(38,-24);
    vertex(31,-14); vertex(-31,-14); endShape(CLOSE);
    fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],75);
    rect(-30,-21,60,2);
    pop();
  }

  function drawCrane(x, y, s = 1, now = 0) {
    push(); translate(x,y); scale(s);
    stroke(...PALETTE.steel); strokeWeight(4);
    line(0,22,0,-45); line(0,-45,43,-34); line(8,-41,38,-32);
    stroke(...PALETTE.brass); strokeWeight(2);
    line(43,-34,43,4+Math.sin(now*0.0013)*2);
    noStroke(); fill(...PALETTE.brass); rect(39,4,8,7,1);
    fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],130); rect(41,6,4,3,1);
    pop();
  }


  function drawDockSurface(ctx) {
    const w=ctx.width, h=ctx.height, now=ctx.now||0;
    // Presentation-only service apron beneath the Dragonfly. It explains the
    // mooring zone while leaving the central player corridor visually open.
    const left=w*0.49, top=h*0.30, right=w*0.96, bottom=h*0.67;
    noStroke();
    fill(35,43,45,205);
    beginShape();
    vertex(left,top+24); vertex(right-34,top); vertex(right,bottom-35);
    vertex(right-82,bottom); vertex(left+18,bottom-20); vertex(left-30,top+70);
    endShape(CLOSE);

    // Reclaimed deck panels: broad bands rather than a noisy tile grid.
    stroke(86,79,64,150); strokeWeight(2);
    for (let i=1;i<7;i++) {
      const t=i/7;
      const x=left+(right-left)*t;
      line(x,top+26,x-20,bottom-28);
    }
    stroke(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],105);
    strokeWeight(2);
    line(left+8,top+61,right-45,top+34);
    line(left+3,bottom-51,right-74,bottom-29);

    // Aether service rail and mooring sockets.
    stroke(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],68);
    strokeWeight(2);
    line(left+38,top+86,right-96,top+70);
    noStroke();
    for (let i=0;i<4;i++) {
      const x=left+78+i*118;
      const y=top+80+i*5;
      fill(12,16,22,210); ellipse(x,y,15,8);
      fill(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],180); ellipse(x,y,8,4);
      fill(PALETTE.aether[0],PALETTE.aether[1],PALETTE.aether[2],90+Math.sin(now*0.004+i)*40); ellipse(x,y,3,2);
    }

    // Narrow timber repair strip adds warm material contrast.
    fill(PALETTE.reclaimedWood[0],PALETTE.reclaimedWood[1],PALETTE.reclaimedWood[2],135);
    quad(left+25,bottom-52,right-86,bottom-34,right-80,bottom-20,left+29,bottom-38);
    stroke(PALETTE.woodLight[0],PALETTE.woodLight[1],PALETTE.woodLight[2],95);
    strokeWeight(1);
    for (let x=left+55;x<right-110;x+=56) line(x,bottom-48,x+3,bottom-27);
    noStroke();
  }

  function drawDockMidground(ctx) {
    const w=ctx.width, h=ctx.height, now=ctx.now||0;
    // A deliberately asymmetric working-dock composition: lived-in support
    // objects frame the hero ship without filling the interaction corridor.
    drawWindVane(w*0.16,h*0.47,1.15,now);
    drawRepairCanopy(w*0.79,h*0.40,1.05,now);
    drawRepairBench(w*0.82,h*0.55,1.15);
    drawPlanter(w*0.22,h*0.60,1.0,now);
    drawPlanter(w*0.88,h*0.63,0.9,now);
    drawBollard(w*0.60,h*0.57,1.0);
    drawBollard(w*0.68,h*0.62,0.9);
    drawRopeCoil(w*0.58,h*0.63,1.0);
    drawCrane(w*0.91,h*0.38,0.95,now);

    // Warm/cool grounding patches visually bind props to the play plane.
    noStroke();
    fill(244,169,82,16); ellipse(w*0.79,h*0.56,w*0.24,h*0.18);
    fill(42,255,181,12); ellipse(w*0.64,h*0.60,w*0.18,h*0.11);
  }

  function drawDockForeground(ctx) {
    const w=ctx.width, h=ctx.height, now=ctx.now||0;
    // Foreground foliage + maintenance hardware create a near-camera depth band.
    noStroke();
    for (const side of [-1,1]) {
      const baseX=side<0 ? 18 : w-18;
      for (let i=0;i<7;i++) {
        const x=baseX + side*(i*7);
        const sway=Math.sin(now*0.002+i)*3;
        stroke(...PALETTE.foliage); strokeWeight(2.2);
        line(x,h,x+sway,h-34-(i%3)*8);
        noStroke(); fill(...PALETTE.foliageLight);
        ellipse(x+sway,h-36-(i%3)*8,7,4);
      }
    }
    fill(13,17,25,190);
    rect(0,h-22,w,22);
    fill(PALETTE.brass[0],PALETTE.brass[1],PALETTE.brass[2],95);
    for (let x=54;x<w;x+=112) rect(x,h-24,21,3,1);
  }

  root.AetherEnvironmentVisualKit = Object.freeze({
    VERSION, SCALE, PALETTE,
    drawDockSurface,
    drawDockMidground,
    drawDockForeground,
    drawBollard,
    drawRopeCoil,
    drawPlanter,
    drawRepairBench,
    drawWindVane,
    drawRepairCanopy,
    drawCrane,
  });
})(typeof window !== 'undefined' ? window : globalThis);
