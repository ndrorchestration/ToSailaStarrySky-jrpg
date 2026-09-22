/**
 * Aetherwake JRPG — UI Module
 * All drawing via p5 primitives. No DOM creation.
 * Exports a global UI object consumed by core.js.
 */
'use strict';

// ─────────────────────────────────────────────
// 16-COLOR PALETTE (from SPEC.md)
// ─────────────────────────────────────────────
const PAL = {
  TEAL:       '#2AFFB5',  // Solar Teal — primary accent / glow
  SCIOTO:     '#7CC8E8',  // Scioto Blue — secondary / sky
  NAVY:       '#1A102E',  // Deep Navy — background
  PARCHMENT:  '#E8DCC6',  // Parchment — text / ports
  DUST:       '#C4A882',  // Dust Tan
  RUST:       '#A04A2C',  // Rust
  SOIL:       '#4A3520',  // Soil Brown
  BIO:        '#4AEB6B',  // Biolum Green — mycelial / gear
  WHITE:      '#F0F4F8',
  OFFWHITE:   '#D8DDE3',
  DIM:        '#8A7F99',
  SHADOW:     '#0D0820',  // deeper than NAVY for borders/depth
  RED:        '#FF5C5C',  // dice fail / danger
  AMBER:      '#FFB347',  // dice partial / heat
  GREEN:      '#5CFF8A',  // dice success / heal
};

// VT323 ≈ monospace 16px–24px feel; Press Start 2P ≈ heavy pixel 8–12px.
// p5 has no font fallback control per-call, so we approximate with size/weight calls.
// In core.js, setTextFont should be called once to load these.

const FONT_BODY  = 'VT323';
const FONT_UI    = 'Press Start 2P';

// ─────────────────────────────────────────────
// GLOBAL STATE (shared with core.js via window.UI)
// ─────────────────────────────────────────────
window.UI = {
  // Menu
  menuOpen: false,
  menuTitle: '',
  menuOptions: [],
  menuCallback: null,

  // Dialogue
  dialogueOpen: false,
  dialogueNPC: null,
  dialogueText: '',
  dialogueContinue: null,

  // Shop
  shopOpen: false,
  shopItems: [],

  // Turn overlay flag
  turnOverlay: false,

  // Combat log entries (circular, last N)
  combatLog: [],

  // Quest log entries
  questLog: [],

  // Inventory items
  inventory: [],

  // Day-night timer (0..120s mapped to 0..PI2)
  dayNightPhase: 0,
};

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────

/** Push a string into the combat log, keep last 6. */
function logCombat(msg) {
  window.UI.combatLog.push(msg);
  if (window.UI.combatLog.length > 6) window.UI.combatLog.shift();
}

/** Push a quest entry. */
function logQuest(msg) {
  window.UI.questLog.push(msg);
  if (window.UI.questLog.length > 8) window.UI.questLog.shift();
}

/** Push an inventory item. */
function addInventory(item) {
  window.UI.inventory.push(item);
}

// ─────────────────────────────────────────────
// AESTHETIC PRIMITIVES
// ─────────────────────────────────────────────

/**
 * Draw the global background: dark navy + teal grid overlay at low opacity.
 * Call once per frame in draw() BEFORE other UI layers.
 */
function drawBackground() {
  background(PAL.NAVY);

  // Subtle teal grid overlay (low opacity)
  push();
  stroke(PAL.TEAL);
  strokeWeight(1);
  const gridSize = 40;
  const alpha = 18; // ~7% opacity
  fill(color(PAL.TEAL), alpha);
  noStroke();
  for (let x = 0; x < width; x += gridSize) {
    for (let y = 0; y < height; y += gridSize) {
      rect(x, y, 1, 1);
    }
  }
  // Thicker grid lines at low opacity
  stroke(color(PAL.TEAL), 12);
  strokeWeight(1);
  for (let x = 0; x < width; x += gridSize) {
    line(x, 0, x, height);
  }
  for (let y = 0; y < height; y += gridSize) {
    line(0, y, width, y);
  }
  pop();
}

/**
 * Scanline overlay — horizontal lines across the whole canvas.
 * Call AFTER all content, semi-transparent dark teal lines.
 */
function drawScanlines() {
  push();
  noStroke();
  fill(color(PAL.SHADOW), 40); // subtle dark scanline tint
  for (let y = 0; y < height; y += 3) {
    rect(0, y, width, 1);
  }
  // Brighter scanline gaps
  fill(color(PAL.TEAL), 6);
  for (let y = 1; y < height; y += 3) {
    rect(0, y, width, 1);
  }
  pop();
}

/**
 * Pixel border: nested rects to simulate box-shadow depth.
 * @param {number} x,y,w,h — outer rect
 * @param {number} layers — how many nested border layers
 * @param {string} colorOuter — outer border color (default NAVY shadow)
 * @param {string} colorInner — inner border color (default TEAL)
 */
function drawPixelBorder(x, y, w, h, layers = 3,
                         colorOuter = PAL.SHADOW, colorInner = PAL.TEAL) {
  push();
  noFill();
  for (let i = 0; i < layers; i++) {
    const shrink = i * 2 + 1;
    const cx = x - shrink;
    const cy = y - shrink;
    const cw = w + shrink * 2;
    const ch = h + shrink * 2;
    stroke(i === 0 ? colorOuter : (i === layers - 1 ? colorInner : lerpColor(
      color(colorOuter), color(colorInner), i / (layers - 1))));
    strokeWeight(2);
    rect(cx, cy, cw, ch);
  }
  pop();
}

/**
 * Teal glow text — simulates text-shadow 0 0 8px #2AFFB5 via multiple offset draws.
 * Calls fill(textColor) once, then draws the same string several times offset with low-alpha TEAL.
 * @param {string} txt
 * @param {number} x, y
 * @param {string} textColor — main text color
 * @param {number} size — font size
 * @param {string} font — 'VT323' or 'Press Start 2P'
 */
function drawGlowText(txt, x, y, textColor = PAL.TEAL, size = 18,
                      font = FONT_BODY) {
  push();
  textFont(font);
  textSize(size);
  textAlign(LEFT, TOP);
  textLeading(size * 1.2);

  // Glow pass — 6 offset draws with low-alpha TEAL
  const glowColor = color(PAL.TEAL);
  glowColor.setAlpha(60);
  fill(glowColor);
  noStroke();
  for (let dx = -2; dx <= 2; dx++) {
    for (let dy = -2; dy <= 2; dy++) {
      if (dx === 0 && dy === 0) continue;
      text(txt, x + dx, y + dy);
    }
  }
  // Brighter inner glow
  glowColor.setAlpha(100);
  fill(glowColor);
  text(txt, x, y);

  // Main text
  fill(textColor);
  text(txt, x, y);
  pop();
}

/**
 * Glow text centered.
 */
function drawGlowTextCenter(txt, x, y, textColor = PAL.TEAL, size = 18,
                            font = FONT_BODY) {
  push();
  textFont(font);
  textSize(size);
  textAlign(CENTER, CENTER);
  textLeading(size * 1.2);

  const glowColor = color(PAL.TEAL);
  glowColor.setAlpha(60);
  fill(glowColor);
  noStroke();
  for (let dx = -2; dx <= 2; dx++) {
    for (let dy = -2; dy <= 2; dy++) {
      if (dx === 0 && dy === 0) continue;
      text(txt, x + dx, y + dy);
    }
  }
  glowColor.setAlpha(100);
  fill(glowColor);
  text(txt, x, y);

  fill(textColor);
  text(txt, x, y);
  pop();
}

/**
 * Draw a stat label with teal glow in VT323 style.
 */
function drawStatLabel(label, x, y, value, valueColor = PAL.PARCHMENT,
                       size = 16) {
  push();
  textFont(FONT_BODY);
  textSize(size);
  textAlign(LEFT, TOP);
  // Label with teal glow
  drawGlowText(label, x, y, PAL.TEAL, size);
  // Value in parchment
  fill(valueColor);
  noStroke();
  text(value, x + textWidth(label) + 8, y);
  pop();
}

// ─────────────────────────────────────────────
// VISUAL EFFECTS STATE (shared)
// ─────────────────────────────────────────────

/** Screen flash overlay — set by combat.js / core.js on big moments. */
window.screenFlash = { active: false, color: null, alpha: 0, startTime: 0 };

/**
 * Trigger a screen flash — color [r,g,b], duration ms, peak alpha 0..255.
 */
function triggerScreenFlash(r, g, b, duration, peakAlpha) {
  window.screenFlash.active = true;
  window.screenFlash.color = [r, g, b];
  window.screenFlash.alpha = peakAlpha || 120;
  window.screenFlash.startTime = millis();
  window.screenFlash.duration = duration || 250;
}

/** Draw the screen flash overlay if active. Call near end of drawHUDFrame. */
function drawScreenFlash() {
  if (!window.screenFlash.active) return;
  const now = millis();
  const age = now - window.screenFlash.startTime;
  if (age > (window.screenFlash.duration || 250)) {
    window.screenFlash.active = false;
    return;
  }
  const t = age / (window.screenFlash.duration || 250);
  const alpha = window.screenFlash.alpha * (1 - t);
  if (alpha < 1) return;
  noStroke();
  fill(window.screenFlash.color[0], window.screenFlash.color[1],
       window.screenFlash.color[2], alpha);
  rect(0, 0, width, height);
}

// ─────────────────────────────────────────────
// ANIMATED STAT BARS
// ─────────────────────────────────────────────

/** Track smoothed bar values so they animate instead of snapping. */
const _barAnim = new Map();

