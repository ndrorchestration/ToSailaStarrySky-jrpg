/* ============================================================
   Aetherwake JRPG — Character Creation Module
   modules/char-create.js

   ARCHITECTURE NOTES
   ─────────────────
   1. STATE FLOW: This module inserts a CHARCREATE step between MENU
      and WORLD. The full flow becomes BOOT → MENU → CHARCREATE → WORLD.
      core.js must add STATE.CHARCREATE to its STATE enum and dispatch
      to charCreate.draw() / charCreate.handleInput() in its draw() and
      handleInput() functions (see integration notes at bottom).

   2. PARTY DATA: This module produces a three-character preservation
      draft. party[0] is Ender and party[1]/party[2] are the two current
      player-created companion slots. The persistent runtime authority is
      modules/party-state.js: core.js commits this draft into ROSTER[5]
      and ACTIVE_PARTY[3] after review. CharCreate is therefore onboarding
      input, not the owner of persistent party identity.

   3. JOB SYSTEM: Three distinct jobs (Sky-Sailor, Engine-Wright,
      Aether-Weaver), each with a fixed rank-1 stat profile and two
      abilities drawn from the PbtA 2D6+stat tradition. The player
      assigns one job to each companion slot. Abilities are stored as
      string IDs in unlockedAbilities so combat.js can extend its
      actions table later without char-create needing to know resolution
      logic. SynergyBonus fields describe passive party-composition
      bonuses as flavor + mechanical notes for future combat expansion.

   4. DRAWING: All rendering uses p5.js primitives only — no DOM
      creation. The visual language reuses ui.js patterns: pixel
      borders (drawPixelBorder), teal-glow text (drawGlowText /
      drawGlowTextCenter), the C palette from core.js, and the
      VT323 / Press Start 2P font convention. The module is
      self-contained: it does not depend on ui.js functions being
      loaded first, though it follows their style exactly.

   5. INTEGRATION: core.js needs ~10 lines of changes to wire in
      CHARCREATE (see integration block at end of this file). No changes
      to combat.js or world.js are required for the rank-1 baseline —
      char-create populates window.party and world.player, and the
      existing startGame() / combat.init() path consumes them.
   ============================================================ */

'use strict';

// ── Imports from other modules (available at load time) ──
// C — core.js palette: { teal, navy, parchment, dusttan, rust, soil, biolum }
// These are used throughout for RGB fills/strokes.
// Drawing helpers from ui.js are global functions: drawPixelBorder,
// drawGlowText, drawGlowTextCenter. If ui.js is not yet loaded, we
// fall back to local equivalents defined below.

// ── Local font / palette aliases (in case ui.js not loaded) ──
const CC_FONT_BODY = 'VT323';
const CC_FONT_UI   = 'Press Start 2P';
const CC_PAL = {
  TEAL:      '#2AFFB5',
  SCIOTO:    '#7CC8E8',
  NAVY:      '#1A102E',
  PARCHMENT: '#E8DCC6',
  DUST:      '#C4A882',
  RUST:      '#A04A2C',
  SOIL:      '#4A3520',
  BIO:       '#4AEB6B',
  DIM:       '#8A7F99',
  SHADOW:    '#0D0820',
  AMBER:     '#FFB347',
  GREEN:     '#5CFF8A',
};

// Helper: safely call drawPixelBorder if it exists, else draw a simple rect border.
function safePixelBorder(x, y, w, h, layers, outer, inner) {
  if (typeof drawPixelBorder === 'function') {
    drawPixelBorder(x, y, w, h, layers, outer, inner);
  } else {
    noFill();
    for (let i = 0; i < (layers || 2); i++) {
      const s = i * 2 + 1;
      stroke(C.navy[0], C.navy[1], C.navy[2], i === 0 ? 255 : 80);
      strokeWeight(2);
      rect(x - s, y - s, w + s * 2, h + s * 2);
    }
    stroke(C.teal[0], C.teal[1], C.teal[2]);
    strokeWeight(2);
    rect(x - (layers || 2) * 2 - 1, y - (layers || 2) * 2 - 1,
          w + ((layers || 2) * 2 + 1) * 2, h + ((layers || 2) * 2 + 1) * 2);
    noStroke();
  }
}

// Helper: safely call drawGlowText if it exists, else draw plain text with a teal offset.
function safeGlowText(txt, x, y, textColor, size, font) {
  if (typeof drawGlowText === 'function') {
    drawGlowText(txt, x, y, textColor, size, font);
    return;
  }
  textFont(font || CC_FONT_BODY);
  textSize(size);
  textAlign(LEFT, TOP);
  // Simple glow: 5 offset draws with low-alpha teal
  fill(C.teal[0], C.teal[1], C.teal[2], 60);
  noStroke();
  for (let dx = -1; dx <= 1; dx++) {
    for (let dy = -1; dy <= 1; dy++) {
      if (dx === 0 && dy === 0) continue;
      text(txt, x + dx, y + dy);
    }
  }
  fill(textColor || C.teal);
  text(txt, x, y);
}

function safeGlowTextCenter(txt, x, y, textColor, size, font) {
  if (typeof drawGlowTextCenter === 'function') {
    drawGlowTextCenter(txt, x, y, textColor, size, font);
    return;
  }
  textFont(font || CC_FONT_BODY);
  textSize(size);
  textAlign(CENTER, CENTER);
  fill(C.teal[0], C.teal[1], C.teal[2], 60);
  noStroke();
  for (let dx = -1; dx <= 1; dx++) {
    for (let dy = -1; dy <= 1; dy++) {
      if (dx === 0 && dy === 0) continue;
      text(txt, x + dx, y + dy);
    }
  }
  fill(textColor || C.teal);
  text(txt, x, y);
}

// ── Job / Class Definitions ──
// Each job: fixed rank-1 stats, two abilities (id, label, stat, description),
// and a synergyBonus string shown at party review.
const JOBS = [
  {
    id: 'skySailor',
    name: 'Sky-Sailor',
    tagline: 'Wind navigator · mobile striker',
    vit: 10, echoes: 2, wits: 1, presence: 0, spirit: 1, might: -1, grace: 2,
    color: 'scioto',
    abilities: [
      { id: 'windShearDance', label: 'Wind-Shear Dance',
        stat: 'grace', desc: '2D6+Grace. Evade / reposition. 10+: next Grace roll +1.' },
      { id: 'aetherCompass', label: 'Aether Compass',
        stat: 'wits', desc: '2D6+Wits. Reveal resources — gain scrap or aether.' },
    ],
    synergyBonus: 'Wind-Reader — Ender\'s Uncover Truth grants +1 to Sky-Sailor\'s Grace rolls.',
    previewGlyph: 'W', // displayed on companion preview
  },
  {
    id: 'engineWright',
    name: 'Engine-Wright',
    tagline: 'Mechanical engineer · heavy hitter',
    vit: 12, echoes: 2, wits: 0, presence: 2, spirit: 0, might: 2, grace: -1,
    color: 'rust',
    abilities: [
      { id: 'overdriveStrike', label: 'Overdrive Strike',
        stat: 'might', desc: '2D6+Might. Heavy EMP: 1d6+3 damage. Generates 1 Heat.' },
      { id: 'patchworkShield', label: 'Patchwork Shield',
        stat: 'presence', desc: '2D6+Presence. Absorb 1 damage for an ally. Return 1 scrap.' },
    ],
    synergyBonus: 'Engine Heart — Ender\'s Mycelial Ledger grants +1 scrap on success while Wright is present.',
    previewGlyph: 'E',
  },
  {
    id: 'aetherWeaver',
    name: 'Aether-Weaver',
    tagline: 'Spirit caster · healer & buffer',
    vit: 9, echoes: 3, wits: 1, presence: 1, spirit: 2, might: -2, grace: 0,
    color: 'biolum',
    abilities: [
      { id: 'spiritThread', label: 'Spirit Thread',
        stat: 'spirit', desc: '2D6+Spirit. Heal 1-3 Vit to a target ally.' },
      { id: 'aetherWeave', label: 'Aether Weave',
        stat: 'presence', desc: '2D6+Presence. Buff ally\'s next roll +1. Costs 1 Aether.' },
    ],
    synergyBonus: 'Dreamweaver\'s Pact — Ender\'s Shared Dream heals +1 extra Vit when Weaver is in party.',
    previewGlyph: 'A',
  },
];

