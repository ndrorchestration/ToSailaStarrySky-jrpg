# P0 planetary bathymetry and future underwater exploration

**Status:** CREATOR-ESTABLISHED WORLD-SYSTEM REQUIREMENT (2026-10-27), not a finished feature, approved seabed atlas, geography lock or underwater gameplay release. Preserve public/restricted lore boundaries.

## Product requirement

**Map the entire planetary surface beneath the oceans as real topography.** A navigable ocean must be more than a flat water plane or a color overlay: it needs persistent seabed relief so future **underwater exploration** can use the same underlying world geography. Do this from the start of the global map data design even if underwater swimming, vehicles, camera, fauna, story, missions and access gates are built much later.

### Coordinate and data contract (PROPOSED implementation)

- Use one planetary geodetic reference frame for emergent terrain and submerged seabed, with latitude/longitude and a sampled signed **bed elevation relative to a documented sea-level datum**. Do not confuse surface-water height, ship altitude, total ocean depth and seabed elevation.
- Define ocean depth as `max(sea_surface_elevation - seabed_elevation, 0)` in matching units and reference frames; keep the planet's actual radius and sea-level datum configurable until approved.
- Preserve coastal transition continuity: uplands → beaches/estuaries → shelves → continental slopes → deep basins. Seafloor ridges, valleys, seamounts, trenches, reef elevations and submerged caves are **design possibilities**, not approved named geography or canon.
- Maintain deterministic seam-safe data across the antimeridian and poles. No divergent coastlines between orbital globe, air navigation chart, water shader, local ground mesh or a future underwater scene.
- Stream bathymetric height/normal/biome data at multiple LODs, with low-resolution world overview and fine tiles for dive-scale interaction. Physically navigable collision meshes must match their rendered seabed where underwater access is granted.
- Keep **discovery/knowledge** separate from physical existence: the world has ocean-floor topology even when the map does not reveal it. Sonar, charting, visibility, pressure, depth zones and traversal restrictions are future mechanics, not automatically approved.
- At the water rendering layer, drive shallow-water color, shelves, subsurface scattering/fog and coastline materials from shared depth data rather than hand-painted disconnected masks. Performance paths may use simplifications but must not change world geography.
- Record any authored overrides with stable region/tile IDs, provenance and versioning for later save persistence and navigation. Avoid exposing restricted lunar/celestial content.

### Staged work without blocking cinematic P0

| Stage | Acceptance expectation |
|---|---|
| **Now — cinematic ocean** | The shoreline is derived from terrain vs water-surface elevation; shallow shelf and deep-water hues reflect a consistent height source; no double coastlines or flat-color sea illusion |
| **Globe geography build** | Signed global terrain/bathymetry atlas covers ocean basins as well as land; deterministic longitude wrap, pole continuity and stable streamed LOD |
| **Underwater visual slice (later)** | One test site: sea surface → descent through water column → collision-matched seabed → return to surface; coherent light absorption and fog at depth |
| **Full underwater gameplay (future)** | Movement, hazards, ecology, discoveries, save/load and progression designed and creator-approved separately |

### Verification / regression gates

1. Same sample at the coastline yields the same bed elevation for air/land/ocean and underwater consumers.
2. A point at sea level has depth zero; positive dry-land elevation is not classified as underwater; negative bed elevations produce positive depth.
3. LOD boundaries, antimeridian and polar regions have no topography gaps, cracks or contradictory wet/dry classifications.
4. Nearshore seabed and offshore contours remain coherent in both native Godot screenshots and actual physics collision samples; tests alone are insufficient to assert cinematic quality.
5. When introduced, underwater travel must respect explicit exploration/ability gates and measured performance on supported hardware.

### Current implementation boundary (verified from source, not gameplay acceptance)

In the noncanonical local Godot flight slice, `terrain.gd` already produces a signed `sample_height(x,z)` beneath `SEA_LEVEL`. The water shader samples a texture baked from that same function. This gives a **local prototype starting point** for coastal depth coloring. It is **not** an authored planetary bathymetry atlas, realistically varied deep-ocean topography, underwater collision surface, or swimmable world. The local sample currently has modest shallow relief and cannot be projected onto the whole globe without a separate geographic data and LOD architecture.

**Priority:** This is foundational design work underneath the highest-priority cinematic surface world, not permission to divert current effort to speculative underwater gameplay before the hero route is visually accepted. Track [P0 planetary world map #387](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/387).

## 2026-10-27 — Implemented first local depth contract (PR #390 only)

- `godot/flight_slice/bathymetry.gd` now exposes local bed elevation, water depth and submerged classification using **the existing TerrainStudy height sampler and SEA_LEVEL**, without new geographical noise or a second ocean floor.
- `water.gdshader` accepts the sea-level datum as a shader uniform, derives shelf depth from the pre-existing signed RF height texture, and adds restrained shallow-water color response. It does **not** create playable underwater space.
- `tests/test_visuals.gd` checks sampled offshore/shore/forest heights and datum consistency. The pre-existing native GL capture script now additionally attempts three HUD-free screenshots without changing the existing six standard-capture markers.
- **Verification gate:** This is a code candidate until exact-head native Godot CI and capture artifacts finish successfully. Native outputs must still be visually inspected and approved by the creator. Global bathymetry and open-ocean depth contours remain unimplemented.