/**
 * Get smoothed bar value — lerps toward target each frame.
 * @param {string} key — unique bar identifier (e.g. 'playerVit', 'enemyHp')
 * @param {number} target — current target value (pixels or 0..1)
 * @param {number} [speed=0.12] — lerp speed per frame
 * @returns {number} smoothed current value
 */
function animBar(key, target, speed) {
  speed = speed == null ? 0.12 : speed;
  let cur = _barAnim.has(key) ? _barAnim.get(key) : target;
  cur = lerp(cur, target, Math.min(1, speed));
  _barAnim.set(key, cur);
  return cur;
}

/** Reset all bar animations (call on state change / new encounter). */
function resetBarAnimations() {
  _barAnim.clear();
}

// ─────────────────────────────────────────────
// PARTICLE SYSTEM (simple, p5-primitive based)
// ─────────────────────────────────────────────
window.particles = [];

/**
 * Emit a particle burst at (x, y). Color as [r,g,b] or PAL key.
 * @param {number} x, y
 * @param {object} opts — { count, color, speed, life, size, spread, upward }
 */
function emitParticles(x, y, opts) {
  if (!VIS.particles) return;
  opts = opts || {};
  const count = opts.count || 8;
  const color = opts.color || [42, 255, 181];
  const speed = opts.speed || 2;
  const life = opts.life || 40;
  const size = opts.size || 3;
  const spread = opts.spread || 1.8;
  const upward = opts.upward ? 1 : 0;
  for (let i = 0; i < count; i++) {
    const angle = Math.random() * TWO_PI;
    const spd = speed * (0.3 + Math.random() * 0.7);
    window.particles.push({
      x: x, y: y,
      vx: Math.cos(angle) * spd * spread,
      vy: Math.sin(angle) * spd * spread - (upward ? spd * 0.5 : 0),
      life: life * (0.5 + Math.random() * 0.5),
      maxLife: life,
      size: size * (0.5 + Math.random() * 0.5),
      color: color,
      decay: 0.97 + Math.random() * 0.02,
    });
  }
}

/**
 * Emit a ring expansion (for covenant field activation, ability effects).
 * @param {number} cx, cy
 * @param {number} maxRadius — ring start radius
 * @param {number} expandDist — how far it expands
 * @param {number} life — frames to live
 * @param {array} color
 */
function emitRing(cx, cy, maxRadius, expandDist, life, color) {
  if (!VIS.particles) return;
  for (let i = 0; i < 32; i++) {
    const a = (i / 32) * TWO_PI;
    const inner = maxRadius;
    const outer = maxRadius + expandDist;
    const r = inner + Math.random() * (outer - inner);
    window.particles.push({
      x: cx + Math.cos(a) * r,
      y: cy + Math.sin(a) * r,
      vx: Math.cos(a) * 0.3,
      vy: Math.sin(a) * 0.3,
      life: life * (0.6 + Math.random() * 0.4),
      maxLife: life,
      size: 2 + Math.random() * 2,
      color: color || [42, 255, 181],
      decay: 0.97,
      ring: true,
    });
  }
}

/** Update and cull particles. Call once per frame in drawHUDFrame. */
function updateParticles() {
  for (let i = window.particles.length - 1; i >= 0; i--) {
    const p = window.particles[i];
    p.x += p.vx;
    p.y += p.vy;
    p.vy += 0.04; // slight gravity
    p.vx *= p.decay || 0.98;
    p.vy *= p.decay || 0.98;
    p.life--;
    if (p.life <= 0) {
      window.particles.splice(i, 1);
    }
  }
  // Cap total particles for performance
  if (window.particles.length > 200) {
    window.particles.splice(0, window.particles.length - 200);
  }
}

/** Draw all active particles. Call after world/combat but before scanlines. */
function drawParticles() {
  if (!window.particles.length) return;
  noStroke();
  for (const p of window.particles) {
    const t = p.life / p.maxLife;
    const alpha = t * 200;
    const col = p.color;
    fill(col[0], col[1], col[2], alpha * 0.6);
    ellipse(p.x, p.y, p.size * t, p.size * t);
    // Core highlight
    fill(col[0], col[1], col[2], alpha * 0.3);
    ellipse(p.x, p.y, p.size * t * 2.2, p.size * t * 2.2);
  }
}

// ─────────────────────────────────────────────
// HUD IMPROVEMENTS
// ─────────────────────────────────────────────

/** Pulses when vit is low (< 5). */
let _lowVitPulse = 0;

/**
 * Draw animated HP bar — smooth transition, color shifts with health.
 * @param {number} x, y, w, h — bar rect
 * @param {number} current — current HP
 * @param {number} max — max HP
 * @param {string} label — optional label text above
 * @param {string} lowColor
 * @param {string} highColor
 */
function drawAnimatedHPBar(x, y, w, h, current, max, label,
                            lowColor, highColor) {
  lowColor = lowColor || PAL.RED;
  highColor = highColor || PAL.GREEN;
  push();
  const ratio = max > 0 ? constrain(current / max, 0, 1) : 0;
  // Smoothed ratio for animation
  const animKey = 'hp_' + label + '_' + current;
  const smoothRatio = animBar(animKey, ratio, 0.15);

  // Background
  noStroke();
  fill(PAL.NAVY);
  rect(x, y, w, h, 2);
  drawPixelBorder(x, y, w, h, 1, PAL.SHADOW, PAL.DIM);

  // Fill bar — color blends from low to high
  const fillW = max(0, (w - 2) * smoothRatio);
  if (fillW > 0) {
    // Blend color based on ratio
    const lc = color(lowColor);
    const hc = color(highColor);
    const blend = lerpColor(lc, hc, smoothRatio);
    blend.setAlpha(200);
    fill(blend);
    noStroke();
    rect(x + 1, y + 1, fillW, h - 2, 1.5);
    // Glow
    blend.setAlpha(60);
    fill(blend);
    rect(x + 1, y + 1, fillW, h - 2, 1.5);
  }

  // Low HP pulse — red flash overlay
  if (current > 0 && current < 5) {
    _lowVitPulse = (millis() * 0.005) % 1;
    const pulseAlpha = sin(_lowVitPulse * TWO_PI) * 0.4 + 0.4;
    fill(color(PAL.RED), pulseAlpha * 80);
    noStroke();
    rect(x, y, w, h, 2);
  }

  // Label
  if (label) {
    textFont(FONT_UI);
    textSize(8);
    textAlign(LEFT, TOP);
    fill(PAL.PARCHMENT, 180);
    noStroke();
    text(label.toUpperCase(), x, y - 11);
  }
  pop();
}

/**
 * Draw echo diamonds — small diamond icons showing current/max echoes.
 * @param {number} x, y — position
 * @param {number} current
 * @param {number} max
 * @param {number} size
 */
function drawEchoDiamonds(x, y, current, max, size) {
  size = size || 8;
  push();
  const totalDiamonds = max || 1;
  const diaW = size * 1.6;
  const diaH = size * 1.6;
  const gap = 3;
  const startX = x;
  for (let i = 0; i < totalDiamonds; i++) {
    const dx = startX + i * (diaW + gap);
    const filled = i < current;
    const col = filled ? PAL.BIO : PAL.SHADOW;
    const alpha = filled ? 220 : 60;
    // Diamond shape
    push();
    translate(dx + diaW / 2, y + diaH / 2);
    noStroke();
    fill(color(col), alpha);
    beginShape();
    vertex(0, -diaH / 2);
    vertex(diaW / 2, 0);
    vertex(0, diaH / 2);
    vertex(-diaW / 2, 0);
    endShape(CLOSE);
    // Glow on filled
    if (filled) {
      fill(color(PAL.BIO), 50);
      beginShape();
      vertex(0, -diaH / 2);
      vertex(diaW / 2, 0);
      vertex(0, diaH / 2);
      vertex(-diaW / 2, 0);
      endShape(CLOSE);
    }
    pop();
  }
  pop();
}

/**
 * Draw heat warning indicator — orange glow when heat > 2.
 * @param {number} x, y
 * @param {number} current
 * @param {number} max
 */
function drawHeatWarning(x, y, current, max) {
  push();
  const ratio = max > 0 ? current / max : 0;
  const warning = ratio > 0.67; // heat > 2/3
  const pulse = warning ? (millis() * 0.006) % 1 : 0;
  const glowAlpha = warning ? (sin(pulse * TWO_PI) * 0.3 + 0.5) * 160 : 0;

  // Warning glow bg
  if (glowAlpha > 5) {
    noStroke();
    fill(PAL.AMBER, glowAlpha * 0.3);
    ellipse(x, y, 24, 24);
  }

  // Icon — warning diamond/exclamation
  textFont(FONT_UI);
  textSize(10);
  textAlign(CENTER, CENTER);
  fill(warning ? PAL.AMBER : PAL.DIM, warning ? 220 : 100);
  noStroke();
  text('⚠', x, y);

  // Heat bar to the right
  const barW = 30, barH = 4;
  const bx = x + 10, by = y + 8;
  noStroke();
  fill(PAL.NAVY);
  rect(bx, by, barW, barH, 1);
  drawPixelBorder(bx, by, barW, barH, 1, PAL.SHADOW, PAL.DIM);
  const fillW = max(0, (barW - 2) * ratio);
  if (fillW > 0) {
    const hc = color(PAL.AMBER);
    hc.setAlpha(180);
    fill(hc);
    noStroke();
    rect(bx + 1, by + 1, fillW, barH - 2, 1);
  }
  // Label
  textFont(FONT_BODY);
  textSize(9);
  textAlign(LEFT, CENTER);
  fill(PAL.PARCHMENT, 160);
  noStroke();
  text('HEAT', bx + barW + 4, by + barH / 2);
  pop();
}

