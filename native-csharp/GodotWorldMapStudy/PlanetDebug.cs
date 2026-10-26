using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// ACTUAL Godot .NET scene exercising the independently verified C# logical quadtree.
/// Renders integer-grid watertight debug tiles with a bounded, reversible LOD swap,
/// per-tile static triangle collision and a human-navigable camera. Deliberately
/// NON-CANON: sphere dimensions, colors and elevation are test fixtures.
/// No authored geography, save, world authority or gameplay route is established.
/// </summary>
public partial class PlanetDebug : Node3D
{
    private const float DebugRadiusUnits = 6f;
    private const int SegmentsPerTile = WatertightTiles.SegmentsPerLeaf;
    private readonly TileBudget _budget = new(64, 128);
    private IReadOnlyList<TileId> _cover = QuadtreeCoverage.SixFaceRoots();
    private readonly List<MeshInstance3D> _rendered = new();
    private Camera3D? _camera;
    private Label? _label;
    private int _triangles;
    private int _physicsTicks;
    private bool _rayValidated;
    private float _azimuthDegrees = 20f;
    private float _latitudeDegrees = 17f;
    private float _cameraDistance = 22f;
    private bool _expanded;
    private VersionedTerrainStream _stream = new();
    private SceneAdmissionBudget? _sceneAdmission;
    private IReadOnlyList<TileId>? _stagedCover;
    private bool _stagedExpansion;
    private bool _stageObservedActive;
    private int _committedTransitions;
    private bool _coarsenRequested;
    private bool _queuedExpansion;
    private TileId? _lastSelected;
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

