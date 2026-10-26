using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// Bounded, noncanonical cube-sphere mesh lab. CPU-only triangle preparation
/// can run on a worker thread. All Godot engine Resource creation is separated
/// into BuildTile/BuildFromPrepared and must run on the scene/main thread.
/// </summary>
public static class AdaptiveBoundaryTiles
{
    private const int N = WatertightTiles.SegmentsPerLeaf;
    private const int MaxLevel = WatertightTiles.MaximumDemonstratedLevel;
    private const int MaxTriangles = WatertightTiles.MaximumTriangleBudget;

    private readonly record struct Edge(WatertightTiles.GridPoint A, WatertightTiles.GridPoint B)
    {
        public static Edge Of(WatertightTiles.GridPoint a, WatertightTiles.GridPoint b)
            => a.CompareTo(b) < 0 ? new Edge(a, b) : new Edge(b, a);
    }

    public sealed class PreparedCover
    {
        public TileId[] Tiles { get; }
        public IReadOnlyDictionary<TileId, Vector3[]> Vertices { get; }
        public int Triangles { get; }
        public int DistinctEdges { get; }
        public int NonmanifoldEdges { get; }
        public int GlobalLevel { get; }
        public int InsertedVertices { get; }
        public int StitchedCells { get; }
        public int DistinctVertices { get; }
        public float MinHeight { get; }
        public float MaxHeight { get; }

        internal PreparedCover(TileId[] tiles, Dictionary<TileId, Vector3[]> vertices,
            int triangles, int edges, int bad, int level, int inserted, int stitched,
            int uniqueVertices, float minHeight, float maxHeight)
        {
            Tiles = tiles;
            Vertices = vertices;
            Triangles = triangles;
            DistinctEdges = edges;
            NonmanifoldEdges = bad;
            GlobalLevel = level;
            InsertedVertices = inserted;
            StitchedCells = stitched;
            DistinctVertices = uniqueVertices;
            MinHeight = minHeight;
            MaxHeight = maxHeight;
        }
    }

    /// <summary>
    /// No engine object construction, scene mutation, GD logging or resources.
    /// Godot Vector3 is only a value type in this CPU preparation path.
    /// Caller must not mutate the input cover concurrently.
    /// </summary>
    public static PreparedCover Prepare(IReadOnlyList<TileId> cover, float radius,
        CancellationToken cancellation = default)
    {
        ArgumentNullException.ThrowIfNull(cover);
        cancellation.ThrowIfCancellationRequested();
        if (!float.IsFinite(radius) || radius < 1f)
            throw new ArgumentOutOfRangeException(nameof(radius));
        TileId[] snapshot = cover.ToArray();
        if (!QuadtreeCoverage.IsCompleteSixFaceCover(snapshot))
            throw new InvalidOperationException("Adaptive boundary refuses non-covering tiles.");
        int level = snapshot.Max(t => t.Level);
        if (level > MaxLevel)
            throw new InvalidOperationException("Adaptive study supports at most two refinements.");

        int globalSteps = N << level;
        var neighbors = new NeighborBoundaryIndex(snapshot, level);
        int inserted = 0, stitched = 0, triangles = 0;
        var payloads = new Dictionary<TileId, Vector3[]>();
        var incidence = new Dictionary<Edge, int>();

        foreach (TileId tile in snapshot)
        {
            cancellation.ThrowIfCancellationRequested();
            int step = 1 << (level - tile.Level);
            int startX = tile.Column * N * step;
            int startY = tile.Row * N * step;
            var verts = new List<Vector3>(N * N * 9);

            for (int row = 0; row < N; row++)
            for (int col = 0; col < N; col++)
            {
                cancellation.ThrowIfCancellationRequested();
                int x = startX + col * step;
                int y = startY + row * step;
                var a = WatertightTiles.Cube(tile.Face, x, y, globalSteps);
                var b = WatertightTiles.Cube(tile.Face, x + step, y, globalSteps);
                var c = WatertightTiles.Cube(tile.Face, x + step, y + step, globalSteps);
                var d = WatertightTiles.Cube(tile.Face, x, y + step, globalSteps);
                bool bottom = row == 0 && neighbors.HasIntermediate(tile.Face, x, y, x + step, y);
                bool right = col == N - 1 && neighbors.HasIntermediate(tile.Face, x + step, y, x + step, y + step);
                bool top = row == N - 1 && neighbors.HasIntermediate(tile.Face, x + step, y + step, x, y + step);
                bool left = col == 0 && neighbors.HasIntermediate(tile.Face, x, y + step, x, y);

                if (!(bottom || right || top || left))
                {
                    AddTriangle(verts, a, b, c, radius, incidence);
                    AddTriangle(verts, a, c, d, radius, incidence);
                    triangles += 2;
                }
                else
                {
                    var ring = new List<WatertightTiles.GridPoint> { a };
                    inserted += neighbors.Append(ring, tile.Face, x, y, x + step, y, row == 0);
                    inserted += neighbors.Append(ring, tile.Face, x + step, y, x + step, y + step, col == N - 1);
                    inserted += neighbors.Append(ring, tile.Face, x + step, y + step, x, y + step, row == N - 1);
                    inserted += neighbors.Append(ring, tile.Face, x, y + step, x, y, col == 0);
                    ring.RemoveAt(ring.Count - 1);
                    var center = WatertightTiles.Cube(tile.Face, x + step / 2, y + step / 2, globalSteps);
                    for (int k = 0; k < ring.Count; k++)
                    {
                        AddTriangle(verts, center, ring[k], ring[(k + 1) % ring.Count], radius, incidence);
                        triangles++;
                    }
                    stitched++;
                }
                if (triangles > MaxTriangles)
                    throw new InvalidOperationException("CPU terrain triangle budget exceeded.");
            }
            payloads.Add(tile, verts.ToArray());
        }

        cancellation.ThrowIfCancellationRequested();
        int bad = incidence.Values.Count(v => v != 2);
        if (bad != 0 || incidence.Count * 2 != triangles * 3)
            throw new InvalidOperationException($"Nonmanifold CPU terrain: bad={bad}, triangles={triangles}.");
        var points = incidence.Keys.SelectMany(e => new[] { e.A, e.B }).Distinct().ToArray();
        float minHeight = points.Min(TerrainDisplacementFixture.Offset);
        float maxHeight = points.Max(TerrainDisplacementFixture.Offset);
        if (minHeight >= -0.01f || maxHeight <= 0.01f)
            throw new InvalidOperationException("No bidirectional displacement in CPU fixture.");
        return new PreparedCover(snapshot, payloads, triangles, incidence.Count, bad, level,
            inserted, stitched, points.Length, minHeight, maxHeight);
    }

