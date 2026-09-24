/* Aetherwake — Chapter 1 scene music controller.
   Non-fatal presentation layer: missing/unadmitted music never blocks gameplay. */
(function(root){
  'use strict';

  const VERSION = '0.1.0';
  const TRACKS = Object.freeze({
    opening: { id:'first-wake-cinematic', src:'assets/audio/amonigio-umulula.mp3', volume:0.50 },
    exploration: { id:'solar-punk-airship', src:'assets/audio/solar-punk-airship.mp3', volume:0.46 },
    combat: { id:'nocturnal-resolve', src:'assets/audio/nocturnal-resolve.mp3', volume:0.52 },
    ender: { id:'open-sky-signal', src:'assets/audio/open-sky-signal.mp3', volume:0.50 },
  });

  let audio = null;
  let currentId = null;
  let lastError = null;
  let timer = null;
  let overrideId = null;

  function desiredTrack() {
    const state = typeof root.gameState === 'string' ? root.gameState : 'boot';
    if (state === 'boot' || state === 'menu') return null;
    if (overrideId && TRACKS[overrideId]) return TRACKS[overrideId];
    if (state === 'combat') return TRACKS.combat;
    if (state === 'opening') return TRACKS.opening;

    // The First Note ending is Ender's authored Chapter I musical payoff.
    const questState = root._world && typeof root._world.getQuestState === 'function'
      ? root._world.getQuestState()
      : null;
    if (questState &&
        (questState.state === 'wake' || questState.state === 'done') &&
        questState.wakeEpilogueId === 'epiline_10') {
      return TRACKS.ender;
    }

    if (state === 'world' || state === 'airship' || state === 'dialogue' ||
        state === 'questlog' || state === 'charsheet' || state === 'saveload') {
      return TRACKS.exploration;
    }
    return null;
  }

  function ensureAudio() {
    if (audio) return audio;
    if (typeof root.Audio !== 'function') return null;
    audio = new root.Audio();
    audio.loop = true;
    audio.preload = 'auto';
    audio.setAttribute?.('aria-hidden','true');
    audio.addEventListener?.('error', function(){
      lastError = 'SCENE_MUSIC_ASSET_UNAVAILABLE:' + (currentId || 'unknown');
    });
    return audio;
  }

  function stop() {
    if (!audio) { currentId = null; return; }
    try { audio.pause(); audio.currentTime = 0; } catch (_) {}
    currentId = null;
  }

  function sync(force) {
    const track = desiredTrack();
    if (!track) { stop(); return false; }
    const a = ensureAudio();
    if (!a) { lastError='SCENE_MUSIC_AUDIO_UNAVAILABLE'; return false; }
    if (!force && currentId === track.id && !a.paused) return true;

    if (currentId !== track.id) {
      try { a.pause(); a.currentTime = 0; } catch (_) {}
      a.src = track.src;
      a.loop = true;
      a.volume = track.volume;
      currentId = track.id;
    }

    try {
      const result = a.play();
      if (result && typeof result.catch === 'function') {
        result.catch(function(err){
          lastError = 'SCENE_MUSIC_PLAY_REJECTED:' + (err && err.message ? err.message : 'unknown');
        });
      }
      return true;
    } catch (err) {
      lastError = 'SCENE_MUSIC_PLAY_FAILED:' + (err && err.message ? err.message : 'unknown');
      return false;
    }
  }

  function setCharacterTheme(characterId) {
    if (characterId === 'ender') {
      overrideId = 'ender';
      sync(true);
      return true;
    }
    return false;
  }

  function clearCharacterTheme() {
    overrideId = null;
    sync(true);
  }

  function onGesture(){ sync(true); }

  function init(){
    if (timer !== null) return api;
    root.addEventListener?.('keydown', onGesture, {passive:true});
    root.addEventListener?.('pointerdown', onGesture, {passive:true});
    timer = root.setInterval(function(){ sync(false); }, 300);
    return api;
  }

  const api = Object.freeze({
    VERSION, TRACKS, init, sync, stop, setCharacterTheme, clearCharacterTheme,
    get state(){ return Object.freeze({currentId,lastError,overrideId,desiredId:desiredTrack()?.id || null}); }
  });
  root.AetherSceneMusic = api;

  if (root.document) {
    if (root.document.readyState === 'loading') {
      root.document.addEventListener('DOMContentLoaded', init, {once:true});
    } else init();
  }
})(typeof window !== 'undefined' ? window : globalThis);
