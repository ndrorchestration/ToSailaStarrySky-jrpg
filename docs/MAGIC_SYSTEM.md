# Aetherwake Magic System — Domain Map v0.1

**Status:** target design contract; not yet an executable spell catalog.  
**Runtime rule:** definitions may be referenced by tests/design tooling, but no domain becomes usable in combat until its abilities and effect semantics are explicitly implemented.

## 1. Design rules

Aetherwake magic is built for a multi-job JRPG rather than a flat elemental weakness chart.

1. **Character knowledge persists across jobs.** Jobs influence access, training, equipment, passives and Job Arts; they do not own a character's learned magic.
2. **Every full tree must justify five mastery ranks.** If a concept cannot produce a distinct Rank 1, defining Rank 3 and transformative Rank 5, it is a branch, reaction or synthesis rather than a full tree.
3. **Mastery synergies change behavior.** Cross-mastery should unlock routing, conversion, field behavior, triggers, new casting rules or synthesis arts—not merely +X% damage.
4. **The UI may compress five ranks into three tiers.** Ranks 1–2 = Foundation, 3–4 = Advanced, 5 = Grandmaster.
5. **Rare does not mean stronger by default.** High-order schools have stricter access, costs and constraints; they remain sidegrade-capable rather than mandatory.
6. **Dreaming is exceptional.** It is plot-bound and outside the ordinary learnable-school catalog.
7. **Holy/Unholy are not elements.** Sacred/corrupted metaphysics are modifiers layered onto compatible magic.

## 2. Character affinity vs mastery

Innate affinity and learned mastery are separate state.

- **Affinity** means a character has an unusual natural relationship, sensitivity, or compatibility with a domain.
- **Mastery rank** records learned/practiced capability in a tree or domain.
- Affinity does **not** automatically grant Rank 1, free spells, or combat authorization.
- Ender's established innate affinities are **Aether, Resonance/Harmonic, Correspondence, and Lumen**.
- Lyra, Ionia, Reson, and Aepex remain **OPEN** for formal magical affinities; no affinity is inferred from thematic fit.
- Dreaming remains exceptional and is not stored as ordinary mastery.

`modules/character-magic-profile.js` v0.1 encodes this boundary as a pure profile contract; it is not yet persistent runtime state.

## 3. Mastery model

| Detailed rank | Name | 1–3 compression | Design purpose |
| --- | --- | --- | --- |
| 1 | Initiate | 1 — Foundation | recognizable core verb |
| 2 | Adept | 1 — Foundation | first utility/control application |
| 3 | Specialist | 2 — Advanced | defining tree mechanic |
| 4 | Master | 2 — Advanced | cross-tree interaction and field control |
| 5 | Grandmaster | 3 — Grandmaster | transformative capstone / Grand Synthesis eligibility |

Cross-mastery thresholds:

- **2 + 2:** minor interaction or passive behavior.
- **3 + 3:** Cross-School Art.
- **4 + 4:** advanced synergy passive or field rule.
- **5 + 5:** Grand Synthesis Art.

## 4. Elemental trees

### Primal trees

| Tree | Core verb | JRPG combat identity | Major branches/applications |
| --- | --- | --- | --- |
| **Fire** | Transform | burst, Burn, ignition chains, thermal field control | ash/smoke, radiant heat |
| **Water** | Flow | control, cleanse, pressure, sustain, phase-state play | mist, steam, pressure, buoyancy |
| **Air** | Move | speed, lift, displacement, trajectory, pressure | vacuum, gale, flight assistance |
| **Earth** | Form | defense, terrain, Break, structure, mineral shaping | sand/dust, magma, glass/vitrification, seismic |

The absorbed concepts remain mechanically available:
- **Sand/Dust** is an Earth application, not a separate mastery tree.
- **Steam/Mist** is a Water application, with Fire/Air knowledge improving access and behavior.
- **Magma** is an Earth application gated/amplified by Fire mastery.
- **Glass** is vitrification within Earth/Magma/mineral play, not a separate tree.

### Advanced and hybrid trees

| Tree | Parent/access logic | Core verb | Distinct identity |
| --- | --- | --- | --- |
| **Frost** | Water 2+ | Preserve | heat extraction, Freeze, brittleness, ice construction |
| **Lightning** | Air 2+ | Charge | current, Conduct, chains, electromagnetism |
| **Crystal** | Earth 2+ | Order | lattices, storage, refraction, resonance structures |
| **Metal** | Earth 2+ | Forge | equipment shaping, armor, magnetism, conductive networks |
| **Plasma** | Fire 4+ and Aether familiarity | Ionize | high-cost high-energy piercing/field magic |
| **Sonic** | Air 2+ or Resonance 2+ | Vibrate | physical pressure waves, stagger, silence/dampening, structural Break |
| **Storm** | Air 3+ + Lightning 3+; Water strongly benefits | Orchestrate | persistent weather systems and encounter-scale atmospheric state |

**Sonic boundary:** Sonic governs physical vibration/acoustics. **Resonance/Harmonic** governs deeper magical frequency relationships, synchronization and sympathetic attunement. They deliberately overlap enough to synergize without being synonyms.

