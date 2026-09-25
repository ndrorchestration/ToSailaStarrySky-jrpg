# Chapter 1 — 2.5D Visual Remediation

Status: **PLAYER-ACCEPTANCE REMEDIATION / ACTIVE**

## Direction

Aetherwake now targets an original **2.5D solarpunk JRPG** presentation: pixel-authored characters remain crisp and readable while environments, maps, the Dragonfly, lighting, atmosphere, and cinematic staging create convincing dimensional depth.

The relevant reference principle is the same broad visual construction used by *Star Ocean: The Second Story R*: 2D pixel characters staged against dimensional environments. Aetherwake must not copy Star Ocean assets, compositions, characters, UI, environments, or proprietary designs. The reference is structural, not imitative.

## Expert panel synthesis

### JRPG creative director
- Preserve pixel-character charm; do not replace the cast with generic 3D models.
- Opening quality must establish the visual promise before free movement begins.
- The Dragonfly is the hero object and should receive character-level art attention.
- Every major location needs one memorable silhouette/composition, not interchangeable tile fields.

### 2.5D environment art lead
- Build scenes as camera compositions with foreground, play plane, midground structures, distant geography, cloud/weather volume, and horizon.
- Ground planes should imply perspective and elevation rather than read as flat rectangular boards.
- Use occlusion, cast shadows, haze, scale falloff, and parallax to establish depth.
- Maps may retain deterministic grid/collision logic underneath while rendering as dimensional spaces above it.
### Pixel-character art lead
- Character sprites remain pixel-authored and use integer scaling.
- Do not blur sprites to make them fit smoother environmental art.
- Use contact shadows, light-wrap accents, rim light, and environment-aware contrast to seat sprites into dimensional scenes.
- Preserve distinct silhouettes and authored idle timing for Ender, Lyra, Ionia, Reson, and Aepex.

### Cinematic animation director
- Story-bearing screens never auto-advance merely because a timer elapsed.
- Opening beats use hold/reveal/confirm rhythm: reveal motion may be timed; progression belongs to the player.
- Transition from cinematic opening to controllable sprites should be one continuous visual handoff, not a hard downgrade.
- Use slow parallax, camera settle, foreground wipes, lighting continuity, and one authored hero reveal of the Dragonfly.

### UX/onboarding designer
- Boot/preamble: player-dismissed.
- Title: indefinite hold until explicit New Game/Continue.
- Cinematic scenes: minimum dwell prevents accidental skipping, then explicit advance.
- Interactive scenes: controls appear contextually and do not compete with narrative text.
- Acceptance test should measure comprehension and perceived control, not only mechanical reachability.

### Technical art lead
- Favor a layered 2.5D renderer over an engine rewrite for Chapter 1.
- Current p5 runtime can support perspective cues with layered rendering, transforms, parallax, masks, light overlays, depth sorting, and pre-rendered dimensional assets.
- True 3D geometry can be introduced selectively later; Chapter 1 should not be blocked on a wholesale engine migration.
- Separate visual coordinates from collision/state coordinates so art can evolve without changing quest logic.

### Gameplay engineer
- Do not rewrite working Chapter 1 navigation/combat logic for visual reasons.
- Introduce presentation projection functions between logical map coordinates and screen coordinates.
- Keep save payloads in logical/world coordinates, never camera/presentation coordinates.
- Add visual contracts/tests for pacing, renderer authority, and state/presentation separation.

### Production / QA lead
- The prior technical candidate remains valid evidence for the old tree but is not player-accepted.
- Visual remediation creates a new candidate requiring focused regression plus full Windows re-verification.
- No lower-level promotion occurs until the new exact candidate passes technical evidence and uncoached acceptance.
## Canonical 2.5D scene stack

Every flagship exterior scene should expose at least five perceptible layers:
1. foreground occlusion and close atmospheric particles;
2. player/sprite navigation plane;
3. local architecture, vegetation, props, railings, machinery, ropes, and interactables;
4. mid/far geography, ships, towers, islands, cloud banks, and weather structures;
5. horizon/sky/celestial layer with atmospheric perspective.

Interiors should use at least four:
1. foreground framing/occlusion;
2. character navigation plane;
3. walls, furnishings, machinery, doors, windows, and vertical structures;
4. exterior view/light volume or deeper interior continuation.

## Dragonfly redesign standard

The Dragonfly must stop reading as a collection of rectangles and become a recognizable craft:
- elongated insect-like hull silhouette with a tapered tail;
- two articulated wing pairs with translucent solar/aether membranes;
- readable cockpit/helm glazing and warm inhabited cabin windows;
- visible aether-core heart with restrained teal/silver emission;
- landing legs/docking rig distinct from flight silhouette;
- control surfaces that bank/brake rather than only rotate the whole sprite;
- propulsion wake shaped by speed and heading;
- shield envelope visible only under relevant states;
- damage state with asymmetry, flicker, smoke/vapor, and wing degradation;
- interior materials and window placement correspond to exterior structure.

Required hero states: docked, idle-hover, cruise, bank-left/right, brake, acceleration, shielded, damaged, firing/ability, recovery.
## Map redesign standard

Maps remain deterministic gameplay spaces but render as places rather than diagrams.

### Wake interior
- Replace flat room-color rectangles with a continuous dimensional deck.
- Use perspective floor seams, hull curvature, structural ribs, windows, hanging cables, pipes, plants, tables, bunks, gauges, and warm practical lighting.
- Room identity comes from architecture/props/light, not floating labels alone.
- Keep optional labels as subtle instrumentation, not primary spatial communication.
- Characters must visually pass behind/under selected foreground structures.

### Exterior/dock
- Give the dock vertical drop, railings, gantries, mooring hardware, cloud depth below, distant structures, and moving air traffic.
- Dragonfly should dominate the composition at first reveal.
- Walking toward the ship should increase apparent scale and detail.