/**
 * Draw aether crystal visual — glowing crystal when aether > 0.
 * @param {number} x, y — center
 * @param {number} current
 * @param {number} max
 */
function drawAetherCrystal(x, y, current, max) {
  push();
  translate(x, y);
  const ratio = max > 0 ? current / max : 0;
  const hasAether = current > 0;
  const pulse = hasAether ? (millis() * 0.004) % 1 : 0;
  const glowAlpha = hasAether ? (sin(pulse * TWO_PI) * 0.3 + 0.5) * 180 : 30;

  // Outer glow
  noStroke();
  fill(PAL.SCIOTO, glowAlpha * 0.3);
  ellipse(0, 0, 22 + glowAlpha * 0.05, 22 + glowAlpha * 0.05);

  // Crystal shape — diamond/hex
  const s = 7;
  noStroke();
  fill(hasAether ? PAL.SCIOTO : PAL.DIM, hasAether ? 220 : 80);
  beginShape();
  vertex(0, -s);
  vertex(s * 0.6, -s * 0.3);
  vertex(s * 0.6, s * 0.3);
  vertex(0, s);
  vertex(-s * 0.6, s * 0.3);
  vertex(-s * 0.6, -s * 0.3);
  endShape(CLOSE);

  // Inner bright core when charged
  if (hasAether && ratio > 0.3) {
    fill(PAL.TEAL, 160);
    beginShape();
    vertex(0, -s * 0.5);
    vertex(s * 0.3, -s * 0.15);
    vertex(s * 0.3, s * 0.15);
    vertex(0, s * 0.5);
    vertex(-s * 0.3, s * 0.15);
    vertex(-s * 0.3, -s * 0.15);
    endShape(CLOSE);
  }

  // Label
  textFont(FONT_UI);
  textSize(7);
  textAlign(CENTER, TOP);
  fill(PAL.PARCHMENT, 140);
  noStroke();
  text('AETHER', 0, s + 5);
  pop();
}

/**
 * Draw solar charge meter with sun/moon icon.
 * @param {number} x, y — top-left of meter
 * @param {number} current kWh
 * @param {number} max kWh
 * @param {number} dayNightPhase 0..1 (0=noon day, 0.5=night)
 */
function drawSolarMeterHUD(x, y, current, max, dayNightPhase) {
  push();
  const ratio = max > 0 ? constrain(current / max, 0, 1) : 0;

  // Background panel
  noStroke();
  fill(PAL.NAVY);
  rect(x, y, 120, 22, 3);
  drawPixelBorder(x, y, 120, 22, 2, PAL.SHADOW, PAL.TEAL);

  // Sun/moon icon on left
  const iconX = x + 14, iconY = y + 11;
  const isDay = dayNightPhase != null ? dayNightPhase < 0.5 : ratio > 0.2;
  noStroke();
  if (isDay) {
    // Sun — circle with rays
    fill(PAL.SCIOTO, 200);
    ellipse(iconX, iconY, 8, 8);
    fill(PAL.SCIOTO, 80);
    ellipse(iconX, iconY, 14, 14);
    // Rays
    stroke(PAL.SCIOTO, 100);
    strokeWeight(1);
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * TWO_PI + millis() * 0.001;
      const r1 = 7, r2 = 11;
      line(iconX + cos(a) * r1, iconY + sin(a) * r1,
           iconX + cos(a) * r2, iconY + sin(a) * r2);
    }
    noStroke();
  } else {
    // Moon — crescent
    fill(PAL.TEAL, 200);
    ellipse(iconX, iconY, 8, 8);
    fill(PAL.NAVY, 200);
    ellipse(iconX + 2, iconY - 2, 6, 6);
    fill(PAL.TEAL, 60);
    ellipse(iconX, iconY, 12, 12);
    noStroke();
  }

  // Charge bar
  const barX = x + 24, barY = y + 5, barW = 82, barH = 12;
  noStroke();
  fill(PAL.NAVY);
  rect(barX, barY, barW, barH, 2);
  drawPixelBorder(barX, barY, barW, barH, 1, PAL.SHADOW, PAL.DIM);

  const fillW = max(0, (barW - 2) * ratio);
  if (fillW > 0) {
    const sc = color(PAL.TEAL);
    sc.setAlpha(200);
    fill(sc);
    noStroke();
    rect(barX + 1, barY + 1, fillW, barH - 2, 1.5);
    // Glow
    sc.setAlpha(50);
    fill(sc);
    rect(barX + 1, barY + 1, fillW, barH - 2, 1.5);
  }

  // Label
  textFont(FONT_BODY);
  textSize(10);
  textAlign(LEFT, CENTER);
  fill(PAL.PARCHMENT, 170);
  noStroke();
  const label = isDay ? '☀ SOLAR' : '☽ SOLAR';
  text(label, barX + barW + 6, barY + barH / 2);

  textFont(FONT_UI);
  textSize(7);
  textAlign(RIGHT, CENTER);
  fill(PAL.DIM, 140);
  noStroke();
  text(current.toFixed(1) + 'kWh', x + 116, y + 17);
  pop();
}

/**
 * Draw quest progress indicator — dots for each stage.
 * @param {number} x, y — position
 * @param {string} currentState — 'signal' | 'crossing' | 'contact' | 'choice' | 'wake'
 */
function drawQuestProgress(x, y, currentState) {
  push();
  const stages = [
    { key: 'signal',   label: 'SIG', color: PAL.TEAL },
    { key: 'crossing', label: 'CROSS', color: PAL.AMBER },
    { key: 'contact',  label: 'CONTACT', color: PAL.SCIOTO },
    { key: 'choice',   label: 'CHOICE', color: PAL.RUST },
    { key: 'wake',     label: 'WAKE', color: PAL.BIO },
  ];
  const dotSize = 6;
  const gap = 4;
  const totalW = stages.length * (dotSize + gap) - gap;
  const startX = x;

  // Background pill
  noStroke();
  fill(PAL.NAVY);
  rect(x - 6, y - dotSize - 4, totalW + 12, dotSize * 2 + 12, 4);
  drawPixelBorder(x - 6, y - dotSize - 4, totalW + 12, dotSize * 2 + 12, 1, PAL.SHADOW, PAL.DIM);

  stages.forEach((s, i) => {
    const dx = startX + i * (dotSize + gap);
    const dy = y;
    const done = i < stages.findIndex(st => st.key === currentState);
    const active = s.key === currentState;
    const col = done ? PAL.TEAL : (active ? s.color : PAL.DIM);
    const alpha = done ? 220 : (active ? 220 : 80);

    // Dot
    noStroke();
    fill(color(col), alpha);
    ellipse(dx + dotSize / 2, dy + dotSize / 2, dotSize, dotSize);
    // Glow on active
    if (active) {
      fill(color(col), 50);
      ellipse(dx + dotSize / 2, dy + dotSize / 2, dotSize * 2, dotSize * 2);
    }

    // Label below
    textFont(FONT_UI);
    textSize(6);
    textAlign(CENTER, TOP);
    fill(PAL.PARCHMENT, done ? 160 : 90);
    noStroke();
    text(s.label, dx + dotSize / 2, dy + dotSize + 3);
  });
  pop();
}

/**
 * Draw day-night indicator. 0 = noon (bright), 0.5 = night (dark), 1 = noon again.
 * Phase maps to angle: 0 = top (noon), PI = bottom (night).
 * arc / ellipse with scioto-blue → dark navy gradient.
 */
function drawDayNightIndicator(cx, cy, r = 28) {
  push();
  const phase = window.UI.dayNightPhase; // 0..1
  const angle = phase * TWO_PI;

  // Outer ring — pixel border
  drawPixelBorder(cx - r - 6, cy - r - 6, (r + 6) * 2, (r + 6) * 2, 2,
                   PAL.SHADOW, PAL.TEAL);

  // Background circle
  noStroke();
  fill(PAL.NAVY);
  ellipse(cx, cy, r * 2);

  // Day arc (top half, scioto blue) — drawn from -PI/2 to PI/2 based on phase
  const dayStart = -HALF_PI;
  const dayEnd = dayStart + TWO_PI * phase;
  stroke(PAL.SCIOTO);
  strokeWeight(4);
  noFill();
  // Day arc: from -PI/2 clockwise by phase*2PI
  const startA = -HALF_PI;
  const endA = startA + phase * TWO_PI;
  // When phase > 0.5 the day arc overlaps; we draw a "night" wedge instead
  if (phase <= 0.5) {
    arc(cx, cy, r * 2, r * 2, startA, endA);
  } else {
    // Night: draw full circle dark, then day arc for remaining
    fill(PAL.NAVY);
    noStroke();
    ellipse(cx, cy, r * 2 - 4);
    arc(cx, cy, r * 2, r * 2, startA, endA);
  }

  // Sun/moon indicator at the leading edge
  const indicatorAngle = endA;
  const ix = cx + cos(indicatorAngle) * (r - 6);
  const iy = cy + sin(indicatorAngle) * (r - 6);
  noStroke();
  if (phase < 0.5) {
    // Sun
    fill(PAL.SCIOTO);
    ellipse(ix, iy, 8, 8);
    // Glow
    fill(color(PAL.SCIOTO), 80);
    ellipse(ix, iy, 14, 14);
  } else {
    // Moon
    fill(PAL.TEAL);
    ellipse(ix, iy, 7, 7);
    fill(color(PAL.TEAL), 60);
    ellipse(ix, iy, 12, 12);
  }

  // Label
  fill(PAL.PARCHMENT);
  noStroke();
  textFont(FONT_UI);
  textSize(9);
  textAlign(CENTER, CENTER);
  const label = phase < 0.25 ? 'DAWN' : phase < 0.5 ? 'DAY' :
                phase < 0.75 ? 'DUSK' : 'NIGHT';
  text(label, cx, cy + r + 14);
  pop();
}

