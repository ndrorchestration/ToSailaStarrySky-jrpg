# Cinematic surface textures and night readability — isolated Godot study

**State:** Implemented candidate on draft branch; native test and visual acceptance pending.  
**Parent:** atmospheric continuity draft PR #420 (which itself stacks on PR #417). Noncanonical 960×640 Godot 4.7.2 Compatibility flight slice only. No world-map release or canon progression claims.

## Authored texture assets (binary PNG committed to GitHub)

| Asset | Size | Purpose | Shader |
| --- | --- | --- | --- |
| `godot/flight_slice/textures/terrain_microdetail.png` | 128×128 RGBA | Variations within grass, fractured alpine stone, sand grit, and roughness | `shaders/terrain.gdshader` |
| `godot/flight_slice/textures/foliage_microdetail.png` | 128×128 RGBA | World-anchored leaf, crown and forest-floor fiber granularity without a repetitive per-tree decal | `shaders/foliage.gdshader`, `shaders/understory.gdshader` |
| `godot/flight_slice/textures/water_ripple_detail.png` | 128×128 RGBA | Small-scale ripples/rough sparkle modulations subordinate to existing ocean/shore geometry | `shaders/water.gdshader` |

These are **real imported Texture2D PNG resources sampled by the shaders**, not only procedural noise functions or illustrative image mocks. They are original, offline-generated seamless repeating multi-octave channel masks. None are downloaded, copied from other games, or derived from external stock photos. Full source is in `godot/flight_slice/tools/generate_surface_textures.mjs`; `node ... --check` validates every committed PNG byte against generation and `--write` regenerates assets without external dependencies. Samples are inexpensive base textures, **not** 4K PBR production photogrammetry, artist-approved tile atlases, or a full materials pipeline.

The existing biome height/slope classifications, shared shoreline heights, single-batch foliage, physics and terrain tiles remain unchanged. Tiling is anchored in stable world-space coordinates. Textures never encode gameplay collision or location routing.

## Cinematic / accessibility rules

- Preset night key, cool fill, ambient lighting and fog values have been balanced upward slightly for ship/terrain silhouettes in weather. **No simulated moon, changed lunar phase, celestial lane or story trigger.**
- **K** toggles texture microdetail for exact same-frame visual A/B; default is ON. **V** low-detail overrides K and sends strength 0 for all surface families. Texture maps are still present on disk and in memory; *lower quality does not promise zero sampler cost* until GPU profiling.
- Weather, lighting, magical sky fades from #420 remain uninterrupted. **M** reduced-motion controls vegetation sway and weather particles, not texture appearance; no new blinking/emissive assets.
- Capture test `tests/capture_surface_textures.gd` images golden with texture off/on, storm night with texture off/on, and a dedicated coastal ocean/shoreline off/on pair, with matched viewport, scene clock, camera and route. Native probe ensures rendered pixel differences in terrain/water/foliage screen region. Pixel deltas show integration, **not** artistic superiority.

## Gates and limitations

- Godot import, byte-accurate PNG source verification, `tests/test_surface_textures.gd`, GL capture (4 images), existing atmospheric and touchdown regression, high/low software-GL sweep.
- Do **not** merge or promote to canonical planet textures until creator approves screenshots in representative biomes. At least two GPU targets, distant texture shimmer/mipmap quality, VRAM budgets, perspective transition artifacts, forest path contrast, water shoreline macro-readability, color-blind contrast and the complete high-resolution sprite/normal/roughness atlases remain open.