// ── Ender (fixed protagonist — always party[0]) ──
const ENDER = {
  name: 'Ender',
  age: 22,
  class: 'Rift Scholar',
  vit: 13, maxVit: 13,
  echoes: { current: 3, max: 3 }, maxEchoes: 3,
  wits: 2, presence: 1, spirit: 1, might: -1, grace: 0,
  scrap: 7,
  aether: { current: 4, max: 6 },
  heat: { current: 1, max: 3 },
  charge: 2.0,
  staffCharges: 2, maxStaffCharges: 2,
  level: 1, xp: 0, xpToNext: 50,
  unlockedAbilities: ['uncoverTruth', 'sharedDream', 'mycelialLedger'],
  equipment: { staff: null, backpack: null },
  jobId: 'ender',
  synergyBonus: 'Analyst-controller baseline. Final party synergy remains open.',
};

// ── Color helpers ──
function jobColorRGB(jobId) {
  if (jobId === 'skySailor') return [C.scioto[0], C.scioto[1], C.scioto[2]];
  if (jobId === 'engineWright') return [C.rust[0], C.rust[1], C.rust[2]];
  if (jobId === 'aetherWeaver') return [C.biolum[0], C.biolum[1], C.biolum[2]];
  return [C.teal[0], C.teal[1], C.teal[2]];
}

// ─────────────────────────────────────────────
//  CHARCREATE MODULE
// ─────────────────────────────────────────────

