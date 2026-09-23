(function(factory) {
  const root = typeof window !== 'undefined' ? window : globalThis;
  const api = factory(root);
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.AetherMusicBus = api;
})(function(root) {
  'use strict';

  const VERSION = '0.1.0';
  const DEFAULT_VOLUME_PERCENT = 80;

  const tracks = new Map();
  let volumePercent = DEFAULT_VOLUME_PERCENT;
  let duckFactor = 1;
  let currentTrackId = null;
  let audioElement = null;
  let lastError = null;

  function clamp01(value) {
    return Math.max(0, Math.min(1, Number(value) || 0));
  }

  function validateTrack(track) {
    if (!track || typeof track !== 'object' || Array.isArray(track)) {
      throw new Error('MUSIC_TRACK_OBJECT_REQUIRED');
    }
    if (typeof track.id !== 'string' || !track.id.trim()) {
      throw new Error('MUSIC_TRACK_ID_REQUIRED');
    }
    if (typeof track.src !== 'string' || !track.src.trim()) {
      throw new Error('MUSIC_TRACK_SRC_REQUIRED');
    }
    if (/^(?:https?:)?\/\//i.test(track.src)) {
      throw new Error('MUSIC_TRACK_REMOTE_SOURCE_FORBIDDEN');
    }
    return true;
  }

  function registerTrack(track) {
    validateTrack(track);
    const normalized = Object.freeze({
      id: track.id.trim(),
      src: track.src.trim(),
      loop: track.loop !== false,
      title: typeof track.title === 'string' ? track.title : track.id.trim()
    });
    tracks.set(normalized.id, normalized);
    return normalized;
  }

  function unregisterTrack(trackId) {
    if (currentTrackId === trackId) stop();
    return tracks.delete(trackId);
  }

  function listTracks() {
    return Array.from(tracks.values()).map(track => ({ ...track }));
  }

  function ensureAudioElement() {
    if (audioElement) return audioElement;
    const AudioCtor = root && root.Audio;
    if (typeof AudioCtor !== 'function') return null;
    audioElement = new AudioCtor();
    audioElement.preload = 'auto';
    audioElement.addEventListener?.('error', function() {
      lastError = 'MUSIC_TRACK_PLAYBACK_ERROR';
    });
    applyVolume();
    return audioElement;
  }

  function effectiveVolume() {
    return clamp01((volumePercent / 100) * duckFactor);
  }

  function applyVolume() {
    if (audioElement) audioElement.volume = effectiveVolume();
    return effectiveVolume();
  }

  function setVolumePercent(value) {
    const numeric = Number(value);
    if (!Number.isFinite(numeric)) throw new Error('MUSIC_VOLUME_INVALID');
    volumePercent = Math.max(0, Math.min(100, Math.round(numeric)));
    applyVolume();
    return volumePercent;
  }

  function setDuckFactor(value) {
    const numeric = Number(value);
    if (!Number.isFinite(numeric)) throw new Error('MUSIC_DUCK_INVALID');
    duckFactor = clamp01(numeric);
    applyVolume();
    return duckFactor;
  }

  function play(trackId, options) {
    const track = tracks.get(trackId);
    if (!track) {
      lastError = 'MUSIC_TRACK_UNREGISTERED:' + trackId;
      return { ok: false, reason: lastError };
    }
    const audio = ensureAudioElement();
    if (!audio) {
      lastError = 'MUSIC_AUDIO_UNAVAILABLE';
      return { ok: false, reason: lastError };
    }

    const opts = options || {};
    const shouldRestart = opts.restart === true || currentTrackId !== track.id;
    if (shouldRestart) {
      audio.src = track.src;
      audio.loop = track.loop;
      try { audio.currentTime = 0; } catch (_) {}
    }
    currentTrackId = track.id;
    applyVolume();

    let promise = null;
    try {
      promise = audio.play();
    } catch (error) {
      lastError = 'MUSIC_PLAY_THROW:' + error.message;
      return { ok: false, reason: lastError };
    }
    if (promise && typeof promise.catch === 'function') {
      promise.catch(function(error) {
        lastError = 'MUSIC_PLAY_REJECTED:' + (error && error.message ? error.message : 'unknown');
      });
    }
    lastError = null;
    return { ok: true, trackId: track.id };
  }

  function pause() {
    if (audioElement && typeof audioElement.pause === 'function') audioElement.pause();
    return Boolean(currentTrackId);
  }

  function stop() {
    if (audioElement && typeof audioElement.pause === 'function') {
      audioElement.pause();
      try { audioElement.currentTime = 0; } catch (_) {}
    }
    currentTrackId = null;
    return true;
  }

  function snapshot() {
    return {
      version: VERSION,
      volumePercent,
      duckFactor,
      effectiveVolume: effectiveVolume(),
      currentTrackId,
      registeredTrackIds: Array.from(tracks.keys()),
      hasAudioElement: Boolean(audioElement),
      lastError
    };
  }

  return Object.freeze({
    VERSION,
    DEFAULT_VOLUME_PERCENT,
    registerTrack,
    unregisterTrack,
    listTracks,
    setVolumePercent,
    setDuckFactor,
    play,
    pause,
    stop,
    snapshot
  });
});
