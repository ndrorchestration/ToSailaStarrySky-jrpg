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