// ─────────────────────────────────────────────
// COVENANT FIELD (teal circle)
// ─────────────────────────────────────────────

/**
 * Draw a Covenant Field — a teal circle with glow, pulsing ring, and mycelial accents.
 * @param {number} x, y — center
 * @param {number} radius — field radius (pixels)
 * @param {number} pulse — 0..1 pulse phase for animation
 */
function drawCovenantField(x, y, radius = 60, pulse = 0) {
  push();
  translate(x, y);

  // Outer glow — large soft teal ellipse
  noStroke();
  for (let g = 5; g >= 0; g--) {
    const alpha = map(g, 0, 5, 5, 40);
    fill(color(PAL.TEAL), alpha);
    ellipse(0, 0, radius * 2 + g * 12, radius * 2 + g * 12);
  }

  // Main field circle
  stroke(PAL.TEAL);
  strokeWeight(2);
  fill(color(PAL.TEAL), 18); // very low opacity fill
  ellipse(0, 0, radius * 2);

  // Inner ring — pulsing
  const pulseRadius = radius * (0.85 + 0.15 * sin(pulse * TWO_PI));
  noFill();
  stroke(PAL.TEAL);
  strokeWeight(1);
  ellipse(0, 0, pulseRadius * 2);

  // Mycelial accent lines (radial, teal)
  stroke(PAL.TEAL);
  strokeWeight(1);
  const segments = 8;
  for (let i = 0; i < segments; i++) {
    const a = (TWO_PI / segments) * i + pulse * 0.3;
    const r1 = radius * 0.2;
    const r2 = radius * (0.7 + 0.2 * sin(pulse * TWO_PI + i));
    line(cos(a) * r1, sin(a) * r1, cos(a) * r2, sin(a) * r2);
  }

  // Center glyph — diamond / hex
  push();
  rotate(pulse * TWO_PI * 0.5);
  stroke(PAL.TEAL);
  strokeWeight(2);
  noFill();
  // Diamond
  const d = radius * 0.18;
  beginShape();
  vertex(0, -d);
  vertex(d, 0);
  vertex(0, d);
  vertex(-d, 0);
  endShape(CLOSE);
  pop();

  pop();
}

// ─────────────────────────────────────────────
// CHARACTER SHEET HUD
// ─────────────────────────────────────────────

/**
 * Draw the full character sheet HUD: portrait, class/level, stats, abilities, gear, resources.
 * Layout: top-left portrait + vitals, right column stats, bottom abilities/gear/resources.
 */
function drawCharSheet(px, py, pw, ph) {
  push();
  const sheet = {
    portraitX: px + 16,
    portraitY: py + 16,
    portraitW: 120,
    portraitH: 140,
    classX: px + 160,
    classY: py + 16,
    levelX: px + 160,
    levelY: py + 48,
    statsX: px + 160,
    statsY: py + 80,
    abilitiesX: px + 16,
    abilitiesY: py + 170,
    gearX: px + 300,
    gearY: py + 170,
    resourcesX: px + 16,
    resourcesY: py + 290,
    panelW: pw - 32,
    panelH: ph - 32,
  };

  // Panel background with pixel border
  noStroke();
  fill(PAL.NAVY);
  rect(px, py, pw, ph);
  drawPixelBorder(px, py, pw, ph, 3, PAL.SHADOW, PAL.TEAL);

  // ── Portrait Area ──
  const portX = sheet.portraitX;
  const portY = sheet.portraitY;
  const portW = sheet.portraitW;
  const portH = sheet.portraitH;

  // Portrait frame — pixel border
  drawPixelBorder(portX, portY, portW, portH, 3, PAL.SHADOW, PAL.TEAL);

  // Portrait bg
  noStroke();
  fill(PAL.SHADOW);
  rect(portX + 4, portY + 4, portW - 8, portH - 8);

  // Portrait placeholder: Ender — green goggles, trimmed beard, mycelial tattoos
  const cx = portX + portW / 2;
  const cy = portY + portH / 2 - 10;
  const headR = 32;

  // Head silhouette
  fill(PAL.DUST);
  noStroke();
  ellipse(cx, cy, headR * 2, headR * 2.1);

  // Mycelial tattoos — teal branching on face
  stroke(PAL.TEAL);
  strokeWeight(1.5);
  noFill();
  // Left branch
  beginShape();
  vertex(cx - 18, cy - 10);
  vertex(cx - 24, cy - 4);
  vertex(cx - 22, cy + 4);
  vertex(cx - 16, cy + 8);
  endShape();
  // Right branch
  beginShape();
  vertex(cx + 18, cy - 10);
  vertex(cx + 24, cy - 4);
  vertex(cx + 22, cy + 4);
  vertex(cx + 16, cy + 8);
  endShape();
  // Forehead line
  line(cx - 14, cy - 18, cx + 14, cy - 18);

  // Goggles — green
  noStroke();
  fill(PAL.BIO);
  ellipse(cx - 12, cy - 4, 14, 10);
  ellipse(cx + 12, cy - 4, 14, 10);
  fill(PAL.SCIOTO);
  ellipse(cx - 12, cy - 4, 8, 6);
  ellipse(cx + 12, cy - 4, 8, 6);

  // Trimmed beard
  fill(PAL.SOIL);
  noStroke();
  beginShape();
  vertex(cx - 16, cy + 6);
  vertex(cx - 20, cy + 18);
  vertex(cx - 12, cy + 22);
  vertex(cx, cy + 20);
  vertex(cx + 12, cy + 22);
  vertex(cx + 20, cy + 18);
  vertex(cx + 16, cy + 6);
  endShape(CLOSE);

  // Eyes
  fill(PAL.NAVY);
  noStroke();
  ellipse(cx - 12, cy - 4, 4, 4);
  ellipse(cx + 12, cy - 4, 4, 4);

  // Short trimmed hair (beard top)
  fill(PAL.SOIL);
  noStroke();
  beginShape();
  vertex(cx - 22, cy - 22);
  vertex(cx - 26, cy - 14);
  vertex(cx - 24, cy - 8);
  vertex(cx - 18, cy - 14);
  vertex(cx - 14, cy - 20);
  endShape();
  beginShape();
  vertex(cx + 22, cy - 22);
  vertex(cx + 26, cy - 14);
  vertex(cx + 24, cy - 8);
  vertex(cx + 18, cy - 14);
  vertex(cx + 14, cy - 20);
  endShape();

  // Armor collar hint
  fill(PAL.RUST);
  noStroke();
  rect(cx - 18, cy + 22, 36, 8);

  // ── Class + Level ──
  textFont(FONT_UI);
  textSize(10);
  textAlign(LEFT, TOP);
  drawGlowText('CLASS', sheet.classX, sheet.classY, PAL.TEAL, 10);
  fill(PAL.PARCHMENT);
  text('Rift Scholar', sheet.classX + 44, sheet.classY);

  drawGlowText('LEVEL', sheet.levelX, sheet.levelY, PAL.TEAL, 10);
  fill(PAL.PARCHMENT);
  text('Rank 1', sheet.levelX + 44, sheet.levelY);

  // ── Stats ──
  textFont(FONT_BODY);
  textSize(14);
  const statsY = sheet.statsY;
  const statColor = PAL.PARCHMENT;
  const statAccent = PAL.TEAL;
  const stats = [
    { label: 'Vit',    value: '13',   accent: PAL.RUST },
    { label: 'Echoes', value: '3/3',  accent: PAL.BIO },
    { label: 'Wits',   value: '+2',   accent: PAL.SCIOTO },
    { label: 'Presence', value: '+1', accent: PAL.TEAL },
    { label: 'Spirit', value: '+1',   accent: PAL.TEAL },
    { label: 'Might',  value: '-1',   accent: PAL.RUST },
  ];
  stats.forEach((s, i) => {
    const sy = statsY + i * 18;
    drawGlowText(s.label, sheet.statsX, sy, statAccent, 14);
    fill(s.accent);
    noStroke();
    textSize(16);
    text(s.value, sheet.statsX + textWidth(s.label) + 8, sy - 2);
  });

  // ── Abilities ──
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('ABILITIES', sheet.abilitiesX, sheet.abilitiesY,
               PAL.TEAL, 9);
  textFont(FONT_BODY);
  textSize(13);
  const abils = [
    'Uncover Truth: Analyze weakness',
    'Shared Dream: Legacy / SSOT blocked',
    'Mycelial Ledger: Commons analysis',
    'Resonator Staff: EMP formula attack',
  ];
  abils.forEach((a, i) => {
    const ay = sheet.abilitiesY + 22 + i * 18;
    fill(PAL.PARCHMENT);
    noStroke();
    // Ability name in teal
    const parts = a.split(':');
    if (parts.length === 2) {
      drawGlowText(parts[0] + ':', sheet.abilitiesX + 10, ay,
                   PAL.TEAL, 13);
      fill(PAL.PARCHMENT);
      text(parts[1].trim(), sheet.abilitiesX + 10 + textWidth(parts[0] + ':') + 8, ay);
    } else {
      drawGlowText(a, sheet.abilitiesX + 10, ay, PAL.TEAL, 13);
    }
  });

  // ── Gear ──
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('GEAR', sheet.gearX, sheet.gearY, PAL.TEAL, 9);
  textFont(FONT_BODY);
  textSize(13);
  const gear = [
    { name: 'Loom Backpack', desc: 'Solar green tubes / 2.0kWh / 400W' },
    { name: 'Resonator Staff', desc: 'Gunmetal shaft, claw mount, cyan crystal' },
  ];
  gear.forEach((g, i) => {
    const gy = sheet.gearY + 22 + i * 30;
    drawGlowText(g.name, sheet.gearX + 10, gy, PAL.BIO, 13);
    fill(PAL.DIM);
    noStroke();
    textSize(12);
    text(g.desc, sheet.gearX + 10, gy + 16);
  });

  // ── Resources ──
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('RESOURCES', sheet.resourcesX, sheet.resourcesY,
               PAL.TEAL, 9);
  textFont(FONT_BODY);
  textSize(14);
  const resY = sheet.resourcesY + 22;
  const res = [
    { label: 'Scrap',   value: '7',    unit: '' },
    { label: 'Aether',  value: '4',    unit: '/6' },
    { label: 'Heat',    value: '1',    unit: '/3' },
    { label: 'Charge',  value: '2.0',  unit: 'kWh / 400W' },
  ];
  res.forEach((r, i) => {
    const ry = resY + i * 20;
    drawGlowText(r.label, sheet.resourcesX + 10, ry, PAL.SCIOTO, 14);
    fill(PAL.PARCHMENT);
    noStroke();
    textSize(15);
    text(r.value + r.unit, sheet.resourcesX + 10 + textWidth(r.label) + 10, ry - 1);
  });

  pop();
}