## 5. Elemental five-rank development

The registry contains five named stages for every elemental tree. The mechanical expectation is:

- **Fire:** Spark → Flame → Inferno → Furnace → Conflagration
- **Water:** Flow → Current → Pressure → Deep Tide → Dominion
- **Air:** Breeze → Wind → Gale → Atmosphere → Sky Dominion
- **Earth:** Stone → Masonry → Fault → Bastion → Mountain
- **Frost:** Chill → Ice → Brittle → Glacial → Deep Freeze
- **Lightning:** Static → Arc → Circuit → Field → Thunder
- **Crystal:** Shard → Facet → Lattice → Array → Cathedral
- **Metal:** Bend → Temper → Armory → Magnetic Field → Living Forge
- **Plasma:** Arc → Ion → Lance → Containment → Stellar
- **Sonic:** Pulse → Frequency → Resonant Force → Standing Wave → World Chord
- **Storm:** Tendency → Front → Storm Cell → Tempest → Sky Dominion

These are progression labels, not a frozen spell list. Individual spell names remain authorable content.

### Elemental spell-tree catalog v0.1

`modules/elemental-spell-trees.js` now provides a complete **design-only learnable catalog** for all 11 admitted elemental trees.

Each tree contains:
- exactly five mastery ranks,
- at least two learnable spell/technique seeds per rank,
- a distinct fantasy/signature combat loop,
- at least four JRPG tactical role families across the full tree,
- at least one Rank-5 Grand Art,
- explicit cross-mastery prerequisites where needed.

The first catalog contains **110+ spell/technique seeds** across Fire, Water, Air, Earth, Frost, Lightning, Crystal, Metal, Plasma, Sonic, and Storm.

Important absorbed concepts remain intact:
- Sand/Dust stays inside Earth.
- Steam/Mist stays inside Water.
- Magma and vitrification/glass stay inside Earth and require Fire knowledge where appropriate.
- Sonic remains physical vibration/acoustics rather than replacing Resonance/Harmonic.
- Heavenbreak Tempest is explicitly gated by Storm 5 + Lightning 5.

This catalog is still **not executable**. It supplies learnable design content for later ability-definition admission and balance work.

## 6. Non-elemental domains

### Established families

| Domain | Verb | Hard boundary |
| --- | --- | --- |
| **Aether** | Channel | raw world-accessible magical current; not generic mana |
| **Lumen** | Illuminate | light, radiance, optics, refraction, revelation; not Holy |
| **Resonance / Harmonic** | Attune | frequency relationships, synchronization, sympathetic magic; broader than Sonic |
| **Correspondence** | Connect | space, distance, adjacency, routing, location; not Time |
| **Arcane** | Encode | formal magical structures, glyphs, force and transformation logic |
| **Psychic** | Influence | mind, perception, telepathy, telekinesis; not soul or Fate |
| **Spirit** | Commune | souls, spirits, wards, identity beyond body; not generic biology |

### Proposed ordinary/later domains

| Domain | Verb | Boundary / role |
| --- | --- | --- |
| **Vital** | Cultivate | biology, healing, growth, ecology |
| **Entropy** | Degrade | decay, dissipation, disorder, unmaking; not Shadow |
| **Umbral / Shadow** | Occlude | concealment, shadow, absence, silhouettes, negative space; morally neutral |
| **Memory** | Recall | stored experience, traces, echoes, remembrance |
| **Covenant** | Bind | names, permissions, reciprocal conditions, oaths and magical agreements |
| **Technomancy / Aethercraft** | Interface | designed magical machinery, cores, circuits and instrumented spell systems |

### Proposed high-order domains

| Domain | Verb | Safeguard |
| --- | --- | --- |
| **Time** | Sequence | bounded haste/delay/anchor/stasis; no casual history rewriting, resurrection-by-rewind or indefinite turn denial |
| **Fate / Probability** | Bias | alters likelihood/branching possibility; distinct from Time and from Psychic prediction |

### Exceptional

**Dreaming** is plot-bound exceptional access rather than an ordinary learnable school. It may interact with Psychic, Memory, Resonance and other domains without becoming another standard mastery icon.

## 7. Metaphysical modifier layer

The following are qualities, not schools:

**Sanctified · Profaned · Blessed · Cursed · Hallowed · Blighted**

Lumen is not automatically Sanctified. Umbral is not automatically Profaned.

## 8. Environmental channels and reactions

Battlefields should eventually track four readable channels:

**Atmosphere · Surface · Temperature · Charge**

Representative reactions:

| Existing state | Applied magic | Reaction | Tactical result |
| --- | --- | --- | --- |
| Wet | Lightning | **Conduct** | routes/branches current across connected targets |
| Wet | Frost | **Freeze** | converts setup into immobilization/brittleness |
| Wet | Fire | **Flash Steam** | removes Wet, creates heat/mist/scald behavior |
| Frozen | Fire | **Thermal Shock** | high Break; destroys or converts frozen state |
| Burning | Water | **Quench** | ends Burn and changes field state |
| Burning | Air | **Fan Flame** | expands/intensifies fire at positioning risk |
| Metallic | Lightning | **Surge** | creates conductive routing/magnetic interactions |
| Crystal | Sonic | **Harmonic Shatter** | tuned Break/fragmentation |
| Wet Earth | Earth | **Mire** | movement/position control |

