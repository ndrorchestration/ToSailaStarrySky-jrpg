using System;
using System.Collections.Generic;
using System.Linq;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// Noncanonical bounded cube-sphere mesh contract: vertices on every edge,
/// including mixed quadtree levels and adjacent cube faces, share an exact
/// integer cube-grid address before radial projection. Independent geometry
/// edge-incidence verification is required before any scene swap.
/// This is deliberately a UNIFORM deepest-leaf tessellation demonstration,
/// NOT a scalable world streamer, crack-free displaced terrain or production LOD.
/// </summary>
public static class WatertightTiles
{
    public const int SegmentsPerLeaf = 8;
    public const int MaximumDemonstratedLevel = 2;
    public const int MaximumTriangleBudget = 50000;

    public readonly record struct GridPoint(int X, int Y, int Z) : IComparable<GridPoint>
    {
        public int CompareTo(GridPoint b)
        {
            int c = X.CompareTo(b.X);
            if (c != 0) return c;
            c = Y.CompareTo(b.Y);
            return c != 0 ? c : Z.CompareTo(b.Z);
        }

        public Vector3 Sphere(float radius) => new Vector3(X, Y, Z).Normalized() * radius;
    }

    private readonly record struct GridEdge(GridPoint A, GridPoint B)
    {
        public static GridEdge Between(GridPoint a, GridPoint b)
            => a.CompareTo(b) < 0 ? new GridEdge(a, b) : new GridEdge(b, a);
    }

    public sealed record CheckedMeshSet(
        IReadOnlyDictionary<TileId, ArrayMesh> Meshes,
        int Triangles,
        int DistinctEdges,
        int NonmanifoldEdges,
        int GlobalLevel);

    public static CheckedMeshSet Build(IReadOnlyList<TileId> cover, float radius)
    {
        ArgumentNullException.ThrowIfNull(cover);
        if (!float.IsFinite(radius) || radius <= 0f)
            throw new ArgumentOutOfRangeException(nameof(radius));
        if (!QuadtreeCoverage.IsCompleteSixFaceCover(cover))
            throw new InvalidOperationException("Refuse incomplete/overlapping logical cube-face cover.");

        int level = cover.Max(t => t.Level);
        if (level > MaximumDemonstratedLevel)
            throw new InvalidOperationException("Bounded engineering demo supports level <= 2.");
        int globalSteps = SegmentsPerLeaf << level;

        // Preflight construction quota; never allocate unbounded geometry.
        long expectedTriangles = cover.Sum(t =>
        {
            int n = SegmentsPerLeaf << (level - t.Level);
            return (long)n * n * 2;
        });
        if (expectedTriangles > MaximumTriangleBudget)
            throw new InvalidOperationException("Bounded engineering triangle budget exceeded.");

        var meshes = new Dictionary<TileId, ArrayMesh>();
        var incidence = new Dictionary<GridEdge, int>();
        int triangles = 0;

        foreach (TileId tile in cover)
        {
            int n = SegmentsPerLeaf << (level - tile.Level);
            int originX = tile.Column * n;
            int originY = tile.Row * n;
            var tool = new SurfaceTool();
            tool.Begin(Mesh.PrimitiveType.Triangles);

            for (int row = 0; row < n; ++row)
            {
                for (int col = 0; col < n; ++col)
                {
                    GridPoint a = Cube(tile.Face, originX + col, originY + row, globalSteps);
                    GridPoint b = Cube(tile.Face, originX + col + 1, originY + row, globalSteps);
                    GridPoint c = Cube(tile.Face, originX + col + 1, originY + row + 1, globalSteps);
                    GridPoint d = Cube(tile.Face, originX + col, originY + row + 1, globalSteps);
                    Triangle(tool, a, b, c, radius, incidence);
                    Triangle(tool, a, c, d, radius, incidence);
                    triangles += 2;
                }
            }
            ArrayMesh mesh = tool.Commit();
            if (mesh.GetSurfaceCount() != 1)
                throw new InvalidOperationException("Native mesh surface missing.");
            meshes.Add(tile, mesh);
        }
        int badEdges = incidence.Values.Count(count => count != 2);
        if (badEdges != 0)
        {
            foreach (var item in meshes.Values) item.Dispose();
            throw new InvalidOperationException($"Nonwatertight cube sphere: {badEdges} edge incidences != 2");
        }
        if (triangles != expectedTriangles || incidence.Count * 2 != triangles * 3)
            throw new InvalidOperationException("Triangle / edge closure count mismatch.");

        return new CheckedMeshSet(meshes, triangles, incidence.Count, badEdges, level);
    }

    public static GridPoint Cube(CubeFace face, int x, int y, int side)
    {
        if (side <= 0 || x < 0 || x > side || y < 0 || y > side)
            throw new ArgumentOutOfRangeException(nameof(x), "Invalid integer cube-face coordinates.");
        int u = 2 * x - side;
        int v = 2 * y - side;
        return face switch
        {
            CubeFace.PositiveX => new GridPoint(side, v, -u),
            CubeFace.NegativeX => new GridPoint(-side, v, u),
            CubeFace.PositiveY => new GridPoint(u, side, -v),
            CubeFace.NegativeY => new GridPoint(u, -side, v),
            CubeFace.PositiveZ => new GridPoint(u, v, side),
            CubeFace.NegativeZ => new GridPoint(-u, v, -side),
            _ => throw new ArgumentOutOfRangeException(nameof(face))
        };
    }

    private static void Triangle(SurfaceTool tool, GridPoint a, GridPoint b, GridPoint c,
        float radius, Dictionary<GridEdge, int> edges)
    {
        Vector3 av = a.Sphere(radius);
        Vector3 bv = b.Sphere(radius);
        Vector3 cv = c.Sphere(radius);
        Vector3 outward = (av + bv + cv).Normalized();
        if ((bv - av).Cross(cv - av).Dot(outward) < 0f)
            (b, c) = (c, b);
        Vertex(tool, a, radius);
        Vertex(tool, b, radius);
        Vertex(tool, c, radius);
        Count(a, b, edges);
        Count(b, c, edges);
        Count(c, a, edges);
    }

    private static void Vertex(SurfaceTool tool, GridPoint point, float radius)
    {
        Vector3 v = point.Sphere(radius);
        tool.SetNormal(v.Normalized());
        tool.AddVertex(v);
    }

    private static void Count(GridPoint a, GridPoint b, Dictionary<GridEdge, int> edges)
    {
        GridEdge e = GridEdge.Between(a, b);
        edges.TryGetValue(e, out int current);
        edges[e] = current + 1;
    }
}
