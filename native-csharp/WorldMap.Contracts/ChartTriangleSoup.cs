using System;
using System.Collections.Generic;

namespace StarrySky.WorldMap.Contracts;

/// <summary>
/// Engine-neutral triangle-list geometry with one UV per triangle corner.
/// A Godot adapter may consume these arrays, but this contract does not
/// instantiate ArrayMesh, materials, collisions or GPU resources.
/// </summary>
public static class ChartTriangleSoup
{
    public sealed record Expanded(
        IReadOnlyList<CubeSphereMeshFixture.Point3> Vertices,
        IReadOnlyList<CubeSphereMeshFixture.Point3> Normals,
        IReadOnlyList<CubeSphereMeshFixture.TexCoord> ChartUvs);

    public static Expanded Expand(CubeSphereMeshFixture.TileMesh mesh)
    {
        ArgumentNullException.ThrowIfNull(mesh);
        if (mesh.Vertices.Count != mesh.Normals.Count ||
            mesh.Vertices.Count != mesh.ChartUvs.Count ||
            mesh.Indices.Count % 3 != 0)
            throw new ArgumentException("Inconsistent mesh attributes.", nameof(mesh));
        for (int i = 0; i < mesh.Vertices.Count; i++)
        {
            var p = mesh.Vertices[i];
            var n = mesh.Normals[i];
            if (!double.IsFinite(p.X) || !double.IsFinite(p.Y) || !double.IsFinite(p.Z)
                || !double.IsFinite(n.X) || !double.IsFinite(n.Y) || !double.IsFinite(n.Z)
                || n.X * n.X + n.Y * n.Y + n.Z * n.Z < 1e-20)
                throw new ArgumentException("Nonfinite vertex or invalid normal.", nameof(mesh));
        }
        var uv = ChartSeamUnwrap.TriangleUvs(mesh);
        var vertices = new CubeSphereMeshFixture.Point3[mesh.Indices.Count];
        var normals = new CubeSphereMeshFixture.Point3[mesh.Indices.Count];
        for (int i = 0; i < mesh.Indices.Count; i++)
        {
            int source = mesh.Indices[i];
            if (source < 0 || source >= mesh.Vertices.Count)
                throw new ArgumentException("Out of range index.", nameof(mesh));
            vertices[i] = mesh.Vertices[source];
            normals[i] = mesh.Normals[source];
        }
        return new Expanded(Array.AsReadOnly(vertices),
            Array.AsReadOnly(normals), uv);
    }
}