The UI should preview these before confirmation whenever practical.

`modules/magic-field-reactions.js` v0.1 now encodes these as **immutable design-state transitions**. It can preview and resolve state tags such as Wet→Frozen, Wet→Mist, Frozen→Brittle, Metallic→Charged, and Wet Earth→Mire, but it does not yet apply damage, turn-order effects, duration, resistance checks, or combat mutations.

## 9. Cross-mastery map

| Pair | Mastery behavior | Grand Synthesis seed |
| --- | --- | --- |
| **Storm + Lightning** | storms accumulate/route charge; Lightning gains field-triggered strikes | **Heavenbreak Tempest** |
| **Water + Frost** | Wet→Freeze becomes more efficient; ice gains fluid setup options | **White-Tide Dominion** |
| **Air + Sonic** | pressure control extends range, cone shaping and sonic-boom thresholds | **Skybreaker Chorus** |
| **Crystal + Resonance** | lattices store/amplify/distribute tuned frequencies | **Harmonic Prism Array** |
| **Crystal + Lumen** | prisms split, route, focus and persist light effects | **Cathedral of Light** |
| **Metal + Lightning** | equipment/objects become deliberate conductive networks | **Crown of Induction** |
| **Earth + Fire** | unlocks magma/vitrification applications inside Earth | **World-Furnace Fault** |
| **Umbral + Correspondence** | bounded connected shadows become spatial endpoints | **Penumbra Meridian** |
| **Lumen + Umbral** | contrast, silhouette, eclipse and penumbra control | **Eclipse Domain** |
| **Time + Fate** | Time changes when; Fate changes likelihood inside bounded windows | **Moment of Many Roads** |
| **Psychic + Memory** | read/reconstruct/defend remembered experience without equating memory with obedience | **Palace of Echoes** |
| **Spirit + Covenant** | spirit links gain explicit conditions, permissions, consent and reciprocal costs | **Living Accord** |
| **Vital + Fire** | growth acceleration/cauterization with Blight risk | **Phoenix Garden** |
| **Vital + Water** | hydration/cleansing reinforce restoration and ecology | **Worldroot Spring** |
| **Aether + Plasma** | Aether stabilizes/contains high-energy ionized fields | **Aetheric Corona** |
| **Aether + Correspondence** | world currents become routable spatial pathways | **Songline Gate** |
| **Resonance + Correspondence** | frequency signatures identify and route effects through spatial links | **Impossible Coordinate** |

The names above are design seeds. The interaction rules are the durable part; capstone names may change during narrative/content authoring.

## 10. Storm + Lightning exemplar

This pair defines the desired ceiling.

- **2+2:** Storm fields increase the reliability of charge buildup.
- **3+3:** unlock a Cross-School Art that creates a charged front and marks valid strike routes.
- **4+4:** persistent Storm fields automatically accumulate charge and can discharge on movement, casting or marked-state triggers.
- **5+5:** unlock a Grand Synthesis in which the storm itself becomes an electrical network rather than simply adding lightning damage.

Thus a master Storm mage with master Lightning is exceptionally destructive because the two systems change each other's rules, not because both damage coefficients are multiplied.

## 11. Discovery and UI pacing

Do not expose every school at character creation.

Suggested reveal rings:

1. **Early readable layer:** Fire, Water, Air, Earth plus the character's personal established affinities.
2. **First specialization layer:** Frost, Lightning, Crystal, Metal, Sonic and ordinary non-elemental families encountered through teachers/jobs/story.
3. **Deep-build layer:** Storm, Plasma, Vital, Entropy, Umbral, Memory, Covenant, Technomancy.
4. **Rare/high-order layer:** Time and Fate.
5. **Exceptional narrative layer:** Dreaming and Personal Grand Synthesis.

## 12. Implementation boundary

'magic-defs.js' v0.1 is a **design registry**, not a runtime admission registry.

The pure design-side eligibility layer now exists in `modules/magic-mastery.js` v0.1. It can:
- validate 0–5 tree/domain mastery profiles,
- evaluate tree prerequisites such as Water→Frost, Fire+Aether→Plasma, and Air+Lightning→Storm,
- evaluate 2+2 / 3+3 / 4+4 / 5+5 registered cross-mastery thresholds,
- return registered reaction lookups,
- compress detailed 1–5 ranks into the 1–3 UI tier.

It **does not mutate character state, award mastery, unlock spells, or authorize combat use**.

Before executable magic is enabled, later implementation still must add:
- ability definitions for actual spells,
- status/field semantics,
- environmental channels in encounter state,
- mastery XP/rank acquisition rules,
- persistent character mastery storage and save migration,
- UI reaction previews,
- effect-resolver coverage,
- automated combat tests for executable spells.

Unsupported magic must continue to fail closed rather than being simulated through narration-only effects.
