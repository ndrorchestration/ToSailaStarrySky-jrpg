/* ============================================================
   Aetherwake JRPG — Magic Domain Definitions v0.1
   modules/magic-defs.js

   Design-contract registry. This file does NOT make the listed
   domains executable in the preservation runtime. Runtime admission
   remains fail-closed until abilities/effects are implemented.
   ============================================================ */

(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherwakeMagicDefs = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  const MASTERY_RANKS = Object.freeze({
    1: Object.freeze({ label: 'Initiate', compressedTier: 1, purpose: 'foundation' }),
    2: Object.freeze({ label: 'Adept', compressedTier: 1, purpose: 'application' }),
    3: Object.freeze({ label: 'Specialist', compressedTier: 2, purpose: 'identity' }),
    4: Object.freeze({ label: 'Master', compressedTier: 2, purpose: 'advanced-synergy' }),
    5: Object.freeze({ label: 'Grandmaster', compressedTier: 3, purpose: 'transformation' })
  });

  const ELEMENTAL_TREES = Object.freeze({
    fire: Object.freeze({
      id: 'fire', name: 'Fire', tier: 'primal', verb: 'transform',
      governs: ['heat', 'combustion', 'ignition', 'thermal transfer'],
      branches: ['ash-smoke', 'radiant-heat'],
      ranks: ['Spark', 'Flame', 'Inferno', 'Furnace', 'Conflagration']
    }),
    water: Object.freeze({
      id: 'water', name: 'Water', tier: 'primal', verb: 'flow',
      governs: ['liquid', 'moisture', 'pressure', 'cleansing', 'phase-change'],
      branches: ['mist', 'steam', 'pressure', 'buoyancy'],
      ranks: ['Flow', 'Current', 'Pressure', 'Deep Tide', 'Dominion']
    }),
    air: Object.freeze({
      id: 'air', name: 'Air', tier: 'primal', verb: 'move',
      governs: ['airflow', 'lift', 'pressure-gradient', 'vacuum', 'trajectory'],
      branches: ['vacuum', 'gale', 'lift'],
      ranks: ['Breeze', 'Wind', 'Gale', 'Atmosphere', 'Sky Dominion']
    }),
    earth: Object.freeze({
      id: 'earth', name: 'Earth', tier: 'primal', verb: 'form',
      governs: ['stone', 'soil', 'mineral', 'sand-dust', 'structure', 'density'],
      branches: ['sand-dust', 'magma', 'glass-vitrification', 'seismic'],
      ranks: ['Stone', 'Masonry', 'Fault', 'Bastion', 'Mountain']
    }),
    frost: Object.freeze({
      id: 'frost', name: 'Frost', tier: 'advanced', verb: 'preserve',
      requires: Object.freeze([{ tree: 'water', rank: 2 }]),
      governs: ['heat-extraction', 'ice', 'preservation', 'brittleness'],
      ranks: ['Chill', 'Ice', 'Brittle', 'Glacial', 'Deep Freeze']
    }),
    lightning: Object.freeze({
      id: 'lightning', name: 'Lightning', tier: 'advanced', verb: 'charge',
      requires: Object.freeze([{ tree: 'air', rank: 2 }]),
      governs: ['charge', 'current', 'conductivity', 'electromagnetism'],
      ranks: ['Static', 'Arc', 'Circuit', 'Field', 'Thunder']
    }),
    crystal: Object.freeze({
      id: 'crystal', name: 'Crystal', tier: 'advanced', verb: 'order',
      requires: Object.freeze([{ tree: 'earth', rank: 2 }]),
      governs: ['crystal-growth', 'refraction', 'resonance', 'storage', 'lattice'],
      ranks: ['Shard', 'Facet', 'Lattice', 'Array', 'Cathedral']
    }),
    metal: Object.freeze({
      id: 'metal', name: 'Metal', tier: 'advanced', verb: 'forge',
      requires: Object.freeze([{ tree: 'earth', rank: 2 }]),
      governs: ['metal-shaping', 'alloy', 'magnetism', 'armor', 'conductivity'],
      ranks: ['Bend', 'Temper', 'Armory', 'Magnetic Field', 'Living Forge']
    }),
    plasma: Object.freeze({
      id: 'plasma', name: 'Plasma', tier: 'advanced', verb: 'ionize',
      requires: Object.freeze([{ tree: 'fire', rank: 4 }, { domain: 'aether', rank: 2 }]),
      governs: ['ionization', 'extreme-heat', 'charged-gas', 'high-energy-discharge'],
      ranks: ['Arc', 'Ion', 'Lance', 'Containment', 'Stellar']
    }),
    sonic: Object.freeze({
      id: 'sonic', name: 'Sonic', tier: 'advanced', verb: 'vibrate',
      requiresAny: Object.freeze([{ tree: 'air', rank: 2 }, { domain: 'resonance', rank: 2 }]),
      governs: ['physical-vibration', 'pressure-wave', 'acoustics', 'concussion', 'dampening'],
      excludes: ['metaphysical-harmonic-relationships'],
      ranks: ['Pulse', 'Frequency', 'Resonant Force', 'Standing Wave', 'World Chord']
    }),
    storm: Object.freeze({
      id: 'storm', name: 'Storm', tier: 'hybrid', verb: 'orchestrate',
      requires: Object.freeze([{ tree: 'air', rank: 3 }, { tree: 'lightning', rank: 3 }]),
      benefitsFrom: Object.freeze([{ tree: 'water', rank: 2 }]),
      governs: ['weather-system', 'rain', 'wind-field', 'atmospheric-charge', 'storm-front'],
      ranks: ['Tendency', 'Front', 'Storm Cell', 'Tempest', 'Sky Dominion']
    })
  });

  const NON_ELEMENTAL_DOMAINS = Object.freeze({
    aether: Object.freeze({ id:'aether', name:'Aether', status:'established', access:'specialized', verb:'channel', boundary:'raw external/world-accessible magical current; not generic mana' }),
    lumen: Object.freeze({ id:'lumen', name:'Lumen', status:'established', access:'specialized', verb:'illuminate', boundary:'light, radiance, optics and revelation; not Holy' }),
    resonance: Object.freeze({ id:'resonance', name:'Resonance / Harmonic', status:'established', access:'specialized', verb:'attune', boundary:'frequency relationships, synchronization and sympathetic magic; broader than Sonic' }),
    correspondence: Object.freeze({ id:'correspondence', name:'Correspondence', status:'established', access:'specialized', verb:'connect', boundary:'space, distance, adjacency, routing and location; not Time' }),
    arcane: Object.freeze({ id:'arcane', name:'Arcane', status:'established-family', access:'ordinary', verb:'encode', boundary:'formal magical structure, glyph, force and transformation logic' }),
    psychic: Object.freeze({ id:'psychic', name:'Psychic', status:'established-family', access:'ordinary', verb:'influence', boundary:'mind, perception, telepathy and telekinesis; not soul or fate' }),
    spirit: Object.freeze({ id:'spirit', name:'Spirit', status:'established-family', access:'ordinary', verb:'commune', boundary:'souls, spirits, wards and identity-after-body; not generic life energy' }),
    vital: Object.freeze({ id:'vital', name:'Vital', status:'proposed', access:'ordinary-later', verb:'cultivate', boundary:'life processes, growth, healing and ecology' }),
    entropy: Object.freeze({ id:'entropy', name:'Entropy', status:'proposed', access:'ordinary-later', verb:'degrade', boundary:'decay, dissipation, disorder and unmaking; not Shadow' }),
    umbral: Object.freeze({ id:'umbral', name:'Umbral / Shadow', status:'proposed', access:'ordinary-later', verb:'occlude', boundary:'shadow, concealment, absence, silhouettes and negative space; morally neutral' }),
    time: Object.freeze({ id:'time', name:'Time', status:'proposed-high-order', access:'rare', verb:'sequence', boundary:'bounded local timing, delay, haste, anchor and stasis; no casual history rewrite' }),
    fate: Object.freeze({ id:'fate', name:'Fate / Probability', status:'proposed-high-order', access:'rare', verb:'bias', boundary:'likelihood and branching possibility; not temporal flow or simple prediction' }),
    memory: Object.freeze({ id:'memory', name:'Memory', status:'proposed', access:'ordinary-later', verb:'recall', boundary:'stored experience, traces, echoes and remembrance; not Psychic mind control' }),
    covenant: Object.freeze({ id:'covenant', name:'Covenant', status:'proposed', access:'ordinary-later', verb:'bind', boundary:'oaths, reciprocal conditions, names, permissions and magical agreements' }),
    technomancy: Object.freeze({ id:'technomancy', name:'Technomancy / Aethercraft', status:'proposed', access:'ordinary-later', verb:'interface', boundary:'designed magical machinery, cores, circuits and instrumented spell systems' })
  });

  const METAPHYSICAL_MODIFIERS = Object.freeze([
    'sanctified', 'profaned', 'blessed', 'cursed', 'hallowed', 'blighted'
  ]);

  const EXCEPTIONAL_POWERS = Object.freeze({
    dreaming: Object.freeze({
      id:'dreaming', name:'Dreaming', access:'plot-bound', ordinaryLearnable:false,
      boundary:'exceptional dream-reality access; not part of the ordinary school catalog'
    })
  });

  const SYNERGY_THRESHOLDS = Object.freeze({
    '2+2': 'minor-interaction',
    '3+3': 'cross-school-art',
    '4+4': 'advanced-synergy-passive',
    '5+5': 'grand-synthesis-art'
  });

  const CROSS_MASTERY = Object.freeze([
    Object.freeze({ a:'storm', b:'lightning', behavior:'storm fields accumulate and route charge; lightning gains field-triggered strikes', grand:'Heavenbreak Tempest' }),
    Object.freeze({ a:'water', b:'frost', behavior:'Wet converts to Freeze more efficiently; ice structures gain fluid setup options', grand:'White-Tide Dominion' }),
    Object.freeze({ a:'air', b:'sonic', behavior:'pressure control extends wave range, cone shaping and sonic-boom thresholds', grand:'Skybreaker Chorus' }),
    Object.freeze({ a:'crystal', b:'resonance', behavior:'crystal lattices store, amplify and redistribute tuned magical frequencies', grand:'Harmonic Prism Array' }),
    Object.freeze({ a:'crystal', b:'lumen', behavior:'prisms split, route, focus and persist light effects', grand:'Cathedral of Light' }),
    Object.freeze({ a:'metal', b:'lightning', behavior:'metal marks create conductive networks, magnetic routing and equipment interactions', grand:'Crown of Induction' }),
    Object.freeze({ a:'earth', b:'fire', behavior:'unlocks magma and vitrification applications inside Earth rather than a separate tree', grand:'World-Furnace Fault' }),
    Object.freeze({ a:'umbral', b:'correspondence', behavior:'connected shadows become legal spatial endpoints under bounded conditions', grand:'Penumbra Meridian' }),
    Object.freeze({ a:'lumen', b:'umbral', behavior:'controls contrast, silhouette, eclipse and penumbra rather than moral opposition', grand:'Eclipse Domain' }),
    Object.freeze({ a:'time', b:'fate', behavior:'Time changes when; Fate changes likelihood; synthesis manipulates bounded windows of possibility', grand:'Moment of Many Roads' }),
    Object.freeze({ a:'psychic', b:'memory', behavior:'read, reconstruct and defend remembered experience without equating memory with obedience', grand:'Palace of Echoes' }),
    Object.freeze({ a:'spirit', b:'covenant', behavior:'wards and spirit links gain explicit consent, conditions, permissions and reciprocal costs', grand:'Living Accord' }),
    Object.freeze({ a:'vital', b:'fire', behavior:'heat accelerates growth or cauterizes at cost; misuse can Blight', grand:'Phoenix Garden' }),
    Object.freeze({ a:'vital', b:'water', behavior:'hydration, cleansing and growth fields reinforce restoration/ecology', grand:'Worldroot Spring' }),
    Object.freeze({ a:'aether', b:'plasma', behavior:'aether stabilizes high-energy ionized fields and containment', grand:'Aetheric Corona' }),
    Object.freeze({ a:'aether', b:'correspondence', behavior:'aether currents become routable spatial pathways', grand:'Songline Gate' }),
    Object.freeze({ a:'resonance', b:'correspondence', behavior:'frequency signatures identify and route effects through spatial links', grand:'Impossible Coordinate' })
  ]);

  const REACTION_STATES = Object.freeze([
    Object.freeze({ state:'wet', applied:'lightning', reaction:'conduct' }),
    Object.freeze({ state:'wet', applied:'frost', reaction:'freeze' }),
    Object.freeze({ state:'wet', applied:'fire', reaction:'flash-steam' }),
    Object.freeze({ state:'frozen', applied:'fire', reaction:'thermal-shock' }),
    Object.freeze({ state:'burning', applied:'water', reaction:'quench' }),
    Object.freeze({ state:'burning', applied:'air', reaction:'fan-flame' }),
    Object.freeze({ state:'metallic', applied:'lightning', reaction:'surge' }),
    Object.freeze({ state:'crystal', applied:'sonic', reaction:'harmonic-shatter' }),
    Object.freeze({ state:'wet-earth', applied:'earth', reaction:'mire' })
  ]);

  const ENVIRONMENT_CHANNELS = Object.freeze(['atmosphere', 'surface', 'temperature', 'charge']);

  function getTree(id) { return ELEMENTAL_TREES[id] || null; }
  function getDomain(id) { return NON_ELEMENTAL_DOMAINS[id] || null; }

  return Object.freeze({
    version: '0.1.0',
    runtimeStatus: 'DESIGN_CONTRACT_NOT_EXECUTABLE',
    MASTERY_RANKS,
    ELEMENTAL_TREES,
    NON_ELEMENTAL_DOMAINS,
    METAPHYSICAL_MODIFIERS,
    EXCEPTIONAL_POWERS,
    SYNERGY_THRESHOLDS,
    CROSS_MASTERY,
    REACTION_STATES,
    ENVIRONMENT_CHANNELS,
    getTree,
    getDomain
  });
});
