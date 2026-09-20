/* ============================================================
   Aetherwake JRPG — First Wake provisional actor kits
   modules/first-wake-kits.js

   The roles and action ownership here are intentionally provisional.
   They describe the playable First Wake slice without claiming final
   jobs, schools, chronology, or resource canon for Lyra and Ionia.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherFirstWakeKits = api;
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const ROLES = Object.freeze({
    reader: Object.freeze({ id: 'reader', label: 'Reader', canonStatus: 'provisional' }),
    receiver: Object.freeze({ id: 'receiver', label: 'Receiver', canonStatus: 'provisional' }),
    anchor: Object.freeze({ id: 'anchor', label: 'Anchor', canonStatus: 'provisional' }),
  });

  const ACTORS = Object.freeze({
    ender: Object.freeze({
      id: 'ender',
      roleId: 'reader',
      actionIds: Object.freeze([
        'staffStrike', 'uncoverTruth', 'sharedDream', 'mycelialLedger', 'hold',
      ]),
    }),
    lyra: Object.freeze({
      id: 'lyra',
      roleId: 'receiver',
      actionIds: Object.freeze(['frequencyRead', 'echoRedirect', 'hold']),
      temporary: true,
      defaults: Object.freeze({
        vit: 9,
        maxVit: 9,
        echoes: 2,
        echoesMax: 2,
        aether: 4,
        aetherMax: 4,
        heat: 0,
        heatMax: 3,
        staffCharges: 1,
        maxStaffCharges: 1,
        level: 1,
        xp: 0,
        xpToNext: 50,
        wits: 2,
        presence: 1,
        spirit: 2,
        might: 0,
        grace: 1,
        scrap: 0,
      }),
    }),
    ionia: Object.freeze({
      id: 'ionia',
      roleId: 'anchor',
      actionIds: Object.freeze(['braceTheWake', 'routeCommand', 'hold']),
      temporary: true,
      defaults: Object.freeze({
        vit: 11,
        maxVit: 11,
        echoes: 2,
        echoesMax: 2,
        aether: 3,
        aetherMax: 3,
        heat: 0,
        heatMax: 3,
        staffCharges: 1,
        maxStaffCharges: 1,
        level: 1,
        xp: 0,
        xpToNext: 50,
        wits: 0,
        presence: 2,
        spirit: 1,
        might: 2,
        grace: 0,
        scrap: 0,
      }),
    }),
  });

  function validate() {
    const roleIds = Object.keys(ROLES);
    if (roleIds.join('|') !== 'reader|receiver|anchor') {
      throw new Error('FIRST_WAKE_ROLE_ORDER_INVALID');
    }

    const actorIds = Object.keys(ACTORS);
    if (actorIds.join('|') !== 'ender|lyra|ionia') {
      throw new Error('FIRST_WAKE_ACTOR_ORDER_INVALID');
    }

    actorIds.forEach(id => {
      const actor = ACTORS[id];
      if (actor.id !== id || !ROLES[actor.roleId]) {
        throw new Error('FIRST_WAKE_ACTOR_ROLE_INVALID:' + id);
      }
      if (!Array.isArray(actor.actionIds) || actor.actionIds.length < 1) {
        throw new Error('FIRST_WAKE_ACTOR_ACTIONS_INVALID:' + id);
      }
      if (new Set(actor.actionIds).size !== actor.actionIds.length) {
        throw new Error('FIRST_WAKE_ACTOR_ACTION_DUPLICATE:' + id);
      }
    });

    return true;
  }

  validate();

  return Object.freeze({
    version: 1,
    roles: ROLES,
    actors: ACTORS,
    validate,
  });
});
