using System;
using System.Collections.Generic;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// Per-neighbor cube-face boundary index. Indexes only the native vertices
/// present on the edges of actual active leaf tiles; a coarser tile adds an
/// intermediate boundary vertex only when another tile already requires it.
/// Cube-face conversion is canonical, so opposite orientations share keys.
/// Bounded, synchronous, noncanonical engineering proof (LOD <= 2).
/// </summary>
public sealed class NeighborBoundaryIndex
{
    private readonly HashSet<WatertightTiles.GridPoint> _perimeterPoints = new();
    private readonly int _side;

    public NeighborBoundaryIndex(IReadOnlyList<TileId> cover, int globalLevel)
    {
        ArgumentNullException.ThrowIfNull(cover);
        if (globalLevel < 0 || globalLevel > WatertightTiles.MaximumDemonstratedLevel)
            throw new ArgumentOutOfRangeException(nameof(globalLevel));
        _side = WatertightTiles.SegmentsPerLeaf << globalLevel;
        foreach (TileId tile in cover)
        {
            int step = 1 << (globalLevel - tile.Level);
            int startX = tile.Column * WatertightTiles.SegmentsPerLeaf * step;
            int startY = tile.Row * WatertightTiles.SegmentsPerLeaf * step;
            for (int i = 0; i <= WatertightTiles.SegmentsPerLeaf; i++)
            {
                int v = i * step;
                _perimeterPoints.Add(WatertightTiles.Cube(tile.Face,startX+v,startY,_side));
                _perimeterPoints.Add(WatertightTiles.Cube(tile.Face,startX+v,startY+WatertightTiles.SegmentsPerLeaf*step,_side));
                _perimeterPoints.Add(WatertightTiles.Cube(tile.Face,startX,startY+v,_side));
                _perimeterPoints.Add(WatertightTiles.Cube(tile.Face,startX+WatertightTiles.SegmentsPerLeaf*step,startY+v,_side));
            }
        }
    }

    public bool HasIntermediate(CubeFace face,int ax,int ay,int bx,int by)
    {
        int steps=Math.Max(Math.Abs(bx-ax),Math.Abs(by-ay));
        for (int i=1;i<steps;i++)
        {
            int x=ax+(bx-ax)*i/steps;
            int y=ay+(by-ay)*i/steps;
            if (_perimeterPoints.Contains(WatertightTiles.Cube(face,x,y,_side)))
                return true;
        }
        return false;
    }

    public int Append(List<WatertightTiles.GridPoint> ring,CubeFace face,
        int ax,int ay,int bx,int by,bool tileBoundary)
    {
        int steps=Math.Max(Math.Abs(bx-ax),Math.Abs(by-ay));
        int added=0;
        if (tileBoundary)
        {
            for(int i=1;i<steps;i++)
            {
                int x=ax+(bx-ax)*i/steps;
                int y=ay+(by-ay)*i/steps;
                var point=WatertightTiles.Cube(face,x,y,_side);
                if(_perimeterPoints.Contains(point))
                {
                    ring.Add(point);
                    added++;
                }
            }
        }
        ring.Add(WatertightTiles.Cube(face,bx,by,_side));
        return added;
    }
}