    private static void AddTriangle(List<Vector3> vertices, WatertightTiles.GridPoint a,
        WatertightTiles.GridPoint b, WatertightTiles.GridPoint c, float radius,
        Dictionary<Edge, int> edges)
    {
        var av = TerrainDisplacementFixture.Position(a, radius);
        var bv = TerrainDisplacementFixture.Position(b, radius);
        var cv = TerrainDisplacementFixture.Position(c, radius);
        if ((bv - av).Cross(cv - av).Dot((av + bv + cv).Normalized()) < 0f)
        {
            (b, c) = (c, b);
            (bv, cv) = (cv, bv);
        }
        vertices.Add(av);
        vertices.Add(bv);
        vertices.Add(cv);
        Count(edges, a, b);
        Count(edges, b, c);
        Count(edges, c, a);
    }

    private static void Count(Dictionary<Edge, int> edges,
        WatertightTiles.GridPoint a, WatertightTiles.GridPoint b)
    {
        var key = Edge.Of(a, b);
        edges.TryGetValue(key, out int count);
        edges[key] = count + 1;
    }

    /// <summary>Must run on Godot main thread. One tile costs one admission unit.</summary>
    public static ArrayMesh BuildTile(PreparedCover prepared, TileId tile)
    {
        if (!prepared.Vertices.TryGetValue(tile, out var positions))
            throw new InvalidOperationException("Prepared terrain does not include tile.");
        var tool = new SurfaceTool();
        tool.Begin(Mesh.PrimitiveType.Triangles);
        foreach (Vector3 v in positions)
        {
            tool.SetNormal(v.Normalized()); // noncanon radial approximation
            tool.AddVertex(v);
        }
        var mesh = tool.Commit();
        if (mesh.GetSurfaceCount() != 1)
        {
            mesh.Dispose();
            throw new InvalidOperationException("Native Godot adaptive surface missing.");
        }
        return mesh;
    }

    /// <summary>Main-thread, synchronous compatibility for initial sphere.</summary>
    public static WatertightTiles.CheckedMeshSet Build(IReadOnlyList<TileId> cover, float radius)
        => BuildFromPrepared(Prepare(cover, radius));

    public static WatertightTiles.CheckedMeshSet BuildFromPrepared(PreparedCover prepared)
    {
        var meshes = new Dictionary<TileId, ArrayMesh>();
        try
        {
            foreach (TileId t in prepared.Tiles)
                meshes.Add(t, BuildTile(prepared, t));
            return Assemble(prepared, meshes);
        }
        catch
        {
            foreach (var mesh in meshes.Values) mesh.Dispose();
            throw;
        }
    }

    public static WatertightTiles.CheckedMeshSet Assemble(PreparedCover prepared,
        IReadOnlyDictionary<TileId, ArrayMesh> stagedMeshes)
    {
        if (stagedMeshes.Count != prepared.Tiles.Length ||
            prepared.Tiles.Any(t => !stagedMeshes.ContainsKey(t)))
            throw new InvalidOperationException("Incomplete main-thread terrain staging.");
        if (prepared.NonmanifoldEdges != 0)
            throw new InvalidOperationException("Nonmanifold terrain denied.");
        GD.Print($"GODOT_CSHARP_DISPLACEMENT_PASS level={prepared.GlobalLevel} vertices={prepared.DistinctVertices} minHeight={prepared.MinHeight:F6} maxHeight={prepared.MaxHeight:F6}");
        GD.Print($"GODOT_CSHARP_NEIGHBOR_PASS level={prepared.GlobalLevel} tiles={prepared.Tiles.Length} inserted={prepared.InsertedVertices} stitchedCells={prepared.StitchedCells} triangles={prepared.Triangles} nonmanifold={prepared.NonmanifoldEdges}");
        return new WatertightTiles.CheckedMeshSet(
            new Dictionary<TileId, ArrayMesh>(stagedMeshes), prepared.Triangles,
            prepared.DistinctEdges, prepared.NonmanifoldEdges, prepared.GlobalLevel);
    }
}
