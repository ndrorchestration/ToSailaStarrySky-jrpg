/* ============================================================
   Aetherwake JRPG — First Wake Opening Runtime v0.4
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

  const VERSION = '0.4.0';

  const SCENES = Object.freeze([
    Object.freeze({
      id: 'arrival_horizon',
      sequence: 0,
      visual: 'dock-horizon',
      cinematic: true,
      minimumTicks: 75,
      title: 'WAKE DOCK — LOWER VERDANT REACH',
      speaker: null,
      lines: Object.freeze([
        'Dawn gathers beneath a sea of clouds.',
        'A small patched vessel hangs against a very large sky.',
      ]),
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'ender_arrives',
      sequence: 1,
      visual: 'arrival',
      cinematic: true,
      minimumTicks: 60,
      title: 'ARRIVAL',
      speaker: 'IONIA',
      lines: Object.freeze([
        'You said you could fix things.',
        'ENDER: I said I was willing to learn how.',
        "IONIA: Good. That's usually cheaper.",
      ]),
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'dock_walk',
      sequence: 2,
      visual: 'dock-walk',
      interactive: true,
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
      visual: 'berth',
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
      visual: 'talen',
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
      visual: 'household',
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
      id: 'wrong_song',
      sequence: 6,
      visual: 'wrong-song',
      title: 'THE WRONG SONG',
      speaker: 'LYRA',
      lines: Object.freeze([
        '...Did you hear that?',
        "ENDER: I didn't hear it.",
        'ENDER: But yes.',
        'A frequency distortion and a displaced spatial relation overlap.',
      ]),
      joinCharacterId: 'lyra',
      activePartyIds: Object.freeze(['ender']),
    }),
    Object.freeze({
      id: 'ionia_practical',
      sequence: 7,
      visual: 'practical',
      title: 'MAKE IT PRACTICAL',
      speaker: 'IONIA',
      lines: Object.freeze([
        'Core load just moved twelve percent.',
        "LYRA: That's not what I meant.",
        "IONIA: It's what keeps the rooms warm.",
      ]),
      activePartyIds: Object.freeze(['ender', 'lyra']),
    }),
    Object.freeze({
      id: 'core_walk',
      sequence: 8,
      visual: 'core-walk',
      title: 'TO THE CORE',
      speaker: null,
      lines: Object.freeze([
        'They pass the shared table, unreliable galley, and exposed conduit.',
        'A sealed Core-room door waits at the end of the passage.',
        'LYRA: This one listened back.',
      ]),
      activePartyIds: Object.freeze(['ender', 'lyra']),
    }),
    Object.freeze({
      id: 'first_wake_card',
      sequence: 9,
      visual: 'chapter',
      title: 'AETHERWAKE',
      subtitle: 'CHAPTER I — FIRST WAKE',
      speaker: null,
      lines: Object.freeze([
        'Geometry. Frequency. Failing instrumentation.',
        'Three ways of knowing face the same impossible signal.',
      ]),
      activePartyIds: Object.freeze(['ender', 'lyra']),
      chapterCard: true,
    }),
  ]);

  function validate() {
    if (SCENES.length !== 10) throw new Error('FIRST_WAKE_OPENING_SCENE_COUNT_DRIFT');
    SCENES.forEach((scene, index) => {
      if (scene.sequence !== index) throw new Error('FIRST_WAKE_OPENING_SEQUENCE_DRIFT:' + scene.id);
      if (!scene.id || !scene.title || !scene.visual) throw new Error('FIRST_WAKE_OPENING_SCENE_INVALID:' + index);
      if (scene.interactive && scene.id !== 'dock_walk') {
        throw new Error('FIRST_WAKE_OPENING_INTERACTIVE_DRIFT:' + scene.id);
      }
      if (scene.cinematic && (!Number.isInteger(scene.minimumTicks) || scene.minimumTicks < 1)) {
        throw new Error('FIRST_WAKE_OPENING_CINEMATIC_TIMING_INVALID:' + scene.id);
      }
      if (!['dock-horizon','arrival','dock-walk','berth','talen','household','wrong-song','practical','core-walk','chapter'].includes(scene.visual)) {
        throw new Error('FIRST_WAKE_OPENING_VISUAL_INVALID:' + scene.id);
      }
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

  function createState() {
    validate();
    return {
      sceneIndex: 0,
      complete: false,
      appliedJoinIds: [],
      sceneTicks: 0,
      dockWalk: {
        x: 0,
        max: 8,
        ready: false,
      },
    };
  }

  function currentScene(state) {
    if (!state || !Number.isInteger(state.sceneIndex)) {
      throw new Error('FIRST_WAKE_OPENING_STATE_REQUIRED');
    }
    return SCENES[Math.min(state.sceneIndex, SCENES.length - 1)];
  }

  function advance(state) {
    if (!state || state.complete) return { state, event: null };
    const scene = currentScene(state);
    if (scene.cinematic && state.sceneTicks < (scene.minimumTicks || 0)) {
      return {
        state,
        event: Object.freeze({ type: 'presentation-required', remainingTicks: (scene.minimumTicks || 0) - state.sceneTicks }),
      };
    }
    if (scene.interactive && (!state.dockWalk || !state.dockWalk.ready)) {
      return {
        state,
        event: Object.freeze({ type: 'interaction-required', interaction: 'dock-walk' }),
      };
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
    return { state, event };
  }

  function tickPresentation(state, ticks) {
    if (!state || state.complete) return state;
    const amount = Number.isFinite(ticks) ? Math.max(0, Math.floor(ticks)) : 1;
    state.sceneTicks += amount;
    return state;
  }

  function presentationReady(state) {
    if (!state || state.complete) return true;
    const scene = currentScene(state);
    return !scene.cinematic || state.sceneTicks >= (scene.minimumTicks || 0);
  }

  function moveDock(state, delta) {
    if (!state || !state.dockWalk) throw new Error('FIRST_WAKE_DOCK_WALK_STATE_REQUIRED');
    const scene = currentScene(state);
    if (!scene.interactive || scene.id !== 'dock_walk') {
      return { state, moved: false, ready: Boolean(state.dockWalk.ready) };
    }
    const step = Number.isFinite(delta) ? Math.sign(delta) : 0;
    if (step === 0) return { state, moved: false, ready: Boolean(state.dockWalk.ready) };
    state.dockWalk.x = Math.max(0, Math.min(state.dockWalk.max, state.dockWalk.x + step));
    state.dockWalk.ready = state.dockWalk.x >= state.dockWalk.max;
    return { state, moved: true, ready: state.dockWalk.ready };
  }

  function dockWalkProgress(state) {
    if (!state || !state.dockWalk) throw new Error('FIRST_WAKE_DOCK_WALK_STATE_REQUIRED');
    return state.dockWalk.max > 0 ? state.dockWalk.x / state.dockWalk.max : 1;
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
    advance,
    tickPresentation,
    presentationReady,
    moveDock,
    dockWalkProgress,
    expectedPartyIds,
  });
});
