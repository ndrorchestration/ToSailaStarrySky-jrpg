using System;
using System.Collections.Generic;
using System.Linq;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// Small, NONCANON adaptive cube-sphere mesh laboratory.
/// Each tile has only 8x8 interior cells; on its perimeter, cells split only where actual neighboring active
/// tile edge vertices require it (including across cube faces). Boundary
/// cell triangle fans eliminate T-junctions; complete global edge-incidence
/// verification detects holes and duplicate faces before scene admission.
/// Bounded at LOD 2 and <=50k triangles; NOT a terrain streamer or a
/// production displaced-terrain stitching implementation.
/// </summary>
public static class AdaptiveBoundaryTiles
{
    private const int N = WatertightTiles.SegmentsPerLeaf;
    private const int MaxLevel = WatertightTiles.MaximumDemonstratedLevel;
    private const int MaxTriangles = WatertightTiles.MaximumTriangleBudget;
    private readonly record struct Edge(WatertightTiles.GridPoint A, WatertightTiles.GridPoint B)
    {
        public static Edge Of(WatertightTiles.GridPoint a, WatertightTiles.GridPoint b)
            => a.CompareTo(b) < 0 ? new Edge(a,b) : new Edge(b,a);
    }

    public static WatertightTiles.CheckedMeshSet Build(IReadOnlyList<TileId> cover, float radius)
    {
        ArgumentNullException.ThrowIfNull(cover);
        if (!float.IsFinite(radius) || radius <= 0)
            throw new ArgumentOutOfRangeException(nameof(radius));
        if (!QuadtreeCoverage.IsCompleteSixFaceCover(cover))
            throw new InvalidOperationException("Adaptive boundary refuses non-covering tiles.");
        int level = cover.Max(t => t.Level);
        if (level > MaxLevel)
            throw new InvalidOperationException("Adaptive study supports at most two refinements.");
        int globalSteps = N << level;
        var neighbors = new NeighborBoundaryIndex(cover,level);
        int insertedBoundaryVertices=0;
        int stitchedCells=0;
        var meshes = new Dictionary<TileId, ArrayMesh>();
        var edges = new Dictionary<Edge, int>();
        int triangles = 0;
        try
        {
            foreach (TileId tile in cover)
            {
                int step = 1 << (level - tile.Level);
                int startX = tile.Column * N * step;
                int startY = tile.Row * N * step;
                var builder = new SurfaceTool();
                builder.Begin(Mesh.PrimitiveType.Triangles);
                for (int row = 0; row < N; row++)
                for (int col = 0; col < N; col++)
                {
                    int x = startX + col * step, y = startY + row * step;
                    var a = WatertightTiles.Cube(tile.Face, x, y, globalSteps);
                    var b = WatertightTiles.Cube(tile.Face, x+step, y, globalSteps);
                    var c = WatertightTiles.Cube(tile.Face, x+step, y+step, globalSteps);
                    var d = WatertightTiles.Cube(tile.Face, x, y+step, globalSteps);
                    bool bottom = row==0 && neighbors.HasIntermediate(tile.Face,x,y,x+step,y);
                    bool right = col==N-1 && neighbors.HasIntermediate(tile.Face,x+step,y,x+step,y+step);
                    bool top = row==N-1 && neighbors.HasIntermediate(tile.Face,x+step,y+step,x,y+step);
                    bool left = col==0 && neighbors.HasIntermediate(tile.Face,x,y+step,x,y);
                    if (!(bottom||right||top||left))
                    {
                        Triangle(builder,a,b,c,radius,edges);
                        Triangle(builder,a,c,d,radius,edges);
                        triangles += 2;
                    }
                    else
                    {
                        var ring = new List<WatertightTiles.GridPoint> { a };
                        insertedBoundaryVertices += neighbors.Append(ring,tile.Face,x,y,x+step,y,row==0);
                        insertedBoundaryVertices += neighbors.Append(ring,tile.Face,x+step,y,x+step,y+step,col==N-1);
                        insertedBoundaryVertices += neighbors.Append(ring,tile.Face,x+step,y+step,x,y+step,row==N-1);
                        insertedBoundaryVertices += neighbors.Append(ring,tile.Face,x,y+step,x,y,col==0);
                        ring.RemoveAt(ring.Count-1);
                        var center=WatertightTiles.Cube(tile.Face,x+step/2,y+step/2,globalSteps);
                        for (int i=0;i<ring.Count;i++)
                        {
                            Triangle(builder,center,ring[i],ring[(i+1)%ring.Count],radius,edges);
                            triangles++;
                        }
                        stitchedCells++;
                    }
                    if (triangles > MaxTriangles)
                        throw new InvalidOperationException("Adaptive mesh exceeded global safety quota.");
                }
                var mesh = builder.Commit();
                if (mesh.GetSurfaceCount()!=1)
                    throw new InvalidOperationException("Godot adaptive native surface missing.");
                meshes.Add(tile,mesh);
            }
            int bad=edges.Values.Count(x=>x!=2);
            if (bad!=0 || edges.Count*2!=triangles*3)
                throw new InvalidOperationException($"Adaptive edge validation failed: edges={edges.Count} bad={bad} triangles={triangles}");
            GD.Print($"GODOT_CSHARP_NEIGHBOR_PASS level={level} tiles={cover.Count} inserted={insertedBoundaryVertices} stitchedCells={stitchedCells} triangles={triangles} nonmanifold={bad}");
            return new WatertightTiles.CheckedMeshSet(meshes,triangles,edges.Count,bad,level);
        }
        catch
        {
            foreach(var mesh in meshes.Values) mesh.Dispose();
            throw;
        }
    }

    private static void Triangle(SurfaceTool tool,WatertightTiles.GridPoint a,
        WatertightTiles.GridPoint b, WatertightTiles.GridPoint c,float radius,
        Dictionary<Edge,int> edges)
    {
        var av=a.Sphere(radius); var bv=b.Sphere(radius); var cv=c.Sphere(radius);
        if((bv-av).Cross(cv-av).Dot((av+bv+cv).Normalized())<0)
            (b,c)=(c,b);
        Vertex(tool,a,radius);Vertex(tool,b,radius);Vertex(tool,c,radius);
        Count(edges,a,b);Count(edges,b,c);Count(edges,c,a);
    }
    private static void Vertex(SurfaceTool tool,WatertightTiles.GridPoint p,float r)
    {
        var v=p.Sphere(r);
        tool.SetNormal(v.Normalized());tool.AddVertex(v);
    }
    private static void Count(Dictionary<Edge,int> edges,
        WatertightTiles.GridPoint a,WatertightTiles.GridPoint b)
    {
        var key=Edge.Of(a,b);
        edges.TryGetValue(key,out var n);
        edges[key]=n+1;
    }
}
