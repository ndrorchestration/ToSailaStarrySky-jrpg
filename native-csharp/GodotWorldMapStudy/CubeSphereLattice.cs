using System;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// Isolated, noncanonical spherical-debug geometry lattice for a bounded native
/// rendering experiment. The uniform base-face sample grid prevents cracks
/// between adjacent cube faces and the current one-level refined face; it is
/// NOT a progressive production LOD implementation.
/// </summary>
internal static class CubeSphereLattice
{
    public const int BaseFaceSegments = 32;
    public const float DebugRadius = 6f;

    public static int SegmentsFor(TileId tile)
    {
        // Every leaf samples the SAME 32-segment lattice on its parent face.
        // Intentionally supports only levels 0..4 in this debug experiment.
        if (tile.Level < 0 || tile.Level > 4)
            throw new ArgumentOutOfRangeException(nameof(tile),
                "Debug geometry cannot represent this level at a useful lattice resolution.");
        return BaseFaceSegments >> tile.Level;
    }

    public static Vector3 Point(CubeFace face, float normalizedU, float normalizedV)
    {
        if (!Enum.IsDefined(face) ||
            !float.IsFinite(normalizedU) || !float.IsFinite(normalizedV) ||
            normalizedU < 0f || normalizedU > 1f ||
            normalizedV < 0f || normalizedV > 1f)
            throw new ArgumentOutOfRangeException(nameof(normalizedU));

        float u = normalizedU * 2f - 1f;
        float v = normalizedV * 2f - 1f;
        Vector3 cube = face switch
        {
            CubeFace.PositiveX => new Vector3(1, v, -u),
            CubeFace.NegativeX => new Vector3(-1, v, u),
            CubeFace.PositiveY => new Vector3(u, 1, -v),
            CubeFace.NegativeY => new Vector3(u, -1, v),
            CubeFace.PositiveZ => new Vector3(u, v, 1),
            CubeFace.NegativeZ => new Vector3(-u, v, -1),
            _ => throw new ArgumentOutOfRangeException(nameof(face)),
        };
        return cube.Normalized() * DebugRadius;
    }

    public static Vector3 TilePoint(TileId tile, int localCol, int localRow)
    {
        int divisions = SegmentsFor(tile);
        if (localCol < 0 || localCol > divisions ||
            localRow < 0 || localRow > divisions)
            throw new ArgumentOutOfRangeException(nameof(localCol));
        int cells = 1 << tile.Level;
        float u = (tile.Column * divisions + localCol) /
            (float)(cells * divisions);
        float v = (tile.Row * divisions + localRow) /
            (float)(cells * divisions);
        return Point(tile.Face, u, v);
    }

    /// <summary>
    /// Four oriented sides sampled at a fixed face resolution. Caller compares
    /// either forward or reverse ordering for a matching edge of another face.
    /// </summary>
    public static Vector3 FaceBorder(CubeFace face, int edge, int index)
    {
        if (edge < 0 || edge >= 4 ||
            index < 0 || index > BaseFaceSegments)
            throw new ArgumentOutOfRangeException(nameof(index));
        float s = index / (float)BaseFaceSegments;
        return edge switch
        {
            0 => Point(face, s, 0),
            1 => Point(face, s, 1),
            2 => Point(face, 0, s),
            3 => Point(face, 1, s),
            _ => throw new ArgumentOutOfRangeException(nameof(edge)),
        };
    }

    /// <summary>
    /// This fixed face grid is intentionally identical at a root/child split.
    /// Each refined child contains half the 32 base-face intervals on an edge.
    /// </summary>
    public static Vector3 RefinedBorderPoint(CubeFace face, int edge, int index)
    {
        if (index < 0 || index > BaseFaceSegments ||
            edge < 0 || edge > 3)
            throw new ArgumentOutOfRangeException(nameof(index));
        int half = BaseFaceSegments / 2;
        int h = index >= half ? 1 : 0;
        int local = index - h * half;
        TileId child = edge switch
        {
            0 => new TileId(face, 1, h, 0),
            1 => new TileId(face, 1, h, 1),
            2 => new TileId(face, 1, 0, h),
            _ => new TileId(face, 1, 1, h),
        };
        return edge switch
        {
            0 => TilePoint(child, local, 0),
            1 => TilePoint(child, local, half),
            2 => TilePoint(child, 0, local),
            _ => TilePoint(child, half, local),
        };
    }
}
