/* Aetherwake - cinematic articulated character renderer
   Reference authority: Ender=center, Reson=left, Aepex=right from approved key-art.
   Runtime-drawn: no still-image character compositing. */
(function (root) {
  'use strict';

  const VERSION = '0.5.0';
  const PROFILES = Object.freeze({
    ender: Object.freeze({
      skin:[214,170,132], hair:[154,94,50], hairDark:[100,57,37],
      shirt:[55,61,65], vest:[172,149,104], accent:[58,105,66],
      leather:[81,55,38], metal:[176,130,57], boot:[50,39,34], pants:[58,55,49],
      build:0.98, shoulder:1.0, leg:1.02, heightScale:1.00, hairMode:'crop',
      goggles:true, freckles:true, embroidery:true, fieldVest:true, collarOpen:true, posture:'focused'
    }),
    reson: Object.freeze({
      skin:[220,178,143], hair:[70,45,33], hairDark:[48,32,27],
      shirt:[216,202,176], vest:[78,62,48], accent:[133,50,40],
      leather:[75,50,35], metal:[172,121,52], boot:[47,36,31], pants:[71,62,53],
      build:1.16, shoulder:1.16, leg:1.0, heightScale:1.08, hairMode:'cap',
      scarf:[133,50,40], cap:[150,43,45], mustache:true, heavyHarness:true, utilityRig:true, rolledSleeves:true, posture:'open'
    }),
    aepex: Object.freeze({
      skin:[211,165,132], hair:[194,164,122], hairDark:[119,98,79],
      shirt:[39,40,44], vest:[52,49,48], accent:[181,134,60],
      leather:[52,43,39], metal:[174,127,54], boot:[35,31,30], pants:[38,38,42],
      build:0.94, shoulder:0.98, leg:1.05, heightScale:1.05, hairMode:'undercut',
      tattoos:true, eyebrowNotch:true, harness:true, techRig:true, neckGoggles:true, asymmetry:true, posture:'guarded'
    }),
    ionia: Object.freeze({
      skin:[202,158,126], hair:[205,169,92], hairDark:[139,103,57],
      shirt:[48,63,67], vest:[111,102,82], accent:[69,132,137],
      leather:[72,54,42], metal:[145,115,71], boot:[46,40,38], pants:[46,50,51],
      build:0.96, shoulder:0.98, leg:1.0, heightScale:0.96, hairMode:'curlyShoulder', curls:true, tailoredLayer:true, posture:'steady'
    }),
    lyra: Object.freeze({
      skin:[218,178,145], hair:[163,58,43], hairDark:[104,39,34],
      shirt:[70,76,86], vest:[145,111,85], accent:[118,159,164],
      leather:[80,58,46], metal:[151,119,75], boot:[51,43,40], pants:[79,61,56],
      build:0.84, shoulder:0.88, leg:0.94, heightScale:0.96, hairMode:'longRed', longHair:true, layeredDrape:true, posture:'light'
    })
  });

  const clamp01 = v => Math.max(0, Math.min(1, v));
  const mix = (a,b,t) => a + (b-a)*t;

  function motionState(options) {
    const o = options || {};
    const speed = clamp01(Number(o.speed) || 0);
    const now = Number(o.now) || 0;
    const action = o.action || (speed > 0.1 ? 'walk' : 'idle');
    const cadence = action === 'run' ? 0.018 : (speed > 0.1 ? 0.012 : 0.0045);
    const phase = (now * cadence) % (Math.PI * 2);
    return {
      speed, now, action, phase,
      moving: speed > 0.08 || action === 'walk' || action === 'run',
      run: action === 'run',
      talk: action === 'talk',
      focus: action === 'focus',
      attack: action === 'attack'
    };
  }

  function capsule(x1,y1,x2,y2,width,colorValue) {
    stroke(30,25,24,190);
    strokeWeight(width + 1.25);
    strokeCap(ROUND);
    line(x1,y1,x2,y2);
    stroke(...colorValue);
    strokeWeight(width);
    line(x1,y1,x2,y2);
    stroke(255,226,188,36);
    strokeWeight(Math.max(0.7, width * 0.14));
    line(x1 - 0.4, y1 - 0.6, x2 - 0.4, y2 - 0.6);
    noStroke();
    fill(...colorValue);
    ellipse(x1,y1,width,width);
    ellipse(x2,y2,width,width);
  }

  function drawGroundShadow(s, depth, motion) {
    noStroke();
    fill(5,8,13,Math.round(48 + depth*58));
    const stretch = motion.moving ? 1.08 : 1;
    ellipse(0, 3*s, 31*s*stretch, 7.5*s);
  }

  function drawLeg(profile, side, hipY, s, stride, lift, front) {
    const hipX = side * 4.1*s;
    const kneeX = side * 4.5*s + stride*0.45;
    const kneeY = hipY + 17*s - lift*2.8*s;
    const footX = side * 5.0*s + stride*0.68;
    const footY = -1.5*s - lift*1.8*s;

    capsule(hipX, hipY, kneeX, kneeY, 5.8*s, profile.pants || [68,59,53]);
    capsule(kneeX, kneeY, footX, footY, 5.0*s, profile.boot);
    fill(...profile.leather);
    rect(footX - 4.3*s, footY - 1.1*s, 8.6*s, 2.7*s, 1.2*s);

    if (front) {
      fill(...profile.leather);
      rect(kneeX - 3.3*s, kneeY - 1.8*s, 6.6*s, 3.6*s, 1*s);
    }
  }

  function drawTorso(profile, s, breath, lean, motion) {
    push();
    translate(0,-50*s);
    rotate(lean);

    const shoulder = 17.5*s*profile.shoulder;
    const waist = 9.8*s*profile.build;
    const chestH = (25 + breath*0.8)*s;

    stroke(30,25,24,185);
    strokeWeight(1.05*s);
    fill(...profile.shirt);
    beginShape();
    vertex(-shoulder/2,-12*s); vertex(shoulder/2,-12*s);
    vertex(waist/2,13*s); vertex(-waist/2,13*s);
    endShape(CLOSE);

    stroke(44,34,28,180);
    strokeWeight(0.95*s);
    fill(...profile.vest);
    beginShape();
    vertex(-shoulder*0.46,-8*s); vertex(shoulder*0.46,-8*s);
    vertex(waist*0.45,10*s); vertex(-waist*0.45,10*s);
    endShape(CLOSE);
    noStroke();

    fill(255,231,192,22);
    quad(-shoulder*0.40,-7*s,0,-7*s,-1*s,8*s,-waist*0.36,8*s);

    // Open vest/shirt seam.
    fill(...profile.shirt);
    beginShape();
    vertex(-1.4*s,-8*s); vertex(1.4*s,-8*s);
    vertex(2.6*s,9*s); vertex(-2.6*s,9*s);
    endShape(CLOSE);

    // Cross-body field harness and waist belt.
    stroke(...profile.leather);
    strokeWeight(1.7*s);
    line(-shoulder*0.32,-8*s, waist*0.42,10*s);
    line(-waist*0.52,6*s, waist*0.52,6*s);
    noStroke();
    fill(...profile.metal);
    rect(-1.7*s,4.5*s,3.4*s,3*s,0.6*s);

    if (profile.embroidery) {
      stroke(...profile.accent);
      strokeWeight(0.8*s);
      for (const side of [-1,1]) {
        line(side*4.7*s,-5*s, side*4.2*s,7*s);
        line(side*4.6*s,-2*s, side*6.1*s,-3*s);
        line(side*4.4*s,2*s, side*5.8*s,1*s);
        line(side*4.2*s,6*s, side*5.4*s,5*s);
      }
      noStroke();
    }

    if (profile.harness) {
      stroke(...profile.metal);
      strokeWeight(1.1*s);
      line(-shoulder*0.4,-4*s,-waist*0.48,8*s);
      line(shoulder*0.42,-5*s,waist*0.5,7*s);
      noStroke();
      fill(...profile.metal);
      ellipse(-6*s,4*s,2.4*s,2.4*s);
      ellipse(6*s,4*s,2.4*s,2.4*s);
    }

    // Reference-backed costume silhouette cues. These are visual only and do
    // not imply equipment canon beyond the approved modeling references.
    if (profile.fieldVest) {
      stroke(...profile.leather);
      strokeWeight(1.15*s);
      line(-shoulder*0.42,-7*s,-waist*0.48,10*s);
      line(shoulder*0.42,-7*s,waist*0.48,10*s);
      noStroke();
      fill(...profile.leather);
      rect(-shoulder*0.44,7*s,shoulder*0.88,2.2*s,0.8*s);
    }
    if (profile.heavyHarness) {
      stroke(...profile.leather);
      strokeWeight(2.3*s);
      line(-shoulder*0.38,-8*s,waist*0.52,10*s);
      line(shoulder*0.38,-8*s,-waist*0.52,10*s);
      noStroke();
      fill(...profile.metal);
      for (const x of [-5.5,0,5.5]) rect(x*s-1.1*s,5*s,2.2*s,3.1*s,0.5*s);
    }
    if (profile.utilityRig) {
      fill(...profile.leather);
      rect(-9*s,8*s,5*s,7*s,1*s);
      rect(4*s,8*s,5*s,7*s,1*s);
      fill(...profile.metal);
      rect(-7.8*s,9.2*s,2.2*s,1.4*s,0.4*s);
      rect(5.2*s,9.2*s,2.2*s,1.4*s,0.4*s);
    }
    if (profile.techRig) {
      fill(...profile.leather);
      rect(-8*s,5*s,4*s,8*s,1*s);
      rect(4*s,6*s,5*s,7*s,1*s);
      fill(...profile.metal);
      rect(-6.8*s,6*s,1.8*s,4.5*s,0.5*s);
      rect(5.2*s,7*s,2.2*s,3.5*s,0.5*s);
      fill(...profile.accent);
      rect(6*s,8*s,1.2*s,1.2*s);
    }
    if (profile.tailoredLayer) {
      stroke(...profile.metal);
      strokeWeight(0.8*s);
      line(-shoulder*0.34,-6*s,-waist*0.38,9*s);
      line(shoulder*0.34,-6*s,waist*0.38,9*s);
      noStroke();
    }
    if (profile.layeredDrape) {
      // Lyra's rust-and-cream layered silhouette: longer asymmetric coat tails
      // separate her immediately from the four trouser-and-harness builds.
      fill(...profile.vest);
      beginShape();
      vertex(-waist*0.64,6*s); vertex(-waist*0.54,18*s); vertex(-1.4*s,13*s);
      vertex(0,10*s); vertex(waist*0.30,17*s); vertex(waist*0.60,7*s);
      endShape(CLOSE);
      fill(223,211,188,150);
      beginShape();
      vertex(-waist*0.32,8*s); vertex(-waist*0.20,16*s); vertex(0,12*s);
      vertex(waist*0.16,15*s); vertex(waist*0.28,8*s); endShape(CLOSE);
    }
    if (profile.tailoredLayer) {
      // Ionia reads as a clean captain/engineer through narrow lapels and a
      // structured waist rather than additional bulk.
      stroke(...profile.accent);
      strokeWeight(0.9*s);
      line(-shoulder*0.28,-7*s,-2*s,2*s);
      line(shoulder*0.28,-7*s,2*s,2*s);
      noStroke();
      fill(...profile.leather);
      rect(-waist*0.55,5*s,waist*1.1,2*s,0.6*s);
    }
    if (profile.asymmetry) {
      // Aepex's one-sided shoulder plate and hanging tool strap create a
      // recognisable maverick/engineer silhouette even without facial detail.
      fill(...profile.metal);
      quad(4*s,-11*s,9*s,-10*s,10*s,-5*s,5*s,-6*s);
      stroke(...profile.accent);
      strokeWeight(1.1*s);
      line(7*s,-7*s,9*s,10*s);
      noStroke();
    }
    if (profile.fieldVest && profile.collarOpen) {
      // Ender's open field-scholar collar leaves a small light V beneath the
      // goggles/vest silhouette instead of reading as another closed uniform.
      fill(205,194,170,145);
      triangle(-3.1*s,-8*s,3.1*s,-8*s,0,-2*s);
    }

    if (profile.scarf) {
      fill(...profile.scarf);
      arc(0,-9*s,17*s,7*s,0,Math.PI);
      const wind = Math.sin(motion.phase*0.75) * (motion.moving ? 3.5 : 1.5)*s;
      beginShape();
      vertex(4*s,-7*s); vertex(8*s,-6*s);
      vertex(8*s+wind,2*s); vertex(4*s+wind*0.55,0);
      endShape(CLOSE);
    }

    if (profile.neckGoggles) {
      noFill();
      stroke(...profile.metal);
      strokeWeight(1.0*s);
      ellipse(-3.0*s,-7.2*s,4.6*s,3.6*s);
      ellipse(3.0*s,-7.2*s,4.6*s,3.6*s);
      line(-0.7*s,-7.2*s,0.7*s,-7.2*s);
      noStroke();
    }

    if (motion.focus) {
      noFill();
      stroke(...profile.accent,105);
      strokeWeight(1.1*s);
      ellipse(0,0,24*s,34*s);
      noStroke();
    }
    pop();
  }

  function drawArm(profile, side, s, swing, bend, front, motion) {
    const shoulderX = side * 7.4*s*profile.shoulder;
    const shoulderY = -39*s;
    const elbowX = side * 10.1*s + swing*0.28;
    const elbowY = -28*s + bend*1.4*s;
    let handX = side * 8.8*s + swing*0.55;
    let handY = -18.5*s + bend*2.1*s;

    if (motion.talk && front) {
      handX = side * 12*s;
      handY = -31*s + Math.sin(motion.phase)*2*s;
    }
    if (motion.attack && front) {
      handX = side * 17*s;
      handY = -34*s;
    }

    capsule(shoulderX,shoulderY,elbowX,elbowY,4.8*s,profile.shirt);
    if (profile.rolledSleeves) {
      stroke(...profile.leather);
      strokeWeight(1.3*s);
      line((shoulderX+elbowX)*0.48,(shoulderY+elbowY)*0.48,(shoulderX+elbowX)*0.55,(shoulderY+elbowY)*0.55);
      noStroke();
    }
    capsule(elbowX,elbowY,handX,handY,3.8*s,profile.skin);

    fill(...profile.leather);
    rect(handX-2.3*s,handY-2*s,4.6*s,4*s,1*s);

    if (profile.tattoos) {
      stroke(48,42,39,190);
      strokeWeight(0.75*s);
      line(elbowX,elbowY,handX,handY);
      ellipse((elbowX+handX)/2,(elbowY+handY)/2,4*s,4*s);
      noStroke();
    }
  }

  function drawHead(profile, s, motion, expression) {
    const faceY = -49*s;
    const nod = motion.talk ? Math.sin(motion.phase*1.7)*0.7*s : 0;

    if (profile.hairMode === 'longRed') {
      noStroke();
      fill(...profile.hairDark);
      beginShape();
      vertex(-6.5*s,faceY-4*s+nod); vertex(-8.8*s,faceY+2*s+nod);
      vertex(-9.2*s,faceY+13*s+nod); vertex(-5.8*s,faceY+16*s+nod);
      vertex(-3.8*s,faceY+7*s+nod); vertex(3.8*s,faceY+7*s+nod);
      vertex(5.8*s,faceY+16*s+nod); vertex(9.2*s,faceY+13*s+nod);
      vertex(8.8*s,faceY+2*s+nod); vertex(6.5*s,faceY-4*s+nod);
      endShape(CLOSE);
    }

    stroke(46,34,30,175);
    strokeWeight(0.85*s);
    fill(...profile.skin);
    ellipse(0,faceY+nod,11.5*s,14.5*s);
    noStroke();
    fill(120,76,62,34);
    arc(2.2*s,faceY+0.4*s+nod,7.2*s,12*s,-Math.PI/2,Math.PI/2);

    fill(...profile.hair);
    if (profile.hairMode === 'undercut') {
      arc(-0.5*s,faceY-4.5*s+nod,12*s,8*s,Math.PI,Math.PI*2);
      triangle(-5.5*s,faceY-4*s+nod,1*s,faceY-10*s+nod,6*s,faceY-4*s+nod);
      fill(...profile.hairDark);
      rect(-6*s,faceY-3*s+nod,2.2*s,5*s,1*s);
    } else if (profile.hairMode === 'cap') {
      arc(0,faceY-4.2*s+nod,12*s,7*s,Math.PI,Math.PI*2);
      fill(...profile.cap);
      arc(-1*s,faceY-5*s+nod,15*s,7*s,Math.PI,Math.PI*2);
      rect(-7*s,faceY-6*s+nod,4*s,1.5*s,0.5*s);
    } else if (profile.hairMode === 'curlyShoulder') {
      arc(0,faceY-4.0*s+nod,13*s,8*s,Math.PI,Math.PI*2);
      for (const side of [-1,1]) {
        ellipse(side*5.2*s,faceY-1.2*s+nod,3.5*s,4.4*s);
        ellipse(side*5.7*s,faceY+2.0*s+nod,3.8*s,4.8*s);
        ellipse(side*5.0*s,faceY+5.0*s+nod,3.2*s,4.0*s);
      }
    } else if (profile.hairMode === 'longRed') {
      arc(0,faceY-3.8*s+nod,13.5*s,9*s,Math.PI,Math.PI*2);
      ellipse(-5.6*s,faceY+1.3*s+nod,2.8*s,8*s);
      ellipse(5.6*s,faceY+1.3*s+nod,2.8*s,8*s);
    } else {
      arc(0,faceY-4.3*s+nod,12*s,8*s,Math.PI,Math.PI*2);
      triangle(-5*s,faceY-4*s+nod,-1*s,faceY-8*s+nod,1*s,faceY-4*s+nod);
      triangle(0,faceY-4*s+nod,3*s,faceY-8.5*s+nod,5.5*s,faceY-3*s+nod);
    }

    stroke(74,48,40,170);
    strokeWeight(0.55*s);
    line(-4*s,faceY-2*s+nod,-1.2*s,faceY-2.6*s+nod);
    line(1.2*s,faceY-2.6*s+nod,4*s,faceY-2*s+nod);
    noStroke();
    fill(35,30,28);
    ellipse(-2.2*s,faceY-0.5*s+nod,1.1*s,0.9*s);
    ellipse(2.2*s,faceY-0.5*s+nod,1.1*s,0.9*s);
    if (profile.freckles) {
      fill(151,94,70,170);
      for (const fx of [-3.4,-2.1,2.1,3.4]) ellipse(fx*s,faceY+1.7*s+nod,0.65*s,0.65*s);
    }
    if (profile.eyebrowNotch) {
      stroke(...profile.skin);
      strokeWeight(0.8*s);
      line(2.4*s,faceY-2.7*s+nod,3.0*s,faceY-2.1*s+nod);
      noStroke();
    }
    stroke(116,75,60,150);
    strokeWeight(0.5*s);
    line(0,faceY+0.2*s+nod,0.8*s,faceY+2.4*s+nod);
    noStroke();

    if (profile.mustache) {
      stroke(...profile.hairDark);
      strokeWeight(0.75*s);
      line(-2.3*s,faceY+3.1*s+nod,-0.3*s,faceY+3.5*s+nod);
      line(0.3*s,faceY+3.5*s+nod,2.3*s,faceY+3.1*s+nod);
      noStroke();
    }
    if (expression === 'talk') {
      fill(96,53,47);
      ellipse(0,faceY+4*s+nod,2.5*s,1.6*s);
    } else {
      stroke(107,70,57);
      strokeWeight(0.7*s);
      line(-1.6*s,faceY+4*s+nod,1.6*s,faceY+4*s+nod);
      noStroke();
    }

    if (profile.goggles) {
      noFill();
      stroke(...profile.metal);
      strokeWeight(1.1*s);
      ellipse(-3*s,faceY-5.6*s+nod,4.3*s,3.6*s);
      ellipse(3*s,faceY-5.6*s+nod,4.3*s,3.6*s);
      line(-0.8*s,faceY-5.6*s+nod,0.8*s,faceY-5.6*s+nod);
      noStroke();
    }
  }

  function drawCharacter(id,x,y,options) {
    const profile = PROFILES[id] || PROFILES.ender;
    const o = options || {};
    const m = motionState(o);
    const depth = clamp01(Number.isFinite(o.depth) ? o.depth : 0.62);
    const scaleBase = Math.max(0.48, Number(o.scale) || 1);
    const s = scaleBase * mix(0.88,1.12,depth);

    const gait = Math.sin(m.phase);
    const liftL = Math.max(0, Math.sin(m.phase));
    const liftR = Math.max(0, -Math.sin(m.phase));
    const strideAmount = m.moving ? (m.run ? 9 : 6.2) : 0.6;
    const stride = gait*strideAmount*s;
    const breath = Math.sin(m.phase*0.5)*0.55;
    const bob = (m.moving ? Math.abs(Math.sin(m.phase))*-1.4 : Math.sin(m.phase*0.5)*0.4)*s;
    const lean = m.run ? 0.045 : (m.moving ? 0.018*gait : 0);
    const armSwing = -stride*0.72;

    push();
    translate(x,y+bob);
    if (o.facing === 'left') scale(-1,1);

    drawGroundShadow(s,depth,m);

    // Height authority scales vertically around the grounded foot origin; build
    // and shoulder factors remain independent so tall does not mean bulky.
    push();
    scale(1, profile.heightScale || 1);

    // Rear limbs, torso, front limbs produce consistent depth during gait.
    drawLeg(profile,-1,-22*s,s, stride,liftL,false);
    drawArm(profile,-1,s,armSwing,0,false,m);
    drawLeg(profile,1,-22*s,s,-stride,liftR,true);
    drawTorso(profile,s,breath,lean,m);
    drawArm(profile,1,s,-armSwing,0,true,m);

    drawHead(profile,s,m,o.expression || (m.talk ? 'talk' : 'neutral'));

    // Small gear cues keep the silhouettes tied to the approved key art.
    fill(...profile.metal);
    ellipse(-7*s,-25*s,2.4*s,2.4*s);
    ellipse(7*s,-25*s,2.4*s,2.4*s);
    if (id === 'aepex') {
      stroke(...profile.metal);
      strokeWeight(1.1*s);
      line(-5*s,-34*s,6*s,-24*s);
      noStroke();
    }

    if (o.highlight) {
      noFill();
      stroke(...profile.accent,95);
      strokeWeight(1.1*s);
      ellipse(0,-27*s,29*s,61*s);
      noStroke();
    }
    pop(); // height authority
    pop();
    return true;
  }

  function drawPortrait(id,x,y,options) {
    const profile = PROFILES[id] || PROFILES.ender;
    const o = options || {};
    const s = Math.max(1.2, Number(o.scale) || 2.2);
    const m = motionState({ now:o.now, action:o.action || 'talk' });

    push();
    translate(x,y);
    if (o.facing === 'left') scale(-1,1);

    noStroke();
    fill(...profile.shirt);
    beginShape();
    vertex(-15*s,0); vertex(-11*s,-14*s); vertex(-7*s,-21*s);
    vertex(7*s,-21*s); vertex(11*s,-14*s); vertex(15*s,0);
    endShape(CLOSE);

    fill(...profile.vest);
    quad(-10*s,-18*s,10*s,-18*s,8*s,-2*s,-8*s,-2*s);
    stroke(...profile.leather);
    strokeWeight(1.4*s);
    line(-8*s,-8*s,8*s,-8*s);
    line(-5*s,-18*s,5*s,-3*s);
    noStroke();

    if (profile.scarf) {
      fill(...profile.scarf);
      arc(0,-19*s,18*s,8*s,0,Math.PI);
    }
    if (profile.embroidery) {
      stroke(...profile.accent);
      strokeWeight(0.8*s);
      line(-6*s,-15*s,-5*s,-3*s);
      line(6*s,-15*s,5*s,-3*s);
      noStroke();
    }
    if (profile.tattoos) {
      noFill();
      stroke(48,42,39,190);
      strokeWeight(0.8*s);
      ellipse(10*s,-10*s,7*s,7*s);
      line(7*s,-14*s,13*s,-6*s);
      noStroke();
    }

    // Dialogue-scale identity: retain the costume cues that distinguish the
    // five protagonists in the approved modeling references.
    if (profile.heavyHarness) {
      stroke(...profile.leather);
      strokeWeight(2.3*s);
      line(-10*s,-18*s,8*s,-2*s);
      line(10*s,-18*s,-8*s,-2*s);
      noStroke();
      fill(...profile.metal);
      rect(-1.8*s,-10*s,3.6*s,3*s,0.7*s);
    }
    if (profile.techRig) {
      stroke(...profile.metal);
      strokeWeight(1.4*s);
      line(-9*s,-17*s,8*s,-2*s);
      noStroke();
      fill(...profile.leather);
      rect(7*s,-12*s,5*s,8*s,1*s);
      fill(...profile.accent);
      rect(8.5*s,-9*s,2*s,2*s,0.4*s);
    }
    if (profile.neckGoggles) {
      noFill();
      stroke(...profile.metal);
      strokeWeight(1.2*s);
      ellipse(-3.4*s,-18*s,5.2*s,4*s);
      ellipse(3.4*s,-18*s,5.2*s,4*s);
      line(-0.8*s,-18*s,0.8*s,-18*s);
      noStroke();
    }
    if (profile.tailoredLayer) {
      stroke(...profile.metal);
      strokeWeight(0.9*s);
      line(-9*s,-17*s,-7*s,-3*s);
      line(9*s,-17*s,7*s,-3*s);
      noStroke();
    }
    if (profile.layeredDrape) {
      fill(...profile.vest);
      beginShape();
      vertex(-11*s,-8*s); vertex(-7*s,0); vertex(0,-4*s); vertex(7*s,0); vertex(11*s,-8*s);
      endShape(CLOSE);
    }

    push();
    translate(0,19*s);
    drawHead(profile,s*1.18,m,o.expression || 'talk');
    pop();

    pop();
    return true;
  }

  function validate() {
    return ['ender','reson','aepex','ionia','lyra'].every(id => PROFILES[id]);
  }

  root.AetherCharacterRenderer = Object.freeze({
    VERSION, PROFILES, draw:drawCharacter, drawPortrait, validate
  });
})(typeof window !== 'undefined' ? window : globalThis);
