> **2026-10-27 current production/ship notice:** Read the [cinematic production and orphan-work audit](2026-10-27_CINEMATIC_PRODUCTION_ORPHAN_AUDIT.md) before implementing this historically authored visual grammar. **Aureate Wake** is the protagonists' dragonfly-derived home and current flight hero-asset target. **The Dragonfly** is a different larger Frigate, so historical “Dragonfly as the visual hero object” language below does not authorize their substitution. The five character *story energies* are Ender Spirit, Lyra Water (plus pink Spirit motif), Ionia Earth, Reson Fire and Aepex Air, distinct from learned schools/VFX palettes. Old screenshots/asset drafts and technical capture PASS are not creator art acceptance. Preserve the luminous pixel-authoring thesis while using forward Godot 4.7.2/GDScript.

---

# Aetherwake Visual Bible

> **2026-10-25 authority update:** The player-facing title is **To Sail the Starry Sky** (Aetherwake is the historical/in-world identifier). Forward implementation uses **Godot 4.7.2 / GDScript**. Preserve the established visual thesis below. For newer creator-specific character locks, planetary fidelity, Dragonfly scale, and physical world grounding read [CHARACTER_AND_ART_AUTHORITY.md](CHARACTER_AND_ART_AUTHORITY.md), [WORLD_SHIP_VISUAL_DIRECTION.md](WORLD_SHIP_VISUAL_DIRECTION.md) and [AGENT_HANDOFF_INDEX.md](AGENT_HANDOFF_INDEX.md); historical statements about open eye/hair/outfit traits or engine strategy may be superseded.

Status: **CANONICAL VISUAL DIRECTION**
Scope: project-wide visual language for gameplay, UI, magic, cinematics, environments, characters, the Dragonfly, and authored video clips.

## 1. Visual thesis

Aetherwake should look like the idealized memory of a late-16/32-bit JRPG reconstructed with modern lighting, atmospheric depth, cinematic composition, responsive animation, and a strong solarpunk sky-fantasy identity.

The goal is not literal retro simulation and not generic HD-2D imitation. The game must remain recognizably pixel-authored while using modern presentation techniques where they materially improve depth, drama, legibility, or atmosphere.

A screenshot with the logo removed should still be recognizable as Aetherwake.

## 2. Core identity

Primary visual idea: **Solarpunk Sky Fantasy**.

Recurring signatures:

- enormous skies and vertical scale;
- luminous cloud strata and distant floating geography;
- intimate human-scale settlements nested inside much larger natural and engineered systems;
- warm reclaimed materials against cool aetheric illumination;
- living machinery, botanical geometry, rope, cloth, wood, brass, stone, glass, weathered ceramics, and hand-maintained technology;
- aether systems expressed through restrained teal/silver light rather than generic neon;
- the Dragonfly as the visual hero object;
- air, weather, altitude, wind, and pressure expressed visually at all times.

## 3. Palette hierarchy

Canonical palette families:

- Deep Navy / Violet Shadow — structural darkness, deep interiors, night sky, negative space.
- Scioto Blue — atmosphere, distance, daylight sky, reflected environmental light.
- Solar Teal — aetheric systems, instrumentation, selective magical emphasis.
- Parchment / Warm Ivory — readable text, maps, cloth, human warmth.
- Rust / Copper / Amber — machinery, warmth, impact, hearth light, danger accents.
- Soil / Bark / Moss — grounded natural materials.
- Bioluminescent Green — rare living magic and ecological phenomena.
- Silver-Blue — Ender's air/sonic signature and high-pressure magic.

Rule: saturation is hierarchical. Ambient scenery remains quieter than interactables; interactables remain quieter than major magic; world-changing magic may temporarily break the normal palette rules.

## 4. Pixel and rendering policy

Logical gameplay surface remains 960×640.

Desktop presentation may scale that surface, but authored pixel relationships must remain coherent.

Rules:

- pixel edges remain intentional;
- do not mix incompatible pixel densities casually;
- avoid smooth vector-like silhouettes inside normal gameplay art;
- use irregular edges, overlap, decals, clusters, and bespoke landmarks to break obvious tile-grid repetition;
- use subpixel motion sparingly; sprite readability takes priority;
- particles may move smoothly, but their rendered shapes should remain compatible with the pixel presentation.

## 5. Environment depth stack

Every major location should be designed as a layered depth composition:

1. foreground occlusion / close silhouettes;
2. playable ground and collision-bearing layer;
3. local architecture, vegetation, props, and interactables;
4. secondary terrain and structures;
5. distant islands / towers / air traffic / weather masses;
6. cloud strata and atmospheric depth;
7. horizon / celestial layer.

At least three perceptible depth bands should be visible in major exterior scenes.

## 6. Lighting system

Lighting is a core aesthetic system, not decoration.

Required behaviors:

- directional time-of-day tint;
- warm local practical lights;
- aetheric teal/silver point-like illumination;
- weather attenuation;
- cloud shadow and atmospheric dimming;
- night scenes preserve color separation instead of collapsing to black;
- spell effects influence nearby visual elements;
- lightning and major energy discharges briefly alter scene-wide illumination;
- fire produces warm local contrast;
- frost cools nearby reflected light;
- high-level magic may affect multiple visual layers.

