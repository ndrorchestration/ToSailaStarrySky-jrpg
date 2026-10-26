using System;
using System.Collections.Generic;

namespace StarrySky.WorldMap.Contracts;

/// <summary>
/// Dependency-free, constant-radius cube-sphere tile mesh fixture.
/// Mesh units are caller-defined; positions are NOT planetary geography.
/// Adjacent same-LOD tiles share mathematical edge positions, but GPU stitching,
/// mixed-LOD seams, collisions and Godot mesh import are not established.
/// </summary>
public static class CubeSphereMeshFixture
{
    public readonly record struct Point3(double X, double Y, double Z);
    public sealed record TileMesh(IReadOnlyList<Point3> Vertices, IReadOnlyList<int> Indices);

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
        var indices = new int[segments * segments * 6];
        for (int row = 0; row <= segments; row++)
        for (int col = 0; col <= segments; col++)
        {
            double u = (tile.Column + (double)col / segments) / count;
            double v = (tile.Row + (double)row / segments) / count;
            var position = CubeSphereAddressing.ToPosition(tile.Face, u, v);
            double lat = position.LatitudeDegrees * Math.PI / 180.0;
            double lon = position.LongitudeDegrees * Math.PI / 180.0;
            vertices[row * (segments + 1) + col] = new Point3(
                radius * Math.Cos(lat) * Math.Cos(lon),
                radius * Math.Sin(lat),
                radius * Math.Cos(lat) * Math.Sin(lon));
        }
        int offset = 0;
        for (int row = 0; row < segments; row++)
        for (int col = 0; col < segments; col++)
        {
            int a = row * (segments + 1) + col;
            int b = a + 1;
            int c = a + segments + 1;
            int d = c + 1;
            indices[offset++] = a;
            indices[offset++] = c;
            indices[offset++] = b;
            indices[offset++] = b;
            indices[offset++] = c;
            indices[offset++] = d;
        }
        return new TileMesh(Array.AsReadOnly(vertices), Array.AsReadOnly(indices));
    }
}
