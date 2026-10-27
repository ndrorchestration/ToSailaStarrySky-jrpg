# Height-derived coastline and noncolliding highland dressing

**Scope:** Native Godot 4.7.2 Compatibility flight-lab candidate; noncanonical. Stacks directly on draft PR #454 (regional biome textures); do not merge, publish, or reinterpret as globe-wide world art.

## Problem and approach

Previous sand wetness relied on a local height threshold. That can produce wet-looking **lowlands not bordering the sea**. The new `coast_distance.gd` takes the already authoritative 256×256 RF terrain height image, marks actual wet/dry height crossings against `TerrainStudy.SEA_LEVEL`, and bakes a deterministic **signed, bounded coastal distance** by eight-neighbor chamfer passes. Positive is inland; negative is underwater. Both land and water materials consume the **same ImageTexture**, while all geometry, terrain heights, collision, climate/clock, and secret paths remain unchanged.

The terrain shader now darkens sand within a coastal proximity window instead of using an arbitrary height-only band. Ocean foam still requires shared terrain-derived bathymetric depth and tile coverage, but its visual softness can be modulated by distance from that coastline. The texture is a bounded local study mask, **not** a globe-scale geodesic coastline dataset or maritime navigation authority.

## Forest floor and rock detail

- A muted moss/leaf-litter ground-color band uses existing authored forest region boundaries and previously committed original terrain and biome PNG texture channels. No new assets are licensed or imported.
- `rock_dressing.gd` builds an **at most 88-instance** deterministic highland MultiMesh of faceted rock forms. The art shader reuses the **same original terrain_microdetail.png and biome_macrodetail.png** resources. Placements sample actual ground elevation. Rock instances have **no static/rigid/collision bodies**, do not replace actual ground, and cast no shadows.
- Presentation-only `V` disables the rock batch; `K` controls rock fine grain, `J` controls regional rock colors, retaining earlier controls.
- These are small low-poly shapes, not final high-fidelity cliff meshes or PBR atlases. Rock instancing is constrained to suitable highland height/slope and skips beaches.

## Mandatory acceptance

- Godot native test `tests/test_coast_distance.gd`: analytic straight coast, negative underwater/positive inland, actual height sampler agreement, single texture shared with land/water, preserved sea-level identity and unaltered terrain/ship/clock.
- `tests/test_rock_dressing.gd`: bounded instance count, deterministic placements anchored in the authoritative sampler, no physics objects, genuine texture bindings, quality toggles and unchanged touchdown.
- `tests/capture_coast_rocks.gd`: three 960×640 matched-pose **real OpenGL** A/B pairs—coast (with/without J regional/wet material), forest floor, and highland (outcrops visibility). Pixel differences do not establish visual quality or physically realistic coastal distance.
- All existing coastline region, environmental grading, manual flight, native physics touchdown, cinematic camera and software-GL sweeps must pass on exact head.
- Pending: inspect actual screenshot coast and rock silhouettes, distance-transform sampling artifacts at water edges, shoreline foam when at high altitude, target hardware GPU budget, other climate states, production globe/multiple islands. No designer approval or final globe atlas implied.

**No narrative/canon changes:** Five Lights, Chapter One, ship engine, Moon Bridge, auroral lanes, job/plot magic separation untouched.