Bloom-like effects must be restrained enough that pixel structure remains legible.

## 7. Atmosphere and motion

Major scenes should feel alive even when the player is idle.

Subtle motion vocabulary:

- cloud drift at multiple depths;
- grass and foliage response;
- flags, cloth, ropes, cables, and hanging objects;
- drifting spores, seeds, dust, mist, sparks, ash, or rain as location-appropriate;
- tiny distant air traffic;
- machinery pulses, belts, vanes, shutters, pumps, gyros, and control surfaces;
- water, surf, condensation, vapor, and pressure wake.

Rule: ambient motion is quiet. Signature abilities and story moments need contrast.

## 8. Character presentation

Character-specific authority lives in the Character Art Direction & Implementation Contract.

Project-wide requirements:

- each protagonist must have a distinct silhouette at gameplay scale;
- locomotion and idle behavior should communicate personality;
- important characters require authored story gestures in addition to generic walk/idle;
- character colors must remain legible against common environment palettes;
- party members should never become visually interchangeable because of shared animation timing;
- portraits, field sprites, combat poses, and cinematic depictions must describe the same person.

## 9. Dragonfly hero-asset standard

The Dragonfly is not ordinary scenery.

It should support:

- recognizable silhouette at multiple scales;
- articulated wing/control surfaces;
- aether-core and instrument lighting;
- propulsion state changes;
- docking, idle, acceleration, banking, braking, shielding, damage, firing, and recovery states;
- wake distortion / particle behavior;
- warm lived-in details that distinguish it from military machinery;
- readable interior/exterior visual continuity.

The craft should be identifiable in silhouette without labels.

## 10. Magic visual grammar

Magic must behave like transformed physical conditions, not only colored projectiles.

Examples:

- air: pressure, displacement, debris, foliage reaction, cloud disturbance;
- sonic: compression rings, visible wavefronts, environmental vibration, delayed structural response;
- water: flow, spray, reflection, refraction, pooling;
- frost: propagation, crystallization, surface takeover, brittleness;
- fire: ignition, radiant light, smoke, heat shimmer;
- lightning: charge buildup, branching, scene flash, conductive path;
- psychic/spirit/arcane domains each require distinct geometry and temporal behavior.

Major abilities follow:
**anticipation → formation → release → impact → aftermath**.

## 11. Camera language

Exploration camera:
- stable;
- readable;
- predictable;
- minimal unnecessary movement.

Authored cinematic camera:
- slow pans;
- controlled zooms;
- foreground parallax;
- reveal framing;
- brief impact shake;
- purposeful silhouette composition;
- vertical scale emphasis.

Never use camera motion merely because it is available.

## 12. Combat presentation

Combat remains mechanically readable first.

Visual requirements:

- location-specific battlefield staging;
- foreground/background depth;
- readable party/enemy spacing;
- anticipation poses before major abilities;
- impact frames for high-force attacks;
- environmental reaction;
- ability-specific lighting;
- restrained screen shake proportional to force;
- persistent aftermath where narratively meaningful.

## 13. UI visual language

UI should derive from:

- Dragonfly instrumentation;
- cartography;
- field notebooks;
- aether gauges;
- crafted mechanical frames;
- botanical and geometric motifs.

Avoid generic rectangular fantasy panels where possible.

Priority order:
1. information hierarchy;
2. interaction clarity;
3. visual identity;
4. ornament.

## 14. Three presentation layers

Aetherwake has three coordinated visual layers:

### Layer A — Gameplay pixel art
Primary interactive presentation.

### Layer B — In-engine cinematic presentation
Same assets and world, but with authored camera, lighting, overlays, transitions, and animation.

### Layer C — Authored video cinematics
Short pre-rendered clips for visual events that exceed the normal runtime camera or animation budget.

All three layers must depict the same canon, materials, silhouettes, proportions, palettes, and magic behavior.

## 15. Screenshot gates

Every major visual milestone should produce canonical screenshots at 1440×960 presentation.

Required gates:

- title;
- First Wake opening;
- Ender field scene;
- Lyra introduction;
- representative village;
- representative wilderness;
- representative combat;
- Dragonfly docked;
- Dragonfly in flight;
- weather event;
- dusk/night scene;
- signature magic;
- menu;
- one cinematic transition frame.

A mechanically passing build can still fail visual acceptance.

## 16. Visual acceptance test

A benchmark scene is not visually complete until an unedited gameplay screenshot could plausibly serve as a store-page hero image.

Evaluate:

- silhouette clarity;
- focal hierarchy;
- atmospheric depth;
- palette cohesion;
- lighting;
- environmental storytelling;
- motion hierarchy;
- uniqueness;
- absence of obvious placeholders;
- UI cleanliness where present.

## 17. Current implementation boundary

Existing pixel-art recovery work (#113–#116) is implementation material, not automatically final art authority.

Before promotion:

- reconcile against this Bible;
- keep provenance clear;
- reject pieces that introduce a conflicting style;
- prefer one coherent current-main visual foundation over parallel visual stacks.

Old stale branches remain provenance only unless cleanly extracted.
