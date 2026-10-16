/* ============================================================
   Aetherwake JRPG — First Wake Opening Runtime v0.1
   modules/first-wake-opening.js

   Executes the authored opening through the FIRST WAKE chapter card.
   This is a bounded narrative/runtime slice, not the full First Wake.
   No combat kits or unestablished magic semantics are introduced here.
   ============================================================ */

(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherFirstWakeOpening = api;
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';
  const WALK_PULSE_TICKS = 12;

  const SCENES = Object.freeze([
    Object.freeze({
      id: 'arrival_horizon',
      sequence: 0,
      minimumTicks: 240,
      title: 'WAKE DOCK — LOWER VERDANT REACH',
      speaker: null,
      lines: Object.freeze([
        'Dawn gathers beneath a sea of clouds.',
        'A compact patched vessel hangs against a very large sky.',
      ]),
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'ender_arrives',
      sequence: 1,
      title: 'ARRIVAL',
      speaker: 'IONIA',
      lines: Object.freeze([
        'You said you could fix things.',
        'ENDER: I said I was willing to learn how.',
        "IONIA: Good. The Wake respects honest uncertainty more than confident nonsense.",
      ]),
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'dock_walk',
      sequence: 2,
      title: 'THE WALK TO THE WAKE',
      speaker: null,
      lines: Object.freeze([
        'Closed-route marks crowd the dock board.',
        'The Aureate Wake waits ahead: compact, repaired, unfinished.',
      ]),
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'berth_task',
      sequence: 3,
      title: 'A PLACE ABOARD',
      speaker: 'IONIA',
      lines: Object.freeze([
        'That berth leaks heat, the desk lists left,',
        'and something in the wall clicks every thirteen seconds.',
        'Ender clears the berth, aligns the panel, and places his bag.',
      ]),
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'talen_staying',
      sequence: 4,
      title: 'ARE YOU STAYING?',
      speaker: 'TALEN',
      lines: Object.freeze([
        'Are you staying here now?',
        "Don't put your books on that shelf. It falls down.",
        'He leaves a small block-built Wake on the repaired desk.',
      ]),
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'lyra_family',
      sequence: 5,
      title: 'THE HOUSEHOLD',
      speaker: 'LYRA',
      lines: Object.freeze([
        'Galley lit again.',
        'IONIA: For how long?',
        'LYRA: Long enough to become emotionally attached.',
      ]),
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'lyra_join',
      sequence: 6,
      title: 'THE FIRST REACH',
      speaker: 'LYRA',
      lines: Object.freeze([
        '...Did you hear that?',
        "ENDER: I didn't hear it.",
        'ENDER: But yes.',
        'A shield-frequency echo and a displaced spatial relation overlap.'
      ]),
      joinCharacterId: 'lyra',
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'ionia_practical',
      sequence: 7,
      title: 'MAKE IT PRACTICAL',
      speaker: 'IONIA',
      lines: Object.freeze([
        'Wakeheart load just moved twelve percent.',
        "LYRA: That's not what I meant.",
        "IONIA: It's what keeps the rooms warm. Meaning can wait until the shielding holds.",
      ]),
      activePartyIds: Object.freeze(['ender', 'lyra']),
    }),
    Object.freeze({
      id: 'core_walk',
      sequence: 8,
      title: 'TO THE WAKEHEART',
      speaker: null,
      lines: Object.freeze([
        'They pass the shared table, unreliable galley, and exposed conduit.',
        'Beyond the hull, stormlight gathers over the dock shields.',
        'LYRA: This one listened back.',
      ]),
      activePartyIds: Object.freeze(['ender', 'lyra']),
    }),
    Object.freeze({
      id: 'first_wake_card',
      sequence: 9,
      title: 'AETHERWAKE',
      subtitle: 'CHAPTER I — FIRST WAKE',
      speaker: null,
      lines: Object.freeze([
        "The Wake is not awakened by one chosen hand, but by a crew becoming legible to itself.",
        "Ionia holds command. Lyra hears the reach. Ender says yes where the hull expected no.",
        "Beyond the storm, the high lanes remain closed; first, the ship must learn what shelter means.",
      ]),
      activePartyIds: Object.freeze(['ender', 'lyra']),
      chapterCard: true,
    }),
  ]);

  function validate() {
    if (SCENES.length !== 10) throw new Error('FIRST_WAKE_OPENING_SCENE_COUNT_DRIFT');
    SCENES.forEach((scene, index) => {
      if (scene.sequence !== index) throw new Error('FIRST_WAKE_OPENING_SEQUENCE_DRIFT:' + scene.id);
      if (!scene.id || !scene.title) throw new Error('FIRST_WAKE_OPENING_SCENE_INVALID:' + index);
      if (!Array.isArray(scene.activePartyIds) || scene.activePartyIds.length < 1) {
        throw new Error('FIRST_WAKE_OPENING_PARTY_INVALID:' + scene.id);
      }
    });
    if (SCENES[6].joinCharacterId !== 'lyra') {
      throw new Error('FIRST_WAKE_LYRA_JOIN_POINT_DRIFT');
    }
    if (SCENES.some(scene => scene.activePartyIds.includes('ionia'))) {
      throw new Error('FIRST_WAKE_IONIA_JOINED_TOO_EARLY');
    }
    return true;
  }

  function createState(options) {
    validate();
    return {
      sceneIndex: 0,
      presentationTicks: 0,
      complete: false,
      appliedJoinIds: [],
      ...(options && options.exploration === true ? { wakeExploration: {
        active: false, x: 3, y: 5, steps: 0, visited: ['berth'], interactions: [],
        moving: false, movingUntilTick: 0, facing: 'right',
        anomalyTriggered: false, wrongSongAcknowledged: false, ioniaFound: false,
        clues: [], coreUnlocked: false, coreEntered: false,
        lastMessage: 'Your berth is behind you. The Wake is open.',
      } } : {}),
    };
  }

  function currentScene(state) {
    if (!state || !Number.isInteger(state.sceneIndex)) {
      throw new Error('FIRST_WAKE_OPENING_STATE_REQUIRED');
    }
    return SCENES[Math.min(state.sceneIndex, SCENES.length - 1)];
  }

  function tickPresentation(state, ticks) {
    if (!state || state.complete) return 0;
    const delta = Number.isFinite(ticks) ? Math.max(0, ticks) : 1;
    state.presentationTicks = (state.presentationTicks || 0) + delta;
    if (state.wakeExploration) {
      const e = state.wakeExploration;
      e.moving = isWakeExplorationActive(state) && state.presentationTicks < e.movingUntilTick;
    }
    return state.presentationTicks;
  }

  function canAdvancePresentation(state) {
    if (!state || state.complete) return false;
    const scene = currentScene(state);
    const minimumTicks = Number.isFinite(scene.minimumTicks) ? scene.minimumTicks : 0;
    return (state.presentationTicks || 0) >= minimumTicks;
  }

  function advance(state) {
    if (!state || state.complete) return { state, event: null };
    const scene = currentScene(state);
    if (state.wakeExploration && scene.sequence >= 5 && scene.sequence <= 8) {
      if (!state.wakeExploration.active) {
        state.wakeExploration.active = true;
        state.wakeExploration.moving = false;
        state.wakeExploration.movingUntilTick = 0;
        state.wakeExploration.lastMessage = scene.lines[0] || '';
        return { state, event: Object.freeze({ type: 'exploration-started' }) };
      }
      if (!canAdvanceWake(state)) {
        return { state, event: Object.freeze({ type: 'interaction-required', interaction: scene.id }) };
      }
      state.wakeExploration.active = false;
      state.wakeExploration.moving = false;
      state.wakeExploration.movingUntilTick = 0;
    }
    const event = scene.joinCharacterId && !state.appliedJoinIds.includes(scene.joinCharacterId)
      ? Object.freeze({ type: 'party-join', characterId: scene.joinCharacterId })
      : null;

    if (event) state.appliedJoinIds.push(event.characterId);

    if (state.sceneIndex >= SCENES.length - 1) {
      state.complete = true;
      return { state, event: event || Object.freeze({ type: 'opening-complete' }) };
    }

    state.sceneIndex += 1;
    state.presentationTicks = 0;
    return { state, event };
  }

  // Wake-only recovery from unmerged #258; current scene records/clock stay authoritative.
  function isWakeExplorationActive(state) {
    if (!state || state.complete || !state.wakeExploration || !state.wakeExploration.active) return false;
    const sequence = currentScene(state).sequence;
    return sequence >= 5 && sequence <= 8;
  }

  function canAdvanceWake(state) {
    if (!isWakeExplorationActive(state)) return false;
    const e = state.wakeExploration;
    const field = { lyra_family: 'anomalyTriggered', lyra_join: 'wrongSongAcknowledged',
      ionia_practical: 'ioniaFound', core_walk: 'coreEntered' }[currentScene(state).id];
    return Boolean(field && e[field]);
  }

  const WAKE_BOUNDS = Object.freeze({ minX: 1, maxX: 14, minY: 1, maxY: 7 });
  const WAKE_HOTSPOTS = Object.freeze({
    berth: Object.freeze({ id: 'berth', x: 3, y: 5, kind: 'optional' }),
    talen_art: Object.freeze({ id: 'talen_art', x: 4, y: 6, kind: 'optional' }),
    lyra: Object.freeze({ id: 'lyra', x: 7, y: 3, kind: 'character' }),
    route_chart: Object.freeze({ id: 'route_chart', x: 5, y: 2, kind: 'structural' }),
    ionia: Object.freeze({ id: 'ionia', x: 12, y: 2, kind: 'character' }),
    resonant_wall: Object.freeze({ id: 'resonant_wall', x: 9, y: 6, kind: 'frequency' }),
    telemetry: Object.freeze({ id: 'telemetry', x: 11, y: 5, kind: 'systems' }),
    core_door: Object.freeze({ id: 'core_door', x: 13, y: 5, kind: 'threshold' }),
  });

  function requireWakeExploration(state) {
    if (!state || !state.wakeExploration) throw new Error('FIRST_WAKE_EXPLORATION_STATE_REQUIRED');
    return state.wakeExploration;
  }

  function wakeZone(x, y) {
    if (x <= 4 && y >= 4) return 'berth';
    if (x <= 5 && y <= 3) return 'shared-table';
    if (x >= 6 && x <= 8 && y <= 4) return 'lyra-space';
    if (x >= 10 && y <= 3) return 'navigation';
    if (x >= 7 && x <= 11 && y >= 5) return 'maintenance';
    if (x >= 12 && y >= 4) return 'core-approach';
    return 'passage';
  }

  function nearbyWakeHotspot(state, maxDistance) {
    const e = requireWakeExploration(state);
    const limit = Number.isFinite(maxDistance) ? maxDistance : 1;
    let best = null;
    let bestDist = Infinity;
    Object.keys(WAKE_HOTSPOTS).forEach(id => {
      const spot = WAKE_HOTSPOTS[id];
      const d = Math.abs(spot.x - e.x) + Math.abs(spot.y - e.y);
      if (d <= limit && d < bestDist) {
        best = spot;
        bestDist = d;
      }
    });
    return best;
  }

  function maybeTriggerWrongSong(state, reason) {
    const e = requireWakeExploration(state);
    const scene = currentScene(state);
    if (scene.id !== 'lyra_family' || e.anomalyTriggered) return null;

    const distinctZones = new Set(e.visited).size;
    const contextualInteraction = e.interactions.includes('lyra') ||
      e.interactions.includes('route_chart') ||
      e.interactions.includes('resonant_wall');

    if (reason === 'resonant_wall' || reason === 'route_chart' ||
        (contextualInteraction && e.steps >= 4) ||
        (distinctZones >= 3 && e.steps >= 8)) {
      e.anomalyTriggered = true;
      e.lastMessage = 'The Wake falls out of rhythm.';
      return Object.freeze({ type: 'wrong-song-triggered' });
    }
    return null;
  }

  function moveWake(state, dx, dy) {
    if (!isWakeExplorationActive(state)) return { state, moved: false, event: null };
    const e = requireWakeExploration(state);

    const sx = Number.isFinite(dx) ? Math.sign(dx) : 0;
    const sy = Number.isFinite(dy) ? Math.sign(dy) : 0;
    if (sx === 0 && sy === 0) return { state, moved: false, event: null };

    const nextX = Math.max(WAKE_BOUNDS.minX, Math.min(WAKE_BOUNDS.maxX, e.x + sx));
    const nextY = Math.max(WAKE_BOUNDS.minY, Math.min(WAKE_BOUNDS.maxY, e.y + sy));
    if (nextX === e.x && nextY === e.y) return { state, moved: false, event: null };
    const horizontalMove = nextX !== e.x;
    e.x = nextX;
    e.y = nextY;
    if (horizontalMove) e.facing = sx < 0 ? 'left' : 'right';
    e.moving = true;
    e.movingUntilTick = state.presentationTicks + WALK_PULSE_TICKS;
    e.steps += 1;
    const zone = wakeZone(e.x, e.y);
    if (!e.visited.includes(zone)) e.visited.push(zone);
    e.lastMessage = zone === 'core-approach' && !e.coreUnlocked
      ? 'The Core route is sealed.'
      : 'You move through the Wake.';

    return { state, moved: true, event: maybeTriggerWrongSong(state, 'movement') };
  }

  function interactWake(state) {
    if (!isWakeExplorationActive(state)) return { state, event: null, hotspot: null };
    const e = requireWakeExploration(state);
    const scene = currentScene(state);

    const spot = nearbyWakeHotspot(state, 1);
    if (!spot) {
      e.lastMessage = 'Nothing here demands your attention.';
      return { state, event: Object.freeze({ type: 'ambient-interaction' }), hotspot: null };
    }

    if (!e.interactions.includes(spot.id)) e.interactions.push(spot.id);

    if (scene.id === 'lyra_family') {
      const messages = {
        berth: 'Your bag is still only half unpacked.',
        talen_art: 'Talen has made the Wake much larger in the drawing than it really is.',
        lyra: 'Lyra is sorting supplies. She pauses once, listening, then keeps working.',
        route_chart: 'Several familiar lanes are crossed out. One old line does not quite meet itself.',
        ionia: 'Ionia is buried in navigation and repair figures.',
        resonant_wall: 'A thin vibration runs against the ship\'s normal rhythm.',
        telemetry: 'The panel disagrees with the room temperature by three degrees.',
        core_door: 'The Core route is still sealed.',
      };
      e.lastMessage = messages[spot.id] || 'The Wake feels inherited rather than settled.';
      const trigger = maybeTriggerWrongSong(state, spot.id);
      return { state, event: trigger || Object.freeze({ type: 'optional-discovery', id: spot.id }), hotspot: spot };
    }

    if (scene.id === 'lyra_join') {
      if (spot.id !== 'lyra') {
        e.lastMessage = 'Whatever is wrong, Lyra noticed it too. Find her.';
        return { state, event: Object.freeze({ type: 'wrong-song-seek-lyra' }), hotspot: spot };
      }
      e.wrongSongAcknowledged = true;
      e.lastMessage = 'LYRA: You heard that too?  ENDER: Not exactly.';
      return { state, event: Object.freeze({ type: 'wrong-song-acknowledged' }), hotspot: spot };
    }

    if (scene.id === 'ionia_practical') {
      if (spot.id !== 'ionia') {
        e.lastMessage = 'Find Ionia. She needs to see what the Core is doing.';
        return { state, event: Object.freeze({ type: 'seek-ionia' }), hotspot: spot };
      }
      e.ioniaFound = true;
      e.lastMessage = 'IONIA: Core load just moved twelve percent. That keeps the rooms warm.';
      return { state, event: Object.freeze({ type: 'ionia-found' }), hotspot: spot };
    }

    if (scene.id === 'core_walk') {
      const clueMap = {
        route_chart: 'structural',
        resonant_wall: 'frequency',
        telemetry: 'systems',
      };
      const clue = clueMap[spot.id];
      if (clue) {
        if (!e.clues.includes(clue)) e.clues.push(clue);
        e.coreUnlocked = e.clues.length >= 2;
        e.lastMessage = clue === 'structural'
          ? 'Ender maps a relation that should not close, but does.'
          : clue === 'frequency'
            ? 'Lyra isolates a harmonic beneath the Wake\'s normal song.'
            : 'Ionia finds telemetry that contradicts the ship\'s physical state.';
        return {
          state,
          event: Object.freeze({ type: 'investigation-clue', clue, count: e.clues.length, coreUnlocked: e.coreUnlocked }),
          hotspot: spot,
        };
      }

      if (spot.id === 'core_door') {
        if (!e.coreUnlocked) {
          e.lastMessage = 'The Core route stays sealed. You need more than one way of seeing the problem.';
          return { state, event: Object.freeze({ type: 'core-locked', clueCount: e.clues.length }), hotspot: spot };
        }
        e.coreEntered = true;
        e.lastMessage = 'The household sounds fall away behind you.';
        return { state, event: Object.freeze({ type: 'core-threshold' }), hotspot: spot };
      }

      e.lastMessage = 'Useful context, but not the evidence you need.';
      return { state, event: Object.freeze({ type: 'optional-discovery', id: spot.id }), hotspot: spot };
    }

    return { state, event: null, hotspot: spot };
  }

  function wakeExplorationView(state) {
    const e = requireWakeExploration(state);
    const scene = currentScene(state);
    return Object.freeze({
      x: e.x,
      y: e.y,
      zone: wakeZone(e.x, e.y),
      steps: e.steps,
      visited: e.visited.slice(),
      interactions: e.interactions.slice(),
      clues: e.clues.slice(),
      anomalyTriggered: e.anomalyTriggered,
      wrongSongAcknowledged: e.wrongSongAcknowledged,
      ioniaFound: e.ioniaFound,
      coreUnlocked: e.coreUnlocked,
      coreEntered: e.coreEntered,
      lastMessage: e.lastMessage,
      objective: scene.id === 'lyra_family'
        ? 'Explore the Wake. Get settled.'
        : scene.id === 'lyra_join'
          ? 'Find Lyra.'
          : scene.id === 'ionia_practical'
            ? 'Find Ionia.'
            : scene.id === 'core_walk'
              ? (e.coreUnlocked ? 'The Core route is open.' : 'Investigate the anomaly: ' + e.clues.length + ' / 2 required clues.')
              : '',
    });
  }

  function expectedPartyIds(state) {
    return currentScene(state).activePartyIds.slice();
  }

  validate();

  return Object.freeze({
    VERSION,
    SCENES,
    validate,
    createState,
    currentScene,
    tickPresentation,
    canAdvancePresentation,
    advance,
    expectedPartyIds,
    isWakeExplorationActive,
    canAdvanceWake,
    moveWake,
    interactWake,
    wakeExplorationView,
    nearbyWakeHotspot,
  });
});