/**
 * Minimal HUD version — smaller, top-bar style.
 */
function drawWorldHUD() {
  push();
  // Top bar — vitals + quest phase
  const hudX = 8, hudY = 8, hudW = width - 512, hudH = 52;
  
  // Panel background
  noStroke();
  fill(PAL.NAVY);
  rect(hudX, hudY, hudW, hudH);
  drawPixelBorder(hudX, hudY, hudW, hudH, 2, PAL.SHADOW, PAL.TEAL);
  
  // Character name + level
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('ENDER', hudX + 12, hudY + 8, PAL.TEAL, 9);
  fill(PAL.PARCHMENT);
  textSize(9);
  text('Rift Scholar  Lv.1', hudX + 64, hudY + 8);
  
  // Vitals row
  textFont(FONT_BODY);
  textSize(12);
  const vY = hudY + 28;
  drawStatLabel('Vit', hudX + 12, vY, '13', PAL.RUST);
  drawStatLabel('Echoes', hudX + 80, vY, '3/3', PAL.BIO);
  drawStatLabel('Scrap', hudX + 160, vY, '7', PAL.DUST);
  drawStatLabel('Aether', hudX + 220, vY, '4/6', PAL.SCIOTO);
  drawStatLabel('Heat', hudX + 290, vY, '1/3', PAL.AMBER);
  
  // Right side — quest phase indicator
  const qX = hudX + hudW - 130;
  const qY = hudY + 8;
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('QUEST', qX, qY, PAL.TEAL, 9);
  fill(PAL.PARCHMENT);
  textSize(10);
  text('Signal 0/3', qX + 44, qY);
  
  // Day-night mini indicator
  drawDayNightIndicator(hudX + hudW - 36, hudY + 32, 20);
  
  pop();
}

// ─────────────────────────────────────────────
// COMBAT UI PANEL
// ─────────────────────────────────────────────

/** Action icon glyphs — simple p5 shapes for each action type */
function drawActionIcon(cx, cy, size, actionId) {
  push();
  translate(cx, cy);
  const s = size * 0.5;
  textFont(FONT_UI);
  textSize(s * 0.7);
  textAlign(CENTER, CENTER);
  let glyph = '?';
  let col = PAL.TEAL;
  switch (actionId) {
    case 'staffStrike':
      glyph = '\u2605'; // star
      col = PAL.AMBER;
      break;
    case 'uncoverTruth':
      glyph = '\u2726'; // four pointed star
      col = PAL.SCIOTO;
      break;
    case 'sharedDream':
      glyph = '\u2665'; // heart
      col = PAL.BIO;
      break;
    case 'mycelialLedger':
      glyph = '\u25A0'; // square
      col = PAL.GREEN;
      break;
    case 'hold':
      glyph = '\u25CF'; // circle
      col = PAL.DIM;
      break;
  }
  fill(col);
  noStroke();
  text(glyph, 0, 0);
  pop();
}

