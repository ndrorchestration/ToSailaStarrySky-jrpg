# Godot .NET native adaptive boundary mesh — October 26, 2026

**STATUS: noncanonical engineering study, DRAFT PR #375, not production integration or art acceptance.**
**Exact engine-tested head:** `c470e509d2abb19bddcab398a5baae74bade7d6b`.

## Engineering change

Prior `WatertightTiles.cs` proof used **the globally finest active tile resolution on every face and interior**, preventing T-junctions but scaling poorly. This checkpoint retains it as a baseline and adds:

- `AdaptiveBoundaryTiles.cs`: independent per-tile 8×8 **coarser interiors**. Boundary cells introduce vertex subdivisions at **shared integer cube coordinates**, triangulated as outward-facing fans, so fine-neighbor edges and cube-face edges share exactly identical grid points. Each complete mesh candidate is checked for a **closed two-incident-edge manifold** before native scene replacement. Max demonstrated LOD=2, max mesh budget 50,000 triangles.
- `CameraTilePriority.cs`: deterministic outward-direction prioritization of a currently active level-1 tile using the live Godot camera position. Prototype exercises a selected refinement at frame 12, reverses the exact selected parent at frame 24, preserving atomic logical six-face coverage. This is a bounded demonstration **not continuous streaming or a screen-error LOD manager**.
- `PlanetDebug.cs`: material + native trimesh collider integration, Camera3D orbit/input preserved, diagnostic receipts for camera choice, mesh edge closure and triangle savings.
- `godot-net-native-scene.yml`: rejects missing per-level native seam checks, camera-priority selection, both LOD transitions, ray contact, real nonblank 960×640 framebuffer, and mathematically inconsistent reported triangle savings. All original C# source contracts still link from `../WorldMap.Contracts/*.cs`.

## Actual hosted Godot 4.7.2 .NET CI evidence

[Native study run #40281324876](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40281324876) — **SUCCESS at exact head** `c470e509...`.

| State | Original uniform tessellation | New per-tile interior / stitched boundary | Saved | Nonmanifold edges |
| --- | ---: | ---: | ---: | ---: |
| 9 tiles (initial level 1) | 3,072 triangles | 1,592 triangles | 1,480 (48.2%) | 0 |
| 12 tiles (camera-prioritized level 2) | 12,288 triangles | 2,560 triangles | 9,728 (79.2%) | 0 |
| 9 tiles (reverted) | 3,072 triangles | 1,592 triangles | 1,480 (48.2%) | 0 |

Direct job log: `GODOT_CSHARP_CAMERA_PRIORITY_PASS selected=PositiveZ/1/1/1`; `GODOT_CSHARP_ADAPTIVE_CI_PASS`; native `GODOT_CSHARP_COLLISION_PASS`; exact 960×640 PNG/foreground check passed (117 non-background samples). Official Godot C# assembly built with 0 errors and 0 compiler warnings. Real software-rendered image artifact [#12631414070](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40281324876/artifacts/12631414070).

Note: Independent C# contract workflow at [run #40281324986](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40281324986) also succeeded. Repository smoke status must be verified separately; do not assume eventual PASS while queued.

## Hard limitations — do not overclaim

This is still a fixed-radius **UNDisplaced, mathematically closed test sphere**, not dynamic planet terrain or production-ready seamless LOD. The algorithm subdivides **all outer boundaries** at the finest active *integer* grid, whether or not a particular edge actually neighbors a fine tile. True neighbor-aware stitching could reduce the boundary workload further. Meshes are fully rebuilt synchronously; no background jobs, cancellation, tile reuse, amortized work frames or stale-result ownership gates exist. The triangle savings are **geometry counts**, not measured GPU FPS, VRAM or CPU latency benefits; additional vertices and collision reconstruction could offset wins. LOD2 and 50k-triangle demo guard is not a scale target.

No authored coastlines, water, weather, atmospheric scattering, physically relevant planet radius, displaced world normals, biomes, meaningful ship landing, live navigation to moon, sensitive story routes, Chapter I saves, Windows GPU profiling or creator visual review. No private lunar code uploaded to the public repository. The historical v0.8.1 GDScript source remains in the owner-private Library, unimported into the private GitHub development main branch.

## Next sanctioned gates

Incrementally validate (1) true neighbor-aware edge density matching and mesh/physics changes under displacement, (2) camera-driven **repeatable** LOD selection with hysteresis and bounded per-frame work/cancellation, (3) geodesic atlas tile identity, (4) authored ocean/terrain/coast material stacks and physically meaningful lighting, (5) ship/planet surface transitions and private route content behind a verified private source boundary. Human art and production release acceptance remain separate decisions.
