// AetherUI — Adapter for ui.js flat functions
// Bridges window.UI (set by ui.js) so core.js can call methods.
// ui.js flat functions call bare p5 primitives (fill, text, rect, etc.) —
// those work in global p5 mode. This adapter adds methods core expects.

window.AetherUI = function(p, C) {
  const self = this;

  // Reference to the p5 instance (global mode, so p === window)
  this.p = p;

  this.init = function() {
    // Ensure UI globals exist (ui.js creates window.UI)
    if (!window.UI) window.UI = {};
    window.UI.dayNightPhase = 0;
    window.UI.combatLog = [];
    window.UI.questLog = [];
    window.UI.inventory = [];
    window.UI.menuOpen = false;
    window.UI.dialogueOpen = false;
    window.UI.shopOpen = false;
    window.UI.menuTitle = '';
    window.UI.menuOptions = [];
    window.UI.menuCallback = null;
    window.UI.dialogueNPC = null;
    window.UI.dialogueText = '';
    window.UI.shopItems = [];
    window.UI.turnOverlay = false;
  };

  // ── Methods core.js calls ──

  this.drawTitleScreen = function() {
    background(C.navy[0], C.navy[1], C.navy[2]);

    // Grid
    stroke(C.teal[0], C.teal[1], C.teal[2], 12);
    strokeWeight(1);
    for (let x = 0; x < width; x += 32) line(x, 0, x, height);
    for (let y = 0; y < height; y += 32) line(0, y, width, y);

    // Title
    textFont('VT323');
    textSize(36);
    textAlign(CENTER, CENTER);
    textLeading(40);

    fill(C.teal[0], C.teal[1], C.teal[2], 60);
    for (let dx = -2; dx <= 2; dx++) {
      for (let dy = -2; dy <= 2; dy++) {
        if (dx === 0 && dy === 0) continue;
        text('AETHERWAKE', width/2 + dx, height/2 - 40 + dy);
      }
    }
    fill(C.teal[0], C.teal[1], C.teal[2], 100);
    text('AETHERWAKE', width/2, height/2 - 40);

    textFont('VT323');
    textSize(16);
    fill(C.scioto[0], C.scioto[1], C.scioto[2], 200);
    text('THE SKIES REMEMBER', width/2, height/2 - 10);
    textSize(14);
    fill(C.parchment[0], C.parchment[1], C.parchment[2], 180);
    text('NEW GAME — N or ENTER', width/2, height/2 + 40);
    textSize(11);
    fill(C.dim[0], C.dim[1], C.dim[2]);
    text('WASD move  |  E talk  |  Q covenant  |  F ship', width/2, height/2 + 68);
    text('Tab sky/ground  |  L ledger  |  M shop  |  R sheet  |  T log', width/2, height/2 + 88);

    textFont('Press Start 2P');
    textSize(8);
    fill(C.teal[0], C.teal[1], C.teal[2], 120);
    text('AETHERWAKE // ENDER  //  TURN-BASED JRPG', width/2, height - 24);
  };

  this.drawHUD = function(p, C) {
    if (!world) return;

    const player = world.getPlayer();
    const quest = world.getQuestState();
    const ledger = world.getLedger();
    const inv = world.getInventory();

    window.UI.inventory = inv || [];

    // Panel
    const hx = 8, hy = 8, hw = 380, hh = 90;
    fill(C.navy[0], C.navy[1], C.navy[2]);
    noStroke();
    rect(hx, hy, hw, hh);
    drawPixelBorder(hx, hy, hw, hh, 2, C.navy, C.teal);

    // Name
    textFont('Press Start 2P');
    textSize(9);
    drawGlowText('ENDER', hx + 12, hy + 8, C.teal, 9);
    fill(C.parchment[0], C.parchment[1], C.parchment[2]);
    textSize(9);
    text('Rift Scholar  Lv.07', hx + 68, hy + 8);

    // Stats
    textFont('VT323');
    textSize(14);
    const sy = hy + 30;
    drawStatLabel('Vit', hx + 12, sy, '13', C.rust, 14);
    drawStatLabel('Echo', hx + 90, sy, '3/3', C.biolum, 14);
    drawStatLabel('Scrap', hx + 180, sy, '7', C.dusttan, 14);
    drawStatLabel('Aether', hx + 250, sy, '4/6', C.scioto, 14);
    drawStatLabel('Heat', hx + 320, sy, '1/3', C.rust, 14);

    // Charge bar
    const barX = hx + 12, barY = hy + 56, barW = hw - 24, barH = 6;
    fill(C.navy[0], C.navy[1], C.navy[2], 200);
    noStroke();
    rect(barX, barY, barW, barH);
    const chargePct = 2.0 / 4.0;
    fill(C.biolum[0], C.biolum[1], C.biolum[2]);
    rect(barX, barY, barW * chargePct, barH);
    drawPixelBorder(barX, barY, barW, barH, 1, C.navy, C.teal);

    // Day/night mini indicator
    drawDayNightMini(hx + hw - 30, hy + 54, 20);

    // Quest badge
    const phaseNames = {
      signal: 'SIGNAL', crossing: 'CROSSING', contact: 'CONTACT',
      choice: 'CHOICE', wake: 'WAKE'
    };
    textFont('Press Start 2P');
    textSize(7);
    fill(C.teal[0], C.teal[1], C.teal[2], 160);
    text(phaseNames[quest.phase] || quest.phase, hx + hw - 70, hy + 68);
  };

  this.drawCombatUI = function(p, C) {
    if (!combat) return;
    const state = combat.getState();
    if (!state) return;

    background(C.navy[0]-10, C.navy[1]-5, C.navy[2]-5);

    // Enemy panel
    if (state.enemy) {
      const ex = width/2 - 140, ey = 80, ew = 280, eh = 140;
      fill(C.navy[0], C.navy[1], C.navy[2]);
      noStroke();
      rect(ex, ey, ew, eh);
      drawPixelBorder(ex, ey, ew, eh, 3, C.navy, C.teal);

      textFont('Press Start 2P');
      textSize(10);
      drawGlowText(state.enemy.name, ex + 12, ey + 10, C.teal, 10);
      textFont('VT323');
      textSize(12);
      fill(C.parchment[0], C.parchment[1], C.parchment[2]);
      text('HP: ' + state.enemy.hp + '/' + state.enemy.maxHp, ex + 12, ey + 36);
      fill(C.dim[0], C.dim[1], C.dim[2]);
      text(state.enemy.status, ex + 12, ey + 54);
      fill(C.scioto[0], C.scioto[1], C.scioto[2], 160);
      textSize(10);
      text('Goal: ' + state.enemy.goal, ex + 12, ey + 74);
    }

    // Turn log
    const lx = width - 200, ly = 80, lw = 190, lh = 200;
    drawCombatLog(lx, ly, lw, lh);

    // Action panel
    const ax = 20, ay = height - 140, aw = width - 40, ah = 120;
    fill(C.navy[0], C.navy[1], C.navy[2]);
    noStroke();
    rect(ax, ay, aw, ah);
    drawPixelBorder(ax, ay, aw, ah, 2, C.navy, C.teal);

    textFont('Press Start 2P');
    textSize(9);
    drawGlowText('ACTIONS', ax + 12, ay + 10, C.teal, 9);

    textFont('VT323');
    textSize(13);
    const actions = state.actions || [];
    for (let i = 0; i < actions.length; i++) {
      const a = actions[i];
      const ay2 = ay + 34 + i * 18;
      fill(C.teal[0], C.teal[1], C.teal[2], 180);
      text('[' + (i+1) + '] ' + a.label, ax + 12, ay2);
      fill(C.parchment[0], C.parchment[1], C.parchment[2], 100);
      textSize(11);
      text(a.desc, ax + 160, ay2);
      textSize(13);
    }

    fill(C.dim[0], C.dim[1], C.dim[2]);
    textSize(11);
    text('1-5 select action | ESC end turn | R char sheet | T quest log', width/2, ay + ah - 8);

    // Last roll
    if (state.lastRoll) {
      const roll = state.lastRoll;
      const total = roll.dice + roll.stat;
      const pass = total >= 7;
      const full = total >= 10;
      const label = full ? '10+ SUCCESS' : pass ? '7-9 PARTIAL' : '6- FAILURE';
      const col = full ? C.teal : pass ? [255,180,70] : [255,90,50];
      drawDiceRoll(total, label, width/2, 50, 72);
    }
  };

  this.drawNPCDialogue = function(p, C) {
    if (!window.UI.dialogueOpen) return;
    const npc = window.UI.dialogueNPC;
    const dialogueText = window.UI.dialogueText;

    background(C.navy[0], C.navy[1], C.navy[2], 200);

    const bx = width/2 - 200, by = height - 120, bw = 400, bh = 100;
    fill(C.navy[0], C.navy[1], C.navy[2]);
    noStroke();
    rect(bx, by, bw, bh);
    drawPixelBorder(bx, by, bw, bh, 3, C.navy, C.teal);

    textFont('Press Start 2P');
    textSize(9);
    drawGlowText((npc && npc.name ? npc.name + (npc.title ? ' — ' + npc.title : '') : '???'),
                 bx + 12, by + 10, C.teal, 9);

    textFont('VT323');
    textSize(13);
    fill(C.parchment[0], C.parchment[1], C.parchment[2]);
    textAlign(LEFT, TOP);
    textLeading(16);

    // Word wrap
    const maxW = bw - 24;
    const words = text.split(' ');
    let line = '';
    let ly = by + 32;
    for (let w of words) {
      const test = line + (line ? ' ' : '') + w;
      if (textWidth(test) > maxW && line) {
        text(line, bx + 12, ly);
        line = w;
        ly += 16;
      } else {
        line = test;
      }
    }
    if (line) text(line, bx + 12, ly);

    fill(C.teal[0], C.teal[1], C.teal[2], 120);
    textSize(10);
    textAlign(CENTER, TOP);
    text('E or ENTER to continue', width/2, by + bh + 8);
  };

  this.clearNPCDialogue = function() {
    window.UI.dialogueOpen = false;
    window.UI.dialogueNPC = null;
    window.UI.dialogueText = '';
  };

  this.drawShop = function(p, C) {
    if (!window.UI.shopOpen) return;
    const items = window.UI.shopItems || [];

    background(C.navy[0], C.navy[1], C.navy[2], 200);

    const sx = 40, sy = 40, sw = width - 80, sh = height - 80;
    fill(C.navy[0], C.navy[1], C.navy[2]);
    noStroke();
    rect(sx, sy, sw, sh);
    drawPixelBorder(sx, sy, sw, sh, 3, C.navy, C.teal);

    textFont('Press Start 2P');
    textSize(10);
    drawGlowText('REPAIR CAFE — SHOP', sx + 16, sy + 12, C.teal, 10);
    const scrapAmt = combat ? combat.getState().player.scrap : 7;
    fill(C.parchment[0], C.parchment[1], C.parchment[2]);
    textSize(9);
    text('Scrap: ' + scrapAmt, sx + sw - 100, sy + 12);

    textFont('VT323');
    textSize(13);
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const iy = sy + 40 + i * 36;
      if (iy + 30 > sy + sh - 20) break;
      fill(C.navy[0]+10, C.navy[1]+5, C.navy[2]+5);
      noStroke();
      rect(sx + 12, iy, sw - 24, 32);
      stroke(C.teal[0], C.teal[1], C.teal[2], 60);
      strokeWeight(1);
      rect(sx + 12, iy, sw - 24, 32);

      const buyable = scrapAmt >= item.price;
      fill(buyable ? C.parchment[0] : C.dim[0], buyable ? C.parchment[1] : C.dim[1], buyable ? C.parchment[2] : C.dim[2]);
      text(item.name + ' [' + item.price + ' scrap]', sx + 20, iy + 6);
      fill(C.dim[0], C.dim[1], C.dim[2]);
      textSize(11);
      text(item.desc, sx + 20, iy + 20);
      textSize(13);

      fill(buyable ? C.teal[0] : C.dim[0], buyable ? C.teal[1] : C.dim[1], buyable ? C.teal[2] : C.dim[2], buyable ? 180 : 80);
      text('[1-' + items.length + '] Buy', sx + sw - 80, iy + 6);
      textSize(13);
    }

    fill(C.dim[0], C.dim[1], C.dim[2]);
    textSize(11);
    textAlign(CENTER, TOP);
    text('M or ESC to close  |  number to buy', width/2, sy + sh - 16);
  };

  this.drawLedger = function(p, C) {
    if (!world) return;
    const ledger = world.getLedger();

    background(C.navy[0], C.navy[1], C.navy[2], 200);

    const lx = 40, ly = 40, lw = width - 80, lh = height - 80;
    fill(C.navy[0], C.navy[1], C.navy[2]);
    noStroke();
    rect(lx, ly, lw, lh);
    drawPixelBorder(lx, ly, lw, lh, 2, C.navy, C.teal);

    textFont('Press Start 2P');
    textSize(10);
    drawGlowText('MYCELIAL LEDGER', lx + 16, ly + 12, C.teal, 10);
    fill(C.dim[0], C.dim[1], C.dim[2]);
    textSize(9);
    text('The weave remembers everything.', lx + 16, ly + 30);

    textFont('VT323');
    textSize(12);
    const entries = ledger || [];
    const maxH = lh - 50;
    const entryH = 16;
    const maxEntries = Math.floor(maxH / entryH);
    const start = Math.max(0, entries.length - maxEntries);

    for (let i = start; i < entries.length; i++) {
      const e = entries[i];
      const ey = ly + 48 + (i - start) * entryH;
      fill(C.scioto[0], C.scioto[1], C.scioto[2], 120);
      text(e.date, lx + 16, ey);
      fill(C.parchment[0], C.parchment[1], C.parchment[2]);
      text(e.text, lx + 60, ey);
    }

    fill(C.dim[0], C.dim[1], C.dim[2]);
    textSize(10);
    textAlign(CENTER, TOP);
    text('L or ESC to close', width/2, ly + lh - 16);
  };

  this.drawQuestLog = function(p, C) {
    if (!world) return;
    const quest = world.getQuestState();
    const ledger = world.getLedger();

    background(C.navy[0], C.navy[1], C.navy[2], 200);

    const qx = 40, qy = 40, qw = width - 80, qh = height - 80;
    fill(C.navy[0], C.navy[1], C.navy[2]);
    noStroke();
    rect(qx, qy, qw, qh);
    drawPixelBorder(qx, qy, qw, qh, 2, C.navy, C.teal);

    textFont('Press Start 2P');
    textSize(10);
    drawGlowText('QUEST LOG — THE ISLAND THAT FALLS UPWARD', qx + 16, qy + 12, C.teal, 10);

    const phaseColors = {
      signal: C.dim, crossing: C.scioto, contact: C.teal,
      choice: [80,240,160], wake: C.parchment
    };
    const phaseNames = {
      signal: 'SIGNAL — Receive the call',
      crossing: 'CROSSING — Hazards ahead',
      contact: 'CONTACT — Four souls await',
      choice: 'CHOICE — Three paths',
      wake: 'WAKE — The ending unfolds',
    };
    const pc = phaseColors[quest.phase] || C.dim;
    fill(pc[0], pc[1], pc[2]);
    textSize(11);
    text(phaseNames[quest.phase] || quest.phase, qx + 16, qy + 32);

    fill(C.dim[0], C.dim[1], C.dim[2]);
    textSize(10);
    text('Hooks: ' + quest.hooksDelivered + '/3  Hazards: ' + quest.hazardsPassed + '/3  NPCs: ' + quest.npcsMet + '/4',
         qx + 16, qy + 52);

    if (quest.choiceMade) {
      fill(C.teal[0], C.teal[1], C.teal[2], 180);
      text('Choice: ' + quest.choiceMade, qx + 16, qy + 70);
    }

    fill(C.dim[0], C.dim[1], C.dim[2]);
    textSize(9);
    text('Recent events:', qx + 16, qy + 90);

    textFont('VT323');
    textSize(11);
    const entries = ledger || [];
    const maxHq = qh - 110;
    const maxEq = Math.floor(maxHq / 15);
    const startq = Math.max(0, entries.length - maxEq);
    for (let i = startq; i < entries.length; i++) {
      const e = entries[i];
      const ey2 = qy + 108 + (i - startq) * 15;
      fill(C.scioto[0], C.scioto[1], C.scioto[2], 100);
      text(e.date, qx + 16, ey2);
      fill(C.parchment[0], C.parchment[1], C.parchment[2]);
      text(e.text, qx + 50, ey2);
    }

    fill(C.dim[0], C.dim[1], C.dim[2]);
    textSize(10);
    textAlign(CENTER, TOP);
    text('T or ESC to close', width/2, qy + qh - 14);
  };

  this.drawCharSheet = function(p, C) {
    if (!world || !combat) return;
    const player = combat.getState().player;
    const inv = world.getInventory();
    const quest = world.getQuestState();

    background(C.navy[0], C.navy[1], C.navy[2], 200);

    const sx = 20, sy = 20, sw = 500, sh = height - 40;
    fill(C.navy[0], C.navy[1], C.navy[2]);
    noStroke();
    rect(sx, sy, sw, sh);
    drawPixelBorder(sx, sy, sw, sh, 3, C.navy, C.teal);

    // Portrait area
    const px2 = sx + 16, py2 = sy + 16, pw2 = 100, ph2 = 110;
    fill(C.navy[0]+10, C.navy[1]+5, C.navy[2]+5);
    noStroke();
    rect(px2, py2, pw2, ph2);
    drawPixelBorder(px2, py2, pw2, ph2, 2, C.navy, C.teal);

    // Ender portrait
    const ppx = px2 + pw2/2, ppy = py2 + ph2/2;
    fill(C.parchment[0]-10, C.parchment[1]-10, C.parchment[2]-10);
    noStroke();
    ellipse(ppx, ppy-3, 22, 26);
    // Goggles
    fill(C.biolum[0], C.biolum[1], C.biolum[2], 180);
    stroke(C.teal[0], C.teal[1], C.teal[2], 200);
    strokeWeight(1);
    ellipse(ppx-6, ppy-5, 6, 6);
    ellipse(ppx+6, ppy-5, 6, 6);
    // Beard
    fill(C.parchment[0]-30, C.parchment[1]-20, C.parchment[2]-10);
    noStroke();
    ellipse(ppx, ppy+3, 10, 6);
    // Backpack
    fill(C.scioto[0]-20, C.scioto[1]-20, C.scioto[2]-10);
    noStroke();
    rect(ppx+6, ppy-8, 8, 12);
    stroke(C.teal[0], C.teal[1], C.teal[2], 100);
    strokeWeight(1);
    rect(ppx+6, ppy-8, 8, 12);

    // Name + class
    textFont('Press Start 2P');
    textSize(10);
    drawGlowText('ENDER', sx + 130, sy + 16, C.teal, 10);
    fill(C.parchment[0], C.parchment[1], C.parchment[2]);
    textSize(9);
    text('Age 22  //  Rift Scholar', sx + 130, sy + 36);

    // Stats
    textFont('VT323');
    textSize(14);
    const sy2 = sy + 56;
    drawStatLabel('Vit', sx + 130, sy2, player.vit + '/' + player.maxVit, C.rust, 14);
    drawStatLabel('Echoes', sx + 240, sy2, player.echoes + '/' + player.maxEchoes, C.biolum, 14);
    drawStatLabel('Wits', sx + 350, sy2, '+' + player.wits, C.scioto, 14);

    const sy3 = sy2 + 20;
    drawStatLabel('Presence', sx + 130, sy3, '+' + player.presence, C.scioto, 13);
    drawStatLabel('Spirit', sx + 240, sy3, '+' + player.spirit, C.biolum, 13);
    drawStatLabel('Might', sx + 350, sy3, '+' + player.might, C.rust, 13);

    // Resources
    const sy4 = sy3 + 22;
    drawStatLabel('Scrap', sx + 130, sy4, player.scrap, C.dusttan, 14);
    drawStatLabel('Aether', sx + 240, sy4, player.aether + '/' + player.maxAether, C.scioto, 14);
    drawStatLabel('Heat', sx + 350, sy4, player.heat + '/' + player.maxHeat, C.rust, 14);

    // Abilities
    textFont('Press Start 2P');
    textSize(9);
    drawGlowText('ABILITIES', sx + 16, sy4 + 30, C.teal, 9);

    textFont('VT323');
    textSize(12);
    const abilities = [
      { name: 'Uncover Truth', desc: 'Analyze weakness with Wits' },
      { name: 'Mycelial Ledger', desc: 'Read the commons network' },
      { name: 'Hold', desc: 'Recharge the Resonator Staff' },
      { name: 'Resonator Staff', desc: 'Formula EMP strike — 2 charges' },
    ];
    for (let i = 0; i < abilities.length; i++) {
      const a = abilities[i];
      const ay2 = sy4 + 50 + i * 20;
      fill(C.teal[0], C.teal[1], C.teal[2], 160);
      text(a.name, sx + 16, ay2);
      fill(C.parchment[0], C.parchment[1], C.parchment[2], 140);
      textSize(11);
      text(a.desc, sx + 130, ay2);
      textSize(12);
    }

    // Gear
    textFont('Press Start 2P');
    textSize(9);
    drawGlowText('GEAR', sx + 16, sy4 + 50 + abilities.length * 20 + 12, C.teal, 9);

    textFont('VT323');
    textSize(12);
    for (let i = 0; i < inv.length; i++) {
      const item = inv[i];
      const iy = sy4 + 50 + abilities.length * 20 + 32 + i * 18;
      if (iy > sy + sh - 20) break;
      fill(C.parchment[0], C.parchment[1], C.parchment[2]);
      text(item.name + ' [' + item.qty + 'x]', sx + 16, iy);
      fill(C.dim[0], C.dim[1], C.dim[2]);
      textSize(11);
      text(item.desc, sx + 150, iy);
      textSize(12);
    }

    fill(C.dim[0], C.dim[1], C.dim[2]);
    textSize(10);
    textAlign(CENTER, TOP);
    text('R or ESC to close', width/2, sy + sh - 14);
  };

  // ── Helpers (mirrors of flat functions, but as methods) ──
  this.setNPCDialogue = function(npc, text) {
    window.UI.dialogueOpen = true;
    window.UI.dialogueNPC = npc;
    window.UI.dialogueText = text;
  };

  this.setShopItems = function(items) {
    window.UI.shopOpen = true;
    window.UI.shopItems = items || [];
  };

  this.showEncounterSelect = function(enemies) {
    const names = Object.keys(enemies).map(k => enemies[k].name);
    showMenu('SELECT ENCOUNTER', names, function(chosen) {
      const id = Object.keys(enemies).find(k => enemies[k].name === chosen) || 'skyPredator';
      combat.beginEncounter(id);
    });
  };

  this.handleMenuInput = function(p, pressed) {
    if (!window.UI.menuOpen) return;
    // Arrow keys to navigate, Enter to select
    if (pressed[UP_ARROW] || pressed[p.DOWN_ARROW]) {
      // handled by menu drawing
    }
    if (pressed[ENTER] || pressed[p.ENTER] || key === 'Enter') {
      if (window.UI.menuCallback && window.UI.menuOptions.length > 0) {
        window.UI.menuCallback(window.UI.menuOptions[0]);
        hideMenu();
      }
    }
    if (pressed[27]) hideMenu();
  };
};

