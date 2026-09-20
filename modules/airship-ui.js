/* Aetherwake — Dragonfly-class airship systems view. */
(function attachAirshipView(root) {
  'use strict';

  function rgb(colorValue, alpha) {
    return alpha === undefined
      ? colorValue
      : [colorValue[0], colorValue[1], colorValue[2], alpha];
  }

  function setFill(colorValue, alpha) {
    const value = rgb(colorValue, alpha);
    fill.apply(null, value);
  }

  function setStroke(colorValue, alpha) {
    const value = rgb(colorValue, alpha);
    stroke.apply(null, value);
  }

  function border(x, y, w, h, colorValue) {
    noFill();
    setStroke(colorValue, 120);
    strokeWeight(1);
    rect(x, y, w, h);
    setStroke(colorValue, 34);
    rect(x + 3, y + 3, w - 6, h - 6);
  }

  function bar(x, y, w, h, value, maximum, colorValue) {
    setFill([13, 8, 32], 210);
    noStroke();
    rect(x, y, w, h, 2);
    const ratio = maximum > 0 ? Math.max(0, Math.min(1, value / maximum)) : 0;
    setFill(colorValue, 190);
    rect(x + 2, y + 2, (w - 4) * ratio, h - 4, 1);
    border(x, y, w, h, colorValue);
  }

  function systemStatus(state, system) {
    if (system.id === 'harmonicVeil') return state.shieldMode.toUpperCase();
    if (system.chargeKey) return String(state[system.chargeKey]) + ' CHG';
    return 'READY';
  }

  function drawDragonflySchematic(state, C, x, y, w, h) {
    const cx = x + w / 2;
    const cy = y + h / 2 + 4;
    const pulse = Math.sin(millis() * 0.004) * 0.12 + 0.88;

    setStroke(C.teal, 100);
    strokeWeight(1);
    noFill();
    ellipse(cx, cy, 230 + pulse * 12, 105 + pulse * 8);
    setStroke(C.scioto, 60);
    ellipse(cx, cy, 275 + pulse * 14, 135 + pulse * 10);

    // Four translucent dragonfly wings. The wings and masts are external to
    // the three-container hull volume.
    setFill(C.scioto, 32);
    setStroke(C.scioto, 100);
    ellipse(cx - 96, cy - 28, 150, 55);
    ellipse(cx + 96, cy - 28, 150, 55);
    setFill(C.teal, 26);
    setStroke(C.teal, 90);
    ellipse(cx - 96, cy + 31, 150, 55);
    ellipse(cx + 96, cy + 31, 150, 55);

    // Narrow, reinforced hull and Wakeheart.
    setFill(C.soil, 220);
    noStroke();
    rect(cx - 22, cy - 62, 44, 124, 18);
    setStroke(C.dusttan, 180);
    strokeWeight(2);
    noFill();
    rect(cx - 22, cy - 62, 44, 124, 18);
    setFill(C.teal, 70 * pulse);
    noStroke();
    ellipse(cx, cy, 34, 45);
    setFill(C.scioto, 220);
    ellipse(cx, cy, 13, 20);

    // Mast and rootline tether.
    setStroke(C.dusttan, 180);
    strokeWeight(2);
    line(cx, cy - 62, cx, cy - 92);
    line(cx - 8, cy - 82, cx + 8, cy - 82);
    setStroke(C.teal, 150);
    strokeWeight(1);
    line(cx - 22, cy + 48, cx - 64, cy + 72);
    line(cx + 22, cy + 48, cx + 64, cy + 72);

    setFill(C.parchment, 170);
    textAlign(CENTER, CENTER);
    textFont('VT323');
    textSize(12);
    text('WAKEHEART', cx, cy + 76);
    textSize(10);
    setFill(C.dim, 180);
    text('phase array // rootline // lance', cx, y + h - 10);
  }

  function draw(state, C) {
    const systems = root.AetherAirshipState
      ? root.AetherAirshipState.getSystemDefinitions()
      : [];
    const profile = root.AetherAirshipState
      ? root.AetherAirshipState.getShieldProfile(state.shieldMode)
      : { label: state.shieldMode.toUpperCase(), description: '' };

    background(C.navy[0], C.navy[1], C.navy[2]);
    noStroke();
    setFill(C.teal, 7);
    for (let gx = 0; gx < width; gx += 32) rect(gx, 0, 1, height);
    for (let gy = 0; gy < height; gy += 32) rect(0, gy, width, 1);

    const panelX = 24, panelY = 28, panelW = width - 48, panelH = height - 56;
    setFill(C.navy, 232);
    rect(panelX, panelY, panelW, panelH, 4);
    border(panelX, panelY, panelW, panelH, C.teal);

    textAlign(LEFT, TOP);
    textFont('Press Start 2P');
    textSize(11);
    setFill(C.teal, 220);
    text('THE AUREATE WAKE // DRAGONFLY WAKE', panelX + 18, panelY + 14);
    textFont('VT323');
    textSize(13);
    setFill(C.parchment, 190);
    text('3 CONTAINERS VOLUME  |  MASTS + WINGS EXCLUDED  |  WAKEHEART ONLINE', panelX + 18, panelY + 34);

    const leftX = 42, leftY = 82, leftW = 372, leftH = 420;
    const rightX = 432, rightY = 82, rightW = 486;
    setFill(C.navy, 220);
    rect(leftX, leftY, leftW, leftH, 3);
    rect(rightX, rightY, rightW, 234, 3);
    rect(rightX, rightY + 248, rightW, 164, 3);
    border(leftX, leftY, leftW, leftH, C.scioto);
    border(rightX, rightY, rightW, 234, C.scioto);
    border(rightX, rightY + 248, rightW, 164, C.scioto);

    textFont('Press Start 2P');
    textSize(8);
    setFill(C.scioto, 200);
    text('SHIP SYSTEMS', leftX + 14, leftY + 14);
    text('EXTERNAL RESONANCE PROFILE', rightX + 14, rightY + 14);
    text('LIVE CAPABILITY STATE', rightX + 14, rightY + 262);

    textFont('VT323');
    textSize(13);
    for (let i = 0; i < systems.length; i++) {
      const system = systems[i];
      const rowY = leftY + 42 + i * 70;
      const active = state.lastAction === system.id;
      setFill(active ? C.teal : C.navy, active ? 28 : 150);
      rect(leftX + 10, rowY, leftW - 20, 56, 2);
      border(leftX + 10, rowY, leftW - 20, 56, active ? C.teal : C.dim);
      setFill(active ? C.teal : C.parchment, 220);
      text('[' + (i === 1 ? '2/H' : String(i + 1)) + '] ' + system.shortLabel,
        leftX + 20, rowY + 7);
      setFill(C.dim, 190);
      text(system.description, leftX + 20, rowY + 25, leftW - 115, 24);
      textAlign(RIGHT, TOP);
      setFill(active ? C.teal : C.scioto, 210);
      text(systemStatus(state, system), leftX + leftW - 20, rowY + 8);
      const cooldown = state.cooldowns[system.id] || 0;
      if (cooldown > 0) {
        setFill(C.rust, 220);
        text('COOL ' + cooldown, leftX + leftW - 20, rowY + 29);
      }
      textAlign(LEFT, TOP);
    }

    drawDragonflySchematic(state, C, rightX + 8, rightY + 34, rightW - 16, 190);

    const metricsY = rightY + 292;
    textFont('VT323');
    textSize(13);
    setFill(C.parchment, 200);
    text('POWER ' + state.power + '/' + state.maxPower, rightX + 16, metricsY);
    text('HULL ' + state.hull + '/' + state.maxHull, rightX + 170, metricsY);
    text('PHASE ' + state.phaseIntegrity + '/' + state.maxPhaseIntegrity, rightX + 324, metricsY);
    bar(rightX + 16, metricsY + 20, 125, 9, state.power, state.maxPower, C.teal);
    bar(rightX + 170, metricsY + 20, 125, 9, state.hull, state.maxHull, C.dusttan);
    bar(rightX + 324, metricsY + 20, 145, 9, state.phaseIntegrity, state.maxPhaseIntegrity, C.scioto);
    setFill(C.rust, 210);
    text('HEAT ' + state.heat + '/' + state.maxHeat, rightX + 16, metricsY + 48);
    bar(rightX + 72, metricsY + 51, 110, 9, state.heat, state.maxHeat, C.rust);
    setFill(C.scioto, 210);
    text('VEIL ' + profile.label + ' — ' + profile.description, rightX + 198, metricsY + 48, 270, 28);

    setFill(C.parchment, 220);
    textSize(13);
    text(state.lastMessage || 'Awaiting command.', leftX + 16, leftY + leftH - 40, leftW - 32, 28);

    const footerY = panelY + panelH - 22;
    textAlign(CENTER, CENTER);
    textFont('Press Start 2P');
    textSize(7);
    setFill(C.teal, 190);
    text('1 PHASE-SLIP   2/H VEIL   3 LANCE   4 TETHER   5 FORGE   R VENT   ESC/L LEAVE', width / 2, footerY);
    textAlign(LEFT, TOP);
  }

  root.AetherAirshipView = { draw };
}(typeof window !== 'undefined' ? window : globalThis));
