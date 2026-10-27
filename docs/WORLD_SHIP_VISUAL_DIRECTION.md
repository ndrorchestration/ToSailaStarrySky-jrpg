> **SHIP IDENTITY CORRECTION — CREATOR CANON, 2026-10-27.** **Aureate Wake** is the protagonists' dragonfly-derived compact **home ship**; **the Dragonfly** is a **different**, larger **Frigate-class** airship. The combined “Dragonfly / Aureate Wake” section further below is a **superseded historical working concept**, not authority to collapse both vehicles. Body volume, exact strut/mast counts, Wakeheart helm, interiors, lighting/rig design, roles and plot involvement remain **open unless separately creator-approved**. [Draft #408](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/408) is original, unapproved Aureate Wake silhouette work only; do not treat it as final art or as the Frigate. See [dated audit](2026-10-27_CINEMATIC_PRODUCTION_ORPHAN_AUDIT.md).

---

# World, Dragonfly and presentation — creator-aligned handoff

**Scope:** public-safe art/space goals from creator and Notion worldbuilding. Existing [VISUAL_BIBLE.md](VISUAL_BIBLE.md), [VISUAL_BENCHMARK_SCENE.md](VISUAL_BENCHMARK_SCENE.md), and [CINEMATIC_CLIP_CONTRACT.md](CINEMATIC_CLIP_CONTRACT.md) remain the detailed acceptance contracts.

## The visual promise

**Premium, distinctive solarpunk science-fantasy JRPG:** epic skies, compassionate human-scale detail, luminous ocean/atmospheric horizons, excellent environmental composition, handcrafted wood/brass/rootwood/cloth/glass/aethercraft, legible grounded characters, and a ship that reads as a home. Avoid all-placeholder geometry, undifferentiated neon, clinical mockups, flat empty sky, visual-only terrain without walkable correspondence, and screenshots that rely on labels to convey wonder.

Palette hierarchy already exists in VISUAL_BIBLE: deep navy/violet shade, Scioto sky blue, selective solar teal, parchment ivory, rust/copper/amber, soil/bark/moss, rare bioluminescent greens, silver-blue Ender magic. Preserve materials and selective saturation rather than blanket glow.

## Planet and scene-scale requirements

- **Creator direction:** a vast spherical planet with oceans between distant continents, north/south poles, biome/climate diversity, geographic continuity at the ±180° seam, and authentic horizon curvature. A low-altitude Dragonfly sees a **local horizon**, not the far hemisphere. A separate globe/chart view represents broader known geography and discovery.
- Suggested surface hierarchy: ocean depths, reefs/shelves/coasts, wetlands/river mouths, forests, deserts/steppes, mountains, polar ice, inhabited archipelagos; environmental placement tied to latitude/weather/altitude rather than random decorative colored patches.
- Distinguish **subsurface / surface / low sky / high sky / upper sky**. Distinct camera height, cloud and weather density, floating-mass silhouettes, local movement and late travel changes should make altitude meaningful.
- **Prototype-only:** reference radius 6371 km and approximately 30/70 land/ocean ratio are test/visual targets, **not locked planet radius, accepted geography, climates or canon terrain atlas**.
- Performance architecture: Godot spherical/geodesic math, streamed terrain/chunks with LOD and capped budgets, robust polar/wrap traversal, render-horizon culling, chart fog-of-discovery and persistent coordinates. A checked Python/JS model is not equivalent to a native high-fidelity rendered world.

## Dragonfly / Aureate Wake — identity and scale

**Creator-directed vehicle:** distinctive **dragonfly-inspired compact planar skiff**, enclosed hull roughly the volume of **three standard 20-foot shipping containers** (about 100–115 m³, context only), with larger deployed appendages. Not a galleon, conventional airplane, floating fortress or literal insect.

Working visual assembly: armored *thorax* body, reinforced hammerhead prow, segmented rear abdomen, **four articulated translucent veined wing membranes**, **three planar masts**, central root-and-crystal **Wakeheart** helm, **six retractable landing struts**, living armored rootwood/brass/bronze/stone/moss textiles and restrained aether illumination. External sails/masts/wings do not count toward compact hull volume. Final 3D proportions, deployment gameplay and exact asset approval remain open.

It is also a **mobile home**: captain's work and care, navigation core, limited bunks, repair stores, possible child's nook, communal space, future Aepex workstation, domestic personal objects. Every improvement should support character scenes and livelihoods, not only propulsion stats. Preserve plausible habitable space for five protagonists, Talen and occasional guests without inflating the hull.

**Naming caution:** Dragonfly is a design identity, Aureate Wake the primary ship narrative name. *The Unfinished Song* alias relationship remains unresolved; historical Rootwake/Dragonwake are proposal labels, not authority to rename the ship.

## Visual benchmark / ground truth

A **Dragonfly dusk dock** view should clearly show Ender and his real grounded feet, compact detailed Dragonfly, an inhabited timber/brass dock with occluding props, far islands/sky traffic, multi-layer cloud sea, warm lamps against cool blue/violet evening and restrained teal aether glow. Visuals are only acceptable when collision, actor foot positions, prop occlusion and interactions correspond to a physically coherent traversable scene. If the scene art implies islands with gaps, do not silently assume the 30×30 contiguous playable topology has physically separated bridges. This remains open decision **AW-WORLD-SURFACE-01**.

Ship may travel by free flight, normal regional lanes and eventually more advanced methods. Higher-speed/late-game traversal must preserve narrative recruitment gates; no new hidden routes or advanced world reveals may be fabricated here.

## Native acceptance

Use **Godot 4.7.2 GDScript**, Forward+ for high-fidelity desktop testing and separately verified Compatibility fallback where required; Blender-authored geometry/materials preferred over permanent primitive proxies. Real screenshots must come from actual native Godot, not an offline CPU illustration. Test orbital/local/ground/ship views; lighting, shader compilation, controls, target FPS/VRAM, chart-to-world state, actor scale/landings/collision, and creator review independently.

See [world geography Notion](https://app.notion.com/p/3ebf5bad238b8154a273e3096e98ed44), [Dragonfly Notion](https://app.notion.com/p/3e1f5bad238b8179a30af8a9520d0f07), [ship as home](https://app.notion.com/p/3e2f5bad238b8192a704f3ccb2b552c2), [cinematic planetary plan](https://app.notion.com/p/402f5bad238b81d3b96ef7b8641dd372), [planetary requirements #348](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/348), and [Godot visual quality #350](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/350).