// ── Standalone helpers (used by UI and core) ──
function drawPixelBorder(x, y, w, h, thickness, col1, col2) {
  thickness = thickness || 2;
  col1 = col1 || [26,16,46];
  col2 = col2 || [42,255,181];
  noFill();
  stroke(col2[0], col2[1], col2[2]);
  strokeWeight(thickness);
  rect(x, y, w, h);
  stroke(col1[0], col1[1], col1[2], 180);
  strokeWeight(thickness);
  rect(x + thickness, y + thickness, w - thickness*2, h - thickness*2);
}

function drawGlowText(text, x, y, color, size) {
  size = size || 16;
  textSize(size);
  textAlign(LEFT, TOP);
  textStyle(BOLD);
  fill(color[0], color[1], color[2], 60);
  text(text, x-1, y-1);
  text(text, x+1, y-1);
  text(text, x-1, y+1);
  text(text, x+1, y+1);
  fill(color[0], color[1], color[2]);
  text(text, x, y);
  textStyle(NORMAL);
}

function drawStatLabel(label, x, y, value, color, size) {
  size = size || 14;
  textSize(size);
  textFont('VT323');
  textAlign(LEFT, TOP);
  fill(color[0], color[1], color[2], 180);
  text(label + ':', x, y);
  fill(C.parchment[0], C.parchment[1], C.parchment[2]);
  text(value, x + textWidth(label + ': ') + 4, y);
  fill(C.parchment[0], C.parchment[1], C.parchment[2]); // reset
}

