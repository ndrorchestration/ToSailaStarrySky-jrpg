/* ============================================================
   Aetherwake JRPG — Party Combat Bridge (read-only Phase A)
   modules/party-combat-bridge.js

   Purpose:
   - expose the current three active roster records to combat as a validated
     read-only context;
   - preserve Ender as the only executable combat actor in this phase;
   - expose Lyra/Ionia temporary field-role action declarations without
     authorizing execution before complete outcome contracts exist.

   This module does not mutate party, combat, progression, or save state.
   ============================================================ */

(function (root, factory) {
  'use strict';

  const api = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherPartyCombatBridge = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null), function () {
  'use strict';

  const VERSION = '0.1.0';
  const MODE = 'read-only-three-character-context';
  const EXECUTABLE_STATUS = 'executable-lead';
  const STAGED_STATUS = 'declared-non-executable';
  const NON_EXECUTABLE_REASON = 'OUTCOME_CONTRACT_NOT_ESTABLISHED';

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function finiteOrNull(value) {
    return Number.isFinite(Number(value)) ? Number(value) : null;
  }

  function resourcePair(actor, currentKey, maxKey) {
    return {
      current: finiteOrNull(actor[currentKey]),
      max: finiteOrNull(actor[maxKey]),
    };
  }

  function requireFieldRole(fieldRoleDefs, templateId, actorId) {
    if (!fieldRoleDefs || typeof fieldRoleDefs.getById !== 'function') {
      throw new Error('PARTY_COMBAT_FIELD_ROLE_API_REQUIRED');
    }
    const role = fieldRoleDefs.getById(templateId);
    if (!role) {
      throw new Error('PARTY_COMBAT_UNKNOWN_FIELD_ROLE:' + actorId + ':' + templateId);
    }
    return role;
  }

  function createSnapshot(activeParty, fieldRoleDefs) {
    if (!Array.isArray(activeParty) || activeParty.length !== 3) {
      throw new Error('PARTY_COMBAT_ACTIVE_PARTY_LENGTH_MUST_BE_3');
    }

    const ids = activeParty.map(actor => actor && actor.id);
    if (ids.some(id => typeof id !== 'string' || !id)) {
      throw new Error('PARTY_COMBAT_ACTIVE_ID_REQUIRED');
    }
    if (new Set(ids).size !== ids.length) {
      throw new Error('PARTY_COMBAT_ACTIVE_IDS_MUST_BE_UNIQUE');
    }
    if (ids[0] !== 'ender') {
      throw new Error('PARTY_COMBAT_PHASE_A_LEAD_MUST_BE_ENDER');
    }
    if (activeParty.some(actor => actor.runtimeImplemented === false)) {
      throw new Error('PARTY_COMBAT_ACTIVE_MEMBER_NOT_IMPLEMENTED');
    }

    const members = activeParty.map((actor, index) => {
      const base = {
        index,
        id: actor.id,
        canonicalName: actor.canonicalName || actor.name || actor.id,
        name: actor.name || actor.canonicalName || actor.id,
        vit: finiteOrNull(actor.vit),
        maxVit: finiteOrNull(actor.maxVit),
        echoes: resourcePair(actor, 'echoes', 'echoesMax'),
        aether: resourcePair(actor, 'aether', 'aetherMax'),
        heat: resourcePair(actor, 'heat', 'heatMax'),
        mechanicsTemplateId: actor.mechanicsTemplateId || null,
        mechanicsTemplateName: actor.mechanicsTemplateName || null,
        implementationSource: actor.implementationSource || null,
      };

      if (index === 0) {
        return Object.assign(base, {
          execution: {
            status: EXECUTABLE_STATUS,
            reason: null,
          },
          declaredActions: [],
          fieldRole: null,
        });
      }

      if (!actor.mechanicsTemplateId) {
        throw new Error('PARTY_COMBAT_COMPANION_FIELD_ROLE_REQUIRED:' + actor.id);
      }
      const role = requireFieldRole(fieldRoleDefs, actor.mechanicsTemplateId, actor.id);

      return Object.assign(base, {
        execution: {
          status: STAGED_STATUS,
          reason: NON_EXECUTABLE_REASON,
        },
        fieldRole: {
          id: role.id,
          name: role.name,
          provenance: fieldRoleDefs.PROVENANCE || 'prototype-mechanics',
        },
        declaredActions: role.abilities.map(ability => ({
          id: ability.id,
          label: ability.label,
          stat: ability.stat,
          desc: ability.desc,
          executable: false,
          reason: NON_EXECUTABLE_REASON,
        })),
      });
    });

    const snapshot = {
      version: VERSION,
      mode: MODE,
      leadActorId: 'ender',
      executableActorIds: ['ender'],
      members,
    };

    validateSnapshot(snapshot);
    return clone(snapshot);
  }

  function validateSnapshot(snapshot) {
    if (!snapshot || typeof snapshot !== 'object') {
      throw new Error('PARTY_COMBAT_SNAPSHOT_REQUIRED');
    }
    if (snapshot.version !== VERSION || snapshot.mode !== MODE) {
      throw new Error('PARTY_COMBAT_SNAPSHOT_VERSION_OR_MODE_INVALID');
    }
    if (snapshot.leadActorId !== 'ender') {
      throw new Error('PARTY_COMBAT_SNAPSHOT_LEAD_INVALID');
    }
    if (!Array.isArray(snapshot.executableActorIds) ||
        snapshot.executableActorIds.join('|') !== 'ender') {
      throw new Error('PARTY_COMBAT_EXECUTABLE_ACTORS_INVALID');
    }
    if (!Array.isArray(snapshot.members) || snapshot.members.length !== 3) {
      throw new Error('PARTY_COMBAT_SNAPSHOT_MEMBER_COUNT_INVALID');
    }

    const ids = snapshot.members.map(member => member && member.id);
    if (new Set(ids).size !== 3 || ids.some(id => typeof id !== 'string' || !id)) {
      throw new Error('PARTY_COMBAT_SNAPSHOT_MEMBER_IDS_INVALID');
    }

    snapshot.members.forEach((member, index) => {
      if (!member.execution || typeof member.execution.status !== 'string') {
        throw new Error('PARTY_COMBAT_MEMBER_EXECUTION_STATUS_REQUIRED:' + index);
      }

      if (index === 0) {
        if (member.id !== 'ender' ||
            member.execution.status !== EXECUTABLE_STATUS ||
            !Array.isArray(member.declaredActions) ||
            member.declaredActions.length !== 0) {
          throw new Error('PARTY_COMBAT_LEAD_MEMBER_INVALID');
        }
        return;
      }

      if (member.execution.status !== STAGED_STATUS ||
          member.execution.reason !== NON_EXECUTABLE_REASON) {
        throw new Error('PARTY_COMBAT_COMPANION_EXECUTION_BOUNDARY_INVALID:' + member.id);
      }
      if (!member.fieldRole || typeof member.fieldRole.id !== 'string') {
        throw new Error('PARTY_COMBAT_COMPANION_FIELD_ROLE_INVALID:' + member.id);
      }
      if (!Array.isArray(member.declaredActions) || member.declaredActions.length !== 2) {
        throw new Error('PARTY_COMBAT_COMPANION_ACTION_DECLARATIONS_INVALID:' + member.id);
      }
      member.declaredActions.forEach(action => {
        if (action.executable !== false || action.reason !== NON_EXECUTABLE_REASON) {
          throw new Error('PARTY_COMBAT_COMPANION_ACTION_EXECUTION_LEAK:' + member.id + ':' + action.id);
        }
      });
    });

    return true;
  }

  return Object.freeze({
    VERSION,
    MODE,
    EXECUTABLE_STATUS,
    STAGED_STATUS,
    NON_EXECUTABLE_REASON,
    createSnapshot,
    validateSnapshot,
  });
});