            InstallWorld();
            RenderCover(_cover);
            Check(RejectInvalidCoverWithoutMutation(), "invalid cover rejected atomically");
            int stale = _stream.Request(_cover, DebugRadiusUnits);
            int superseding = _stream.Request(_cover, DebugRadiusUnits);
            Check(!_stream.WouldAdmit(stale) && _stream.WouldAdmit(superseding),
                "stale generation must be denied");
            GD.Print($"GODOT_CSHARP_STALE_REJECT_PASS stale={stale} current={superseding}");
            for (int iteration = 0; iteration < 8; iteration++)
            {
                int previous = superseding;
                superseding = _stream.Request(_cover, DebugRadiusUnits);
                Check(!_stream.WouldAdmit(previous) && _stream.WouldAdmit(superseding),
                    "rapid supersession revision isolation");
            }
            GD.Print($"GODOT_CSHARP_SUPERSESSION_PASS requests=10 staleRejected=9 current={superseding}");
            // This only tests rapid revision supersession, not all worker interleavings.
            // The controlled test requests are never admitted into the live scene.
            _stream.Dispose();
            _stream = new VersionedTerrainStream();
            Check(_rendered.Count == 9, "9 native tile meshes");
            Check(_rendered.All(m => m.Mesh != null), "all native ArrayMeshes nonnull");
            Check(_rendered.All(m => m.GetChildCount() == 1 && m.GetChild(0) is StaticBody3D), "native collision bodies");
            GD.Print($"GODOT_CSHARP_WORLD_PASS assertions={_assertions} faces=6 tiles={_cover.Count} nativeMeshes={_rendered.Count} triangles={_triangles}");
            GD.Print("GODOT_CSHARP_SCENE_SCOPE=NONCANON_SPHERE_MESH_PHYSICS_NO_GAMEPLAY_OR_SAVE");
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
        // Real input-controlled camera orbit; automatic slow orbit only with no user keys.
        bool input = Input.IsKeyPressed(Key.A) || Input.IsKeyPressed(Key.D)
            || Input.IsKeyPressed(Key.W) || Input.IsKeyPressed(Key.S)
            || Input.IsKeyPressed(Key.Q) || Input.IsKeyPressed(Key.E);
        float seconds = (float)Math.Clamp(delta, 0, 0.10);
        float yaw = (Input.IsKeyPressed(Key.D) ? 1f : 0f)
            - (Input.IsKeyPressed(Key.A) ? 1f : 0f);
        float pitch = (Input.IsKeyPressed(Key.W) ? 1f : 0f)
            - (Input.IsKeyPressed(Key.S) ? 1f : 0f);
        float zoom = (Input.IsKeyPressed(Key.E) ? 1f : 0f)
            - (Input.IsKeyPressed(Key.Q) ? 1f : 0f);
        _azimuthDegrees += (input ? yaw * 48f : 8f) * seconds;
        _latitudeDegrees = Mathf.Clamp(_latitudeDegrees + pitch * 40f * seconds, -73f, 73f);
        _cameraDistance = Mathf.Clamp(_cameraDistance + zoom * 12f * seconds, 8f, 48f);
        if (_camera != null)
        {
            float az = Mathf.DegToRad(_azimuthDegrees);
            float elevation = Mathf.DegToRad(_latitudeDegrees);
            _camera.Position = new Vector3(
                _cameraDistance * Mathf.Cos(elevation) * Mathf.Sin(az),
                _cameraDistance * Mathf.Sin(elevation),
                _cameraDistance * Mathf.Cos(elevation) * Mathf.Cos(az));
            _camera.LookAt(Vector3.Zero);
        }
        // Deterministic native LOD lifecycle smoke. Both steps complete before capture:
        // first a 1->4 refinement, then the matching 4->1 coarsening.
        if (_frames == 12) ChangeLod(expand: true);
        if (_frames >= 24 && _committedTransitions == 1 && !_coarsenRequested)
        {
            _coarsenRequested = true;
            ChangeLod(expand: false);
        }
        try
        {
            if (_stream.Pump(out var prepared) && prepared is not null)
            {
                _sceneAdmission?.Dispose();
                _sceneAdmission = new SceneAdmissionBudget(
                    _stream.Revision, prepared, _stream.RequestedCover);
                _stagedCover = _stream.RequestedCover.ToArray();
                _stagedExpansion = _queuedExpansion;
                _stageObservedActive = false;
            }
            if (_sceneAdmission != null)
            {
                if (_sceneAdmission.Revision != _stream.Revision)
                {
                    GD.Print($"GODOT_CSHARP_NODE_STALE_DROP revision={_sceneAdmission.Revision}");
                    _sceneAdmission.Dispose();
                    _sceneAdmission = null;
                }
                else
                {
                    bool complete = _sceneAdmission.Pump(CreateTileNode);
                    if (!complete && !_stageObservedActive)
                    {
                        // The old live cover must remain present while replacement
                        // body/collider nodes are allocated outside the SceneTree.
                        Check(_rendered.Count == (_stagedExpansion ? 9 : 12),
                            "live tile cover preserved during collider staging");
                        _stageObservedActive = true;
                        GD.Print($"GODOT_CSHARP_NODE_ACTIVE_PASS tiles={_rendered.Count} whileStaging=True");
                    }
                    if (complete)
                    {
                        var ready = _sceneAdmission.TakeComplete();
                        ApplyCover(_stagedCover!, _sceneAdmission.CheckedSet, ready);
                        _sceneAdmission.Dispose();
                        _sceneAdmission = null;
                        _committedTransitions++;
                        int expected = _stagedExpansion ? 12 : 9;
                        Check(_rendered.Count == expected, "bounded node/physics admission count");
                        Check(_stream.MaximumObservedFrameAdmissions <= VersionedTerrainStream.MaxTilesPerFrame,
                            "mesh resources frame-budget");
                        GD.Print($"GODOT_CSHARP_LOD_SWAP_PASS expanded={_stagedExpansion} tiles={expected} collisionBodies={_rendered.Count}");
                    }
                }
            }
        }
        catch (Exception ex)
        {
            GD.PushError($"GODOT_CSHARP_STREAM_FAIL: {ex}");
            GetTree().Quit(1);
            return;
        }
        if (_captureRequested && !_captureSaved && _frames >= 35 && _committedTransitions == 2)
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
            Position = new Vector3(8f, 6f, 20f),
        };
        AddChild(_camera);
        _camera.LookAt(Vector3.Zero);

        var overlay = new CanvasLayer { Name = "EngineeringScopeLabel" };
        AddChild(overlay);
        var label = new Label
        {
            Text = "TO SAIL THE STARRY SKY   /   GODOT .NET C# GEOMETRY LAB\nADAPTIVE TILE INTERIORS + SEALED EDGES   •   NON-CANON\nWASD ORBIT  |  Q/E ALTITUDE  |  TILES / COLLISIONS TESTED\nNOT ART / DRAGONFLY / BIOMES / MOON ROUTE",
            Position = new Vector2(24, 22),
        };
        label.AddThemeFontSizeOverride("font_size", 14);
        overlay.AddChild(label);
        _label = label;
    }

    private void RenderCover(IReadOnlyList<TileId> proposedCover)
    {
        // Boot-time compatibility; all later transitions use the worker and staged meshes.
        WatertightTiles.CheckedMeshSet checkedSet = AdaptiveBoundaryTiles.Build(proposedCover, DebugRadiusUnits);
        ApplyCover(proposedCover, checkedSet);
    }

    private void ApplyCover(IReadOnlyList<TileId> proposedCover,
        WatertightTiles.CheckedMeshSet checkedSet,
        IReadOnlyList<MeshInstance3D>? stagedNodes = null)
    {
        int maxLevel = checkedSet.GlobalLevel;
        int uniformTriangles = proposedCover.Sum(t =>
        {
            int n = WatertightTiles.SegmentsPerLeaf << (maxLevel - t.Level);
            return 2 * n * n;
        });
        if (checkedSet.Triangles >= uniformTriangles)
            throw new InvalidOperationException("Adaptive mesh did not save triangles over uniform tessellation.");
        GD.Print($"GODOT_CSHARP_ADAPTIVE_PASS level={maxLevel} tiles={proposedCover.Count} triangles={checkedSet.Triangles} uniformTriangles={uniformTriangles} saved={uniformTriangles-checkedSet.Triangles}");
        if (checkedSet.NonmanifoldEdges != 0)
            throw new InvalidOperationException("Watertightness gate unexpectedly failed.");
        var incoming = stagedNodes != null
            ? new List<MeshInstance3D>(stagedNodes)
            : checkedSet.Meshes.Select(item => CreateTileNode(item.Key, item.Value)).ToList();
        if (incoming.Count != proposedCover.Count ||
            incoming.Any(n => n.GetChildCount() != 1 || n.GetChild(0) is not StaticBody3D))
            throw new InvalidOperationException("Unstaged terrain collision cover rejected.");

        // Final scene-tree/physics attachment still occurs together; instrument,
        // but do NOT confuse this sample with full frame-time or GPU performance.
        var commitWatch = Stopwatch.StartNew();
        foreach (MeshInstance3D old in _rendered)
        {
            RemoveChild(old);
            old.QueueFree();
        }
        _rendered.Clear();
        foreach (MeshInstance3D current in incoming)
        {
            AddChild(current);
            _rendered.Add(current);
        }
        commitWatch.Stop();
        GD.Print($"GODOT_CSHARP_SWAP_METRIC nodes={incoming.Count} commitMs={commitWatch.Elapsed.TotalMilliseconds:F3}");
        _cover = proposedCover;
        _triangles = checkedSet.Triangles;
        GD.Print($"GODOT_CSHARP_SEAM_PASS level={checkedSet.GlobalLevel} tiles={proposedCover.Count} edges={checkedSet.DistinctEdges} nonmanifold={checkedSet.NonmanifoldEdges} triangles={_triangles}");
    }

    private MeshInstance3D CreateTileNode(TileId tile, ArrayMesh mesh)
    {
        var instance = new MeshInstance3D
        {
            Name = $"NativeTile_{tile.Face}_{tile.Level}_{tile.Column}_{tile.Row}",
            Mesh = mesh,
            MaterialOverride = new StandardMaterial3D
            {
                AlbedoColor = Palette(tile),
                Roughness = 0.88f,
                Metallic = 0.04f,
                CullMode = BaseMaterial3D.CullModeEnum.Disabled,
            },
        };
        var body = new StaticBody3D { Name = "SurfaceCollider" };
        var shape = mesh.CreateTrimeshShape();
        shape.BackfaceCollision = true;
        var collision = new CollisionShape3D
        {
            Name = "NativeTrimesh",
            Shape = shape,
        };
        body.AddChild(collision);
        instance.AddChild(body);
        return instance;
    }

    private bool RejectInvalidCoverWithoutMutation()
    {
        IReadOnlyList<TileId> original = _cover;
        var nodes = _rendered.ToArray();
        var invalidCover = _cover.Skip(1).ToArray();
        try
        {
            RenderCover(invalidCover);
        }
        catch (InvalidOperationException)
        {
            bool unchanged = ReferenceEquals(original,_cover)
                && nodes.SequenceEqual(_rendered)
                && QuadtreeCoverage.IsCompleteSixFaceCover(_cover);
            if (unchanged)
                GD.Print($"GODOT_CSHARP_ATOMIC_REJECT_PASS intactTiles={_rendered.Count}");
            return unchanged;
        }
        return false;
    }

    private void ChangeLod(bool expand)
    {
        try
        {
            TileId parent;
            if (expand)
            {
                var chosen = CameraTilePriority.NearestRefinable(_cover, _camera!.Position, 1);
                if (!chosen.HasValue)
                    throw new InvalidOperationException("Camera-facing refinement target missing.");
                parent = chosen.Value;
                _lastSelected = parent;
                GD.Print($"GODOT_CSHARP_CAMERA_PRIORITY_PASS selected={parent} azimuth={_azimuthDegrees:F2}");
            }
            else
            {
                if (!_lastSelected.HasValue)
                    throw new InvalidOperationException("Refinement must precede coarsening.");
                parent = _lastSelected.Value;
            }
            bool changed = expand
                ? QuadtreeCoverage.TryRefine(_cover, parent, _budget, 4, 1, out var proposed)
                : QuadtreeCoverage.TryCoarsen(_cover, parent, _budget, 1, 4, out proposed);
            if (!changed)
                throw new InvalidOperationException("Required native LOD swap was denied.");
            if (!QuadtreeCoverage.IsCompleteSixFaceCover(proposed))
                throw new InvalidOperationException("Invalid proposed native cover.");
            _sceneAdmission?.Dispose();
            _sceneAdmission = null;
            int revision = _stream.Request(proposed, DebugRadiusUnits);
            _queuedExpansion = expand;
            GD.Print($"GODOT_CSHARP_STREAM_QUEUED revision={revision} tiles={proposed.Count}");
        }
        catch (Exception ex)
        {
            GD.PushError($"GODOT_CSHARP_LOD_FAIL: {ex}");
            GetTree().Quit(1);
        }
    }

    public override void _ExitTree()
    {
        _sceneAdmission?.Dispose();
        _stream.Dispose();
    }

    public override void _PhysicsProcess(double delta)
    {
        _physicsTicks++;
        if (_rayValidated || _physicsTicks < 15 || _camera == null)
            return;
        var query = PhysicsRayQueryParameters3D.Create(_camera.Position, Vector3.Zero);
        var hit = GetWorld3D().DirectSpaceState.IntersectRay(query);
        if (hit.Count == 0 || !hit.ContainsKey("collider"))
        {
            GD.PushError($"GODOT_CSHARP_COLLISION_FAIL: ray missed trimesh from {_camera.Position}, physicsTicks={_physicsTicks}, bodies={_rendered.Count}");
            GetTree().Quit(1);
            return;
        }
        _rayValidated = true;
        GD.Print("GODOT_CSHARP_COLLISION_PASS camera-to-center ray hit native trimesh");
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

    private void Check(bool valid, string label)
    {
        _assertions++;
        if (!valid)
            throw new InvalidOperationException($"Native Godot C# scene contract: {label}");
    }
}
