// ============================================================
// Aetherwake JRPG — Synthesized Audio Module (Web Audio API)
// Pure oscillator-based sound effects. No external samples.
// p5.sound is NOT available, so we use raw Web Audio API.
// ============================================================
'use strict';

/** Global audio context — lazily created on first user interaction. */
let _audioCtx = null;

/** Master gain node — all sounds route through here for volume control. */
let _masterGain = null;

/** Per-sound gain envelopes for shaping. */
const _envs = new Map();

/** Whether audio is enabled (player-toggleable). */
window.AUDIO_ENABLED = true;

/** Global volume 0..1. */
window.AUDIO_VOLUME = 0.35;

// ── Audio Context Lifecycle ──────────────────────────────────────────────

function ensureAudio() {
  if (_audioCtx) return _audioCtx;
  try {
    const Ctor = window.AudioContext || window.webkitAudioContext;
    if (!Ctor) {
      console.warn('[Audio] Web Audio API not available in this browser.');
      return null;
    }
    _audioCtx = new Ctor();
    _masterGain = _audioCtx.createGain();
    _masterGain.gain.value = window.AUDIO_VOLUME;
    _masterGain.connect(_audioCtx.destination);
    console.log('[Audio] Web Audio context created.');
    return _audioCtx;
  } catch (e) {
    console.warn('[Audio] Could not create AudioContext:', e.message);
    return null;
  }
}

function isAudioReady() {
  const ctx = ensureAudio();
  return ctx && ctx.state === 'running';
}

/** Resume context if suspended (needed after user gesture in some browsers). */
function resumeAudio() {
  const ctx = ensureAudio();
  if (ctx && ctx.state === 'suspended') {
    ctx.resume().catch(function () {});
  }
}

// ── Generic Sound Builder ─────────────────────────────────────────────────

/**
 * Play a short synthesized sound.
 * @param {function} synth — (osc, gain, ctx, now) => void  — connects/arranges nodes.
 * @param {number} [vol=1] — relative volume 0..1
 * @returns {boolean} whether the sound was scheduled.
 */
function playSound(synth, vol) {
  if (!window.AUDIO_ENABLED) return false;
  vol = vol == null ? 1 : vol;
  const ctx = ensureAudio();
  if (!ctx) return false;
  if (ctx.state === 'suspended') resumeAudio();
  const now = ctx.currentTime;
  try {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    gain.gain.value = 0;
    osc.connect(gain);
    gain.connect(_masterGain);
    synth(osc, gain, ctx, now, vol);
    osc.start(now);
    // Auto-stop oscillators after a safety window to avoid leaks
    const safetyOff = Math.max(0.5, (now + 2.0) - ctx.currentTime);
    if (safetyOff > 0) {
      gain.gain.setValueAtTime(0, now + safetyOff);
      osc.stop(now + safetyOff + 0.05);
    }
    return true;
  } catch (e) {
    console.warn('[Audio] sound error:', e.message);
    return false;
  }
}

// ── Sound Presets ─────────────────────────────────────────────────────────

/**
 * Footstep — soft short click/pop.
 * Repeated softly while moving; only on tile-boundary crossing,
 * not every frame.
 */
window.playFootstep = function () {
  playSound(function (osc, gain, ctx, now, vol) {
    osc.type = 'sine';
    osc.frequency.setValueAtTime(180, now);
    osc.frequency.exponentialRampToValueAtTime(80, now + 0.04);
    gain.gain.setValueAtTime(0.08 * vol, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.06);
  }, 0.5);
};

/**
 * Menu select — short teal blip (rising sine, quick).
 */
window.playMenuSelect = function () {
  playSound(function (osc, gain, ctx, now, vol) {
    osc.type = 'sine';
    osc.frequency.setValueAtTime(520, now);
    osc.frequency.exponentialRampToValueAtTime(780, now + 0.07);
    gain.gain.setValueAtTime(0.10 * vol, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.10);
  }, 0.7);
};

/**
 * Combat hit (player hits enemy) — low thud + short bright tap.
 * Two oscillators: low sine thud + triangle click.
 */
