/* ============================================================
   Aetherwake JRPG — Elemental Spell Trees v0.1
   modules/elemental-spell-trees.js

   Learnable 1–5 design trees for the 11 admitted elemental schools.
   Data only: no spell here is executable until separately admitted.
   ============================================================ */

(function (root, factory) {
  const defs = typeof module === 'object' && module.exports
    ? require('./magic-defs.js')
    : root.AetherwakeMagicDefs;
  const api = factory(defs);
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.AetherwakeElementalSpellTrees = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (defs) {
  'use strict';

  if (!defs) throw new Error('ELEMENTAL_SPELL_TREES_REQUIRE_MAGIC_DEFS');

  function spell(id, name, roles, intent, extra) {
    return Object.freeze(Object.assign({
      id, name,
      roles:Object.freeze(roles.slice()),
      intent
    }, extra || {}));
  }

  function rank(label, spells) {
    return Object.freeze({
      label,
      spells:Object.freeze(spells.slice())
    });
  }

  const TREES = Object.freeze({
    fire: Object.freeze({
      treeId:'fire',
      fantasy:'thermal aggressor and ignition controller',
      signature:'Burn setup → ignition/flashover payoff → furnace field control',
      ranks:Object.freeze({
        1:rank('Spark',[
          spell('fire.ember_dart','Ember Dart',['attack'],'fast single-target fire strike; establishes basic Fire offense'),
          spell('fire.kindle','Kindle',['status','setup'],'apply or strengthen Burning on a valid target')
        ]),
        2:rank('Flame',[
          spell('fire.flame_arc','Flame Arc',['attack','area'],'sweeping cone/line attack for multi-target pressure'),
          spell('fire.heat_ward','Heat Ward',['support','utility'],'raise thermal tolerance and resist Frost/Chill interactions')
        ]),
        3:rank('Inferno',[
          spell('fire.flashover','Flashover',['attack','detonate'],'consume or exploit Burning for a burst payoff'),
          spell('fire.cinderstep','Cinderstep',['movement','field'],'reposition while leaving a temporary burning route')
        ]),
        4:rank('Furnace',[
          spell('fire.furnace_field','Furnace Field',['field','support'],'raise local temperature; empower Fire and pressure Frost states'),
          spell('fire.melt_guard','Melt Guard',['debuff','utility'],'soften armor/material defenses through controlled heat')
        ]),
        5:rank('Conflagration',[
          spell('fire.conflagration','Conflagration',['grand-art','attack','field'],'battlefield-scale ignition cascade with controlled spread'),
          spell('fire.heart_of_the_furnace','Heart of the Furnace',['grand-art','stance'],'grandmaster state for sustained thermal control and ignition economy')
        ])
      })
    }),

    water: Object.freeze({
      treeId:'water',
      fantasy:'flow controller, cleanser, pressure specialist, and phase-state manipulator',
      signature:'Wet/flow setup → pressure and positional control → deep-tide field dominance',
      ranks:Object.freeze({
        1:rank('Flow',[
          spell('water.water_jet','Water Jet',['attack','movement'],'pressure strike that can displace light targets'),
          spell('water.purify','Purify',['support','utility'],'cleanse selected contamination/burning effects and create Wet state when appropriate')
        ]),
        2:rank('Current',[
          spell('water.current_pull','Current Pull',['control','movement'],'redirect target position through controlled flow'),
          spell('water.mist_veil','Mist Veil',['field','defense'],'create obscuring moisture for accuracy/visibility play')
        ]),
        3:rank('Pressure',[
          spell('water.pressure_lance','Pressure Lance',['attack','break'],'focused high-pressure strike with strong Break intent'),
          spell('water.undertow','Undertow',['control','field'],'persistent pull zone that alters movement lanes')
        ]),
        4:rank('Deep Tide',[
          spell('water.deep_tide','Deep Tide',['field','support'],'establish sustained Water field; improves Wet/pressure interactions'),
          spell('water.steam_sheath','Steam Sheath',['defense','hybrid'],'vapor defense/offense layer; stronger with Fire familiarity',
            {requiresMastery:Object.freeze([{tree:'fire',rank:2}])})
        ]),
        5:rank('Dominion',[
          spell('water.ocean_dominion','Ocean Dominion',['grand-art','field','control'],'large-area flow/pressure rewrite with ally-safe routing'),
          spell('water.world_current','World Current',['grand-art','support'],'redistribute water pressure and flow across the encounter')
        ])
      })
    }),

    air: Object.freeze({
      treeId:'air',
      fantasy:'speed, lift, trajectory, vacuum, and directional control',
      signature:'mobility/positioning → pressure shaping → atmosphere-scale movement control',
      ranks:Object.freeze({
        1:rank('Breeze',[
          spell('air.gust','Gust',['control','movement'],'basic push/pull and trajectory adjustment'),
          spell('air.wind_cut','Wind Cut',['attack'],'fast ranged pressure blade')
        ]),
        2:rank('Wind',[
          spell('air.updraft','Updraft',['movement','support'],'lift/reposition an ally or disrupt a grounded foe'),
          spell('air.tailwind','Tailwind',['support','tempo'],'improve movement/initiative efficiency for a short window')
        ]),
        3:rank('Gale',[
          spell('air.gale_step','Gale Step',['movement','defense'],'rapid reposition/evasion using a controlled burst of air'),
          spell('air.vacuum_edge','Vacuum Edge',['attack','control'],'pressure-differential strike that punishes exposed targets')
        ]),
        4:rank('Atmosphere',[
          spell('air.jetstream','Jetstream',['field','movement'],'persistent directional lane that accelerates allies and projectiles'),
          spell('air.atmosphere_lock','Atmosphere Lock',['control','field'],'stabilize or suppress local air movement to counter wind/storm effects')
        ]),
        5:rank('Sky Dominion',[
          spell('air.sky_dominion','Sky Dominion',['grand-art','field','movement'],'battlefield-scale airflow routing and lift control'),
          spell('air.horizon_break','Horizon Break',['grand-art','attack','control'],'massive pressure-front release that repositions the encounter')
        ])
      })
    }),

    earth: Object.freeze({
      treeId:'earth',
      fantasy:'terrain architect, defender, breaker, and mineral transformer',
      signature:'structure/terrain → fault and fortification → magma/vitrification applications → mountain-scale control',
      ranks:Object.freeze({
        1:rank('Stone',[
          spell('earth.stoneguard','Stoneguard',['defense','support'],'reinforce body/armor with mineral structure'),
          spell('earth.stone_spike','Stone Spike',['attack','terrain'],'raise a focused stone strike from ground or nearby mineral matter')
        ]),
        2:rank('Masonry',[
          spell('earth.rampart','Rampart',['defense','field'],'create a physical barrier/cover segment'),
          spell('earth.sand_veil','Sand Veil',['field','control'],'use particulate earth to obscure and erode footing')
        ]),
        3:rank('Fault',[
          spell('earth.fault_line','Fault Line',['attack','break','terrain'],'rupture a line of ground to stagger/break'),
          spell('earth.ironroot','Ironroot',['defense','control'],'anchor an ally against forced movement and destabilization')
        ]),
        4:rank('Bastion',[
          spell('earth.magma_vein','Magma Vein',['hybrid','field','attack'],'melt mineral terrain into controlled molten channels',
            {requiresMastery:Object.freeze([{tree:'fire',rank:3}])}),
          spell('earth.vitrify','Vitrify',['hybrid','utility','field'],'convert mineral/sand surfaces into glassy barriers, lenses, or hazards',
            {requiresMastery:Object.freeze([{tree:'fire',rank:3}])})
        ]),
        5:rank('Mountain',[
          spell('earth.mountains_answer',"Mountain's Answer",['grand-art','field','defense'],'massively reshape terrain while fortifying allies and isolating threats'),
          spell('earth.world_bastion','World Bastion',['grand-art','defense','terrain'],'construct an encounter-defining fortress/terrain geometry')
        ])
      })
    }),

    frost: Object.freeze({
      treeId:'frost',
      fantasy:'heat extractor, freezer, preserver, and brittleness specialist',
      signature:'chill → freeze → brittle/shatter setup → permafrost control',
      ranks:Object.freeze({
        1:rank('Chill',[
          spell('frost.frostbite','Frostbite',['attack','status'],'apply Chill and begin temperature suppression'),
          spell('frost.ice_shard','Ice Shard',['attack'],'basic piercing Frost projectile')
        ]),
        2:rank('Ice',[
          spell('frost.ice_wall','Ice Wall',['defense','field'],'temporary ice barrier and path control'),
          spell('frost.cold_snap','Cold Snap',['control','status'],'rapidly intensify Chill/Freeze buildup')
        ]),
        3:rank('Brittle',[
          spell('frost.brittle_mark','Brittle Mark',['debuff','break'],'make frozen/rigid targets easier to Break or shatter'),
          spell('frost.freeze_lock','Freeze Lock',['control'],'convert sufficient moisture/chill setup into stronger immobilization')
        ]),
        4:rank('Glacial',[
          spell('frost.permafrost_field','Permafrost Field',['field','control'],'sustain low-temperature terrain that slows and preserves Freeze states'),
          spell('frost.glacial_armor','Glacial Armor',['defense','support'],'layer durable ice armor that can fracture instead of consuming HP')
        ]),
        5:rank('Deep Freeze',[
          spell('frost.deep_freeze','Deep Freeze',['grand-art','control','field'],'flash-freeze a large area under strict setup/resistance rules'),
          spell('frost.stillwinter','Stillwinter',['grand-art','field','support'],'grandmaster temperature-control state focused on preservation and denial')
        ])
      })
    }),

    lightning: Object.freeze({
      treeId:'lightning',
      fantasy:'charge router, chain attacker, electromagnetic controller',
      signature:'mark/charge → conduction network → field-triggered discharge',
      ranks:Object.freeze({
        1:rank('Static',[
          spell('lightning.arc_bolt','Arc Bolt',['attack'],'fast electrical strike'),
          spell('lightning.static_mark','Static Mark',['status','setup'],'apply charge signature for later conduction effects')
        ]),
        2:rank('Arc',[
          spell('lightning.chain_spark','Chain Spark',['attack','chain'],'jump through valid conductive/marked targets'),
          spell('lightning.shock_step','Shock Step',['movement','attack'],'short reposition with contact discharge')
        ]),
        3:rank('Circuit',[
          spell('lightning.conduction_network','Conduction Network',['field','setup'],'link conductive targets/objects into a routable electrical graph'),
          spell('lightning.magnetic_pull','Magnetic Pull',['control','utility'],'move metallic targets or equipment using electromagnetic force')
        ]),
        4:rank('Field',[
          spell('lightning.induction_field','Induction Field',['field','control'],'persistent electrical/magnetic zone that reacts to movement/conductors'),
          spell('lightning.lightning_step','Lightning Step',['movement','tempo'],'high-speed reposition along a valid charged/conductive path')
        ]),
        5:rank('Thunder',[
          spell('lightning.heavens_circuit',"Heaven's Circuit",['grand-art','field','attack'],'convert the battlefield conduction graph into a repeated discharge network'),
          spell('lightning.thunder_crown','Thunder Crown',['grand-art','stance'],'grandmaster charge-management state with reactive arcs')
        ])
      })
    }),

    crystal: Object.freeze({
      treeId:'crystal',
      fantasy:'lattice architect, prism user, resonant storage specialist',
      signature:'grow/order → lattice/store → refract/amplify → cathedral-scale magical architecture',
      ranks:Object.freeze({
        1:rank('Shard',[
          spell('crystal.shard_lance','Shard Lance',['attack'],'focused crystal projectile with strong piercing identity'),
          spell('crystal.crystal_growth','Crystal Growth',['field','utility'],'grow controllable crystal structures from valid mineral substrate')
        ]),
        2:rank('Facet',[
          spell('crystal.facet_guard','Facet Guard',['defense','support'],'faceted barrier that can redirect select attacks'),
          spell('crystal.prism_wall','Prism Wall',['field','defense'],'transparent/refractive barrier with Lumen synergy')
        ]),
        3:rank('Lattice',[
          spell('crystal.resonant_lattice','Resonant Lattice',['field','hybrid'],'ordered crystal network that stores/tunes magical vibration'),
          spell('crystal.crystal_battery','Crystal Battery',['resource','utility'],'store bounded magical charge for later release',
            {requiresMastery:Object.freeze([{domain:'aether',rank:2}])})
        ]),
        4:rank('Array',[
          spell('crystal.refraction_array','Refraction Array',['field','hybrid'],'route Lumen/beam effects across multiple crystal nodes',
            {requiresMastery:Object.freeze([{domain:'lumen',rank:2}])}),
          spell('crystal.harmonic_vault','Harmonic Vault',['support','hybrid'],'capture and redistribute tuned resonance effects',
            {requiresMastery:Object.freeze([{domain:'resonance',rank:2}])})
        ]),
        5:rank('Cathedral',[
          spell('crystal.crystal_cathedral','Crystal Cathedral',['grand-art','field','defense'],'construct a large lattice domain that modifies routing, storage, and cover'),
          spell('crystal.world_prism','World Prism',['grand-art','hybrid','utility'],'grandmaster refractive network for light/resonance/aether synthesis')
        ])
      })
    }),

    metal: Object.freeze({
      treeId:'metal',
      fantasy:'armament shaper, magnetic controller, conductive equipment specialist',
      signature:'shape/temper → armory control → magnetic field → living forge',
      ranks:Object.freeze({
        1:rank('Bend',[
          spell('metal.bend_metal','Bend Metal',['utility','control'],'reshape simple metal objects/equipment within bounded limits'),
          spell('metal.iron_skin','Iron Skin',['defense'],'temporary metallic reinforcement')
        ]),
        2:rank('Temper',[
          spell('metal.temper','Temper',['support','equipment'],'improve weapon/armor performance for a bounded duration'),
          spell('metal.magnetic_pull','Magnetic Pull',['control','movement'],'pull/push metallic objects or equipped targets')
        ]),
        3:rank('Armory',[
          spell('metal.conductive_arsenal','Conductive Arsenal',['support','hybrid'],'convert selected metal equipment into a deliberate Lightning-routing network'),
          spell('metal.pole_shift','Pole Shift',['control','field'],'reverse/redirect magnetic relationships among marked metallic objects')
        ]),
        4:rank('Magnetic Field',[
          spell('metal.living_armory','Living Armory',['stance','support'],'actively reshape carried weapons/armor during combat'),
          spell('metal.magnetic_field','Magnetic Field',['field','control'],'persistent magnetic zone for projectile/equipment control')
        ]),
        5:rank('Living Forge',[
          spell('metal.living_forge','Living Forge',['grand-art','stance','equipment'],'grandmaster real-time forging/reconfiguration state'),
          spell('metal.iron_dominion','Iron Dominion',['grand-art','field','control'],'large-scale command of metallic battlefield objects')
        ])
      })
    }),

    plasma: Object.freeze({
      treeId:'plasma',
      fantasy:'rare high-energy ionization magic with containment risk',
      signature:'ionize → contain → lance/field → stellar release',
      ranks:Object.freeze({
        1:rank('Arc',[
          spell('plasma.ion_spark','Ion Spark',['attack'],'small controlled ionized discharge'),
          spell('plasma.corona_needle','Corona Needle',['attack','pierce'],'narrow high-energy strike for precision targets')
        ]),
        2:rank('Ion',[
          spell('plasma.plasma_arc','Plasma Arc',['attack','area'],'curved short-range plasma sweep'),
          spell('plasma.containment_shell','Containment Shell',['defense','utility'],'stabilize dangerous ionized matter before release')
        ]),
        3:rank('Lance',[
          spell('plasma.plasma_lance','Plasma Lance',['attack','pierce'],'high-output line strike with containment cost'),
          spell('plasma.ion_trail','Ion Trail',['field','setup'],'leave a charged ion path that enables later routing')
        ]),
        4:rank('Containment',[
          spell('plasma.stellar_shear','Stellar Shear',['attack','break'],'extreme-energy cutting plane with strict resource/heat limits'),
          spell('plasma.corona_field','Corona Field',['field','control'],'sustained ionized zone requiring active containment')
        ]),
        5:rank('Stellar',[
          spell('plasma.starfire_crown','Starfire Crown',['grand-art','stance','attack'],'grandmaster plasma-control state with severe resource/heat constraints'),
          spell('plasma.white_sun','White Sun',['grand-art','attack','field'],'brief contained high-energy release; never casual spammable damage')
        ])
      })
    }),

    sonic: Object.freeze({
      treeId:'sonic',
      fantasy:'physical vibration, pressure-wave, dampening, and structural-break magic',
      signature:'pulse/sense → frequency control → standing waves → structural grand resonance',
      ranks:Object.freeze({
        1:rank('Pulse',[
          spell('sonic.pulse','Pulse',['attack','control'],'short concussive pressure wave'),
          spell('sonic.echo_sense','Echo Sense',['utility','exploration'],'read nearby geometry/motion through reflected sound')
        ]),
        2:rank('Frequency',[
          spell('sonic.dampen','Dampen',['support','control'],'reduce harmful sound/vibration and suppress selected sonic effects'),
          spell('sonic.sonic_lance','Sonic Lance',['attack','break'],'focused pressure-wave strike')
        ]),
        3:rank('Resonant Force',[
          spell('sonic.resonant_break','Resonant Break',['attack','break'],'identify a physical resonant frequency and exploit it for structural Break'),
          spell('sonic.silence_field','Silence Field',['field','control'],'dampen local acoustic propagation; not a metaphysical anti-magic silence by default')
        ]),
        4:rank('Standing Wave',[
          spell('sonic.standing_wave','Standing Wave',['field','defense'],'persistent pressure node that blocks/redirects motion or projectiles'),
          spell('sonic.waveguide','Waveguide',['utility','field'],'route sonic effects along chosen surfaces/air channels')
        ]),
        5:rank('World Chord',[
          spell('sonic.world_chord','World Chord',['grand-art','field','break'],'large-area synchronized physical vibration with major structural consequences'),
          spell('sonic.shatter_horizon','Shatter Horizon',['grand-art','attack','control'],'massive directional pressure-front release')
        ])
      })
    }),

    storm: Object.freeze({
      treeId:'storm',
      fantasy:'persistent weather-system orchestration combining airflow, charge, and moisture',
      signature:'front formation → storm cell → persistent weather domain → supercell synthesis',
      ranks:Object.freeze({
        1:rank('Tendency',[
          spell('storm.squall','Squall',['attack','control'],'brief localized wind/rain burst'),
          spell('storm.raincall','Raincall',['field','setup'],'create or intensify local precipitation/Wet conditions')
        ]),
        2:rank('Front',[
          spell('storm.thunderhead','Thunderhead',['field','attack'],'create a small storm cloud that can discharge into valid targets'),
          spell('storm.crosswind','Crosswind',['control','field'],'persistent lateral wind that alters movement/projectiles')
        ]),
        3:rank('Storm Cell',[
          spell('storm.storm_cell','Storm Cell',['field','stance'],'sustain an encounter-scale weather system'),
          spell('storm.lightning_harvest','Lightning Harvest',['hybrid','resource','attack'],'capture/redirect charge generated inside the storm field')
        ]),
        4:rank('Tempest',[
          spell('storm.tempest_domain','Tempest Domain',['field','control'],'large sustained weather zone with rain/wind/charge interactions'),
          spell('storm.eye_of_the_storm','Eye of the Storm',['support','field'],'create a stable safe/control zone within an active tempest')
        ]),
        5:rank('Sky Dominion',[
          spell('storm.heavenbreak_tempest','Heavenbreak Tempest',['grand-art','field','attack'],'master Storm + Lightning synthesis; the storm becomes a routable electrical network',
            {requiresMastery:Object.freeze([{tree:'lightning',rank:5}])}),
          spell('storm.sovereign_weather','Sovereign Weather',['grand-art','field','control'],'grandmaster sustained control of encounter-scale weather state')
        ])
      })
    })
  });

  function getTree(treeId) { return TREES[treeId] || null; }

  function allSpells() {
    const out = [];
    for (const tree of Object.values(TREES)) {
      for (let r = 1; r <= 5; r += 1) {
        for (const s of tree.ranks[r].spells) {
          out.push(Object.freeze(Object.assign({ treeId:tree.treeId, rank:r }, s)));
        }
      }
    }
    return Object.freeze(out);
  }

  return Object.freeze({
    version:'0.1.0',
    runtimeStatus:'DESIGN_CATALOG_NOT_EXECUTABLE',
    TREES,
    getTree,
    allSpells
  });
});