### World maps
- Preserve logical collision grids while rendering terrain through projected surfaces and authored landmarks.
- Break visible tile repetition with decals, vegetation clusters, height changes, paths, ledges, bridges, shadow masses, and occlusion.
- Use atmospheric perspective for distant terrain and scale cues.

## Opening remediation sequence

1. Loading indicator may be timed.
2. Story preamble reveals over time but holds until player input.
3. Title/menu holds indefinitely; no idle auto-start.
4. New Game begins Sequence 00 only after a second explicit input.
5. Sequence 00 establishes sky scale + Dragonfly silhouette.
6. Sequence 01 introduces Ender/Ionia with dimensional staging.
7. Transition into controllable dock movement preserves camera, lighting, ship scale, and environment style.
8. First controllable sprite frame must look like the same production, not a fallback representation.

## Acceptance gates

A Chapter 1 visual candidate is not acceptable until:
- no story-bearing screen advances without input;
- title remains stable indefinitely;
- opening-to-gameplay transition has no obvious fidelity collapse;
- Dragonfly is recognizable in silhouette;
- Wake interior no longer reads as a flat debug/map layout;
- representative exterior and interior frames show convincing depth;
- pixel sprites remain crisp and correctly seated in the scene;
- an unedited dock, interior, flight, and map screenshot each meet the project's store-page-quality benchmark;
- all existing gameplay/persistence/combat contracts remain green.

## Production asset replacement matrix

### P0 — opening and first controllable minute
| Surface | Current authority | 2.5D target | Acceptance evidence |
| --- | --- | --- | --- |
| boot/preamble | `aetherwake.js` + title stage | player-paced reveal, volumetric sky depth, slow parallax, no forced story advance | timed idle capture + manual advance test |
| dock reveal | `modules/first-wake-visual-stage.js` | hero Dragonfly composition, deep dock perspective, cloud-drop altitude, foreground cables/gantries | unedited 960x640 dock frame |
| opening → sprites | First Wake visual stage + sprite authority | continuous camera/lighting/scale handoff; no fidelity cliff | side-by-side final cinematic / first controllable frame |
| first interior | First Wake visual stage | dimensional hull, ribs, windows, practical lighting, occlusion layers | unedited interior frame with Ender sprite |

### P1 — Dragonfly hero asset family
One canonical design language must drive all contexts: docked exterior, open-sky cruise, banking, braking, acceleration, shielded, damaged, ability/fire, and recovery. `modules/dragonfly-visual.js` remains the runtime authority until authored raster/3D-derived assets replace individual procedural states. Exterior window/rib/core locations must correspond to interior layout landmarks.

### P1 — Chapter 1 maps
| Map family | Current surface | Required remediation |
| --- | --- | --- |
| Wake interior | First Wake stage / world renderer | projected floor, hull curvature, room architecture, occluding foreground, windows to sky, prop/light-driven room identity |
| dock / boarding approach | First Wake stage | vertical drop, mooring hardware, gantries, air traffic, scale increase toward Dragonfly |
| overworld / island traversal | `modules/preview-world-presentation.js`, `modules/world.js`, preview world assets | projected terrain planes, authored landmark silhouettes, height changes, bridges/ledges, vegetation clusters, atmospheric depth |
| open-sky navigation | `modules/flight-visual-stage.js` | multiple altitude layers, moving cloud volumes, distant islands/towers, route landmarks, speed/bank parallax |
| lore/navigation map UI | `tests/world-lore-map.test.js` + runtime map surface | illustrated dimensional chart aesthetic; retain deterministic locations underneath; avoid debug-grid appearance |

### P2 — legacy preview art retirement
The files `assets/preview/aetherwake-preview-world-pixelart-v2.png`, `aetherwake-preview-interior-pixelart-v1.png`, and related early preview backdrops are reference/provenance until every active runtime call site is audited. They must not silently remain as lower-fidelity fallback art on the accepted Chapter 1 path.

## Camera and composition contract
- Exploration camera target: elevated three-quarter view with readable sprite navigation and visible vertical depth; never pure top-down unless intentionally used for a map UI.
- Keep sprite pixel edges crisp; environment can use smoother gradients, filtered depth textures, fog, bloom-like additive overlays, and subpixel parallax.
- Sprite scale changes only in bounded perspective transitions; normal play uses stable integer scale for readability.
- Foreground objects may occlude the lower 10–25% of characters briefly to communicate depth, but must not hide interaction targets.
- Major scenes need a composition anchor: Dragonfly, aether core, tower, island edge, or strong horizon silhouette.
- Lighting continuity must survive cinematic → playable handoffs: same time of day, key-light direction, atmosphere, and dominant color temperature.

## Opening animation timing contract
- Loading-only motion may be autonomous.
- Story text/reveal may animate, but completion waits for player input.
- Minimum cinematic dwell prevents accidental double-tap skips; after dwell, show a visible continue affordance.
- Use 250–450 ms ease-in/out camera settles between major composition beats; avoid hard frame cuts into gameplay unless narratively intentional.
- Use foreground wipes/cloud passes/ship geometry as transition masks when possible so scene changes feel spatial rather than slideshow-like.
- The first controllable frame should preserve at least three visual anchors from the preceding shot (for example sky palette, Dragonfly scale/location, dock gantry silhouette).

## Definition of visual completion
Visual acceptance is not achieved by contract tests alone. For each P0/P1 surface, require: (1) deterministic runtime test PASS, (2) fresh screenshot or short capture from the exact candidate, and (3) human visual review against this document. Any scene that still reads as debug geometry, flat tile board, or obvious placeholder remains OPEN even if mechanically correct.
