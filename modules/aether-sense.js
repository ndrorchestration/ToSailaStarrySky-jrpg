/* ============================================================
   Aetherwake JRPG — Aether Sense Exploration Runtime
   modules/aether-sense.js

   First executable magic technique:
   - Ender-only through explicit starting ownership;
   - exploration-only in this slice;
   - zero resource cost;
   - deterministic, read-only scene sensing;
   - no quest completion, combat mutation, or persistence changes.
   ============================================================ */

(function (root, factory) {
  'use strict';

  let masteryDefs = null;
  let magicAccess = null;

  if (typeof module === 'object' && module.exports) {
    masteryDefs = require('./mastery-defs.js');
    magicAccess = require('./magic-access.js');
  } else if (root) {
    masteryDefs = root.AetherMasteryDefs;
    magicAccess = root.AetherMagicAccess;
  }

  const api = factory(masteryDefs, magicAccess);

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  }
  if (root) {
    root.AetherSense = api;
  }
})(typeof window !== 'undefined' ? window :
   (typeof globalThis !== 'undefined' ? globalThis : null),
function (masteryDefs, magicAccess) {
  'use strict';

  if (!masteryDefs) throw new Error('AETHER_SENSE_REQUIRES_MASTERY_DEFS');
  if (!magicAccess) throw new Error('AETHER_SENSE_REQUIRES_MAGIC_ACCESS');

  const VERSION = '0.1.0';
  const SPELL_ID = 'aetherSense';
  const CHARACTER_ID = 'ender';
  const RESOURCE_COST = 0;

  const INTENSITY = Object.freeze({
    FAINT: 'faint',
    MODERATE: 'moderate',
    STRONG: 'strong',
    UNSTABLE: 'unstable',
  });

  const SIGNATURE_KIND = Object.freeze({
    CORE: 'core',
    ENTITY: 'entity',
    FIELD: 'field',
    LEAK: 'leak',
    DEVICE: 'device',
  });

  function clone(value) {
    return value == null ? value : JSON.parse(JSON.stringify(value));
  }

  function finiteCoordinate(value, label) {
    if (!Number.isFinite(value)) {
      throw new Error('AETHER_SENSE_' + label.toUpperCase() + '_INVALID');
    }
    return value;
  }

  function validateOrigin(origin) {
    if (!origin || typeof origin !== 'object') {
      throw new Error('AETHER_SENSE_ORIGIN_REQUIRED');
    }
    finiteCoordinate(origin.x, 'origin_x');
    finiteCoordinate(origin.y, 'origin_y');
    return true;
  }

  function validateSignature(signature) {
    if (!signature || typeof signature !== 'object') {
      throw new Error('AETHER_SENSE_SIGNATURE_INVALID');
    }
    if (typeof signature.id !== 'string' || signature.id.length === 0) {
      throw new Error('AETHER_SENSE_SIGNATURE_ID_INVALID');
    }
    if (typeof signature.label !== 'string' || signature.label.length === 0) {
      throw new Error('AETHER_SENSE_SIGNATURE_LABEL_INVALID:' + signature.id);
    }
    if (!Object.values(SIGNATURE_KIND).includes(signature.kind)) {
      throw new Error('AETHER_SENSE_SIGNATURE_KIND_INVALID:' + signature.id);
    }
    if (!Object.values(INTENSITY).includes(signature.intensity)) {
      throw new Error('AETHER_SENSE_SIGNATURE_INTENSITY_INVALID:' + signature.id);
    }
    finiteCoordinate(signature.x, 'signature_x');
    finiteCoordinate(signature.y, 'signature_y');
    return true;
  }

  function directionFromDelta(dx, dy) {
    if (dx === 0 && dy === 0) return 'here';
    if (Math.abs(dx) >= Math.abs(dy)) {
      return dx > 0 ? 'east' : 'west';
    }
    return dy > 0 ? 'south' : 'north';
  }

  function scan(characterId, origin, signatures) {
    const admission = magicAccess.getFoundationSpellStudyAdmission(
      characterId,
      SPELL_ID
    );

    if (!admission.canUse) {
      return {
        ok: false,
        characterId,
        spellId: SPELL_ID,
        resourceCost: RESOURCE_COST,
        reason: admission.reason,
        detections: [],
      };
    }

    validateOrigin(origin);
    if (!Array.isArray(signatures)) {
      throw new Error('AETHER_SENSE_SIGNATURES_MUST_BE_ARRAY');
    }

    const seen = new Set();
    const detections = signatures
      .filter(signature => signature && signature.active !== false)
      .map(signature => {
        validateSignature(signature);
        if (seen.has(signature.id)) {
          throw new Error('AETHER_SENSE_SIGNATURE_DUPLICATE:' + signature.id);
        }
        seen.add(signature.id);

        const dx = signature.x - origin.x;
        const dy = signature.y - origin.y;
        const distance = Math.abs(dx) + Math.abs(dy);

        return {
          id: signature.id,
          label: signature.label,
          kind: signature.kind,
          intensity: signature.intensity,
          x: signature.x,
          y: signature.y,
          distance,
          direction: directionFromDelta(dx, dy),
          note: typeof signature.note === 'string' ? signature.note : null,
        };
      })
      .sort((a, b) => {
        if (a.distance !== b.distance) return a.distance - b.distance;
        return a.id.localeCompare(b.id);
      });

    return {
      ok: true,
      characterId,
      spellId: SPELL_ID,
      resourceCost: RESOURCE_COST,
      origin: { x: origin.x, y: origin.y },
      detections,
    };
  }

  function summarize(result) {
    if (!result || !result.ok) {
      return 'Aether Sense cannot resolve: ' +
        ((result && result.reason) || 'unknown reason') + '.';
    }
    if (result.detections.length === 0) {
      return 'Aether Sense: no explicit Aether signatures answer.';
    }

    return 'Aether Sense: ' + result.detections.map(detection =>
      detection.label + ' [' + detection.intensity + ', ' +
      detection.direction + ', ' + detection.distance + ' tiles]'
    ).join('; ') + '.';
  }

  function validate() {
    const spell = masteryDefs.getFoundationSpellDefinition(SPELL_ID);
    if (!spell) throw new Error('AETHER_SENSE_DEFINITION_MISSING');
    if (spell.designStatus !== masteryDefs.DESIGN_STATUS.ESTABLISHED) {
      throw new Error('AETHER_SENSE_DESIGN_NOT_ESTABLISHED');
    }
    if (spell.runtimeStatus !== masteryDefs.RUNTIME_STATUS.INTEGRATED) {
      throw new Error('AETHER_SENSE_RUNTIME_NOT_INTEGRATED');
    }
    if (spell.resourceBinding !== masteryDefs.RESOURCE_BINDING.NONE ||
        spell.resourceCost !== null) {
      throw new Error('AETHER_SENSE_RESOURCE_BOUNDARY_INVALID');
    }
    if (spell.startingCharacterIds.join('|') !== CHARACTER_ID) {
      throw new Error('AETHER_SENSE_STARTING_OWNER_INVALID');
    }

    const admission = magicAccess.getFoundationSpellStudyAdmission(
      CHARACTER_ID,
      SPELL_ID
    );
    if (!admission.canStudy || !admission.canUse || admission.reason !== 'ok') {
      throw new Error('AETHER_SENSE_ADMISSION_INVALID');
    }

    const probe = scan(
      CHARACTER_ID,
      { x: 0, y: 0 },
      [{
        id: 'probe',
        label: 'Probe',
        kind: SIGNATURE_KIND.DEVICE,
        intensity: INTENSITY.FAINT,
        x: 2,
        y: -1,
      }]
    );
    if (!probe.ok ||
        probe.detections.length !== 1 ||
        probe.detections[0].distance !== 3 ||
        probe.detections[0].direction !== 'east') {
      throw new Error('AETHER_SENSE_PROBE_INVALID');
    }

    return true;
  }

  validate();

  return Object.freeze({
    VERSION,
    SPELL_ID,
    CHARACTER_ID,
    RESOURCE_COST,
    INTENSITY,
    SIGNATURE_KIND,
    scan,
    summarize,
    validate,
    clone,
  });
});