/** Draw the full combat UI panel — left side of screen */
function drawCombatPanel(combatState) {
  if (!combatState) return;
  push();
  const px = 8, py = 8, pw = 220, ph = 580;

  // Panel background
  fill(PAL.NAVY);
  noStroke();
  rect(px, py, pw, ph);
  drawPixelBorder(px, py, pw, ph, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('COMBAT', px + 12, py + 8, PAL.TEAL, 9);
  text('TURN ' + combatState.turn, px + pw - 60, py + 10);

  // Enemy section
  if (combatState.enemy) {
    const ey = py + 36;
    drawPixelBorder(px + 8, ey, pw - 16, 48, 2, PAL.SHADOW, PAL.RUST);
    textFont(FONT_UI);
    textSize(8);
    drawGlowText(combatState.enemy.name.toUpperCase(), px + 14, ey + 4, PAL.RUST, 8);
    textFont(FONT_BODY);
    textSize(11);
    fill(PAL.PARCHMENT);
    noStroke();
    const eNameW = textWidth(combatState.enemy.name);
    text('HP ' + combatState.enemy.hp + '/' + combatState.enemy.maxHp, px + pw - 64, ey + 6);
    // HP bar
    const hpRatio = combatState.enemy.hp / combatState.enemy.maxHp;
    const barW = pw - 32;
    noStroke();
    fill(PAL.SHADOW);
    rect(px + 14, ey + 24, barW, 5);
    const hpCol = hpRatio > 0.5 ? PAL.SCIOTO : (hpRatio > 0.25 ? PAL.AMBER : PAL.RED);
    fill(hpCol);
    rect(px + 14, ey + 24, barW * hpRatio, 5);
    // Weakness hint
    textFont(FONT_UI);
    textSize(7);
    fill(PAL.DIM);
    text('WEAKNESS: ' + (combatState.enemy.weakness || 'unknown'), px + 14, ey + 32);
  }

  // Player status section
  const sY = py + 96;
  drawPixelBorder(px + 8, sY, pw - 16, 88, 2, PAL.SHADOW, PAL.TEAL);
  textFont(FONT_UI);
  textSize(8);
  drawGlowText('ENDER', px + 14, sY + 6, PAL.TEAL, 8);

  // Player resources
  textFont(FONT_BODY);
  textSize(12);
  let rX = px + 14;
  const rY = sY + 24;
  // Vit
  fill(PAL.RUST);
  text('HP', rX, rY);
  rX += 20;
  fill(PAL.PARCHMENT);
  text(combatState.player.vit + '/' + combatState.player.maxVit, rX, rY);
  // Echoes
  rX += 48;
  fill(PAL.BIO);
  text('ECHO', rX, rY);
  rX += 36;
  fill(PAL.PARCHMENT);
  text(combatState.player.echoes.current + '/' + combatState.player.echoes.max, rX, rY);
  // Aether
  rX += 52;
  fill(PAL.SCIOTO);
  text('AETHER', rX, rY);
  rX += 44;
  fill(PAL.PARCHMENT);
  text(combatState.player.aether.current + '/' + combatState.player.aether.max, rX, rY);
  // Staff charges
  rX = px + 14;
  const rY2 = sY + 48;
  fill(PAL.TEAL);
  text('STAFF', rX, rY2);
  rX += 36;
  fill(PAL.PARCHMENT);
  text(combatState.player.staffCharges + '/' + combatState.player.maxStaffCharges, rX, rY2);
  // Scrap
  rX += 52;
  fill(PAL.DUST);
  text('SCRAP', rX, rY2);
  rX += 36;
  fill(PAL.PARCHMENT);
  text(String(combatState.player.scrap), rX, rY2);

  // Actions grid — 5 actions with number keys
  const aX = px + 8;
  const aY = sY + 100;
  const aW = pw - 16;
  const aH = 90;
  drawPixelBorder(aX, aY, aW, aH, 2, PAL.SHADOW, PAL.TEAL);

  textFont(FONT_UI);
  textSize(8);
  drawGlowText('ACTIONS [1-5]', aX + 12, aY + 6, PAL.TEAL, 8);

  const actions = combatState.actions || [];
  const actH = 16;
  const actStartY = aY + 22;
  actions.forEach((action, idx) => {
    const ay = actStartY + idx * actH;
    // Number circle
    fill(PAL.TEAL);
    noStroke();
    ellipse(aX + 12, ay + 7, 9, 9);
    fill(PAL.NAVY);
    textFont(FONT_UI);
    textSize(7);
    textAlign(CENTER, CENTER);
    text(String(idx + 1), aX + 12, ay + 7);
    // Action label
    textFont(FONT_BODY);
    textSize(10);
    textAlign(LEFT, CENTER);
    const label = action.label || action.id;
    fill(PAL.PARCHMENT);
    noStroke();
    text(label.substring(0, 28), aX + 24, ay + 1);
    // Cost indicator
    if (action.cost > 0) {
      textFont(FONT_UI);
      textSize(7);
      fill(PAL.AMBER);
      text('COST: ' + action.cost, aX + 24 + textWidth(label.substring(0, 28)) + 4, ay + 2);
    }
    // Icon
    drawActionIcon(aX + aW - 16, ay + 7, 14, action.id);
  });

  // Enemy special ability hint
  if (combatState.enemy && combatState.enemy.abilityDesc) {
    const abY = aY + aH + 10;
    drawPixelBorder(px + 8, abY, pw - 16, 28, 1, PAL.SHADOW, PAL.RUST);
    textFont(FONT_UI);
    textSize(7);
    fill(PAL.RUST);
    text('ENEMY ABILITY:', px + 14, abY + 5);
    textFont(FONT_BODY);
    textSize(9);
    fill(PAL.PARCHMENT);
    const abText = combatState.enemy.abilityDesc;
    const maxW = pw - 40;
    const words = abText.split(' ');
    let line = '';
    let lines = [];
    for (const w of words) {
      if (textWidth(line + ' ' + w) > maxW && line) {
        lines.push(line);
        line = w;
      } else {
        line = line ? line + ' ' + w : w;
      }
    }
    if (line) lines.push(line);
    lines.forEach((l, i) => {
      text(l, px + 14, abY + 14 + i * 10);
    });
  }

  pop();
}

// ─────────────────────────────────────────────
// COMBAT TURN LOG
// ─────────────────────────────────────────────

/**
 * Draw the combat turn log — right-side panel, scrollable last-N entries.
 */
function drawCombatLog(lx, ly, lw, lh) {
  push();
  fill(PAL.NAVY);
  noStroke();
  rect(lx, ly, lw, lh);
  drawPixelBorder(lx, ly, lw, lh, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('COMBAT LOG', lx + 12, ly + 10, PAL.TEAL, 9);

  // Divider line
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(lx + 12, ly + 24, lx + lw - 12, ly + 24);

  // Entries
  textFont(FONT_BODY);
  textSize(12);
  const log = window.UI.combatLog;
  const entryH = 16;
  const maxEntries = Math.floor((lh - 40) / entryH);
  const start = Math.max(0, log.length - maxEntries);
  for (let i = start; i < log.length; i++) {
    const eY = ly + 32 + (i - start) * entryH;
    const entry = log[i];
    // Timestamp / turn number — dim
    fill(PAL.DIM);
    noStroke();
    text('[' + i +']', lx + 12, eY);
    // Message — parchment with teal glow on key words
    const msgX = lx + 36;
    // Color-code by content
    if (entry.includes('FAIL') || entry.includes('miss')) {
      drawGlowText(entry, msgX, eY, PAL.RED, 12);
    } else if (entry.includes('PARTIAL') || entry.includes('partial') ||
               entry.includes('cost')) {
      drawGlowText(entry, msgX, eY, PAL.AMBER, 12);
    } else if (entry.includes('SUCCESS') || entry.includes('success') ||
               entry.includes('hit')) {
      drawGlowText(entry, msgX, eY, PAL.GREEN, 12);
    } else {
      drawGlowText(entry, msgX, eY, PAL.PARCHMENT, 12);
    }
  }

  // Footer hint
  textFont(FONT_UI);
  textSize(8);
  fill(PAL.DIM);
  noStroke();
  text('Tab: toggle log', lx + lw - 90, ly + lh - 14);

  pop();
}

// ─────────────────────────────────────────────
// LEGACY COMPATIBILITY DICE DISPLAY (2D6)
// ─────────────────────────────────────────────

/**
 * Legacy compatibility helper only. Production-native player actions do not
 * use PbtA outcome bands. Keep this isolated until all compatibility actions
 * and historical presentation paths are retired.
 * @param {number} result — sum of 2D6 (2..12)
 * @param {string} description — what was rolled (e.g. 'Uncover Truth + Wits')
 * @param {number} cx, cy — center position
 * @param {number} size — die size in pixels
 */
function drawDiceRoll(result, description, cx, cy, size = 64) {
  push();
  translate(cx, cy);

  // Background panel
  const panelW = size * 2 + 40;
  const panelH = size + 90;
  fill(PAL.NAVY);
  noStroke();
  rect(-panelW / 2, -panelH / 2, panelW, panelH);
  drawPixelBorder(-panelW / 2, -panelH / 2, panelW, panelH, 3,
                   PAL.SHADOW, PAL.TEAL);

  // Two dice — left and right
  const dieOff = size / 2 + 6;
  drawDie(size, -dieOff, 0, result >= 6 ? 6 : result - 6);
  drawDie(size, dieOff, 0, result >= 6 ? 6 : result);

  // Result sum — big glow text
  const sumColor = result >= 10 ? PAL.GREEN :
                   result >= 7  ? PAL.AMBER : PAL.RED;
  textFont(FONT_UI);
  textSize(22);
  textAlign(CENTER, CENTER);
  drawGlowTextCenter(String(result), 0, -size / 2 - 16, sumColor, 22);

  // Framing label
  textFont(FONT_UI);
  textSize(9);
  let frame = '';
  let frameColor = PAL.PARCHMENT;
  if (result >= 10) {
    frame = '10+  FULL SUCCESS';
    frameColor = PAL.GREEN;
  } else if (result >= 7) {
    frame = '7-9  PARTIAL — COST';
    frameColor = PAL.AMBER;
  } else {
    frame = '6-  FAILURE — GM MOVE';
    frameColor = PAL.RED;
  }
  drawGlowTextCenter(frame, 0, size / 2 + 10, frameColor, 9);

  // Description
  textFont(FONT_BODY);
  textSize(12);
  fill(PAL.PARCHMENT);
  noStroke();
  textAlign(CENTER, CENTER);
  const descY = size / 2 + 24;
  drawGlowTextCenter(description, 0, descY, PAL.TEAL, 12);

  pop();
}

/**
 * Draw a single D6 die face with pips.
 * @param {number} size — side length in pixels
 * @param {number} dx, dy — position
 * @param {number} value — 1..6
 */
function drawDie(size, dx, dy, value) {
  push();
  translate(dx, dy);

  // Die body — rounded rect with pixel border
  const r = 4; // corner radius
  fill(PAL.WHITE);
  noStroke();
  rect(-size / 2, -size / 2, size, size, r);
  drawPixelBorder(-size / 2, -size / 2, size, size, 2, PAL.SHADOW, PAL.SCIOTO);

  // Pip pattern
  const pipR = size * 0.08;
  const pipColor = PAL.NAVY;
  fill(pipColor);
  noStroke();

  const cx = 0;
  const cy = 0;
  const off = size * 0.28;

  // All 6 patterns
  if (value === 1) {
    ellipse(cx, cy, pipR * 2, pipR * 2);
  } else if (value === 2) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  } else if (value === 3) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx, cy, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  } else if (value === 4) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx - off, cy + off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  } else if (value === 5) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx, cy, pipR * 2, pipR * 2);
    ellipse(cx - off, cy + off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  } else if (value === 6) {
    ellipse(cx - off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy - off, pipR * 2, pipR * 2);
    ellipse(cx - off, cy, pipR * 2, pipR * 2);
    ellipse(cx + off, cy, pipR * 2, pipR * 2);
    ellipse(cx - off, cy + off, pipR * 2, pipR * 2);
    ellipse(cx + off, cy + off, pipR * 2, pipR * 2);
  }

  // Subtle shadow under die
  pop();
}

// ─────────────────────────────────────────────
// MENU SYSTEM
// ─────────────────────────────────────────────

/**
 * Draw a menu popup: title + option list + callback.
 * When menuOpen is true, this draws over the game view.
 * Callback signature: callback(optionIndex) or callback(optionText).
 */
function drawMenu() {
  if (!window.UI.menuOpen) return;

  push();
  const title = window.UI.menuTitle;
  const options = window.UI.menuOptions;
  if (!title || !options || options.length === 0) {
    pop();
    return;
  }

  // Measure (approximate with a dummy text pass)
  textFont(FONT_UI);
  textSize(9);
  textAlign(LEFT, TOP);
  const titleW = textWidth(title) + 24;
  const optionH = 20;
  const padX = 16;
  const padY = 14;
  const headerH = 28;
  const totalW = Math.max(titleW, 220);
  const totalH = headerH + options.length * optionH + padY * 2;

  // Position: center screen
  const mx = (width - totalW) / 2;
  const my = (height - totalH) / 2;

  // Backdrop (dim the game)
  fill(color(PAL.NAVY), 220);
  noStroke();
  rect(0, 0, width, height);

  // Menu panel
  fill(PAL.SHADOW);
  noStroke();
  rect(mx, my, totalW, totalH);
  drawPixelBorder(mx, my, totalW, totalH, 3, PAL.SHADOW, PAL.TEAL);

  // Title bar at top
  noStroke();
  fill(PAL.NAVY);
  rect(mx, my, totalW, headerH);
  // Title glow
  textAlign(CENTER, CENTER);
  textFont(FONT_UI);
  textSize(10);
  drawGlowTextCenter(title.toUpperCase(), mx + totalW / 2, my + headerH / 2,
                      PAL.TEAL, 10);

  // Options
  textFont(FONT_BODY);
  textSize(13);
  textAlign(LEFT, TOP);
  options.forEach((opt, i) => {
    const oy = my + headerH + padY + i * optionH;
    const isSelected = i === 0; // highlight first (or implement selection later)
    // Option row bg
    noStroke();
    if (isSelected) {
      fill(color(PAL.TEAL), 18);
    } else {
      fill(PAL.NAVY);
    }
    rect(mx + padX, oy, totalW - padX * 2, optionH);
    // Pixel border on each option
    drawPixelBorder(mx + padX, oy, totalW - padX * 2, optionH, 1,
                     PAL.SHADOW, isSelected ? PAL.TEAL : PAL.DIM);

    // Option number circle
    noStroke();
    fill(isSelected ? PAL.TEAL : PAL.DIM);
    ellipse(mx + padX + 12, oy + optionH / 2, 10, 10);
    fill(PAL.NAVY);
    textSize(10);
    textAlign(CENTER, CENTER);
    textFont(FONT_UI);
    text(String(i + 1), mx + padX + 12, oy + optionH / 2);

    // Option text with glow
    textFont(FONT_BODY);
    textSize(13);
    textAlign(LEFT, CENTER);
    const txtX = mx + padX + 28;
    if (isSelected) {
      drawGlowText(opt, txtX, oy + 2, PAL.TEAL, 13);
    } else {
      fill(PAL.PARCHMENT);
      noStroke();
      text(opt, txtX, oy + 2);
    }
  });

  // Footer hint
  textFont(FONT_UI);
  textSize(8);
  textAlign(CENTER, CENTER);
  fill(PAL.DIM);
  noStroke();
  text('ENTER to select  ESC to close', mx + totalW / 2, my + totalH - 10);

  pop();
}

