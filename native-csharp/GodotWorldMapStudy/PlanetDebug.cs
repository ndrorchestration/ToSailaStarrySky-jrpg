using System;
using System.Collections.Generic;
using System.Linq;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// ACTUAL Godot .NET scene exercising the independently verified C# logical quadtree.
/// Creates native ArrayMesh sphere-face tiles, meshes a bounded atomic refinement,
/// moves a real Camera3D, and captures an actual viewport image on demand.
/// Deliberately NON-CANON: sphere radius/colors and "biomes" are debug fixtures.
/// No collision, save persistence, world authority or gameplay route is established.
/// </summary>
public partial class PlanetDebug : Node3D
{
    // Geometry spacing lives in CubeSphereLattice so sibling/root borders
    // share exact node positions; no independent per-tile step calculation.
    private readonly TileBudget _budget = new(64, 128);
    private IReadOnlyList<TileId> _cover = QuadtreeCoverage.SixFaceRoots();
    private readonly List<MeshInstance3D> _rendered = new();
    private Camera3D? _camera;
    private int _frames;
    private int _assertions;
    private bool _captureRequested;
    private bool _captureSaved;

    public override void _Ready()
    {
        _captureRequested = OS.GetCmdlineUserArgs().Contains("--capture");
        try
        {
            Check(QuadtreeCoverage.IsCompleteSixFaceCover(_cover), "six-face initial cover");
            Check(_cover.Count == 6, "six roots");
            Check(_cover.Select(x => x.Face).Distinct().Count() == 6, "every cube face");
            var target = new TileId(CubeFace.PositiveZ, 0, 0, 0);
            bool refined = QuadtreeCoverage.TryRefine(
                _cover, target, _budget, 4, 1, out var next);
            Check(refined, "atomic refine admitted");
            Check(next.Count == 9, "six roots plus three");
            Check(QuadtreeCoverage.IsCompleteSixFaceCover(next), "no logical gaps");
            Check(!next.Contains(target), "parent replaced");
            _cover = next;
            // World unit conversion is an explicitly noncanonical test fixture.
            var pos0 = new PlanetPosition(0, 0);
            var pos90 = new PlanetPosition(0, 90);
            double arcKm = PlanetGeometry.SurfaceDistanceKm(pos0, pos90, 6.0);
            Check(Math.Abs(arcKm - Math.PI * 3.0) < 1e-9, "great-circle sanity");

            VerifyCubeFaceSeams();
            InstallWorld();
            foreach (TileId tile in _cover)
                AddTile(tile);
            Check(_rendered.Count == 9, "9 native tile meshes");
            Check(_rendered.All(m => m.Mesh != null), "all native ArrayMeshes nonnull");
            int triangles = _cover.Sum(t =>
                2 * CubeSphereLattice.SegmentsFor(t) * CubeSphereLattice.SegmentsFor(t));
            GD.Print($"GODOT_CSHARP_WORLD_PASS assertions={_assertions} faces=6 tiles={_cover.Count} nativeMeshes={_rendered.Count} triangles={triangles}");
            GD.Print("GODOT_CSHARP_SCENE_SCOPE=NONCANON_GEOMETRY_ONLY_NO_COLLISION_NO_SAVE");
        }
        catch (Exception ex)
        {
            GD.PushError($"GODOT_CSHARP_WORLD_FAIL: {ex}");
            GetTree().Quit(1);
        }
    }

