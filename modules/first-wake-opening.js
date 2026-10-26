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

  function createState() {
    validate();
    return {
      sceneIndex: 0,
      presentationTicks: 0,
      complete: false,
      appliedJoinIds: [],
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
  });
});
