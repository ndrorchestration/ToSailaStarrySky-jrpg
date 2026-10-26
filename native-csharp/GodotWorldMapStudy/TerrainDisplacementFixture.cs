using System;
using Godot;

/// <summary>
/// Analytic, deterministic NONCANON height fixture. The same normalized
/// three-dimensional cube-sphere coordinate yields the same radial offset
/// across tile borders, orientations and LOD levels. This is a continuous
/// mathematical test function, NOT any authored or procedurally approved
/// terrain/continent/biome definition. Normals remain radial approximations.
/// </summary>
public static class TerrainDisplacementFixture
{
    public const float Amplitude = 0.14f;

    public static float Offset(WatertightTiles.GridPoint key)
    {
        Vector3 unit = key.Sphere(1f);
        float broad = Mathf.Sin(7.4f * unit.X + 3.1f * unit.Z)
            * Mathf.Cos(6.0f * unit.Y - 2.0f * unit.X);
        float fine = 0.32f * Mathf.Sin(13.0f * unit.Z + 6.0f * unit.Y)
            * Mathf.Cos(9.0f * unit.X - 1.2f * unit.Y);
        return Amplitude * (broad + fine);
    }

    public static Vector3 Position(WatertightTiles.GridPoint key, float radius)
    {
        if (!float.IsFinite(radius) || radius < 1f)
            throw new ArgumentOutOfRangeException(nameof(radius));
        return key.Sphere(1f) * (radius + Offset(key));
    }
}
