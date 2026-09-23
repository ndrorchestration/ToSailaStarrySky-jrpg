(function(root) {
  'use strict';

  // GENERATED AUTHORITY MIRROR.
  // Source of truth: docs/audio-assets.json.
  // scripts/admit-title-audio.js rewrites this module during governed admission.
  const MANIFEST = Object.freeze({
  "version": 1,
  "titleTheme": {
    "id": "title-main",
    "title": "Aetherwake — Skyward Arpeggio Main Title",
    "canonicalPath": "assets/audio/aetherwake-skyward-arpeggio-main-title.mp3",
    "repositoryStatus": "source-verified-repository-missing",
    "musicBusTrackId": "title",
    "runtimeRegistration": false
  }
});

  function registerAdmittedTracks(musicBus) {
    if (!musicBus || typeof musicBus.registerTrack !== 'function') {
      throw new Error('AUDIO_ASSET_MUSIC_BUS_UNAVAILABLE');
    }
    const title = MANIFEST.titleTheme;
    if (!title.runtimeRegistration || title.repositoryStatus !== 'admitted') {
      return {
        ok: false,
        reason: 'TITLE_THEME_NOT_ADMITTED',
        registeredTrackIds: []
      };
    }
    const track = musicBus.registerTrack({
      id: title.musicBusTrackId,
      src: title.canonicalPath,
      loop: true,
      title: title.title
    });
    return {
      ok: true,
      reason: null,
      registeredTrackIds: [track.id]
    };
  }

  const api = Object.freeze({
    MANIFEST,
    registerAdmittedTracks
  });

  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.AetherAudioAssets = api;
})(typeof window !== 'undefined' ? window : globalThis);
