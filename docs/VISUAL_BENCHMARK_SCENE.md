# Visual Benchmark Scene — Dragonfly Dusk Dock

Status: **REFERENCE ACCEPTANCE SCENE**
Purpose: define the first scene that must reach near-final visual quality before broad visual propagation.

## 1. Scene premise

Ender stands beside the Dragonfly at a high floating-island dock at dusk.

The scene should immediately communicate:

- enormous vertical scale;
- a lived-in solarpunk settlement;
- a small but unusually capable airship;
- active wind and weather;
- aetheric technology embedded into an organic world;
- quiet wonder rather than spectacle-for-spectacle's-sake.

## 2. Composition

Primary focal hierarchy:

1. Ender;
2. Dragonfly;
3. illuminated dock / local settlement details;
4. distant floating islands and cloud sea;
5. horizon and sky gradient.

Ender should remain readable without dominating the frame.

The Dragonfly should occupy enough screen area to reveal design character while still feeling small compared with the surrounding world.

## 3. Depth bands

Foreground:
- rope, railing, grasses, machinery edge, fabric, or partial structural occlusion.

Playable plane:
- Ender, dock surface, Dragonfly, immediate props.

Midground:
- settlement structures, wind machinery, vegetation, cranes, gangways, lamps.

Far field:
- floating islands, thin bridges, distant lights, moving air traffic.

Atmosphere:
- cloud sea, haze layers, high cloud streaks, dusk gradient, first stars if appropriate.

## 4. Lighting

Time: late dusk.

Lighting contrast:

- cool blue/violet ambient sky;
- warm settlement lamps;
- restrained teal/silver Dragonfly instrumentation;
- subtle reflected light on Ender;
- distant lights softened by atmospheric depth.

No full-scene neon wash.

## 5. Motion

Required subtle animation:

- clouds at multiple speeds;
- wind response in vegetation/cloth/ropes;
- Dragonfly wing/control-surface idle motion;
- aether-core pulse;
- at least one distant moving craft or bird-like silhouette;
- small environmental particles;
- one piece of mechanical infrastructure with a repeating cycle.

## 6. Audio-aware visual pacing

The scene should support Skyward Arpeggio or an equivalent restrained score bed.

Visual motion should not compete with musical phrasing.

If used after a cinematic clip, the final clip frame and this scene should be matchable in:

- camera direction;
- horizon height;
- dusk palette;
- Dragonfly orientation;
- major lighting state.

## 7. Gameplay integrity

This must remain a real playable scene, not a mockup.

Requirements:

- collision valid;
- interactables real;
- Dragonfly state real;
- Ender sprite real;
- background layers performant;
- no nonfunctional decorative UI;
- no fake interaction prompts.

## 8. Quality gates

PASS only when:

- screenshot reads clearly at full 1440×960 presentation;
- screenshot remains readable at reduced size;
- Ender silhouette remains identifiable;
- Dragonfly silhouette remains identifiable;
- at least three depth bands are immediately perceptible;
- lighting establishes time and focal hierarchy;
- there are no obvious placeholder shapes;
- tiled repetition is not visually dominant;
- no effect obscures interaction readability;
- scene could plausibly serve as a store-page screenshot without retouching.

## 9. Propagation rule

Do not scale this visual treatment across the whole game until:

- this scene passes;
- one dialogue scene passes;
- one representative combat scene passes;
- one Dragonfly flight scene passes.

Those four scenes form the reusable visual foundation.


## Implementation candidate — 2026-09-22

Stacked implementation branch: `feat/dragonfly-dusk-dock-benchmark`, based on Visual Foundation v1 draft PR #121.

Current candidate establishes:
- activation only when the player is in the eastern dock region and the real air-navigation state is moored at `wake-dock`;
- banded dusk sky;
- four moving cloud-depth layers;
- distant floating-island silhouettes and settlement lights;
- distant air traffic;
- first-star layer;
- articulated Dragonfly hero rendering with wing motion, core pulse, shield nodes, navigation lights, idle wake, and mooring lines;
- cool dusk grade plus warm dock-light contrast;
- foreground railing/cables and windborne particles for near-plane depth.

**Status: IMPLEMENTED CANDIDATE / NOT YET VISUAL PASS.** This is the first benchmark implementation, not a claim that the store-page screenshot gate has been satisfied. It remains stacked on unverified Visual Foundation v1 while private-repository Actions cannot allocate runners.


## Evidence capture binding
The benchmark acceptance screenshot is captured as `01-dragonfly-dusk-dock.png` by the exact-head visual-evidence harness. The screenshot and manifest SHA must correspond to the candidate under review. Capture alone does not promote this benchmark to PASS.


## Shared Dragonfly binding
The benchmark's ship rendering delegates to `AetherDragonflyVisual` in dock mode. The benchmark may adjust placement and environmental lighting, but it must not maintain an independent Dragonfly hull/silhouette implementation.