    public override void _Process(double delta)
    {
        _frames++;
        if (_camera != null)
        {
            // The orbit continuously reorients the camera, but does not imply
            // playable ship navigation or a performance guarantee.
            float angle = Mathf.DegToRad(20f + _frames * 0.15f);
            _camera.Position = new Vector3(19.5f * Mathf.Sin(angle),
                6.5f + 1.5f * Mathf.Sin(angle * 0.5f),
                19.5f * Mathf.Cos(angle));
            _camera.LookAt(Vector3.Zero);
        }
        if (_captureRequested && !_captureSaved && _frames >= 35)
        {
            _captureSaved = true;
            string target = ProjectSettings.GlobalizePath("res://evidence/planet-debug.png");
            Error mk = DirAccess.MakeDirRecursiveAbsolute(target.GetBaseDir());
            if (mk != Error.Ok)
            {
                GD.PushError($"GODOT_CSHARP_CAPTURE_FAIL: mkdir {mk}");
                GetTree().Quit(1);
                return;
            }
            Image? frame = GetViewport().GetTexture().GetImage();
            if (frame == null || frame.GetWidth() != 960 || frame.GetHeight() != 640)
            {
                GD.PushError("GODOT_CSHARP_CAPTURE_FAIL: viewport dimensions");
                GetTree().Quit(1);
                return;
            }
            // Reject a blank/clear-only screenshot even if the PNG header is valid.
            Color background = frame.GetPixel(950, 620);
            int foregroundSamples = 0;
            for (int y = 128; y < 544; y += 24)
            {
                for (int x = 160; x < 800; x += 24)
                {
                    Color pixel = frame.GetPixel(x, y);
                    float rgbDelta = Mathf.Abs(pixel.R - background.R)
                        + Mathf.Abs(pixel.G - background.G)
                        + Mathf.Abs(pixel.B - background.B);
                    if (rgbDelta > 0.20f)
                        foregroundSamples++;
                }
            }
            if (foregroundSamples < 50)
            {
                GD.PushError($"GODOT_CSHARP_CAPTURE_FAIL: blank frame ({foregroundSamples} foreground samples)");
                GetTree().Quit(1);
                return;
            }
            GD.Print($"GODOT_CSHARP_FRAME_PIXELS_PASS foreground_samples={foregroundSamples}");
            if (frame.SavePng(target) != Error.Ok)
            {
                GD.PushError("GODOT_CSHARP_CAPTURE_FAIL: PNG save");
                GetTree().Quit(1);
                return;
            }
            GD.Print($"GODOT_CSHARP_FRAME_CAPTURE: {target} 960x640");
            GetTree().Quit(0);
        }
    }

    private void InstallWorld()
    {
        var env = new WorldEnvironment { Name = "NoncanonicalViewportEnvironment" };
        var environment = new Godot.Environment
        {
            BackgroundMode = Godot.Environment.BGMode.Color,
            BackgroundColor = new Color(0.013f, 0.022f, 0.046f),
            AmbientLightSource = Godot.Environment.AmbientSource.Color,
            AmbientLightColor = new Color(0.30f, 0.39f, 0.54f),
            AmbientLightEnergy = 0.32f,
            TonemapMode = Godot.Environment.ToneMapper.Filmic,
        };
        env.Environment = environment;
        AddChild(env);

        var sun = new DirectionalLight3D
        {
            Name = "DebugSun",
            LightColor = new Color(1.0f, 0.87f, 0.67f),
            LightEnergy = 1.5f,
            RotationDegrees = new Vector3(-34f, -52f, 0f),
            ShadowEnabled = false,
        };
        AddChild(sun);

        _camera = new Camera3D
        {
            Name = "ActualCamera3D",
            Current = true,
            Fov = 49f,
            Near = 0.1f,
            Far = 200f,
        };
        AddChild(_camera);

        var overlay = new CanvasLayer { Name = "EngineeringScopeLabel" };
        AddChild(overlay);
        var label = new Label
        {
            Text = "TO SAIL THE STARRY SKY   /   GODOT .NET C# WORLD-MAP LAB\nSIX-FACE SPHERICAL TILE COVER   •   NON-CANON TEST GEOMETRY\nNO TERRAIN COLLISION / BIOMES / SHIP / MOON BRIDGE",
            Position = new Vector2(24, 22),
        };
        label.AddThemeFontSizeOverride("font_size", 14);
        overlay.AddChild(label);
    }