window.playCombatHit = function () {
  playSound(function (osc, gain, ctx, now, vol) {
    osc.type = 'sine';
    osc.frequency.setValueAtTime(120, now);
    osc.frequency.exponentialRampToValueAtTime(55, now + 0.12);
    gain.gain.setValueAtTime(0.18 * vol, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
  }, 0.9);
  // Secondary bright tap
  playSound(function (osc, gain, ctx, now, vol) {
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(880, now);
    osc.frequency.exponentialRampToValueAtTime(440, now + 0.05);
    gain.gain.setValueAtTime(0.06 * vol, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.06);
  }, 0.5);
};

/**
 * Damage taken — descending tone (sad thud).
 */
window.playDamageTaken = function () {
  playSound(function (osc, gain, ctx, now, vol) {
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(260, now);
    osc.frequency.exponentialRampToValueAtTime(90, now + 0.18);
    gain.gain.setValueAtTime(0.12 * vol, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.20);
  }, 0.8);
  playSound(function (osc, gain, ctx, now, vol) {
    osc.type = 'sine';
    osc.frequency.setValueAtTime(140, now);
    osc.frequency.exponentialRampToValueAtTime(60, now + 0.16);
    gain.gain.setValueAtTime(0.10 * vol, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
  }, 0.6);
};

/**
 * Ability success — rising arpeggio (three quick notes).
 */
window.playAbilitySuccess = function () {
  const notes = [523, 659, 784]; // C5, E5, G5
  notes.forEach(function (freq, i) {
    playSound(function (osc, gain, ctx, now, vol) {
      const t = now + i * 0.055;
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, t);
      gain.gain.setValueAtTime(0, t);
      gain.gain.linearRampToValueAtTime(0.08 * vol, t + 0.01);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.12);
    }, 0.6);
  });
};

/**
 * Ability fail / partial — muted descending two-note.
 */
window.playAbilityFail = function () {
  playSound(function (osc, gain, ctx, now, vol) {
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(350, now);
    osc.frequency.exponentialRampToValueAtTime(180, now + 0.12);
    gain.gain.setValueAtTime(0.07 * vol, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
  }, 0.6);
};

/**
 * Level up — bright ascending arpeggio (C major-ish).
 */
window.playLevelUp = function () {
  const notes = [523, 659, 784, 1047]; // C5 E5 G5 C6
  notes.forEach(function (freq, i) {
    playSound(function (osc, gain, ctx, now, vol) {
      const t = now + i * 0.08;
      osc.type = 'square';
      osc.frequency.setValueAtTime(freq, t);
      gain.gain.setValueAtTime(0, t);
      gain.gain.linearRampToValueAtTime(0.05 * vol, t + 0.01);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
      // Filter-ish by using a second sine layer
      const osc2 = ctx.createOscillator();
      const g2 = ctx.createGain();
      osc2.type = 'sine';
      osc2.frequency.setValueAtTime(freq * 2, t);
      g2.gain.value = 0;
      osc2.connect(g2);
      g2.connect(_masterGain);
      g2.gain.setValueAtTime(0.03 * vol, t);
      g2.gain.exponentialRampToValueAtTime(0.001, t + 0.14);
      osc2.start(t);
      osc2.stop(t + 0.15);
    }, 0.55);
  });
};

/**
 * Quest state change — warm chord (major triad).
 */
window.playQuestAdvance = function () {
  [392, 523, 659].forEach(function (freq) { // G4 C5 E5
    playSound(function (osc, gain, ctx, now, vol) {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now);
      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(0.06 * vol, now + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
    }, 0.5);
  });
};

/**
 * Toggle sound on/off.
 */
window.toggleAudio = function () {
  window.AUDIO_ENABLED = !window.AUDIO_ENABLED;
  if (window.AUDIO_ENABLED) {
    ensureAudio();
    resumeAudio();
  }
  console.log('[Audio] audio ' + (window.AUDIO_ENABLED ? 'enabled' : 'disabled'));
  return window.AUDIO_ENABLED;
};

/**
 * Set master volume 0..1.
 */
window.setAudioVolume = function (v) {
  window.AUDIO_VOLUME = Math.max(0, Math.min(1, v));
  if (_masterGain) {
    _masterGain.gain.value = window.AUDIO_VOLUME;
  }
};

console.log('[Audio] Aetherwake audio module loaded — synthesized Web Audio SFX ready.');
