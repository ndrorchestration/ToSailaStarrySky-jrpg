/* ============================================================
   Aetherwake JRPG — Non-Elemental Spell Trees v0.1
   modules/non-elemental-spell-trees.js

   Status-preserving 1–5 design catalogs for all ordinary/rare
   non-elemental domains registered in magic-defs.js.
   No entry becomes canon or executable merely by appearing here.
   ============================================================ */

(function (root, factory) {
  const defs = typeof module === 'object' && module.exports
    ? require('./magic-defs.js')
    : root.AetherwakeMagicDefs;
  const api = factory(defs);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherwakeNonElementalSpellTrees = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (defs) {
  'use strict';
  if (!defs) throw new Error('NON_ELEMENTAL_SPELL_TREES_REQUIRE_MAGIC_DEFS');

  function spell(id, name, roles, intent, extra) {
    return Object.freeze(Object.assign({
      id, name, roles:Object.freeze(roles.slice()), intent
    }, extra || {}));
  }
  function rank(label, spells) {
    return Object.freeze({ label, spells:Object.freeze(spells.slice()) });
  }
  function domain(domainId, fantasy, signature, labels, rows) {
    const def = defs.NON_ELEMENTAL_DOMAINS[domainId];
    if (!def) throw new Error('UNKNOWN_NON_ELEMENTAL_DOMAIN:' + domainId);
    const ranks = {};
    for (let i=0;i<5;i+=1) {
      ranks[i+1] = rank(labels[i], rows[i]);
    }
    return Object.freeze({
      domainId,
      status:def.status,
      access:def.access,
      boundary:def.boundary,
      fantasy,
      signature,
      ranks:Object.freeze(ranks)
    });
  }

  const TREES = Object.freeze({
    aether: domain('aether',
      'world-current channeler and magical power router',
      'sense current → draw safely → route/stabilize → network → world-current grand control',
      ['Sense','Channel','Route','Confluence','World Current'],[
      [spell('aether.current_sense','Current Sense',['utility','exploration'],'detect nearby aether flow, pressure, blockage, and direction'),
       spell('aether.spark_draw','Spark Draw',['resource','support'],'draw a small bounded amount of ambient aether')],
      [spell('aether.channel_ward','Channel Ward',['defense','support'],'stabilize a caster against aether backlash'),
       spell('aether.flow_redirect','Flow Redirect',['control','field'],'bend a nearby aether current toward a valid sink')],
      [spell('aether.aether_bridge','Aether Bridge',['support','hybrid'],'temporarily connect two valid magical systems through a routed current'),
       spell('aether.overload_sink','Overload Sink',['defense','resource'],'bleed excess magical energy into a controlled sink')],
      [spell('aether.confluence','Confluence',['field','support'],'combine multiple bounded aether flows into one controlled node'),
       spell('aether.current_lattice','Current Lattice',['field','utility'],'establish a reusable routing network across an encounter')],
      [spell('aether.world_current','World Current',['grand-art','field','support'],'grandmaster routing of major ambient aether flows without treating aether as generic mana'),
       spell('aether.living_conduit','Living Conduit',['grand-art','stance'],'become a protected high-capacity channel with strict overload safeguards')]
    ]),

    lumen: domain('lumen',
      'optical controller, revealer, prism caster, and radiant defender',
      'light shaping → reveal/refraction → persistent optics → horizon-scale illumination',
      ['Gleam','Ray','Prism','Radiance','Dawn'],[
      [spell('lumen.gleam','Gleam',['utility','support'],'create controllable light and reveal simple darkness/visual concealment'),
       spell('lumen.lumen_ray','Lumen Ray',['attack'],'focused radiant/optical strike; not inherently holy')],
      [spell('lumen.mirage','Mirage',['control','defense'],'bend visible light to distort position and silhouette'),
       spell('lumen.refractive_guard','Refractive Guard',['defense','support'],'redirect selected beam/light effects')],
      [spell('lumen.revelation','Revelation',['utility','reveal'],'expose optical concealment, false images, and hidden light-path evidence'),
       spell('lumen.prism_burst','Prism Burst',['attack','area'],'split one beam into multiple controlled rays')],
      [spell('lumen.lightweave','Lightweave',['field','control'],'maintain persistent optical structures, zones, and decoys'),
       spell('lumen.solar_lens','Solar Lens',['hybrid','field'],'focus ambient light through a stable lens for range/power changes')],
      [spell('lumen.dawn_domain','Dawn Domain',['grand-art','field','support'],'large-area optical/radiant control with reveal and refraction'),
       spell('lumen.crown_of_prisms','Crown of Prisms',['grand-art','hybrid'],'grandmaster multi-beam routing through compatible crystal/lens structures')]
    ]),

    resonance: domain('resonance',
      'attunement mage controlling frequency relationships and sympathetic links',
      'sense/tune → synchronize → sympathetic transfer → harmonic network → grand attunement',
      ['Tone','Attune','Harmony','Sympathy','Grand Chord'],[
      [spell('resonance.true_tone','True Tone',['utility','reveal'],'sense a target or system\'s dominant magical frequency'),
       spell('resonance.tuning_touch','Tuning Touch',['support'],'make a small bounded adjustment to magical resonance')],
      [spell('resonance.phase_match','Phase Match',['support','hybrid'],'synchronize compatible effects or allies for improved interaction'),
       spell('resonance.dissonance','Dissonance',['control','debuff'],'destabilize a magical pattern through frequency mismatch')],
      [spell('resonance.sympathetic_link','Sympathetic Link',['hybrid','support'],'bind two compatible signatures for bounded shared effects'),
       spell('resonance.harmonic_lock','Harmonic Lock',['control','field'],'hold a tuned system near a chosen resonance state')],
      [spell('resonance.resonance_web','Resonance Web',['field','support'],'maintain multiple tuned relationships at once'),
       spell('resonance.countertone','Countertone',['defense','control'],'cancel or weaken a compatible hostile oscillatory effect')],
      [spell('resonance.grand_chord','Grand Chord',['grand-art','field','support'],'orchestrate many magical frequencies as one controlled system'),
       spell('resonance.world_attunement','World Attunement',['grand-art','utility'],'temporarily read and tune a large environment\'s resonant relationships')]
    ]),

    correspondence: domain('correspondence',
      'spatial linker, route-maker, range manipulator, and coordinate mage',
      'locate → connect → shorten/redirect → network → bounded gate architecture',
      ['Locate','Link','Route','Meridian','Gate'],[
      [spell('correspondence.true_bearing','True Bearing',['utility','exploration'],'identify exact relative direction and distance to a known anchor'),
       spell('correspondence.mark_anchor','Mark Anchor',['setup','utility'],'establish a bounded spatial reference point')],
      [spell('correspondence.short_link','Short Link',['utility','support'],'connect two nearby anchors for line-of-effect routing'),
       spell('correspondence.range_fold','Range Fold',['hybrid','attack'],'alter effective range without changing time')],
      [spell('correspondence.route_spell','Route Spell',['hybrid','control'],'redirect a compatible effect through a marked spatial path'),
       spell('correspondence.step_between','Step Between',['movement'],'short bounded translation between valid anchors')],
      [spell('correspondence.meridian_web','Meridian Web',['field','utility'],'maintain a network of spatial anchors and legal routes'),
       spell('correspondence.deny_route','Deny Route',['control','defense'],'invalidate or obstruct hostile spatial routing')],
      [spell('correspondence.songline_gate','Songline Gate',['grand-art','movement','field'],'open a high-order bounded route between prepared anchors'),
       spell('correspondence.impossible_coordinate','Impossible Coordinate',['grand-art','hybrid'],'advanced Resonance-compatible spatial routing through signature-matched endpoints')]
    ]),

    arcane: domain('arcane',
      'formal magic programmer using force, glyphs, wards, and transformation logic',
      'basic constructs → conditional sigils → spell logic → arrays → grand formalism',
      ['Form','Glyph','Sigil','Array','Grand Formula'],[
      [spell('arcane.force_bolt','Force Bolt',['attack'],'basic non-elemental force construct'),
       spell('arcane.simple_ward','Simple Ward',['defense'],'formal barrier against a declared class of effect')],
      [spell('arcane.glyph_trigger','Glyph Trigger',['setup','control'],'store a simple effect behind an explicit trigger'),
       spell('arcane.dispel_pattern','Dispel Pattern',['control','utility'],'unravel a compatible formal magical construct')],
      [spell('arcane.conditional_sigil','Conditional Sigil',['field','control'],'execute one bounded magical effect when a logical condition is met'),
       spell('arcane.transmute_form','Transmute Form',['utility','hybrid'],'temporarily alter a permitted material/magical property')],
      [spell('arcane.runic_array','Runic Array',['field','support'],'coordinate multiple glyphs as one programmable structure'),
       spell('arcane.spellbreaker','Spellbreaker',['defense','control'],'interrupt or dismantle a formal hostile spell sequence')],
      [spell('arcane.grand_formula','Grand Formula',['grand-art','field','hybrid'],'execute a complex multi-condition magical program'),
       spell('arcane.law_of_the_circle','Law of the Circle',['grand-art','control'],'establish a temporary local ruleset for explicitly supported arcane interactions')]
    ]),

    psychic: domain('psychic',
      'mind/perception controller and telekinetic combatant',
      'sense → influence → project/kinetic control → networked cognition → grand psionic field',
      ['Sense','Focus','Project','Nexus','Mindfield'],[
      [spell('psychic.surface_read','Surface Read',['reveal','utility'],'sense immediate surface intent with resistance/consent constraints'),
       spell('psychic.kinetic_nudge','Kinetic Nudge',['control','movement'],'small telekinetic push/pull')],
      [spell('psychic.mind_shield','Mind Shield',['defense','support'],'protect against hostile mental influence'),
       spell('psychic.thought_lance','Thought Lance',['attack','control'],'focused psionic pressure against a conscious target')],
      [spell('psychic.telekinetic_grip','Telekinetic Grip',['control','movement'],'sustain bounded force on an object or target'),
       spell('psychic.shared_focus','Shared Focus',['support'],'coordinate willing allies through a temporary mental link')],
      [spell('psychic.psionic_nexus','Psionic Nexus',['field','support'],'maintain several mental/telekinetic channels simultaneously'),
       spell('psychic.perception_edit','Perception Edit',['control','utility'],'alter a narrow current perception without rewriting identity or memory')],
      [spell('psychic.mindfield','Mindfield',['grand-art','field','control'],'large-area psionic presence affecting perception/kinetic space under resistance rules'),
       spell('psychic.collective_focus','Collective Focus',['grand-art','support'],'high-order voluntary group cognition for coordinated action')]
    ]),

    spirit: domain('spirit',
      'medium, warder, soul-protector, and negotiator with incorporeal beings',
      'sense/ward → commune → bind/protect → sanctuary → grand accord',
      ['Sense','Commune','Ward','Sanctuary','Accord'],[
      [spell('spirit.spirit_sight','Spirit Sight',['reveal','utility'],'perceive spirits, soul traces, and ward boundaries'),
       spell('spirit.basic_ward','Basic Ward',['defense','field'],'establish a simple barrier against spirit intrusion')],
      [spell('spirit.commune','Commune',['utility','support'],'communicate with a present spirit under bounded conditions'),
       spell('spirit.soul_anchor','Soul Anchor',['defense','support'],'stabilize identity/soul against displacement or possession')],
      [spell('spirit.exorcise','Exorcise',['control','attack'],'force a hostile spirit from an invalid occupation/attachment'),
       spell('spirit.ancestor_guard','Ancestor Guard',['support','defense'],'invite a consenting allied spirit to defend or advise')],
      [spell('spirit.sanctuary','Sanctuary',['field','defense'],'create protected space for spirits/souls without implying Sanctified status'),
       spell('spirit.spirit_bridge','Spirit Bridge',['support','utility'],'mediate controlled interaction between embodied and incorporeal entities')],
      [spell('spirit.living_accord','Living Accord',['grand-art','support','field'],'grand Spirit+Covenant framework for explicit reciprocal spirit relations'),
       spell('spirit.soul_haven','Soul Haven',['grand-art','defense'],'large-area protection against possession, severance, and soul displacement')]
    ]),

    vital: domain('vital',
      'life-process shaper, healer, ecologist, and growth controller',
      'stabilize → cultivate → regenerate/shape → ecosystem → worldgarden',
      ['Pulse','Cultivate','Regrow','Biome','Worldgarden'],[
      [spell('vital.life_sense','Life Sense',['reveal','utility'],'read basic biological vitality and stress'),
       spell('vital.stabilize','Stabilize',['support','heal'],'stop worsening injury and restore limited vitality')],
      [spell('vital.accelerate_growth','Accelerate Growth',['utility','field'],'speed bounded plant/fungal growth'),
       spell('vital.detox','Detox',['support','utility'],'assist biological removal of selected toxins/contaminants')],
      [spell('vital.regeneration','Regeneration',['support','heal'],'sustain gradual tissue restoration under resource limits'),
       spell('vital.rootbind','Rootbind',['control','field'],'use living growth to restrain or shape terrain')],
      [spell('vital.biome_weave','Biome Weave',['field','support'],'coordinate several living systems as one temporary micro-ecosystem'),
       spell('vital.adaptive_bloom','Adaptive Bloom',['support','hybrid'],'temporarily tune living allies/plants to an environmental condition')],
      [spell('vital.worldgarden','Worldgarden',['grand-art','field','support'],'large-area ecological restoration/growth under strict resource constraints'),
       spell('vital.phoenix_garden','Phoenix Garden',['grand-art','hybrid'],'Vital+Fire synthesis balancing renewal, heat, and Blight risk',
         {requiresMastery:Object.freeze([{tree:'fire',rank:5}])})]
    ]),

    entropy: domain('entropy',
      'decay, dissipation, disorder, and controlled unmaking specialist',
      'fray → dissipate → unravel → ruin-field → grand dissolution',
      ['Fray','Dissipate','Unravel','Ruin','Dissolution'],[
      [spell('entropy.fray','Fray',['debuff','attack'],'increase wear/disorder in a bounded material or magical pattern'),
       spell('entropy.cooling_loss','Cooling Loss',['utility','control'],'accelerate harmless energy dissipation from a valid system')],
      [spell('entropy.dissipate','Dissipate',['defense','control'],'bleed energy from a compatible hostile effect'),
       spell('entropy.rust_touch','Rust Touch',['debuff','utility'],'accelerate corrosion in vulnerable material')],
      [spell('entropy.unravel','Unravel',['control','attack'],'break down a structured magical/material pattern over time'),
       spell('entropy.decay_field','Decay Field',['field','debuff'],'sustain a zone of increased wear/decay')],
      [spell('entropy.ruin_cascade','Ruin Cascade',['attack','field'],'propagate failure through already compromised structures'),
       spell('entropy.heat_death_ward','Heat-Death Ward',['defense','control'],'suppress energetic escalation by forced dissipation')],
      [spell('entropy.grand_dissolution','Grand Dissolution',['grand-art','attack','field'],'large-scale controlled unmaking with severe safeguards'),
       spell('entropy.last_quiet','Last Quiet',['grand-art','control'],'temporarily drive a bounded system toward minimal usable energy')]
    ]),

    umbral: domain('umbral',
      'shadow, occlusion, absence, silhouette, and negative-space controller',
      'conceal → silhouette → connected absence → penumbra field → eclipse',
      ['Shade','Silhouette','Absence','Penumbra','Eclipse'],[
      [spell('umbral.shade','Shade',['defense','utility'],'deepen local shadow/occlusion for concealment'),
       spell('umbral.silhouette_mark','Silhouette Mark',['setup','reveal'],'track a target through its shadow boundary')],
      [spell('umbral.false_silhouette','False Silhouette',['control','defense'],'create misleading shadow geometry'),
       spell('umbral.light_eater','Light Eater',['field','utility'],'attenuate local visible light without invoking Entropy')],
      [spell('umbral.shadow_step','Shadow Step',['movement'],'move between bounded connected shadows under valid geometry'),
       spell('umbral.absence_veil','Absence Veil',['defense','control'],'reduce targetability by manipulating perceptual negative space')],
      [spell('umbral.penumbra_field','Penumbra Field',['field','control'],'maintain a mixed light/shadow zone with positional effects'),
       spell('umbral.negative_space','Negative Space',['field','utility'],'define a local region by controlled absence/occlusion relationships')],
      [spell('umbral.eclipse_domain','Eclipse Domain',['grand-art','field','control'],'grand Lumen-compatible control of contrast, silhouette, and penumbra'),
       spell('umbral.penumbra_meridian','Penumbra Meridian',['grand-art','movement','hybrid'],'Umbral+Correspondence routing through prepared connected shadows',
         {requiresMastery:Object.freeze([{domain:'correspondence',rank:5}])})]
    ]),

    time: domain('time',
      'rare bounded chronology controller',
      'tempo shift → anchor/delay → local stasis → echo window → bounded chronal domain',
      ['Tempo','Anchor','Interval','Echo','Chronal Domain'],[
      [spell('time.hasten','Hasten',['support','tempo'],'slightly accelerate one bounded action/process'),
       spell('time.delay','Delay',['control','tempo'],'delay one bounded effect without cancelling causality')],
      [spell('time.temporal_anchor','Temporal Anchor',['defense','utility'],'pin a target/system to a recent valid temporal reference'),
       spell('time.borrowed_moment','Borrowed Moment',['tempo','support'],'shift a small amount of action timing at an explicit later cost')],
      [spell('time.stasis','Stasis',['control','field'],'brief bounded suspension with resistance and duration limits'),
       spell('time.afterimage','Afterimage',['defense','utility'],'retain a short-lived temporal trace of recent movement/state')],
      [spell('time.temporal_echo','Temporal Echo',['hybrid','utility'],'replay a bounded non-unique recent effect without rewriting history'),
       spell('time.interval_lock','Interval Lock',['control','field'],'stabilize local timing relationships for a short window')],
      [spell('time.chronal_domain','Chronal Domain',['grand-art','field','tempo'],'large-area bounded timing control; no unrestricted history rewrite'),
       spell('time.moment_of_many_roads','Moment of Many Roads',['grand-art','hybrid'],'Time+Fate synthesis over a narrow possibility window',
         {requiresMastery:Object.freeze([{domain:'fate',rank:5}])})]
    ]),

    fate: domain('fate',
      'rare probability and branching-possibility manipulator',
      'read odds → bias → branch control → probability field → bounded destiny weave',
      ['Odds','Bias','Branch','Fortune Field','Many Roads'],[
      [spell('fate.read_odds','Read Odds',['reveal','utility'],'estimate immediate branching likelihoods without claiming certainty'),
       spell('fate.nudge','Nudge',['support','control'],'slightly bias a bounded random outcome')],
      [spell('fate.fortunate_turn','Fortunate Turn',['support','tempo'],'improve one ally\'s near-term probability envelope'),
       spell('fate.misfortune_mark','Misfortune Mark',['debuff','control'],'worsen one enemy\'s bounded chance window')],
      [spell('fate.branch_sight','Branch Sight',['reveal','support'],'compare several near-term possible outcomes'),
       spell('fate.weighted_path','Weighted Path',['control','support'],'increase likelihood of one declared branch without guaranteeing it')],
      [spell('fate.fortune_field','Fortune Field',['field','support'],'sustain a zone with bounded probability bias rules'),
       spell('fate.cut_thread','Cut Thread',['control','utility'],'remove one already-permitted low-probability branch from a bounded event')],
      [spell('fate.many_roads','Many Roads',['grand-art','field','support'],'grandmaster manipulation of a narrow branching possibility space'),
       spell('fate.fixed_star','Fixed Star',['grand-art','defense'],'protect one declared outcome condition from ordinary probability manipulation')]
    ]),

    memory: domain('memory',
      'mnemonic archivist, trace-reader, echo restorer, and remembrance defender',
      'recall → trace → reconstruct → archive field → palace of echoes',
      ['Recall','Trace','Echo','Archive','Palace'],[
      [spell('memory.recall','Recall',['support','utility'],'assist willing accurate recall of a recent memory'),
       spell('memory.trace_read','Trace Read',['reveal','exploration'],'read faint mnemonic residue from a valid place/object')],
      [spell('memory.echo_image','Echo Image',['reveal','utility'],'reconstruct a bounded sensory fragment from memory residue'),
       spell('memory.mnemonic_ward','Mnemonic Ward',['defense','support'],'protect against memory alteration or loss')],
      [spell('memory.reconstruct','Reconstruct',['support','utility'],'assemble partial memory fragments while preserving uncertainty'),
       spell('memory.memory_anchor','Memory Anchor',['defense','support'],'bind a willing target to a verified reference memory')],
      [spell('memory.living_archive','Living Archive',['field','support'],'maintain multiple labeled memory traces without merging identities'),
       spell('memory.echo_walk','Echo Walk',['exploration','field'],'navigate a location through preserved mnemonic traces')],
      [spell('memory.palace_of_echoes','Palace of Echoes',['grand-art','field','support'],'Psychic-compatible shared mnemonic space with consent and provenance safeguards'),
       spell('memory.witness_eternal','Witness Eternal',['grand-art','utility'],'preserve a high-fidelity bounded event record for later verification')]
    ]),

    covenant: domain('covenant',
      'oath, permission, name, reciprocal-condition, and magical-agreement specialist',
      'declare → bind → enforce → network agreements → grand living accord',
      ['Promise','Bind','Condition','Concord','Living Accord'],[
      [spell('covenant.declare_terms','Declare Terms',['utility','support'],'make magical conditions explicit before binding'),
       spell('covenant.name_mark','Name Mark',['setup','utility'],'establish an authenticated magical identity token')],
      [spell('covenant.minor_oath','Minor Oath',['support','hybrid'],'bind consenting parties to a small reciprocal condition'),
       spell('covenant.permission_ward','Permission Ward',['defense','field'],'allow/deny an explicitly named class of interaction')],
      [spell('covenant.conditional_binding','Conditional Binding',['control','support'],'enforce a declared magical condition with explicit scope'),
       spell('covenant.reciprocal_boost','Reciprocal Boon',['support'],'grant a benefit while both parties honor stated terms')],
      [spell('covenant.concord_field','Concord Field',['field','support'],'maintain multiple permissions/oaths with visible conditions'),
       spell('covenant.arbiter_seal','Arbiter Seal',['control','utility'],'adjudicate whether a magical agreement\'s explicit condition was met')],
      [spell('covenant.living_accord','Living Accord',['grand-art','field','support'],'grand reciprocal framework suited to Spirit+Covenant synthesis'),
       spell('covenant.true_name_covenant','True-Name Covenant',['grand-art','hybrid'],'high-assurance identity-bound agreement with strict consent/scope rules')]
    ]),

    technomancy: domain('technomancy',
      'magical engineer interfacing with cores, instruments, circuits, and designed systems',
      'diagnose → interface → reconfigure → network → grand machine-sorcery',
      ['Diagnose','Interface','Reconfigure','Network','Grand Engine'],[
      [spell('technomancy.aether_diagnostic','Aether Diagnostic',['utility','reveal'],'read basic magical-machine health and flow'),
       spell('technomancy.spark_bridge','Spark Bridge',['utility','support'],'temporarily connect two compatible magical devices')],
      [spell('technomancy.override_limiter','Override Limiter',['support','risk'],'temporarily push a device within declared safe/unsafe bounds'),
       spell('technomancy.field_patch','Field Patch',['support','repair'],'restore limited function to damaged magical machinery')],
      [spell('technomancy.reconfigure_core','Reconfigure Core',['utility','support'],'change a supported machine mode during play'),
       spell('technomancy.counterhack','Counterhack',['control','defense'],'block or reverse hostile magical-system intrusion')],
      [spell('technomancy.aether_network','Aether Network',['field','support'],'coordinate multiple devices through a shared instrumented magical bus'),
       spell('technomancy.autonomous_array','Autonomous Array',['field','hybrid'],'deploy bounded automated magical devices under explicit rules')],
      [spell('technomancy.grand_engine','Grand Engine',['grand-art','field','support'],'orchestrate a large magical-machine system as one controllable whole'),
       spell('technomancy.machine_symphony','Machine Symphony',['grand-art','hybrid'],'Technomancy+Resonance synthesis for tuned multi-device coordination',
         {requiresMastery:Object.freeze([{domain:'resonance',rank:5}])})]
    ])
  });

  function getTree(id) { return TREES[id] || null; }
  function allSpells() {
    const out=[];
    for (const tree of Object.values(TREES)) {
      for (let r=1;r<=5;r+=1) {
        for (const s of tree.ranks[r].spells) {
          out.push(Object.freeze(Object.assign({domainId:tree.domainId, rank:r}, s)));
        }
      }
    }
    return Object.freeze(out);
  }

  return Object.freeze({
    version:'0.1.0',
    runtimeStatus:'STATUS_PRESERVING_DESIGN_CATALOG_NOT_EXECUTABLE',
    TREES,
    getTree,
    allSpells
  });
});