/**
 * Open a menu.
 * @param {string} title
 * @param {string[]} options
 * @param {function} callback — called with option text when selected
 */
function openMenu(title, options, callback) {
  window.UI.menuOpen = true;
  window.UI.menuTitle = title;
  window.UI.menuOptions = options;
  window.UI.menuCallback = callback;
}

/**
 * Close the menu.
 */
function closeMenu() {
  window.UI.menuOpen = false;
  window.UI.menuTitle = '';
  window.UI.menuOptions = [];
  window.UI.menuCallback = null;
}

/**
 * Handle menu input — to be called from core.js on keypress.
 * Returns the selected option text, or null.
 */
function handleMenuInput() {
  if (!window.UI.menuOpen) return null;
  // Simple: ENTER selects first option, ESC closes.
  // In core.js, bind these to keys and call selectMenuOption / closeMenu.
  return null;
}

/**
 * Select the currently highlighted menu option (first by default).
 */
function selectMenuOption(index = 0) {
  if (!window.UI.menuOpen) return;
  const options = window.UI.menuOptions;
  if (index < 0 || index >= options.length) return;
  const cb = window.UI.menuCallback;
  if (cb) cb(options[index]);
  closeMenu();
}

// ─────────────────────────────────────────────
// QUEST LOG
// ─────────────────────────────────────────────

/**
 * Draw the quest log panel — left or right side, scrollable.
 */
