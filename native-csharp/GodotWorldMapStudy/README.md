# Godot 4.7.2 .NET C# — actual six-face globe scene (experimental)

**Scope: PUBLIC-SAFE NONCANON ENGINEERING STUDY, NOT A PRODUCTION GAME FEATURE.**

This is an isolated **real Godot .NET** proof of executing the author's verified [C# logical world-map contracts](../WorldMap.Contracts/) in native Godot with real `World.tscn`, `MeshInstance3D`, `Camera3D`, lighting and framebuffer output. It is stacked on [PR #368](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/368), **without changing any original C# contract source, GDScript study, story, save or release path**.

The 6 initial cube-face roots are checked, one root is atomically replaced with 4 children, the nine-leaf set is verified complete, and 9 native Godot triangulated sphere tiles are built. The camera orbits the illustrative debug sphere. The scene's runtime assertions print `GODOT_CSHARP_WORLD_PASS`. Opt-in `-- --capture` saves a real 960×640 viewport screenshot from the GL Compatibility backend.

Requires Godot **4.7.2 .NET/Mono** and .NET **8** SDK. The standalone `net8.0` contract suite from PR #368 is retained and independent. To run:

```bash
dotnet restore native-csharp/GodotWorldMapStudy/StarrySkyWorldMapStudy.csproj
dotnet build native-csharp/GodotWorldMapStudy/StarrySkyWorldMapStudy.csproj -c Release
godot-mono --headless --audio-driver Dummy --path native-csharp/GodotWorldMapStudy --quit-after 45
xvfb-run -a godot-mono --path native-csharp/GodotWorldMapStudy --rendering-driver opengl3 --audio-driver Dummy --quit-after 120 -- --capture
```

Only the actual CI logs can establish that the native build/import/render passed. This is **not** tile streaming, true LOD edge stitching, continuous terrain, collision, visual polish, ship navigation, a canonical planetary radius, lunar exploration or release readiness. Native previews are not substitute evidence for creator art approval or Windows hardware performance.

## Layout safety

- Code uses the existing independent C# source in `../WorldMap.Contracts/*.cs` via MSBuild compile links, without a parallel fork.
- `World.tscn` is an isolated experimental main scene and does **not** change the actual game's main scene.
- No private moon, route, plot, or protected gameplay data is used.
- This public project is a technical prototype only; do not promote it to canon.


## 2026-10-26: Verified bounded mesh continuity and collider iteration

Native CI now exercises a **real reversible mesh lifecycle**: after first constructing nine spherical surfaces, it refines one level-1 tile into four level-2 tiles (twelve total), then coarsens the exact same four leaves back to their parent (nine total). At each state, `WatertightTiles.cs` calculates all shared edges in **integer cube-face coordinates**, ensures every undirected triangle edge has exactly two incidences, and refuses any incomplete/overlapping six-face quadtree cover before replacing native objects. This includes physical seams between adjacent cube faces, not merely logical addresses.

**Exact previous checkpoint:** native [run 40277716804](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40277716804), at `41f7471c60dfcd24b9cda57e4151c33edb216e83`, **PASS**:
- Six-face initial cover: 9 tiles, 3,072 triangles, 4,608 distinct mesh edges, 0 nonmanifold edge incidences.
- Mixed-depth cover: 12 tiles, 12,288 triangles, 18,432 distinct edges, 0 nonmanifold edge incidences.
- Reverse LOD transition: back to 9 tiles, 0 nonmanifold edge incidences.
- Each tile has a native `StaticBody3D` with a two-sided `ConcavePolygonShape3D`. Native camera-to-center physics ray hits the collider.
- Godot .NET/Mono 4.7.2 compiles with 0 errors/warnings; viewport captures an actual 960×640 PNG, and the nonblank-frame guard passes. Existing C# contracts and game smoke tests remain passing.

Real orbit input keys: `A/D` rotate longitude, `W/S` adjust camera latitude, `Q/E` adjust distance/altitude. No player aircraft is implemented.

**Implementation limitations to retain in all claims:** the demo meshes every face to the **uniform finest active grid resolution** to prevent T-junctions. This is deliberately bounded at level 2 and at most 50,000 triangles; it is NOT scalable near-field adaptive LOD or a terrain stitcher. Integer-grid edge-incidence checks prove combinatorial closure of the constructed debug sphere but not physical smoothness or correct displaced terrain normals at all planetary scales. The Godot collider is a static triangle mesh for a debug planet, **not** character/ship physics or tested landing. There are no authored biomes, ocean, geography, art, route secrets, save system, moon traversal, target GPU results or developer-approved visual acceptance.

[Public Celestial Arc tracker #372](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/372) and the private development ledger are authoritative for the next gameplay production gates. No merge and no migration/admission from the historical GDScript prototypes have been performed.
