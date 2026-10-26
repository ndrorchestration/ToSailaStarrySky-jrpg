using System;
using System.Collections.Generic;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// Conservative, camera-facing refinement choice for the noncanon native
/// globe study. Does not use a screen-error metric, occlusion test, or async
/// tile streaming; respects the existing (complete) logical cover.
/// </summary>
public static class CameraTilePriority
{
    public static TileId? NearestRefinable(
        IReadOnlyList<TileId> cover, Vector3 cameraPosition, int targetLevel)
    {
        ArgumentNullException.ThrowIfNull(cover);
        if (!float.IsFinite(cameraPosition.X) || !float.IsFinite(cameraPosition.Y)
            || !float.IsFinite(cameraPosition.Z) || cameraPosition.LengthSquared() < 1e-6f)
            throw new ArgumentOutOfRangeException(nameof(cameraPosition));
        if (targetLevel < 0 || targetLevel >= WatertightTiles.MaximumDemonstratedLevel)
            throw new ArgumentOutOfRangeException(nameof(targetLevel));
        TileId? best = null;
        float highest = float.NegativeInfinity;
        Vector3 radial = cameraPosition.Normalized();
        foreach (TileId t in cover)
        {
            if (t.Level != targetLevel) continue;
            int n = 1 << t.Level;
            var cube = WatertightTiles.Cube(t.Face, 2*t.Column+1, 2*t.Row+1, 2*n);
            float score = cube.Sphere(1f).Dot(radial);
            if(score > highest + 1e-6f)
            {
                highest=score;
                best=t;
            }
            else if(Math.Abs(score-highest)<=1e-6f && best.HasValue
                && StringComparer.Ordinal.Compare(t.ToString(),best.Value.ToString()) < 0)
                best=t;
        }
        return best;
    }
}