function drawQuestLog(lx, ly, lw, lh) {
  push();
  fill(PAL.NAVY);
  noStroke();
  rect(lx, ly, lw, lh);
  drawPixelBorder(lx, ly, lw, lh, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('QUEST LOG', lx + 12, ly + 10, PAL.TEAL, 9);

  // Divider
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(lx + 12, ly + 24, lx + lw - 12, ly + 24);

  // Stages / entries
  textFont(FONT_BODY);
  textSize(12);
  const log = window.UI.questLog;
  const entryH = 18;
  const maxEntries = Math.floor((lh - 40) / entryH);
  const start = Math.max(0, log.length - maxEntries);
  for (let i = start; i < log.length; i++) {
    const eY = ly + 32 + (i - start) * entryH;
    const entry = log[i];
    // Numbered
    fill(PAL.TEAL);
    noStroke();
    textSize(10);
    textFont(FONT_UI);
    text('[' + (i + 1) + ']', lx + 14, eY - 1);
    // Message
    textFont(FONT_BODY);
    textSize(12);
    fill(PAL.PARCHMENT);
    noStroke();
    const msgX = lx + 50;
    drawGlowText(entry, msgX, eY, PAL.PARCHMENT, 12);
  }

  // Quest stages summary (hardcoded from SPEC)
  const stagesY = ly + lh - 36;
  textFont(FONT_UI);
  textSize(8);
  fill(PAL.DIM);
  noStroke();
  const stages = [
    'SIGNAL: distress / bounty / dream',
    'CROSSING: Wind Shear / Aether Leak / Sky-Predator',
    'CONTACT: elder / engine spirit / child / salvager',
    'CHOICE: Save / Preserve / Allow Ascent',
    'WAKE: 6 epilogues'
  ];
  stages.forEach((s, i) => {
    const sx = lx + 14 + (i % 2) * (lw / 2);
    const sy = stagesY + Math.floor(i / 2) * 14;
    fill(PAL.DIM);
    noStroke();
    text(s, sx, sy);
  });

  pop();
}

// ─────────────────────────────────────────────
// INVENTORY DISPLAY
// ─────────────────────────────────────────────

/**
 * Draw the inventory panel — grid of item slots.
 */
function drawInventory(ix, iy, iw, ih) {
  push();
  fill(PAL.NAVY);
  noStroke();
  rect(ix, iy, iw, ih);
  drawPixelBorder(ix, iy, iw, ih, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(9);
  drawGlowText('INVENTORY', ix + 12, iy + 10, PAL.TEAL, 9);

  // Divider
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(ix + 12, iy + 24, ix + iw - 12, iy + 24);

  // Items grid
  const slotSize = 48;
  const gap = 6;
  const cols = Math.floor((iw - 24) / (slotSize + gap));
  const items = window.UI.inventory;
  const startX = ix + 12;
  const startY = iy + 34;

  textFont(FONT_BODY);
  textSize(11);

  items.forEach((item, idx) => {
    const col = idx % cols;
    const row = Math.floor(idx / cols);
    const sx = startX + col * (slotSize + gap);
    const sy = startY + row * (slotSize + gap);

    // Slot bg
    noStroke();
    fill(PAL.SHADOW);
    rect(sx, sy, slotSize, slotSize);
    drawPixelBorder(sx, sy, slotSize, slotSize, 1, PAL.SHADOW, PAL.DIM);

    // Item name (truncated)
    fill(PAL.PARCHMENT);
    noStroke();
    textAlign(CENTER, CENTER);
    textFont(FONT_UI);
    textSize(8);
    const name = item.name || item;
    text(name.substring(0, 10), sx + slotSize / 2, sy + slotSize / 2 - 4);
    textFont(FONT_BODY);
    textSize(9);
    fill(PAL.DIM);
    text('x' + (item.qty || 1), sx + slotSize / 2, sy + slotSize / 2 + 10);
  });

  if (items.length === 0) {
    textFont(FONT_BODY);
    textSize(12);
    textAlign(CENTER, CENTER);
    fill(PAL.DIM);
    noStroke();
    text('Empty', ix + iw / 2, iy + ih / 2);
  }

  pop();
}

// ─────────────────────────────────────────────
// NPC DIALOGUE BOX
// ─────────────────────────────────────────────

/**
 * Draw an NPC dialogue box at the bottom of the screen.
 * @param {object} npc — { name, title? }
 * @param {string} text — dialogue text (wraps)
 */
function drawNPCDialogue(npc, text) {
  push();
  window.UI.dialogueOpen = true;
  window.UI.dialogueNPC = npc;
  window.UI.dialogueText = text;

  const bw = Math.min(width * 0.7, 600);
  const bh = 90;
  const bx = (width - bw) / 2;
  const by = height - bh - 20;

  // Backdrop
  fill(color(PAL.NAVY), 200);
  noStroke();
  rect(0, height - bh - 40, width, bh + 40);

  // Box
  fill(PAL.SHADOW);
  noStroke();
  rect(bx, by, bw, bh);
  drawPixelBorder(bx, by, bw, bh, 3, PAL.SHADOW, PAL.TEAL);

  // NPC name header
  textFont(FONT_UI);
  textSize(9);
  textAlign(LEFT, TOP);
  const npcName = npc.name || 'UNKNOWN';
  const npcTitle = npc.title ? ' — ' + npc.title : '';
  drawGlowText(npcName + npcTitle, bx + 12, by + 8, PAL.TEAL, 9);

  // Divider
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(bx + 12, by + 22, bx + bw - 12, by + 22);

  // Dialogue text — wrap manually
  textFont(FONT_BODY);
  textSize(13);
  textAlign(LEFT, TOP);
  textLeading(16);

  const maxTextW = bw - 24;
  const words = text.split(' ');
  let line = '';
  let ly = by + 30;
  let lineCount = 0;
  const maxLines = 3;

  for (let i = 0; i < words.length && lineCount < maxLines; i++) {
    const test = line ? line + ' ' + words[i] : words[i];
    if (textWidth(test) > maxTextW && line) {
      // Draw line
      drawGlowText(line, bx + 12, ly, PAL.PARCHMENT, 13);
      line = words[i];
      ly += 16;
      lineCount++;
    } else {
      line = test;
    }
  }
  // Draw last line
  if (line && lineCount < maxLines) {
    drawGlowText(line, bx + 12, ly, PAL.PARCHMENT, 13);
    lineCount++;
  }

  // Continue prompt
  if (lineCount > 0) {
    textFont(FONT_UI);
    textSize(8);
    textAlign(CENTER, CENTER);
    fill(PAL.DIM);
    noStroke();
    const promptY = by + bh - 12;
    drawGlowTextCenter('[E] continue', bx + bw / 2, promptY,
                        PAL.DIM, 8);
  }

  pop();
}

/**
 * Close dialogue.
 */
function closeDialogue() {
  window.UI.dialogueOpen = false;
  window.UI.dialogueNPC = null;
  window.UI.dialogueText = '';
}

// ─────────────────────────────────────────────
// SHOP INTERFACE (Repair Cafe)
// ─────────────────────────────────────────────

/**
 * Draw the Repair Cafe shop interface.
 * @param {Array} items — [{ name, desc, cost, repair?, buy? }]
 */
function drawShop(items) {
  push();
  window.UI.shopOpen = true;
  window.UI.shopItems = items || [];

  const sw = Math.min(width * 0.75, 640);
  const sh = Math.min(height * 0.7, 420);
  const sx = (width - sw) / 2;
  const sy = (height - sh) / 2;

  // Backdrop
  fill(color(PAL.NAVY), 220);
  noStroke();
  rect(0, 0, width, height);

  // Shop panel
  fill(PAL.SHADOW);
  noStroke();
  rect(sx, sy, sw, sh);
  drawPixelBorder(sx, sy, sw, sh, 3, PAL.SHADOW, PAL.TEAL);

  // Header
  textFont(FONT_UI);
  textSize(10);
  textAlign(CENTER, CENTER);
  drawGlowTextCenter('REPAIR CAFE', sx + sw / 2, sy + 18, PAL.TEAL, 10);

  textFont(FONT_BODY);
  textSize(11);
  fill(PAL.DIM);
  noStroke();
  textAlign(CENTER, CENTER);
  text('— Salvager\'s Row —', sx + sw / 2, sy + 34);

  // Divider
  stroke(PAL.TEAL);
  strokeWeight(1);
  line(sx + 16, sy + 44, sx + sw - 16, sy + 44);

  // Money/resource display
  textFont(FONT_UI);
  textSize(9);
  textAlign(LEFT, TOP);
  const resX = sx + 16;
  const resY = sy + 52;
  drawGlowText('SCRAP: 7', resX, resY, PAL.DUST, 9);
  drawGlowText('AETHER: 4/6', resX + 110, resY, PAL.SCIOTO, 9);
  drawGlowText('CHARGE: 2.0kWh', resX + 230, resY, PAL.BIO, 9);

  // Items grid
  const itemsData = window.UI.shopItems;
  const itemW = 180;
  const itemH = 100;
  const itemGap = 12;
  const cols = Math.floor((sw - 32) / (itemW + itemGap));
  const startX = sx + 16;
  const startY = sy + 74;

  textFont(FONT_BODY);
  textSize(12);

  itemsData.forEach((item, idx) => {
    const col = idx % cols;
    const row = Math.floor(idx / cols);
    const ix = startX + col * (itemW + itemGap);
    const iy = startY + row * (itemH + itemGap);

    // Item card
    fill(PAL.NAVY);
    noStroke();
    rect(ix, iy, itemW, itemH);
    drawPixelBorder(ix, iy, itemW, itemH, 2, PAL.SHADOW, PAL.TEAL);

    // Item icon placeholder — colored square
    noStroke();
    fill(PAL.BIO);
    rect(ix + 10, iy + 10, 30, 30);
    drawPixelBorder(ix + 10, iy + 10, 30, 30, 1, PAL.SHADOW, PAL.TEAL);

    // Item name
    fill(PAL.PARCHMENT);
    noStroke();
    textAlign(LEFT, TOP);
    textFont(FONT_UI);
    textSize(9);
    const name = item.name || 'Unknown';
    drawGlowText(name.substring(0, 20), ix + 48, iy + 10, PAL.TEAL, 9);

    // Description
    textFont(FONT_BODY);
    textSize(11);
    fill(PAL.DIM);
    noStroke();
    const desc = item.desc || '';
    const descLines = desc.split(' ').slice(0, 8).join(' ');
    text(descLines.substring(0, 40), ix + 12, iy + 48);

    // Cost
    textFont(FONT_UI);
    textSize(9);
    textAlign(LEFT, TOP);
    const costStr = item.cost ? `SCRAP ${item.cost}` : '—';
    drawGlowText(costStr, ix + 12, iy + 74, item.cost ? PAL.DUST : PAL.DIM, 9);

    // Action hint
    textFont(FONT_UI);
    textSize(8);
    fill(PAL.DIM);
    noStroke();
    const action = item.repair ? '[R] Repair' :
                  item.buy ? '[B] Buy' : '[X] Back';
    text(action, ix + itemW - 60, iy + itemH - 12);
  });

  // Footer
  textFont(FONT_UI);
  textSize(8);
  textAlign(CENTER, CENTER);
  fill(PAL.DIM);
  noStroke();
  text('M: close shop  ESC: back', sx + sw / 2, sy + sh - 10);

  pop();
}

/**
 * Close shop.
 */
function closeShop() {
  window.UI.shopOpen = false;
  window.UI.shopItems = [];
}

// ─────────────────────────────────────────────
// TURN OVERLAY
// ─────────────────────────────────────────────

/**
 * Draw a turn overlay — full-screen announcement of whose turn it is.
 * @param {string} actor — actor name
 * @param {string} phase — 'INITIATIVE' | 'ACTION' | 'RESOLUTION' | 'END'
 */
function drawTurnOverlay(actor, phase) {
  push();
  window.UI.turnOverlay = true;

  const overlayMsg = phase + ' — ' + actor;

  // Dim backdrop
  fill(color(PAL.NAVY), 200);
  noStroke();
  rect(0, 0, width, height);

  // Central text
  textFont(FONT_UI);
  textSize(14);
  textAlign(CENTER, CENTER);
  let color = PAL.TEAL;
  if (phase === 'END') color = PAL.DIM;
  else if (phase === 'RESOLUTION') color = PAL.SCIOTO;
  drawGlowTextCenter(overlayMsg, width / 2, height / 2, color, 14);

  // Sub-text
  textFont(FONT_BODY);
  textSize(11);
  fill(PAL.PARCHMENT);
  noStroke();
  textAlign(CENTER, CENTER);
  const sub = phase === 'INITIATIVE' ? 'Roll Grace + Wits for turn order' :
              phase === 'ACTION' ? 'Choose action — main or secondary' :
              phase === 'RESOLUTION' ? 'Roll 2D6 + relevant stat' :
              phase === 'END' ? 'Press SPACE for next turn' : '';
  if (sub) {
    drawGlowTextCenter(sub, width / 2, height / 2 + 40, PAL.PARCHMENT, 11);
  }

  pop();
}

/**
 * Clear turn overlay.
 */
function clearTurnOverlay() {
  window.UI.turnOverlay = false;
}

// ─────────────────────────────────────────────
// DRAW HUD (main entry — composites all HUD layers)
// ─────────────────────────────────────────────

/**
 * Main HUD draw — called each frame. Composites background, HUD, day-night, scanlines.
 * @param {object} gameState — { showCharSheet, showCombatLog, showQuestLog, showInventory, showDice, diceResult, diceDesc, showMenu, menuArgs, showDialogue, npc, dialogueText, showShop, shopItems, showTurnOverlay, turnActor, turnPhase }
 */
function drawHUDFrame(gameState) {
  push();
  // Background + grid
  drawBackground();

  const mode = gameState || {};

  // Day-night in corner
  drawDayNightIndicator(width - 56, 44, 28);

  // HUD bar
  if (mode.showHUD !== false) {
    drawHUD(16, 16, 440, 72);
  }

  // Character sheet
  if (mode.showCharSheet) {
    drawCharSheet(16, 100, 440, 360);
  }

  // Combat log
  if (mode.showCombatLog) {
    drawCombatLog(width - 240, 100, 224, 260);
  }

  // Quest log
  if (mode.showQuestLog) {
    drawQuestLog(16, 100, 280, 340);
  }

  // Inventory
  if (mode.showInventory) {
    drawInventory(width - 260, 380, 244, 200);
  }

  // Dice roll
  if (mode.showDice && mode.diceResult != null) {
    drawDiceRoll(mode.diceResult, mode.diceDesc || '',
                 width / 2, height / 2 - 20, 56);
  }

  // Dialogue
  if (mode.showDialogue && mode.npc) {
    drawNPCDialogue(mode.npc, mode.dialogueText || '');
  }

  // Shop
  if (mode.showShop) {
    drawShop(mode.shopItems || [
      { name: 'Resonator Tuning', desc: 'Realign cyan crystal, +1 EMP', cost: 3, repair: true },
      { name: 'Loom Patch Kit', desc: 'Solar tube repair — restore 0.5kWh', cost: 2, repair: true },
      { name: 'Mycelial Ink', desc: 'Tattoo refresh — +1 Presence temp', cost: 4, buy: true },
      { name: 'Goggle Lens', desc: 'Green filter — +1 Wits in aether', cost: 5, buy: true },
    ]);
  }

  // Menu
  if (mode.showMenu) {
    // Re-open menu if not already open (compatibility)
    if (!window.UI.menuOpen && mode.menuArgs) {
      const ma = mode.menuArgs;
      openMenu(ma.title || 'MENU', ma.options || [], ma.callback || null);
    }
    drawMenu();
  }

  // Turn overlay
  if (mode.showTurnOverlay) {
    drawTurnOverlay(mode.turnActor || 'ENDER',
                     mode.turnPhase || 'ACTION');
  }

  // Particles
  if (VIS.particles) {
    updateParticles();
    drawParticles();
  }

  // Screen flash
  drawScreenFlash();

  // Scanlines on top of everything
  drawScanlines();

  pop();
}

// ─────────────────────────────────────────────
// MODULE INIT
// ─────────────────────────────────────────────
console.log('[UI] Aetherwake UI module loaded —',
            Object.keys(window.UI).join(', '));