function drawDayNightMini(cx, cy, r) {
  const phase = window.UI.dayNightPhase || 0;
  noStroke();
  fill(C.navy[0], C.navy[1], C.navy[2]);
  ellipse(cx, cy, r*2);
  const isDay = phase < 0.5;
  const col = isDay ? C.scioto : C.teal;
  fill(col[0], col[1], col[2], 180);
  ellipse(cx, cy, r*1.5);
  fill(col[0], col[1], col[2]);
  ellipse(cx, cy, r*0.8);
}

function drawCombatLog(lx, ly, lw, lh) {
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  rect(lx, ly, lw, lh);
  drawPixelBorder(lx, ly, lw, lh, 3, C.navy, C.teal);

  textFont('Press Start 2P');
  textSize(9);
  drawGlowText('COMBAT LOG', lx + 12, ly + 10, C.teal, 9);
  stroke(C.teal[0], C.teal[1], C.teal[2]);
  strokeWeight(1);
  line(lx + 12, ly + 24, lx + lw - 12, ly + 24);

  textFont('VT323');
  textSize(12);
  const log2 = window.UI.combatLog || [];
  const entryH = 16;
  const maxEntries = Math.floor((lh - 40) / entryH);
  const start = Math.max(0, log2.length - maxEntries);
  for (let i = start; i < log2.length; i++) {
    const eY = ly + 32 + (i - start) * entryH;
    fill(C.dim[0], C.dim[1], C.dim[2]);
    text('[' + i + ']', lx + 12, eY);
    fill(C.parchment[0], C.parchment[1], C.parchment[2]);
    const msg = log2[i];
    // Truncate
    let display = msg;
    if (textWidth(display) > lw - 30) {
      while (textWidth(display + '...') > lw - 30 && display.length > 0) {
        display = display.slice(0, -1);
      }
      display = display + '...';
    }
    text(display, lx + 36, eY);
  }
}