    private void VerifyCubeFaceSeams()
    {
        const float epsilon = 0.00001f;
        var faces = Enum.GetValues<CubeFace>();
        int checkedEdges = 0;
        int checkedPositions = 0;
        foreach (CubeFace face in faces)
        {
            for (int edge = 0; edge < 4; edge++)
            {
                int matchingOtherEdges = 0;
                foreach (CubeFace neighbor in faces)
                {
                    if (face == neighbor)
                        continue;
                    for (int neighborEdge = 0; neighborEdge < 4; neighborEdge++)
                    {
                        bool aligned = true;
                        bool reversed = true;
                        for (int i = 0; i <= CubeSphereLattice.BaseFaceSegments; i++)
                        {
                            Vector3 pos = CubeSphereLattice.FaceBorder(face, edge, i);
                            if (pos.DistanceTo(CubeSphereLattice.FaceBorder(
                                neighbor, neighborEdge, i)) > epsilon)
                                aligned = false;
                            if (pos.DistanceTo(CubeSphereLattice.FaceBorder(
                                neighbor, neighborEdge,
                                CubeSphereLattice.BaseFaceSegments - i)) > epsilon)
                                reversed = false;
                            if (!aligned && !reversed)
                                break;
                        }
                        if (aligned || reversed)
                            matchingOtherEdges++;
                    }
                }
                Check(matchingOtherEdges == 1,
                    $"each cube-face edge has exactly one identical adjacent edge: {face}/{edge}");
                checkedEdges++;
            }
        }
        // Refined +Z face and all neighboring root faces use exactly the same
        // 32-step border positions, rather than 16-vs-32 incompatible chords.
        for (int edge = 0; edge < 4; edge++)
        {
            for (int i = 0; i <= CubeSphereLattice.BaseFaceSegments; i++)
            {
                Vector3 root = CubeSphereLattice.FaceBorder(CubeFace.PositiveZ, edge, i);
                Vector3 child = CubeSphereLattice.RefinedBorderPoint(
                    CubeFace.PositiveZ, edge, i);
                Check(root.DistanceTo(child) < epsilon,
                    $"refined child shares exact root edge vertex: {edge}/{i}");
                checkedPositions++;
            }
        }
        Check(checkedEdges == 24, "all twelve undirected cube seams covered from both sides");
        Check(checkedPositions == 4 * (CubeSphereLattice.BaseFaceSegments + 1),
            "all child-to-root surface edge coordinates tested");
        GD.Print($"GODOT_CSHARP_MESH_SEAMS_PASS faceEdges={checkedEdges} refinedEdgeVertices={checkedPositions} grid={CubeSphereLattice.BaseFaceSegments}");
    }

    private void AddTile(TileId tile)
    {
        var builder = new SurfaceTool();
        builder.Begin(Mesh.PrimitiveType.Triangles);
        int resolution = CubeSphereLattice.SegmentsFor(tile);
        for (int row = 0; row < resolution; ++row)
        {
            for (int col = 0; col < resolution; ++col)
            {
                Vector3 a = CubeSphereLattice.TilePoint(tile, col, row);
                Vector3 b = CubeSphereLattice.TilePoint(tile, col + 1, row);
                Vector3 c = CubeSphereLattice.TilePoint(tile, col + 1, row + 1);
                Vector3 d = CubeSphereLattice.TilePoint(tile, col, row + 1);
                AddTriangle(builder, a, b, c);
                AddTriangle(builder, a, c, d);
            }
        }
        var instance = new MeshInstance3D
        {
            Name = $"NativeTile_{tile.Face}_{tile.Level}_{tile.Column}_{tile.Row}",
            Mesh = builder.Commit(),
            MaterialOverride = new StandardMaterial3D
            {
                AlbedoColor = Palette(tile),
                Roughness = 0.88f,
                Metallic = 0.04f,
                CullMode = BaseMaterial3D.CullModeEnum.Disabled,
            },
        };
        AddChild(instance);
        _rendered.Add(instance);
    }

    private static Color Palette(TileId tile)
    {
        float shade = 1f - tile.Level * 0.05f - (tile.Column + tile.Row) * 0.025f;
        var c = tile.Face switch
        {
            CubeFace.PositiveX => new Color(0.17f, 0.48f, 0.49f),
            CubeFace.NegativeX => new Color(0.17f, 0.30f, 0.56f),
            CubeFace.PositiveY => new Color(0.39f, 0.57f, 0.35f),
            CubeFace.NegativeY => new Color(0.19f, 0.42f, 0.36f),
            CubeFace.PositiveZ => new Color(0.27f, 0.50f, 0.60f),
            _ => new Color(0.32f, 0.37f, 0.59f),
        };
        return new Color(c.R * shade, c.G * shade, c.B * shade);
    }

    private static void AddTriangle(SurfaceTool builder, Vector3 a, Vector3 b, Vector3 c)
    {
        Vector3 outside = (a + b + c).Normalized();
        if ((b - a).Cross(c - a).Dot(outside) < 0f)
            (b, c) = (c, b);
        builder.SetNormal(a.Normalized());
        builder.AddVertex(a);
        builder.SetNormal(b.Normalized());
        builder.AddVertex(b);
        builder.SetNormal(c.Normalized());
        builder.AddVertex(c);
    }

    private void Check(bool valid, string label)
    {
        _assertions++;
        if (!valid)
            throw new InvalidOperationException($"Native Godot C# scene contract: {label}");
    }
}
