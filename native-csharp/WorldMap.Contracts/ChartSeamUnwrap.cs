using System;
using System.Collections.Generic;

namespace StarrySky.WorldMap.Contracts;

/// <summary>
/// Per-triangle unwrapped chart U coordinates for equirectangular sampling.
/// Original normalized chart UVs remain unchanged. Outputs can lie outside
/// [0,1], so the consumer must use a wrapping sampler. This only resolves
/// local texture interpolation across the antimeridian, not pole distortion.
/// </summary>
public static class ChartSeamUnwrap
{
    public static IReadOnlyList<CubeSphereMeshFixture.TexCoord> TriangleUvs(
        CubeSphereMeshFixture.TileMesh mesh)
    {
        ArgumentNullException.ThrowIfNull(mesh);
        if (mesh.ChartUvs.Count != mesh.Vertices.Count || mesh.Indices.Count % 3 != 0)
            throw new ArgumentException("Invalid indexed mesh chart mapping.", nameof(mesh));
        var result = new CubeSphereMeshFixture.TexCoord[mesh.Indices.Count];
        for (int start = 0; start < mesh.Indices.Count; start += 3)
        {
            var a = Sample(mesh, mesh.Indices[start]);
            var b = Sample(mesh, mesh.Indices[start + 1]);
            var c = Sample(mesh, mesh.Indices[start + 2]);
            // Anchor near the circular mean, then choose the shortest wraps.
            double sx = Math.Sin(a.U * 2 * Math.PI) + Math.Sin(b.U * 2 * Math.PI)
                + Math.Sin(c.U * 2 * Math.PI);
            double cx = Math.Cos(a.U * 2 * Math.PI) + Math.Cos(b.U * 2 * Math.PI)
                + Math.Cos(c.U * 2 * Math.PI);
            double anchor = Math.Atan2(sx, cx) / (2 * Math.PI);
            if (anchor < 0) anchor += 1;
            result[start] = new CubeSphereMeshFixture.TexCoord(Nearest(a.U, anchor), a.V);
            result[start + 1] = new CubeSphereMeshFixture.TexCoord(Nearest(b.U, anchor), b.V);
            result[start + 2] = new CubeSphereMeshFixture.TexCoord(Nearest(c.U, anchor), c.V);
        }
        return Array.AsReadOnly(result);
    }

    private static CubeSphereMeshFixture.TexCoord Sample(
        CubeSphereMeshFixture.TileMesh mesh, int index)
    {
        if (index < 0 || index >= mesh.ChartUvs.Count)
            throw new ArgumentException("Mesh contains invalid triangle indices.", nameof(mesh));
        var uv = mesh.ChartUvs[index];
        if (!double.IsFinite(uv.U) || !double.IsFinite(uv.V)
            || uv.U < 0 || uv.U > 1 || uv.V < 0 || uv.V > 1)
            throw new ArgumentException("Mesh contains invalid chart UVs.", nameof(mesh));
        return uv;
    }

    private static double Nearest(double u, double anchor)
        => u + Math.Round(anchor - u, MidpointRounding.AwayFromZero);
}