function drawDiceRoll(result, description, cx, cy, size) {
  size = size || 64;
  push();
  translate(cx, cy);

  // Background circle
  fill(C.navy[0], C.navy[1], C.navy[2]);
  noStroke();
  ellipse(0, 0, size);

  // Border
  drawPixelBorder(-size/2, -size/2, size, size, 2, C.navy, C.teal);

  // Result number — large
  textFont('Press Start 2P');
  textSize(size * 0.45);
  textAlign(CENTER, CENTER);
  textStyle(BOLD);

  const isSuccess = result >= 10;
  const isPartial = result >= 7;
  let textColor;
  if (isSuccess) textColor = C.teal;
  else if (isPartial) textColor = [255, 180, 70];
  else textColor = [255, 90, 50];

  fill(textColor[0], textColor[1], textColor[2], 180);
  text(String(result), 0, -4);

  // Glow
  fill(textColor[0], textColor[1], textColor[2], 60);
  text(String(result), -1, -5);
  text(String(result), 1, -5);
  text(String(result), 0, -3);

  textStyle(NORMAL);

  // Description below
  pop();

  textFont('VT323');
  textSize(11);
  textAlign(CENTER, TOP);
  fill(C.parchment[0], C.parchment[1], C.parchment[2], 160);
  text(description, cx, cy + size/2 + 6);
}

function showMenu(title, options, callback) {
  window.UI.menuOpen = true;
  window.UI.menuTitle = title;
  window.UI.menuOptions = options;
  window.UI.menuCallback = callback;
}

function hideMenu() {
  window.UI.menuOpen = false;
  window.UI.menuTitle = '';
  window.UI.menuOptions = [];
  window.UI.menuCallback = null;
}
