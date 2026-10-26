using System;

namespace StarrySky.WorldMap.Contracts;

/// <summary>
/// Non-canon, engine-independent equirectangular chart coordinates.
/// X wraps across the antimeridian; Y includes both poles. No world texture,
/// settlement, discovery reveal, or geographic authority is implied.
/// </summary>
public static class WorldMapChartProjection
{
    /// <summary>Maps an accepted planet coordinate to normalized chart space [0,1].</summary>
    public static (double X, double Y) Project(PlanetPosition position)
    {
        double x = (position.LongitudeDegrees + 180.0) / 360.0;
        double y = (90.0 - position.LatitudeDegrees) / 180.0;
        return (x, y);
    }

    /// <summary>
    /// Maps normalized chart coordinates back to a surface point.
    /// X=1 is the same geographic meridian as X=0, but the chart
    /// may render them at opposite horizontal edges.
    /// </summary>
    public static PlanetPosition Unproject(double x, double y)
    {
        if (!double.IsFinite(x) || x < 0 || x > 1)
            throw new ArgumentOutOfRangeException(nameof(x));
        if (!double.IsFinite(y) || y < 0 || y > 1)
            throw new ArgumentOutOfRangeException(nameof(y));
        return new PlanetPosition(90.0 - y * 180.0, x * 360.0 - 180.0);
    }

    /// <summary>
    /// Returns the shortest horizontal chart displacement across the seam.
    /// Antipodal meridians have two equally short directions: the caller must
    /// choose a direction explicitly rather than receiving an arbitrary sign.
    /// </summary>
    public static bool TryShortestWrappedDeltaX(double fromX, double toX, out double deltaX)
    {
        ValidateX(fromX, nameof(fromX));
        ValidateX(toX, nameof(toX));
        double raw = toX - fromX;
        if (Math.Abs(Math.Abs(raw) - 0.5) < 1e-12)
        {
            deltaX = 0;
            return false;
        }
        deltaX = raw > 0.5 ? raw - 1.0 : raw < -0.5 ? raw + 1.0 : raw;
        return true;
    }

    private static void ValidateX(double x, string name)
    {
        if (!double.IsFinite(x) || x < 0 || x > 1)
            throw new ArgumentOutOfRangeException(name);
    }
}
