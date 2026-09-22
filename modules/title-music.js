/* ============================================================
   Aetherwake — Direct Runtime Title Theme Controller
   modules/title-music.js

   Optional/non-fatal presentation layer. The title theme may never block
   boot, rendering, input, opening progression, or desktop launch.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.2.0';
  const THEME_PATH = 'assets/audio/aetherwake-skyward-arpeggio-main-title.mp3';
  const TITLE_STATES = new Set(['boot', 'menu']);
  const TARGET_VOLUME = 0.58;
  const FADE_STEP = 0.04;
  const FADE_INTERVAL_MS = 50;

  let audio = null;
  let initialized = false;
  let playbackRequested = false;
  let fadeTimer = null;
  let syncTimer = null;
  let assetMissing = false;
  let lastError = null;

  function stateName() {
    return typeof root.gameState === 'string' ? root.gameState : 'boot';
  }

  function shouldPlay() {
    return TITLE_STATES.has(stateName());
  }

  function clearFade() {
    if (fadeTimer !== null) {
      root.clearInterval(fadeTimer);
      fadeTimer = null;
    }
  }

  function requestPlayback() {
    if (!audio || assetMissing || !shouldPlay()) return false;
    clearFade();
    audio.volume = TARGET_VOLUME;
    playbackRequested = true;

    try {
      const result = audio.play();
      if (result && typeof result.catch === 'function') {
        result.catch((error) => {
          playbackRequested = false;
          lastError = error && error.message ? error.message : 'PLAYBACK_REJECTED';
        });
      }
      return true;
    } catch (error) {
      playbackRequested = false;
      lastError = error && error.message ? error.message : 'PLAYBACK_FAILED';
      return false;
    }
  }

  function fadeOut() {
    if (!audio || audio.paused || fadeTimer !== null) return;
    fadeTimer = root.setInterval(() => {
      if (!audio) {
        clearFade();
        return;
      }
      audio.volume = Math.max(0, audio.volume - FADE_STEP);
      if (audio.volume <= 0) {
        audio.pause();
        audio.currentTime = 0;
        audio.volume = TARGET_VOLUME;
        playbackRequested = false;
        clearFade();
      }
    }, FADE_INTERVAL_MS);
  }

  function sync() {
    if (!audio) return;
    if (shouldPlay()) {
      if (!playbackRequested && audio.paused) requestPlayback();
    } else {
      fadeOut();
    }
  }

  function onGesture() {
    if (!initialized) init();
    requestPlayback();
  }

  function addGestureTarget(target) {
    if (!target || typeof target.addEventListener !== 'function') return;
    target.addEventListener('keydown', onGesture, { passive: true });
    target.addEventListener('pointerdown', onGesture, { passive: true });
  }

  function init(options) {
    if (initialized) return api;
    initialized = true;
    const settings = options || {};

    try {
      audio = new Audio(settings.src || THEME_PATH);
      audio.loop = true;
      audio.preload = 'auto';
      audio.volume = TARGET_VOLUME;
      audio.setAttribute('aria-hidden', 'true');

      audio.addEventListener('error', () => {
        assetMissing = true;
        playbackRequested = false;
        lastError = 'TITLE_THEME_ASSET_UNAVAILABLE';
      });

      addGestureTarget(root);
      addGestureTarget(root.document);

      syncTimer = root.setInterval(sync, 250);
      sync();
    } catch (error) {
      lastError = error && error.message ? error.message : 'TITLE_THEME_INIT_FAILED';
      assetMissing = true;
    }

    return api;
  }

  function destroy() {
    clearFade();
    if (syncTimer !== null) {
      root.clearInterval(syncTimer);
      syncTimer = null;
    }
    if (audio) {
      try { audio.pause(); } catch (_) {}
    }
    audio = null;
    initialized = false;
    playbackRequested = false;
  }

  const api = Object.freeze({
    VERSION,
    THEME_PATH,
    init,
    sync,
    requestPlayback,
    fadeOut,
    destroy,
    get state() {
      return Object.freeze({
        initialized,
        gameState: stateName(),
        shouldPlay: shouldPlay(),
        playbackRequested,
        paused: audio ? audio.paused : true,
        assetMissing,
        lastError,
      });
    },
  });

  root.AetherTitleMusic = api;

  if (root.document) {
    if (root.document.readyState === 'loading') {
      root.document.addEventListener('DOMContentLoaded', () => init(), { once: true });
    } else {
      init();
    }
  }
})(typeof window !== 'undefined' ? window : globalThis);
