/* ============================================================
   Aetherwake — Cinematic Clip Player
   modules/cinematic-player.js

   Presentation-only media runtime. It never owns story progression.
   Every play attempt resolves to an explicit result so callers can advance
   canonical state regardless of media decode success.
   ============================================================ */
(function (root) {
  'use strict';

  const VERSION = '0.1.0';
  const FADE_MS = 220;

  let host = null;
  let video = null;
  let caption = null;
  let active = false;
  let activeManifest = null;
  let activeResolve = null;
  let skipHandler = null;

  function ensureHost() {
    if (!root.document) return null;
    if (host && root.document.body && root.document.body.contains(host)) return host;

    host = root.document.createElement('div');
    host.id = 'aw-cinematic-host';
    host.setAttribute('aria-hidden', 'true');
    Object.assign(host.style, {
      position: 'fixed',
      inset: '0',
      zIndex: '9998',
      display: 'none',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#05080d',
      opacity: '0',
      transition: 'opacity ' + FADE_MS + 'ms linear',
      pointerEvents: 'none',
    });

    video = root.document.createElement('video');
    video.id = 'aw-cinematic-video';
    video.playsInline = true;
    video.preload = 'auto';
    video.controls = false;
    video.setAttribute('disablePictureInPicture', '');
    Object.assign(video.style, {
      width: '100vw',
      height: '100vh',
      objectFit: 'contain',
      background: '#05080d',
    });

    caption = root.document.createElement('div');
    caption.id = 'aw-cinematic-caption';
    Object.assign(caption.style, {
      position: 'absolute',
      left: '10%',
      right: '10%',
      bottom: '8%',
      color: '#e8dcc6',
      fontFamily: '"VT323", monospace',
      fontSize: '28px',
      lineHeight: '1.15',
      textAlign: 'center',
      textShadow: '0 2px 4px #000',
      display: 'none',
    });

    host.appendChild(video);
    host.appendChild(caption);
    root.document.body.appendChild(host);
    return host;
  }

  function validateManifest(manifest) {
    if (!manifest || typeof manifest !== 'object') throw new Error('CINEMATIC_MANIFEST_REQUIRED');
    if (typeof manifest.id !== 'string' || !manifest.id) throw new Error('CINEMATIC_ID_REQUIRED');
    if (typeof manifest.file !== 'string' || !manifest.file) throw new Error('CINEMATIC_FILE_REQUIRED');
    if (manifest.blocksProgression !== false) throw new Error('CINEMATIC_PROGRESS_AUTHORITY_FORBIDDEN');
    if (!manifest.fallback || typeof manifest.fallback.type !== 'string') {
      throw new Error('CINEMATIC_FALLBACK_REQUIRED');
    }
    return true;
  }

  function clipUrl(manifest) {
    return 'assets/cinematics/' + manifest.file.replace(/^\/+/, '');
  }

  function subtitleUrl(manifest) {
    return manifest.subtitles && manifest.subtitles.track
      ? 'assets/cinematics/' + String(manifest.subtitles.track).replace(/^\/+/, '')
      : null;
  }

  function cleanupTrack() {
    if (!video) return;
    for (const node of Array.from(video.querySelectorAll('track'))) node.remove();
  }

  function addSubtitleTrack(manifest) {
    cleanupTrack();
    const src = subtitleUrl(manifest);
    if (!src || !video) return;
    const track = root.document.createElement('track');
    track.kind = 'subtitles';
    track.label = 'Subtitles';
    track.srclang = 'en';
    track.src = src;
    track.default = true;
    video.appendChild(track);
  }

  function finalize(status, detail) {
    if (!active) return;
    active = false;

    const resolve = activeResolve;
    activeResolve = null;

    if (skipHandler && root.removeEventListener) {
      root.removeEventListener('keydown', skipHandler, true);
    }
    skipHandler = null;

    if (video) {
      try { video.pause(); } catch (_) {}
      video.removeAttribute('src');
      video.load();
      cleanupTrack();
    }

    if (host) {
      host.style.opacity = '0';
      root.setTimeout(() => {
        if (host) host.style.display = 'none';
      }, FADE_MS);
    }

    const manifest = activeManifest;
    activeManifest = null;

    if (resolve) {
      resolve(Object.freeze({
        status,
        id: manifest ? manifest.id : null,
        detail: detail || null,
      }));
    }
  }

  function skip() {
    if (!active || !activeManifest || activeManifest.skippable !== true) return false;
    finalize('skipped', 'USER_SKIP');
    return true;
  }

  function installSkipHandler() {
    if (!root.addEventListener) return;
    skipHandler = (event) => {
      if (!active || !activeManifest || activeManifest.skippable !== true) return;
      if (event.key === 'Escape' || event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        event.stopPropagation();
        skip();
      }
    };
    root.addEventListener('keydown', skipHandler, true);
  }

  function fallback(manifest, reason) {
    if (typeof root.CustomEvent === 'function' && root.dispatchEvent) {
      root.dispatchEvent(new root.CustomEvent('aetherwake:cinematic-fallback', {
        detail: {
          id: manifest.id,
          fallback: manifest.fallback,
          reason,
        },
      }));
    }
    finalize('fallback', reason);
  }

  function play(manifest) {
    validateManifest(manifest);
    if (active) return Promise.resolve(Object.freeze({
      status: 'busy',
      id: manifest.id,
      detail: 'CINEMATIC_ALREADY_ACTIVE',
    }));

    const node = ensureHost();
    if (!node || !video) {
      return Promise.resolve(Object.freeze({
        status: 'fallback',
        id: manifest.id,
        detail: 'CINEMATIC_DOM_UNAVAILABLE',
      }));
    }

    active = true;
    activeManifest = manifest;
    host.style.display = 'flex';
    host.style.pointerEvents = 'auto';
    root.requestAnimationFrame(() => {
      if (host) host.style.opacity = '1';
    });

    addSubtitleTrack(manifest);
    video.src = clipUrl(manifest);

    installSkipHandler();

    return new Promise((resolve) => {
      activeResolve = resolve;

      const cleanupListeners = () => {
        video.removeEventListener('ended', onEnded);
        video.removeEventListener('error', onError);
        video.removeEventListener('canplay', onCanPlay);
      };

      const onEnded = () => {
        cleanupListeners();
        finalize('played', 'ENDED');
      };

      const onError = () => {
        cleanupListeners();
        fallback(manifest, 'DECODE_OR_LOAD_FAILED');
      };

      const onCanPlay = () => {
        try {
          const result = video.play();
          if (result && typeof result.catch === 'function') {
            result.catch(() => {
              cleanupListeners();
              fallback(manifest, 'PLAYBACK_REJECTED');
            });
          }
        } catch (_) {
          cleanupListeners();
          fallback(manifest, 'PLAYBACK_FAILED');
        }
      };

      video.addEventListener('ended', onEnded, { once: true });
      video.addEventListener('error', onError, { once: true });
      video.addEventListener('canplay', onCanPlay, { once: true });
      video.load();
    });
  }

  async function preload(manifest) {
    validateManifest(manifest);
    if (!root.document) return Object.freeze({ ok: false, reason: 'DOM_UNAVAILABLE' });

    return new Promise((resolve) => {
      const probe = root.document.createElement('video');
      probe.preload = 'metadata';
      probe.src = clipUrl(manifest);

      const done = (ok, reason) => {
        probe.removeAttribute('src');
        try { probe.load(); } catch (_) {}
        resolve(Object.freeze({ ok, reason: reason || null, id: manifest.id }));
      };

      probe.addEventListener('loadedmetadata', () => done(true, null), { once: true });
      probe.addEventListener('error', () => done(false, 'LOAD_FAILED'), { once: true });
      try { probe.load(); } catch (_) { done(false, 'LOAD_FAILED'); }
    });
  }

  function state() {
    return Object.freeze({
      active,
      id: activeManifest ? activeManifest.id : null,
      skippable: Boolean(activeManifest && activeManifest.skippable),
    });
  }

  const api = Object.freeze({
    VERSION,
    validateManifest,
    preload,
    play,
    skip,
    state,
  });

  root.AetherCinematicPlayer = api;
})(typeof window !== 'undefined' ? window : globalThis);
