using System;
using System.Collections.Generic;

namespace StarrySky.WorldMap.Contracts;

/// <summary>
/// Dependency-free, constant-radius cube-sphere tile mesh fixture.
/// Mesh units are caller-defined; positions are NOT planetary geography.
/// Adjacent same-LOD tiles share mathematical edge positions, but GPU stitching,
/// mixed-LOD seams, collisions and Godot mesh import are not established.
/// ChartUvs use a wrapped equirectangular atlas and need seam-aware sampling;
/// face Uvs are cube-face-local addresses, not a unified artistic texture atlas.
/// </summary>
public static class CubeSphereMeshFixture
{
    public readonly record struct Point3(double X, double Y, double Z);
    public readonly record struct TexCoord(double U, double V);
    public sealed record TileMesh(IReadOnlyList<Point3> Vertices, IReadOnlyList<Point3> Normals, IReadOnlyList<TexCoord> Uvs, IReadOnlyList<TexCoord> ChartUvs, IReadOnlyList<int> Indices);

    public static TileMesh Generate(TileId tile, double radius, int segments)
    {
        if (!double.IsFinite(radius) || radius <= 0)
            throw new ArgumentOutOfRangeException(nameof(radius));
        if (segments < 1 || segments > 128)
            throw new ArgumentOutOfRangeException(nameof(segments));
        if (tile.Level < 0 || tile.Level > 12 || tile.Column < 0 || tile.Row < 0 ||
            tile.Column >= (1 << tile.Level) || tile.Row >= (1 << tile.Level) ||
            !Enum.IsDefined(tile.Face))
            throw new ArgumentOutOfRangeException(nameof(tile));

        int count = 1 << tile.Level;
        var vertices = new Point3[(segments + 1) * (segments + 1)];
        var normals = new Point3[vertices.Length];
        var uvs = new TexCoord[vertices.Length];
        var chartUvs = new TexCoord[vertices.Length];
        var indices = new int[segments * segments * 6];
        for (int row = 0; row <= segments; row++)
        for (int col = 0; col <= segments; col++)
        {
            double u = (tile.Column + (double)col / segments) / count;
            double v = (tile.Row + (double)row / segments) / count;
            var position = CubeSphereAddressing.ToPosition(tile.Face, u, v);
            double lat = position.LatitudeDegrees * Math.PI / 180.0;
            double lon = position.LongitudeDegrees * Math.PI / 180.0;
            var unit = new Point3(
                Math.Cos(lat) * Math.Cos(lon),
                Math.Sin(lat),
                Math.Cos(lat) * Math.Sin(lon));
            int index = row * (segments + 1) + col;
            normals[index] = unit;
            uvs[index] = new TexCoord(u, v);
            var chart = WorldMapChartProjection.Project(position);
            chartUvs[index] = new TexCoord(chart.X, chart.Y);
            vertices[index] = new Point3(radius * unit.X, radius * unit.Y, radius * unit.Z);
        }
        int offset = 0;
        for (int row = 0; row < segments; row++)
        for (int col = 0; col < segments; col++)
        {
            int a = row * (segments + 1) + col;
            int b = a + 1;
            int c = a + segments + 1;
            int d = c + 1;
            AddOutwardTriangle(vertices, indices, ref offset, a, c, b);
            AddOutwardTriangle(vertices, indices, ref offset, b, c, d);
        }
        return new TileMesh(Array.AsReadOnly(vertices), Array.AsReadOnly(normals), Array.AsReadOnly(uvs), Array.AsReadOnly(chartUvs), Array.AsReadOnly(indices));
    }

    // Correct each face's handedness rather than assuming a shared cube UV winding.
    private static void AddOutwardTriangle(Point3[] vertices, int[] indices,
        ref int offset, int a, int b, int c)
    {
        var p = vertices[a];
        var q = vertices[b];
        var r = vertices[c];
        double ux = q.X - p.X, uy = q.Y - p.Y, uz = q.Z - p.Z;
        double vx = r.X - p.X, vy = r.Y - p.Y, vz = r.Z - p.Z;
        double nx = uy * vz - uz * vy;
        double ny = uz * vx - ux * vz;
        double nz = ux * vy - uy * vx;
        double outward = nx * (p.X + q.X + r.X)
            + ny * (p.Y + q.Y + r.Y) + nz * (p.Z + q.Z + r.Z);
        if (!double.IsFinite(outward) || outward == 0)
            throw new InvalidOperationException("Degenerate spherical tile triangle.");
        indices[offset++] = a;
        indices[offset++] = outward > 0 ? b : c;
        indices[offset++] = outward > 0 ? c : b;
    }
}
