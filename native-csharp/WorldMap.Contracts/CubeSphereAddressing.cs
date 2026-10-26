using System;

namespace StarrySky.WorldMap.Contracts;

/// <summary>
/// Deterministic sphere-to-cube-face addressing for a non-canon planet.
/// Convention: latitude is +Y, longitude zero is +X, east is +Z.
/// Coordinates are dimensionless. No mesh, elevation, biome or render claim.
/// </summary>
public static class CubeSphereAddressing
{
    public static (CubeFace Face, double U, double V) FromPosition(PlanetPosition point)
    {
        double latitude = point.LatitudeDegrees * Math.PI / 180.0;
        double longitude = point.LongitudeDegrees * Math.PI / 180.0;
        double x = Math.Cos(latitude) * Math.Cos(longitude);
        double y = Math.Sin(latitude);
        double z = Math.Cos(latitude) * Math.Sin(longitude);
        double ax = Math.Abs(x), ay = Math.Abs(y), az = Math.Abs(z);
        CubeFace face;
        double u, v;
        // Equal-magnitude boundaries have a stable face tie-break: X, then Y, then Z.
        if (ax >= ay && ax >= az)
        {
            if (x >= 0) { face = CubeFace.PositiveX; u = -z / ax; v = y / ax; }
            else { face = CubeFace.NegativeX; u = z / ax; v = y / ax; }
        }
        else if (ay >= az)
        {
            if (y >= 0) { face = CubeFace.PositiveY; u = x / ay; v = -z / ay; }
            else { face = CubeFace.NegativeY; u = x / ay; v = z / ay; }
        }
        else
        {
            if (z >= 0) { face = CubeFace.PositiveZ; u = x / az; v = y / az; }
            else { face = CubeFace.NegativeZ; u = -x / az; v = y / az; }
        }
        return (face, Math.Clamp((u + 1) / 2, 0, 1), Math.Clamp((v + 1) / 2, 0, 1));
    }

    public static PlanetPosition ToPosition(CubeFace face, double u, double v)
    {
        if (!Enum.IsDefined(face)) throw new ArgumentOutOfRangeException(nameof(face));
        if (!double.IsFinite(u) || u < 0 || u > 1) throw new ArgumentOutOfRangeException(nameof(u));
        if (!double.IsFinite(v) || v < 0 || v > 1) throw new ArgumentOutOfRangeException(nameof(v));
        double a = 2 * u - 1, b = 2 * v - 1;
        (double x, double y, double z) = face switch
        {
            CubeFace.PositiveX => (1, b, -a),
            CubeFace.NegativeX => (-1, b, a),
            CubeFace.PositiveY => (a, 1, -b),
            CubeFace.NegativeY => (a, -1, b),
            CubeFace.PositiveZ => (a, b, 1),
            CubeFace.NegativeZ => (-a, b, -1),
            _ => throw new ArgumentOutOfRangeException(nameof(face))
        };
        double magnitude = Math.Sqrt(x * x + y * y + z * z);
        double latitude = Math.Asin(Math.Clamp(y / magnitude, -1, 1)) * 180 / Math.PI;
        double longitude = Math.Atan2(z, x) * 180 / Math.PI;
        return new PlanetPosition(latitude, longitude);
    }

    public static TileId LocateTile(PlanetPosition point, int level)
    {
        if (level < 0 || level > 12) throw new ArgumentOutOfRangeException(nameof(level));
        var (face, u, v) = FromPosition(point);
        int count = 1 << level;
        int col = Math.Min((int)(u * count), count - 1);
        int row = Math.Min((int)(v * count), count - 1);
        return new TileId(face, level, col, row);
    }
}
