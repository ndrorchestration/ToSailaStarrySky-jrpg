/* ============================================================
   Aetherwake JRPG — Magic Field & Reaction State v0.1
   modules/magic-field-reactions.js

   Pure immutable field/status-reaction model.
   This module previews and resolves design-state transitions only.
   It does NOT deal damage, alter combat turns, or authorize spells.
   ============================================================ */

(function (root, factory) {
  const defs = typeof module === 'object' && module.exports
    ? require('./magic-defs.js')
    : root.AetherwakeMagicDefs;
  const api = factory(defs);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherwakeMagicFieldReactions = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (defs) {
  'use strict';

  if (!defs) throw new Error('MAGIC_FIELD_REACTIONS_REQUIRES_MAGIC_DEFS');

  const STATE_DEFS = Object.freeze({
    wet: Object.freeze({ id:'wet', channel:'surface', family:'moisture' }),
    frozen: Object.freeze({ id:'frozen', channel:'temperature', family:'phase' }),
    burning: Object.freeze({ id:'burning', channel:'temperature', family:'combustion' }),
    metallic: Object.freeze({ id:'metallic', channel:'surface', family:'material' }),
    crystal: Object.freeze({ id:'crystal', channel:'surface', family:'material' }),
    charged: Object.freeze({ id:'charged', channel:'charge', family:'electrical' }),
    mist: Object.freeze({ id:'mist', channel:'atmosphere', family:'vapor' }),
    mire: Object.freeze({ id:'mire', channel:'surface', family:'terrain' }),
    brittle: Object.freeze({ id:'brittle', channel:'surface', family:'structural' }),
    'wet-earth': Object.freeze({ id:'wet-earth', channel:'surface', family:'terrain-setup' })
  });

  const REACTION_RULES = Object.freeze({
    conduct: Object.freeze({
      id:'conduct',
      when:Object.freeze({ state:'wet', applied:'lightning' }),
      remove:Object.freeze([]),
      add:Object.freeze(['charged']),
      intent:Object.freeze(['route-current','enable-chain-targeting'])
    }),
    freeze: Object.freeze({
      id:'freeze',
      when:Object.freeze({ state:'wet', applied:'frost' }),
      remove:Object.freeze(['wet']),
      add:Object.freeze(['frozen']),
      intent:Object.freeze(['lockdown','brittleness-setup'])
    }),
    'flash-steam': Object.freeze({
      id:'flash-steam',
      when:Object.freeze({ state:'wet', applied:'fire' }),
      remove:Object.freeze(['wet']),
      add:Object.freeze(['mist']),
      intent:Object.freeze(['phase-conversion','visibility-pressure-setup'])
    }),
    'thermal-shock': Object.freeze({
      id:'thermal-shock',
      when:Object.freeze({ state:'frozen', applied:'fire' }),
      remove:Object.freeze(['frozen']),
      add:Object.freeze(['brittle']),
      intent:Object.freeze(['break-spike','phase-break'])
    }),
    quench: Object.freeze({
      id:'quench',
      when:Object.freeze({ state:'burning', applied:'water' }),
      remove:Object.freeze(['burning']),
      add:Object.freeze(['wet']),
      intent:Object.freeze(['extinguish','reset-temperature'])
    }),
    'fan-flame': Object.freeze({
      id:'fan-flame',
      when:Object.freeze({ state:'burning', applied:'air' }),
      remove:Object.freeze([]),
      add:Object.freeze([]),
      intent:Object.freeze(['spread-combustion','increase-area-risk'])
    }),
    surge: Object.freeze({
      id:'surge',
      when:Object.freeze({ state:'metallic', applied:'lightning' }),
      remove:Object.freeze([]),
      add:Object.freeze(['charged']),
      intent:Object.freeze(['conductive-routing','magnetic-setup'])
    }),
    'harmonic-shatter': Object.freeze({
      id:'harmonic-shatter',
      when:Object.freeze({ state:'crystal', applied:'sonic' }),
      remove:Object.freeze([]),
      add:Object.freeze(['brittle']),
      intent:Object.freeze(['structural-break','fragmentation-setup'])
    }),
    mire: Object.freeze({
      id:'mire',
      when:Object.freeze({ state:'wet-earth', applied:'earth' }),
      remove:Object.freeze(['wet-earth']),
      add:Object.freeze(['mire']),
      intent:Object.freeze(['movement-control','terrain-lock'])
    })
  });

  function validateStateId(id) {
    if (!STATE_DEFS[id]) throw new Error('MAGIC_FIELD_UNKNOWN_STATE:' + id);
    return id;
  }

  function validateAppliedMagic(id) {
    if (!defs.ELEMENTAL_TREES[id]) {
      throw new Error('MAGIC_FIELD_UNKNOWN_APPLIED_TREE:' + id);
    }
    return id;
  }

  function normalizeStates(states) {
    if (!Array.isArray(states)) throw new Error('MAGIC_FIELD_STATES_MUST_BE_ARRAY');
    const unique = [];
    const seen = new Set();
    for (const id of states) {
      validateStateId(id);
      if (!seen.has(id)) {
        seen.add(id);
        unique.push(id);
      }
    }
    return Object.freeze(unique);
  }

  function createState(states) {
    return Object.freeze({
      version:'0.1.0',
      tags:normalizeStates(states || [])
    });
  }

  function withState(fieldState, id) {
    validateStateId(id);
    const current = createState(fieldState && fieldState.tags ? fieldState.tags : []);
    if (current.tags.includes(id)) return current;
    return createState(current.tags.concat(id));
  }

  function withoutState(fieldState, id) {
    validateStateId(id);
    const current = createState(fieldState && fieldState.tags ? fieldState.tags : []);
    return createState(current.tags.filter(tag => tag !== id));
  }

  function getMatchingReactions(fieldState, appliedTree) {
    validateAppliedMagic(appliedTree);
    const current = createState(fieldState && fieldState.tags ? fieldState.tags : []);
    return Object.freeze(Object.values(REACTION_RULES)
      .filter(rule => rule.when.applied === appliedTree && current.tags.includes(rule.when.state)));
  }

  function preview(fieldState, appliedTree) {
    const matches = getMatchingReactions(fieldState, appliedTree);
    return Object.freeze(matches.map(rule => Object.freeze({
      reaction:rule.id,
      triggerState:rule.when.state,
      appliedTree,
      remove:rule.remove,
      add:rule.add,
      intent:rule.intent
    })));
  }

  function resolveDesignState(fieldState, appliedTree) {
    const current = createState(fieldState && fieldState.tags ? fieldState.tags : []);
    const matches = getMatchingReactions(current, appliedTree);
    let tags = current.tags.slice();

    for (const rule of matches) {
      tags = tags.filter(tag => !rule.remove.includes(tag));
      for (const tag of rule.add) {
        if (!tags.includes(tag)) tags.push(tag);
      }
    }

    return Object.freeze({
      runtimeStatus:'DESIGN_STATE_ONLY',
      before:current,
      appliedTree,
      reactions:Object.freeze(matches.map(rule => rule.id)),
      after:createState(tags)
    });
  }

  function ruleFor(reactionId) {
    return REACTION_RULES[reactionId] || null;
  }

  // Cross-check against the canonical lightweight reaction list in magic-defs.
  for (const seed of defs.REACTION_STATES) {
    const rule = REACTION_RULES[seed.reaction];
    if (!rule ||
        rule.when.state !== seed.state ||
        rule.when.applied !== seed.applied) {
      throw new Error('MAGIC_FIELD_REACTION_DRIFT:' + seed.reaction);
    }
  }

  return Object.freeze({
    version:'0.1.0',
    runtimeStatus:'DESIGN_STATE_ONLY',
    STATE_DEFS,
    REACTION_RULES,
    createState,
    withState,
    withoutState,
    getMatchingReactions,
    preview,
    resolveDesignState,
    ruleFor
  });
});
