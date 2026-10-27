using System;
using Godot;

/// <summary>
/// Noncanon render-only longitude chart mapping for already triangulated Godot
/// terrain. Triangle-local unwrapping does not alter terrain, collision, saves
/// or author any geography. Renderer must configure horizontal texture repeat.
/// </summary>
internal static class TerrainChartUv
{
    public static Vector2[] FromTriangle(Vector3 a, Vector3 b, Vector3 c)
    {
        Vector2[] uv = { FromPosition(a), FromPosition(b), FromPosition(c) };
        // Select the smallest-width cyclic interval of the three longitudes.
        // A contiguous interval exists for ordinary local triangles, unlike
        // polar/hemisphere-spanning geometry (which is not a texture guarantee).
        float best = float.PositiveInfinity;
        float[] chosen = new float[3];
        for (int anchor = 0; anchor < 3; anchor++)
        {
            var values = new float[3];
            float center = uv[anchor].X;
            for (int j = 0; j < 3; j++)
                values[j] = uv[j].X + Mathf.Round(center - uv[j].X);
            float width = Math.Max(values[0], Math.Max(values[1], values[2])) -
                Math.Min(values[0], Math.Min(values[1], values[2]));
            if (width < best)
            {
                best = width;
                Array.Copy(values, chosen, 3);
            }
        }
        for (int j = 0; j < 3; j++) uv[j].X = chosen[j];
        return uv;
    }

    private static Vector2 FromPosition(Vector3 p)
    {
        if (!p.IsFinite() || p.LengthSquared() <= 0)
            throw new ArgumentException("Nonfinite or degenerate terrain vertex.");
        Vector3 n = p.Normalized();
        float longitude = Mathf.Atan2(n.Z, n.X);
        float latitude = Mathf.Asin(Mathf.Clamp(n.Y, -1f, 1f));
        return new Vector2((longitude + Mathf.Pi) / Mathf.Tau,
            (Mathf.Pi / 2f - latitude) / Mathf.Pi);
    }
}
