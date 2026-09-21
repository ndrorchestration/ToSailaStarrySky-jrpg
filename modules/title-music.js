(function (global) {
  'use strict';

  const THEME_PATH = 'assets/audio/aetherwake-skyward-arpeggio-main-title.mp3';
  const TITLE_STATES = new Set(['boot', 'menu', 'charcreate']);
  const TARGET_VOLUME = 0.58;
  const FADE_STEP = 0.04;
  const FADE_INTERVAL_MS = 50;

  let audio = null;
  let gameFrame = null;
  let fadeTimer = null;
  let playbackRequested = false;
  let initialized = false;

  function getGameWindow() {
    try {
      return gameFrame && gameFrame.contentWindow ? gameFrame.contentWindow : global;
    } catch (_) {
      return global;
    }
  }

  function getGameState() {
    const gameWindow = getGameWindow();
    return gameWindow && typeof gameWindow.gameState === 'string'
      ? gameWindow.gameState
      : 'boot';
  }

  function shouldPlay() {
    return TITLE_STATES.has(getGameState());
  }

  function clearFade() {
    if (fadeTimer !== null) {
      global.clearInterval(fadeTimer);
      fadeTimer = null;
    }
  }

  function fadeOut() {
    if (!audio || audio.paused || fadeTimer !== null) return;
    fadeTimer = global.setInterval(function () {
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

  function requestPlayback() {
    if (!audio || !shouldPlay()) return;
    clearFade();
    audio.volume = TARGET_VOLUME;
    playbackRequested = true;
    const result = audio.play();
    if (result && typeof result.catch === 'function') {
      result.catch(function () {
        playbackRequested = false;
      });
    }
  }

  function handleStateChange() {
    if (shouldPlay()) {
      if (!playbackRequested && audio && audio.paused) requestPlayback();
    } else {
      fadeOut();
    }
  }

  function addGestureListeners(target) {
    if (!target || typeof target.addEventListener !== 'function') return;
    target.addEventListener('keydown', requestPlayback, { passive: true });
    target.addEventListener('pointerdown', requestPlayback, { passive: true });
  }

  function attachToFrame(frame) {
    gameFrame = frame || null;
    if (!gameFrame) return;
    gameFrame.addEventListener('load', function () {
      try {
        addGestureListeners(gameFrame.contentWindow);
        addGestureListeners(gameFrame.contentDocument);
      } catch (_) {
        // Same-origin access can fail in unusual launchers. Audio remains optional.
      }
      handleStateChange();
    });
  }

  function init(options) {
    if (initialized) return api;
    initialized = true;
    const settings = options || {};
    audio = new Audio(settings.src || THEME_PATH);
    audio.loop = true;
    audio.preload = 'auto';
    audio.volume = TARGET_VOLUME;
    audio.setAttribute('aria-hidden', 'true');
    addGestureListeners(global);
    addGestureListeners(global.document);
    attachToFrame(settings.frame || global.document.getElementById('aetherwake-game'));
    global.setInterval(handleStateChange, 250);
    requestPlayback();
    return api;
  }

  const api = {
    init,
    requestPlayback,
    fadeOut,
    get state() {
      return {
        initialized,
        source: audio ? audio.src : THEME_PATH,
        paused: audio ? audio.paused : true,
        gameState: getGameState(),
      };
    },
  };

  global.AetherwakeTitleMusic = api;
})(window);