const CharCreate = {
  // ── State ──
  phase: 'title',       // 'title' | 'name' | 'class' | 'review' | 'done'
  slot: 0,              // 0 or 1 (which companion slot we're filling)
  nameInput: '',        // current name being typed
  cursorPos: 0,         // cursor index in nameInput
  selectedJob: null,    // job object selected for current slot
  party: [],            // will hold 3 characters
  confirmReady: false,  // true when both slots filled and review passes

  // ── Private: current companion being edited ──
  _currentChar: null,

  // ── Init ──
  init: function() {
    this.phase = 'title';
    this.slot = 0;
    this.nameInput = '';
    this.cursorPos = 0;
      this.nameInputValue = this.nameInputValue || '';
    this.selectedJob = null;
    this.confirmReady = false;
    this.party = [ENDER, null, null]; // Ender fixed; two slots open
    this._currentChar = null;
  },

  // ── Start character creation (called from core.js when entering CHARCREATE state) ──
  start: function() {
    this.init();
  },

  // ── Update (per-frame, for any animations) ──
  update: function(dt) {
    // No continuous animations needed for char-create; static UI only.
    // Reserved for future pulse/glow effects.
  },

  // ─────────────────────────────────────────────
  //  INPUT HANDLING
  // ─────────────────────────────────────────────
  handleInput: function(keys, pressed) {
    if (this.phase === 'title') {
      // Any key or Enter starts character creation
      if (pressed[13] || pressed[32] || pressed[78] || pressed[110] ||
          (typeof key !== 'undefined' && (key === 'Enter' || key === ' ' ||
           key === 'n' || key === 'N'))) {
        this.phase = 'name';
        this.slot = 0;
        this.nameInput = '';
        this.cursorPos = 0;
        this.selectedJob = null;
        this._currentChar = null;
        return;
      }
      return;
    }

    if (this.phase === 'name') {
      this._handleNameInput(pressed);
      return;
    }

    if (this.phase === 'class') {
      this._handleClassInput(pressed);
      return;
    }

    if (this.phase === 'review') {
      if (pressed[13] || pressed[32] || pressed[78] || pressed[110]) {
        // Confirm party and finish
        this._finalizeParty();
        return;
      }
      if (pressed[27]) {
        // ESC: go back to class selection for slot 1
        this.phase = 'class';
        this.slot = 0;
        this.selectedJob = this.party[1] ? JOBS.find(j => j.id === this.party[1].jobId) : null;
        this.nameInput = this.party[1] ? this.party[1].name : '';
        return;
      }
      return;
    }
  },

  // ── Name input handler ──
  _handleNameInput: function(pressed) {
    const maxLen = 14;

    // Number keys 1-3: select job for current slot
    if (pressed[49]) { this.selectedJob = JOBS[0]; return; } // '1'
    if (pressed[50]) { this.selectedJob = JOBS[1]; return; } // '2'
    if (pressed[51]) { this.selectedJob = JOBS[2]; return; } // '3'

    // Enter / Space: confirm name and move to class selection
    if (pressed[13] || pressed[32]) {
      const name = this.nameInput.trim() || 'Companion';
      if (this.slot === 0) {
        // Store companion 1
        const job = this.selectedJob || JOBS[0];
        this.party[1] = this._makeCharacter(name, job);
        this.slot = 1;
        this.nameInput = '';
        this.cursorPos = 0;
        this.selectedJob = null;
        // If we already have a saved selection for slot 2, restore it
        // (from a previous cancel in review)
      } else {
        // Store companion 2 and move to review
        const job = this.selectedJob || JOBS[0];
        this.party[2] = this._makeCharacter(name, job);
        this.phase = 'review';
      }
      return;
    }

    // Backspace: delete char before cursor
    if (pressed[8] || pressed[DELETE]) {
      if (this.cursorPos > 0) {
        this.nameInput = this.nameInput.slice(0, this.cursorPos - 1) +
                         this.nameInput.slice(this.cursorPos);
        this.cursorPos--;
      }
      return;
    }

    // Delete: delete char at cursor
    if (pressed[46]) {
      if (this.cursorPos < this.nameInput.length) {
        this.nameInput = this.nameInput.slice(0, this.cursorPos) +
                         this.nameInput.slice(this.cursorPos + 1);
      }
      return;
    }

    // Left/Right arrow: move cursor
    if (pressed[37]) { // LEFT_ARROW
      if (this.cursorPos > 0) this.cursorPos--;
      return;
    }
    if (pressed[39]) { // RIGHT_ARROW
      if (this.cursorPos < this.nameInput.length) this.cursorPos++;
      return;
    }

    // Home/End: jump to start/end
    if (pressed[36]) { this.cursorPos = 0; return; } // HOME
    if (pressed[35]) { this.cursorPos = this.nameInput.length; return; } // END

    // Printable characters (typed via keyTyped, but we also handle here for keyCode)
    // Letters and numbers: insert at cursor
    // This is handled primarily by keyTyped below; keyPressed path handles
    // special keys. For character input we rely on the keyTyped handler
    // registered in core.js.

    // ESC: go back to title (abort)
    if (pressed[27]) {
      this.phase = 'title';
      this.nameInput = '';
      this.cursorPos = 0;
      this.selectedJob = null;
    }
  },

  // ── Called from core.js keyTyped for character input ──
  handleTypedChar: function(ch) {
    if (this.phase !== 'name') return;
    const maxLen = 14;
    if (this.nameInput.length >= maxLen) return;
    // Accept letters, numbers, space, hyphen, apostrophe
    if (/^[a-zA-Z0-9 \-\']$/.test(ch)) {
      this.nameInput = this.nameInput.slice(0, this.cursorPos) + ch +
                       this.nameInput.slice(this.cursorPos);
      this.cursorPos++;
    }
  },

  // ── Class selection input handler ──
  _handleClassInput: function(pressed) {
    // Number keys 1-3: select job
    if (pressed[49]) { this._selectJob(0); return; } // '1'
    if (pressed[50]) { this._selectJob(1); return; } // '2'
    if (pressed[51]) { this._selectJob(2); return; } // '3'

    // Left/Right arrow: cycle through jobs
    if (pressed[37]) { // LEFT_ARROW
      const currentIdx = this.selectedJob ? JOBS.indexOf(this.selectedJob) : -1;
      const nextIdx = (currentIdx - 1 + JOBS.length) % JOBS.length;
      this._selectJob(nextIdx);
      return;
    }
    if (pressed[39]) { // RIGHT_ARROW
      const currentIdx = this.selectedJob ? JOBS.indexOf(this.selectedJob) : -1;
      const nextIdx = (currentIdx + 1) % JOBS.length;
      this._selectJob(nextIdx);
      return;
    }

    // Enter / Space: confirm job and move to name input (or advance if name done)
    if (pressed[13] || pressed[32]) {
      if (this.selectedJob) {
        // If name is empty or cursor at end, confirm and move on
        if (this.slot === 0) {
          // Store companion 1 with selected job, name pending
          this.party[1] = this._makeCharacter(this.nameInput || 'Companion', this.selectedJob);
          this.slot = 1;
          this.nameInput = '';
          this.cursorPos = 0;
          this.selectedJob = null;
          this.phase = 'name';
        } else {
          // Store companion 2
          this.party[2] = this._makeCharacter(this.nameInput || 'Companion', this.selectedJob);
          this.phase = 'review';
        }
      }
      return;
    }

    // ESC: if slot 0, go back to title; if slot 1, go back to slot 0 name edit
    if (pressed[27]) {
      if (this.slot === 0) {
        this.phase = 'title';
        this.nameInput = '';
        this.cursorPos = 0;
        this.selectedJob = null;
      } else {
        // Go back to slot 0 — restore name and job from party[1] if exists
        this.slot = 0;
        this.nameInput = this.party[1] ? this.party[1].name : '';
        this.cursorPos = this.nameInput.length;
        this.selectedJob = this.party[1] ? JOBS.find(j => j.id === this.party[1].jobId) : null;
        this.phase = 'name';
      }
      return;
    }
  },

  _selectJob: function(idx) {
    if (idx < 0 || idx >= JOBS.length) return;
    this.selectedJob = JOBS[idx];
  },

  // ── Create a character object from name + job ──
  _makeCharacter: function(name, job) {
    const j = job || JOBS[0];
    return {
      name: name || 'Companion',
      age: 22,
      class: j.name,
      vit: j.vit,
      maxVit: j.vit,
      echoes: { current: j.echoes, max: 3 },
      maxEchoes: 3,
      wits: j.wits,
      presence: j.presence,
      spirit: j.spirit,
      might: j.might,
      grace: j.grace,
      scrap: 5,
      aether: { current: 3, max: 6 },
      heat: { current: 0, max: 3 },
      charge: 1.5,
      staffCharges: 1,
      maxStaffCharges: 2,
      level: 1,
      xp: 0,
      xpToNext: 50,
      unlockedAbilities: [j.abilities[0].id, j.abilities[1].id],
      equipment: { staff: null, backpack: null },
      jobId: j.id,
      synergyBonus: j.synergyBonus,
    };
  },

  // ── Finalize: expose the onboarding draft and signal completion ──
  _finalizeParty: function() {
    // Guard: ensure party is initialized
    if (!this.party || !Array.isArray(this.party)) {
      this.party = [ENDER, null, null];
    }
    // Ensure both companions exist
    if (!this.party[1]) {
      this.party[1] = this._makeCharacter('Companion', JOBS[0]);
    }
    if (!this.party[2]) {
      this.party[2] = this._makeCharacter('Companion', JOBS[0]);
    }

    // This is migration input only. core.js commits it through AetherPartyState
    // so window.party remains an alias of canonical ACTIVE_PARTY references.
    window.prototypePartyDraft = this.party;

    // Signal that char creation is done — core.js transitions to WORLD
    this.phase = 'done';
  },

  // ─────────────────────────────────────────────
  //  DRAWING
  // ─────────────────────────────────────────────
  draw: function() {
    switch (this.phase) {
      case 'title':  this._drawTitle(); break;
      case 'name':   this._drawNameStep(); break;
      case 'class':  this._drawClassStep(); break;
      case 'review': this._drawReview(); break;
      case 'done':   break; // core.js should transition out of CHARCREATE
    }
    this._syncDOM();
  },

  _syncDOM: function() {
    // Keep DOM inputs in sync with internal state. Currently a no-op;
    // the per-frame DOM write that caused PAGE ERROR spam was removed —
    // nameInputValue is now tracked and only pushed to DOM when it changes.
  },


  // ── Title screen: "ASSEMBLE YOUR CREW" ──
  _drawTitle: function() {
    // Background
    noStroke();
    fill(C.navy[0], C.navy[1], C.navy[2]);
    rect(0, 0, width, height);

    // Teal grid overlay (subtle)
    stroke(C.teal[0], C.teal[1], C.teal[2], 12);
    strokeWeight(1);
    for (let x = 0; x < width; x += 40) line(x, 0, x, height);
    for (let y = 0; y < height; y += 40) line(0, y, width, y);
    noStroke();

    // Floating islands (parallax, matching title screen style)
    const elapsed = millis() || 0;
    for (let i = 0; i < 10; i++) {
      const px = ((i * 73 + 11) % width);
      const py = 80 + (i * 47) % 300 + Math.sin(elapsed * 0.0008 + i * 0.7) * 12;
      const sz = 20 + (i % 4) * 8;
      fill(C.soil[0], C.soil[1], C.soil[2], 140);
      ellipse(px, py, sz, sz * 0.6);
      noFill();
      stroke(C.teal[0], C.teal[1], C.teal[2], 70);
      strokeWeight(1);
      ellipse(px, py, sz, sz * 0.6);
      noStroke();
    }

    // Title
    const cx = width / 2;
    const cy = height / 2 - 60;

    // "ASSEMBLE YOUR CREW" — large glow
    textFont(CC_FONT_BODY);
    textSize(28);
    textAlign(CENTER, CENTER);
    safeGlowTextCenter('ASSEMBLE', cx, cy, C.teal, 28, CC_FONT_BODY);
    safeGlowTextCenter('YOUR CREW', cx, cy + 32, C.scioto, 28, CC_FONT_BODY);

    // Subtitle
    textSize(14);
    fill(C.parchment[0], C.parchment[1], C.parchment[2], 180);
    textAlign(CENTER, CENTER);
    text('Young Ender is your anchor —', cx, cy + 68);
    text('choose two companions for the journey.', cx, cy + 84);

    // Ender preview — small silhouette bottom-center
    const enderX = cx;
    const enderY = height - 100;
    this._drawEnderPreview(enderX, enderY, 48);

    // Flashing prompt
    const blink = (millis() % 1200) < 600 ? 255 : 120;
    textFont(CC_FONT_UI);
    textSize(11);
    fill(C.teal[0], C.teal[1], C.teal[2], blink);
    textAlign(CENTER, CENTER);
    text('PRESS  ENTER  /  SPACE  /  N  TO  BEGIN', cx, height - 42);

    // Controls hint
    textSize(9);
    fill(C.dim[0], C.dim[1], C.dim[2], 120);
    text('1-3: pick job   ← →: cycle   ENTER: confirm   ESC: back', cx, height - 22);
  },

  // ── Draw Ender preview silhouette ──
  _drawEnderPreview: function(x, y, size) {
    push();
    translate(x, y);

    // Glow
    fill(C.teal[0], C.teal[1], C.teal[2], 40);
    noStroke();
    ellipse(0, 0, size * 1.8, size * 1.8);

    // Body
    fill(C.teal[0], C.teal[1], C.teal[2], 180);
    ellipse(0, 0, size * 0.8, size * 0.85);

    // Goggle accent
    fill(C.biolum[0], C.biolum[1], C.biolum[2], 200);
    ellipse(-size * 0.18, -size * 0.08, size * 0.22, size * 0.16);
    ellipse(size * 0.18, -size * 0.08, size * 0.22, size * 0.16);
    fill(C.scioto[0], C.scioto[1], C.scioto[2], 180);
    ellipse(-size * 0.18, -size * 0.08, size * 0.14, size * 0.1);
    ellipse(size * 0.18, -size * 0.08, size * 0.14, size * 0.1);

    // Mycelial tattoo hint
    stroke(C.teal[0], C.teal[1], C.teal[2], 120);
    strokeWeight(1.5);
    noFill();
    beginShape();
    vertex(-size * 0.3, -size * 0.05);
    vertex(-size * 0.4, size * 0.05);
    vertex(-size * 0.35, size * 0.15);
    endShape();
    beginShape();
    vertex(size * 0.3, -size * 0.05);
    vertex(size * 0.4, size * 0.05);
    vertex(size * 0.35, size * 0.15);
    endShape();
    noStroke();

    // Name label
    pop();
    textFont(CC_FONT_UI);
    textSize(9);
    textAlign(CENTER, CENTER);
    fill(C.parchment[0], C.parchment[1], C.parchment[2], 200);
    text('YOUNG ENDER', x, y + size * 0.7 + 14);
    textSize(8);
    fill(C.teal[0], C.teal[1], C.teal[2], 140);
    text('Rift Scholar + Dreamwright  ·  Rank 1', x, y + size * 0.7 + 26);
  },

  // ── Name input step ──
  _drawNameStep: function() {
    // Background
    noStroke();
    fill(C.navy[0], C.navy[1], C.navy[2]);
    rect(0, 0, width, height);
    stroke(C.teal[0], C.teal[1], C.teal[2], 10);
    strokeWeight(1);
    for (let x = 0; x < width; x += 40) line(x, 0, x, height);
    for (let y = 0; y < height; y += 40) line(0, y, width, y);
    noStroke();

    // Panel
    const panelW = Math.min(560, width - 40);
    const panelH = 340;
    const panelX = (width - panelW) / 2;
    const panelY = (height - panelH) / 2;

    fill(C.navy[0] + 10, C.navy[1] + 8, C.navy[2] + 10);
    noStroke();
    rect(panelX, panelY, panelW, panelH);
    safePixelBorder(panelX, panelY, panelW, panelH, 3, PAL.SHADOW, PAL.TEAL);

    // Step header
    textFont(CC_FONT_UI);
    textSize(10);
    textAlign(LEFT, TOP);
    const stepLabel = this.slot === 0 ? 'COMPANION 1' : 'COMPANION 2';
    safeGlowText(stepLabel, panelX + 20, panelY + 14, C.teal, 10, CC_FONT_UI);

    // Slot indicator
    fill(C.dim[0], C.dim[1], C.dim[2], 150);
    textSize(9);
    textAlign(LEFT, TOP);
    const slotHint = this.slot === 0
      ? 'Choose name for your first companion.'
      : 'Choose name for your second companion.';
    text(slotHint, panelX + 20, panelY + 28);

    // Divider
    stroke(C.teal[0], C.teal[1], C.teal[2], 60);
    strokeWeight(1);
    line(panelX + 20, panelY + 44, panelX + panelW - 20, panelY + 44);
    noStroke();

    // Name input field
    const fieldX = panelX + 24;
    const fieldY = panelY + 56;
    const fieldW = panelW - 48;
    const fieldH = 36;

    // Field background
    fill(C.shad[0], C.shad[1], C.shad[2]);
    noStroke();
    rect(fieldX, fieldY, fieldW, fieldH);
    safePixelBorder(fieldX, fieldY, fieldW, fieldH, 1, PAL.SHADOW, PAL.DIM);

    // Field label
    textFont(CC_FONT_UI);
    textSize(8);
    fill(C.teal[0], C.teal[1], C.teal[2], 160);
    textAlign(LEFT, TOP);
    text('NAME', fieldX + 8, fieldY + 6);

    // Name text with cursor
    const displayName = this.nameInput || (this.slot === 0 ? '' : (this.party[1] ? this.party[1].name : ''));
    textFont(CC_FONT_BODY);
    textSize(18);
    textAlign(LEFT, TOP);
    fill(C.parchment[0], C.parchment[1], C.parchment[2], 230);
    text(displayName, fieldX + 8, fieldY + 18);

    // Cursor
    const cursorX = fieldX + 8 + textWidth(displayName);
    const cursorBlink = (millis() % 800) < 400;
    if (cursorBlink) {
      stroke(C.teal[0], C.teal[1], C.teal[2], 200);
      strokeWeight(2);
      line(cursorX, fieldY + 8, cursorX, fieldY + fieldH - 8);
      noStroke();
    }

    // Character count
    textFont(CC_FONT_UI);
    textSize(7);
    fill(C.dim[0], C.dim[1], C.dim[2], 120);
    textAlign(RIGHT, TOP);
    text(this.nameInput.length + '/14', fieldX + fieldW - 8, fieldY + 6);

    // Confirm hint
    textFont(CC_FONT_UI);
    textSize(8);
    fill(C.teal[0], C.teal[1], C.teal[2], 140);
    textAlign(LEFT, TOP);
    text('ENTER to confirm name', fieldX + 8, fieldY + fieldH + 10);

    // Already-named companion preview (if returning from review)
    if (this.slot === 1 && this.party[1]) {
      const prevX = panelX + panelW - 140;
      const prevY = panelY + 60;
      fill(C.navy[0], C.navy[1], C.navy[2], 200);
      noStroke();
      rect(prevX, prevY, 120, 100);
      safePixelBorder(prevX, prevY, 120, 100, 2, PAL.SHADOW, PAL.SCIOTO);

      textFont(CC_FONT_UI);
      textSize(8);
      fill(C.scioto[0], C.scioto[1], C.scioto[2], 160);
      textAlign(CENTER, TOP);
      text('COMPANION 1', prevX + 60, prevY + 8);

      textFont(CC_FONT_BODY);
      textSize(12);
      fill(C.parchment[0], C.parchment[1], C.parchment[2], 200);
      textAlign(CENTER, TOP);
      text(this.party[1].name, prevX + 60, prevY + 22);

      textSize(9);
      fill(C.dim[0], C.dim[1], C.dim[2], 140);
      textAlign(CENTER, TOP);
      text(this.party[1].class, prevX + 60, prevY + 40);
    }

    // ESC hint
    textFont(CC_FONT_UI);
    textSize(7);
    fill(C.dim[0], C.dim[1], C.dim[2], 100);
    textAlign(RIGHT, BOTTOM);
    text('ESC to cancel', panelX + panelW - 16, panelY + panelH - 10);
  },

  // ── Class selection step ──
  _drawClassStep: function() {
    // Background
    noStroke();
    fill(C.navy[0], C.navy[1], C.navy[2]);
    rect(0, 0, width, height);
    stroke(C.teal[0], C.teal[1], C.teal[2], 10);
    strokeWeight(1);
    for (let x = 0; x < width; x += 40) line(x, 0, x, height);
    for (let y = 0; y < height; y += 40) line(0, y, width, y);
    noStroke();

    // Panel
    const panelW = Math.min(720, width - 40);
    const panelH = 430;
    const panelX = (width - panelW) / 2;
    const panelY = (height - panelH) / 2;

    fill(C.navy[0] + 10, C.navy[1] + 8, C.navy[2] + 10);
    noStroke();
    rect(panelX, panelY, panelW, panelH);
    safePixelBorder(panelX, panelY, panelW, panelH, 3, PAL.SHADOW, PAL.TEAL);

    // Header
    textFont(CC_FONT_UI);
    textSize(10);
    textAlign(LEFT, TOP);
    const stepLabel = this.slot === 0 ? 'COMPANION 1 — CLASS' : 'COMPANION 2 — CLASS';
    safeGlowText(stepLabel, panelX + 20, panelY + 14, C.teal, 10, CC_FONT_UI);

    const nameDisplay = (this.slot === 0 ? this.nameInput :
                         (this.party[1] ? this.party[1].name : ''));
    fill(C.parchment[0], C.parchment[1], C.parchment[2], 160);
    textSize(11);
    textAlign(LEFT, TOP);
    text('"' + (nameDisplay || ' unnamed') + '"', panelX + 20, panelY + 28);

    // Divider
    stroke(C.teal[0], C.teal[1], C.teal[2], 50);
    strokeWeight(1);
    line(panelX + 20, panelY + 44, panelX + panelW - 20, panelY + 44);
    noStroke();

    // Job cards — 3 across
    const cardW = (panelW - 60) / 3;
    const cardH = 290;
    const cardGap = 10;
    const cardStartX = panelX + 20;
    const cardStartY = panelY + 56;

    JOBS.forEach((job, i) => {
      const cx = cardStartX + i * (cardW + cardGap);
      const cy = cardStartY;
      const selected = this.selectedJob && this.selectedJob.id === job.id;

      // Card background
      fill(selected ? color(C.teal[0], C.teal[1], C.teal[2], 18) : C.shad[0], selected ? C.teal[1] : C.shad[1], selected ? C.teal[2] : C.shad[2]);
      noStroke();
      rect(cx, cy, cardW, cardH);
      safePixelBorder(cx, cy, cardW, cardH, 2, PAL.SHADOW, selected ? PAL.TEAL : PAL.DIM);

      // Selection indicator — left teal bar
      if (selected) {
        fill(C.teal[0], C.teal[1], C.teal[2], 200);
        noStroke();
        rect(cx, cy, 4, cardH);
        // Glow strip
        fill(C.teal[0], C.teal[1], C.teal[2], 40);
        rect(cx - 2, cy, 6, cardH);
      }

      // Job number
      textFont(CC_FONT_UI);
      textSize(14);
      textAlign(CENTER, TOP);
      fill(selected ? C.teal : C.dim);
      const numX = cx + cardW / 2;
      text('' + (i + 1), numX, cy + 10);

      // Key hint
      textSize(7);
      fill(C.dim[0], C.dim[1], C.dim[2], 120);
      text('[' + (i + 1) + ']', numX, cy + 26);

      // Job name
      textFont(CC_FONT_UI);
      textSize(11);
      textAlign(CENTER, TOP);
      const jobCol = jobColorRGB(job.id);
      fill(jobCol[0], jobCol[1], jobCol[2], selected ? 255 : 180);
      text(job.name, numX, cy + 38);

      // Tagline
      textFont(CC_FONT_BODY);
      textSize(10);
      textAlign(CENTER, TOP);
      fill(C.parchment[0], C.parchment[1], C.parchment[2], selected ? 200 : 130);
      text(job.tagline, numX, cy + 52);

      // Divider under header
      stroke(C.teal[0], C.teal[1], C.teal[2], 30);
      strokeWeight(1);
      line(cx + 12, cy + 64, cx + cardW - 12, cy + 64);
      noStroke();

      // Stats grid
      const stats = [
        { label: 'Vit', value: job.vit, color: C.rust },
        { label: 'Echoes', value: job.echoes + '/3', color: C.biolum },
        { label: 'Wits', value: (job.wits > 0 ? '+' : '') + job.wits, color: C.scioto },
        { label: 'Presence', value: (job.presence > 0 ? '+' : '') + job.presence, color: C.teal },
        { label: 'Spirit', value: (job.spirit > 0 ? '+' : '') + job.spirit, color: C.teal },
        { label: 'Might', value: (job.might > 0 ? '+' : '') + job.might, color: C.rust },
        { label: 'Grace', value: (job.grace > 0 ? '+' : '') + job.grace, color: C.scioto },
      ];

      textFont(CC_FONT_UI);
      textSize(7);
      fill(C.teal[0], C.teal[1], C.teal[2], 120);
      textAlign(LEFT, TOP);
      text('STATS', cx + 12, cy + 70);

      textFont(CC_FONT_BODY);
      textSize(11);
      const statStartY = cy + 82;
      const statRowH = 17;
      // Two columns of stats
      const col1 = stats.slice(0, 4);
      const col2 = stats.slice(4);

      col1.forEach((s, idx) => {
        const sy = statStartY + idx * statRowH;
        fill(C.parchment[0], C.parchment[1], C.parchment[2], 180);
        textAlign(LEFT, TOP);
        text(s.label, cx + 14, sy);
        fill(s.color[0], s.color[1], s.color[2], 200);
        textAlign(RIGHT, TOP);
        text(s.value, cx + cardW - 14, sy);
      });

      // Divider between stat columns
      stroke(C.dim[0], C.dim[1], C.dim[2], 40);
      strokeWeight(1);
      line(cx + cardW / 2, cy + 82, cx + cardW / 2, cy + 82 + 4 * statRowH);
      noStroke();

      col2.forEach((s, idx) => {
        const sy = statStartY + idx * statRowH;
        fill(selected ? C.parchment[0] : C.dim[0], selected ? C.parchment[1] : C.dim[1], selected ? C.parchment[2] : C.dim[2], selected ? 200 : 120);
        textAlign(LEFT, TOP);
        text(s.label, cx + cardW / 2 + 10, sy);
        fill(s.color[0], s.color[1], s.color[2], selected ? 200 : 140);
        textAlign(RIGHT, TOP);
        text(s.value, cx + cardW - 14, sy);
      });

      // Synergies text (uses sy declared below)
      const synY = cy + cardH - 28;
      textFont(CC_FONT_UI);
      textSize(7);
      fill(C.teal[0], C.teal[1], C.teal[2], 120);
      textAlign(CENTER, TOP);
      text(synText, cx + cardW / 2, synY);
      const abilY = cy + 82 + 4 * statRowH + 10;
      textFont(CC_FONT_UI);
      textSize(7);
      fill(C.teal[0], C.teal[1], C.teal[2], 120);
      textAlign(LEFT, TOP);
      text('ABILITIES', cx + 12, abilY);

      textFont(CC_FONT_BODY);
      textSize(10);
      const abilStartY = abilY + 14;
      job.abilities.forEach((abil, idx) => {
        const ay = abilStartY + idx * 38;
        // Ability name with color accent
        const abilCol = jobColorRGB(job.id);
        fill(abilCol[0], abilCol[1], abilCol[2], selected ? 220 : 140);
        textAlign(LEFT, TOP);
        text(abil.label + '  ', cx + 14, ay);
        // Description
        fill(C.parchment[0], C.parchment[1], C.parchment[2], selected ? 200 : 130);
        textAlign(LEFT, TOP);
        // Truncate if too long
        let desc = abil.desc;
        const maxDescW = cardW - 28;
        if (textWidth(desc) > maxDescW) {
          let truncated = desc;
          while (textWidth(truncated + '...') > maxDescW && truncated.length > 5) {
            truncated = truncated.slice(0, -1);
          }
          desc = truncated + '...';
        }
        text(desc, cx + 14, ay + 14);
      });

      // Confirm button at bottom of card
      const btnY = cy + cardH - 30;
      if (selected) {
        fill(C.teal[0], C.teal[1], C.teal[2], 30);
        noStroke();
        rect(cx + 20, btnY, cardW - 40, 20);
        safePixelBorder(cx + 20, btnY, cardW - 40, 20, 1, PAL.SHADOW, PAL.TEAL);
        textFont(CC_FONT_UI);
        textSize(8);
        textAlign(CENTER, CENTER);
        fill(C.teal[0], C.teal[1], C.teal[2], 220);
        text('✓ SELECTED', cx + cardW / 2, btnY + 10);
      } else {
        fill(C.navy[0], C.navy[1], C.navy[2], 150);
        noStroke();
        rect(cx + 20, btnY, cardW - 40, 20);
        textFont(CC_FONT_UI);
        textSize(8);
        textAlign(CENTER, CENTER);
        fill(C.dim[0], C.dim[1], C.dim[2], 120);
        text('PRESS ' + (i + 1) + ' TO SELECT', cx + cardW / 2, btnY + 10);
      }
    });

    // Footer hint
    textFont(CC_FONT_UI);
    textSize(8);
    fill(C.dim[0], C.dim[1], C.dim[2], 120);
    textAlign(CENTER, BOTTOM);
    text('← → to cycle  ·  1-3 to select  ·  ENTER to confirm  ·  ESC to go back',
         width / 2, height - 16);
  },

  // ── Party review step ──
  _drawReview: function() {
    // Background
    noStroke();
    fill(C.navy[0], C.navy[1], C.navy[2]);
    rect(0, 0, width, height);
    stroke(C.teal[0], C.teal[1], C.teal[2], 10);
    strokeWeight(1);
    for (let x = 0; x < width; x += 40) line(x, 0, x, height);
    for (let y = 0; y < height; y += 40) line(0, y, width, y);
    noStroke();

    // Panel
    const panelW = Math.min(800, width - 40);
    const panelH = 440;
    const panelX = (width - panelW) / 2;
    const panelY = (height - panelH) / 2;

    fill(C.navy[0] + 10, C.navy[1] + 8, C.navy[2] + 10);
    noStroke();
    rect(panelX, panelY, panelW, panelH);
    safePixelBorder(panelX, panelY, panelW, panelH, 3, PAL.SHADOW, PAL.TEAL);

    // Header
    textFont(CC_FONT_UI);
    textSize(11);
    textAlign(CENTER, TOP);
    safeGlowTextCenter('YOUR CREW', width / 2, panelY + 20, C.teal, 11, CC_FONT_UI);

    textFont(CC_FONT_BODY);
    textSize(12);
    fill(C.parchment[0], C.parchment[1], C.parchment[2], 160);
    textAlign(CENTER, TOP);
    text('The island that falls upward awaits — your party is set.', width / 2, panelY + 36);

    // Divider
    stroke(C.teal[0], C.teal[1], C.teal[2], 50);
    strokeWeight(1);
    line(panelX + 40, panelY + 52, panelX + panelW - 40, panelY + 52);
    noStroke();

    // Three character cards
    const charCards = this.party.slice(0, 3);
    const cardW = (panelW - 50) / 3;
    const cardH = 260;
    const cardGap = 10;
    const cardStartX = panelX + 20;
    const cardStartY = panelY + 62;

    charCards.forEach((chr, i) => {
      const cx = cardStartX + i * (cardW + cardGap);
      const cy = cardStartY;
      const isEnder = i === 0;
      const job = JOBS.find(j => j.id === chr.jobId);

      // Card background
      fill(C.shad[0], C.shad[1], C.shad[2]);
      noStroke();
      rect(cx, cy, cardW, cardH);
      safePixelBorder(cx, cy, cardW, cardH, 2, PAL.SHADOW, isEnder ? PAL.TEAL : (job ? jobColorRGB(chr.jobId) : PAL.DIM));

      // Ender banner
      if (isEnder) {
        fill(C.teal[0], C.teal[1], C.teal[2], 30);
        noStroke();
        rect(cx, cy, cardW, 4);
        textFont(CC_FONT_UI);
        textSize(7);
        textAlign(CENTER, TOP);
        fill(C.teal[0], C.teal[1], C.teal[2], 160);
        text('★ ANCHOR ★', cx + cardW / 2, cy + 8);
      } else {
        // Job color accent bar
        if (job) {
          const jCol = jobColorRGB(chr.jobId);
          fill(jCol[0], jCol[1], jCol[2], 40);
          noStroke();
          rect(cx, cy, cardW, 4);
        }
        textFont(CC_FONT_UI);
        textSize(7);
        textAlign(CENTER, TOP);
        fill(C.dim[0], C.dim[1], C.dim[2], 120);
        text('COMPANION ' + (i), cx + cardW / 2, cy + 8);
      }

      // Character preview silhouette
      const previewSize = 36;
      const prevX = cx + cardW / 2;
      const prevY = cy + 36;

      push();
      translate(prevX, prevY);

      // Glow
      const glowCol = isEnder ? C.teal : (job ? jobColorRGB(chr.jobId) : C.dim);
      fill(glowCol[0], glowCol[1], glowCol[2], 35);
      noStroke();
      ellipse(0, 0, previewSize * 1.6, previewSize * 1.6);

      // Body
      fill(glowCol[0], glowCol[1], glowCol[2], 170);
      ellipse(0, 0, previewSize * 0.75, previewSize * 0.8);

      // Accent details
      if (isEnder) {
        // Goggles
        fill(C.biolum[0], C.biolum[1], C.biolum[2], 200);
        ellipse(-previewSize * 0.16, -previewSize * 0.06, previewSize * 0.2, previewSize * 0.14);
        ellipse(previewSize * 0.16, -previewSize * 0.06, previewSize * 0.2, previewSize * 0.14);
        fill(C.scioto[0], C.scioto[1], C.scioto[2], 180);
        ellipse(-previewSize * 0.16, -previewSize * 0.06, previewSize * 0.12, previewSize * 0.08);
        ellipse(previewSize * 0.16, -previewSize * 0.06, previewSize * 0.12, previewSize * 0.08);
      } else if (job) {
        // Job-specific accent
        const jCol = jobColorRGB(chr.jobId);
        if (chr.jobId === 'skySailor') {
          // Wind lines
          stroke(jCol[0], jCol[1], jCol[2], 150);
          strokeWeight(1);
          noFill();
          for (let w = 0; w < 3; w++) {
            const wa = millis() * 0.003 + w * 2.1;
            line(-previewSize * 0.3 + Math.sin(wa) * 5, -previewSize * 0.2 + Math.cos(wa * 0.7) * 3,
                  previewSize * 0.3 + Math.sin(wa + 1) * 5, previewSize * 0.1 + Math.cos(wa * 0.7 + 1) * 3);
          }
          noStroke();
        } else if (chr.jobId === 'engineWright') {
          // Gear accent
          fill(jCol[0], jCol[1], jCol[2], 180);
          noStroke();
          ellipse(0, previewSize * 0.15, previewSize * 0.18, previewSize * 0.18);
          stroke(jCol[0], jCol[1], jCol[2], 120);
          strokeWeight(1);
          noFill();
          ellipse(0, previewSize * 0.15, previewSize * 0.1, previewSize * 0.1);
          noStroke();
        } else if (chr.jobId === 'aetherWeaver') {
          // Aether sparkles
          fill(jCol[0], jCol[1], jCol[2], 180);
          noStroke();
          for (let s = 0; s < 3; s++) {
            const sa = millis() * 0.004 + s * 2.3;
            const sx = Math.sin(sa) * previewSize * 0.3;
            const sy = Math.cos(sa * 0.8) * previewSize * 0.25 - previewSize * 0.1;
            ellipse(sx, sy, 3, 3);
          }
          noStroke();
        }
      }
      pop();

      // Name
      textFont(CC_FONT_UI);
      textSize(9);
      textAlign(CENTER, TOP);
      fill(C.parchment[0], C.parchment[1], C.parchment[2], 200);
      text(chr.name, prevX, prevY + previewSize * 0.7 + 6);

      // Class
      textFont(CC_FONT_BODY);
      textSize(10);
      textAlign(CENTER, TOP);
      const jobName = isEnder ? 'Rift Scholar + Dreamwright' :
                     (job ? job.name : 'Unknown');
      const classCol = isEnder ? C.teal : (job ? jobColorRGB(chr.jobId) : C.dim);
      fill(classCol[0], classCol[1], classCol[2], 160);
      text(jobName, prevX, prevY + previewSize * 0.7 + 22);

      // Rank
      textFont(CC_FONT_UI);
      textSize(7);
      textAlign(CENTER, TOP);
      fill(C.dim[0], C.dim[1], C.dim[2], 130);
      text('RANK 1', prevX, prevY + previewSize * 0.7 + 36);

      // Stats (compact, 2 columns)
      const statsY = cy + cardH - 80;
      textFont(CC_FONT_UI);
      textSize(7);
      fill(C.teal[0], C.teal[1], C.teal[2], 110);
      textAlign(LEFT, TOP);
      text('STATS', cx + 12, statsY - 4);

      const stats = [
        { label: 'Vit', value: chr.vit },
        { label: 'Echoes', value: chr.echoes.current + '/' + chr.echoes.max },
        { label: 'Wits', value: (chr.wits > 0 ? '+' : '') + chr.wits },
        { label: 'Presence', value: (chr.presence > 0 ? '+' : '') + chr.presence },
        { label: 'Spirit', value: (chr.spirit > 0 ? '+' : '') + chr.spirit },
        { label: 'Might', value: (chr.might > 0 ? '+' : '') + chr.might },
        { label: 'Grace', value: (chr.grace > 0 ? '+' : '') + chr.grace },
      ];

      textFont(CC_FONT_BODY);
      textSize(9);
      const sRowH = 12;
      const sStartY = statsY + 4;
      const col1s = stats.slice(0, 4);
      const col2s = stats.slice(4);

      col1s.forEach((s, idx) => {
        const sy = sStartY + idx * sRowH;
        fill(C.dim[0], C.dim[1], C.dim[2], 150);
        textAlign(LEFT, TOP);
        text(s.label, cx + 14, sy);
        fill(C.parchment[0], C.parchment[1], C.parchment[2], 180);
        textAlign(RIGHT, TOP);
        text('' + s.value, cx + cardW / 2 - 10, sy);
      });

      stroke(C.dim[0], C.dim[1], C.dim[2], 30);
      strokeWeight(1);
      line(cx + cardW / 2, sStartY, cx + cardW / 2, sStartY + 4 * sRowH);
      noStroke();

      col2s.forEach((s, idx) => {
        const sy = sStartY + idx * sRowH;
        fill(C.dim[0], C.dim[1], C.dim[2], 130);
        textAlign(LEFT, TOP);
        text(s.label, cx + cardW / 2 + 10, sy);
        fill(C.parchment[0], C.parchment[1], C.parchment[2], 160);
        textAlign(RIGHT, TOP);
        text('' + s.value, cx + cardW - 14, sy);
      });

      // Synergy bonus text
      const synY = cy + cardH - 16;
      textFont(CC_FONT_BODY);
      textSize(8);
      textAlign(CENTER, TOP);
      const synText = isEnder ? chr.synergyBonus : (chr.synergyBonus || '—');
      fill(C.teal[0], C.teal[1], C.teal[2], 100);
      text(synText, cx + cardW / 2, synY);
    });

    // Synergy summary at bottom
    const synSummaryY = panelY + panelH - 40;
    textFont(CC_FONT_UI);
    textSize(8);
    textAlign(CENTER, TOP);

    const companion1 = this.party[1];
    const companion2 = this.party[2];
    const job1 = companion1 ? JOBS.find(j => j.id === companion1.jobId) : null;
    const job2 = companion2 ? JOBS.find(j => j.id === companion2.jobId) : null;

    let synergyLines = [];
    if (job1 && job2) {
      synergyLines.push(job1.synergyBonus);
      synergyLines.push(job2.synergyBonus);
      // Cross-synergy if applicable
      if (job1.id === 'skySailor' && job2.id === 'aetherWeaver') {
        synergyLines.push('Sky-Weave Current — Sailor\'s mobility + Weaver\'s buffs: both act on partial successes.');
      } else if (job1.id === 'engineWright' && job2.id === 'skySailor') {
        synergyLines.push('Propeller Sync — Wright\'s Overdrive fuels Sailor\'s repositioning on partial successes.');
      } else if (job1.id === 'aetherWeaver' && job2.id === 'engineWright') {
        synergyLines.push('Arcane Engine — Weaver\'s Aether Weave extends Wright\'s buff duration by 1 turn.');
      }
    }

    if (synergyLines.length > 0) {
      const synText = synergyLines.join('  ·  ');
      const maxSynW = panelW - 80;
      fill(C.scioto[0], C.scioto[1], C.scioto[2], 130);
      text('PARTY SYNERGY:  ' + synText, width / 2, synSummaryY);
    } else {
      fill(C.dim[0], C.dim[1], C.dim[2], 100);
      text('Select both companions to see party synergy.', width / 2, synSummaryY);
    }

    // Confirm button
    const btnX = width / 2 - 100;
    const btnY = panelY + panelH - 18;
    const btnW = 200;
    const btnH = 16;

    fill(C.teal[0], C.teal[1], C.teal[2], 25);
    noStroke();
    rect(btnX, btnY, btnW, btnH);
    safePixelBorder(btnX, btnY, btnW, btnH, 1, PAL.SHADOW, PAL.TEAL);

    textFont(CC_FONT_UI);
    textSize(9);
    textAlign(CENTER, CENTER);
    fill(C.teal[0], C.teal[1], C.teal[2], 220);
    const confirmLabel = this.party[1] && this.party[2]
      ? '▶  CONFIRM PARTY  —  ENTER  ◀'
      : '▷  Fill both slots to continue  ◁';
    text(confirmLabel, width / 2, btnY + btnH / 2);

    // Footer
    textFont(CC_FONT_UI);
    textSize(7);
    fill(C.dim[0], C.dim[1], C.dim[2], 100);
    textAlign(CENTER, BOTTOM);
    text('ENTER to begin  ·  ESC to edit companions', width / 2, height - 12);
  },
};

// ─────────────────────────────────────────────
//  WINDOW EXPOSURE
// ─────────────────────────────────────────────

window.AetherCharCreate = CharCreate;

// ─────────────────────────────────────────────
//  INTEGRATION NOTES FOR core.js
// ─────────────────────────────────────────────
//
// Add these changes to core.js to wire in character creation:
//
// 1. STATE enum — add CHARCREATE:
//    const STATE = {
//      BOOT: 'boot', MENU: 'menu', CHARCREATE: 'charcreate',
//      WORLD: 'world', COMBAT: 'combat', ...
//    };
//
// 2. setup() — after creating combat, also create char-create:
//    if (typeof window.AetherCharCreate !== 'undefined') {
//      window._charcreate = window.AetherCharCreate;
//      window._charcreate.init();
//    }
//
// 3. draw() — add dispatch branch:
//    else if (gameState === STATE.CHARCREATE) {
//      if (window._charcreate && typeof window._charcreate.draw === 'function') {
//        window._charcreate.draw();
//      }
//    }
//
// 4. handleInput() — add CHARCREATE branch:
//    else if (gameState === STATE.CHARCREATE) {
//      if (window._charcreate && typeof window._charcreate.handleInput === 'function') {
//        window._charcreate.handleInput(keys, keysPressed);
//      }
//    }
//
// 5. keyTyped() — forward typed characters to char-create:
//    if (gameState === STATE.CHARCREATE) {
//      if (window._charcreate && typeof window._charcreate.handleTypedChar === 'function') {
//        window._charcreate.handleTypedChar(key);
//      }
//    }
//
// 6. startGame() — redirect to CHARCREATE instead of WORLD:
//    Replace:  gameState = STATE.WORLD;
//    With:
//      gameState = STATE.CHARCREATE;
//      if (window._charcreate && typeof window._charcreate.start === 'function') {
//        window._charcreate.start();
//      }
//
// 7. After char-create completes (phase === 'done'), core.js should
//    transition to WORLD. Add this check at the top of draw():
//    if (gameState === STATE.CHARCREATE &&
//        window._charcreate && window._charcreate.phase === 'done') {
//      // Populate world.player from party[0] (Ender)
//      if (window._charcreate.party && window._charcreate.party[0]) {
//        const p = window._charcreate.party[0];
//        world.player = {
//          vit: p.vit, maxVit: p.maxVit,
//          echoes: p.echoes.current, echoesMax: p.echoes.max,
//          wits: p.wits, presence: p.presence, spirit: p.spirit,
//          might: p.might, grace: p.grace,
//          scrap: p.scrap, aether: p.aether.current, aetherMax: p.aether.max,
//          heat: p.heat.current, heatMax: p.heat.max,
//          staffCharges: p.staffCharges, maxStaffCharges: p.maxStaffCharges,
//          level: p.level, xp: p.xp, xpToNext: p.xpToNext,
//          unlockedAbilities: p.unlockedAbilities,
//          equipment: p.equipment,
//        };
//      }
//      gameState = STATE.WORLD;
//      window.gameState = gameState;
//      // Also re-init combat with the new player data
//      if (combat && typeof combat.init === 'function') {
//        combat.init({
//          vit: world.player.vit, scrap: world.player.scrap,
//          aether: { current: world.player.aether, max: world.player.aetherMax },
//          heat: { current: world.player.heat, max: world.player.heatMax },
//          echoes: { current: world.player.echoes, max: world.player.echoesMax },
//          charges: world.player.staffCharges, staffMax: world.player.maxStaffCharges,
//          aetherMax: world.player.aetherMax, heatMax: world.player.heatMax,
//          echoesMax: world.player.echoesMax,
//          level: world.player.level, xp: world.player.xp,
//          xpToNext: world.player.xpToNext,
//          unlockedAbilities: world.player.unlockedAbilities,
//          equipment: world.player.equipment,
//        });
//      }
//    }
//
// 8. (Optional) HP bar / HUD updates: the existing drawCharSheet and
//    world HUD use hardcoded Ender stats. To display companion stats,
//    pass the active party member (world.player) to those functions.
//    For rank-1 baseline, Ender is always the active combatant so the
//    existing HUD works unchanged.
//
// 9. Module loading: add <script src="modules/char-create.js"></script>
//    to index.html AFTER ui.js and BEFORE p5.min.js (or bundle into
//    aetherwake.js alongside the other modules).
