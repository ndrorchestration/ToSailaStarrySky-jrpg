using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// Noncanonical, main-thread ONLY, per-frame bounded staging of mesh instances,
/// collision shapes and StaticBody3D children. Unparented candidates cannot
/// replace active terrain until the complete set has been constructed.
/// Does not bound final AddChild/RemoveChild/physics registration cost.
/// </summary>
public sealed class SceneAdmissionBudget : IDisposable
{
    public const int MaxNodesPerFrame = 2;
    private readonly TileId[] _tiles;
    private readonly WatertightTiles.CheckedMeshSet _checked;
    private readonly Dictionary<TileId, MeshInstance3D> _staged = new();
    private int _next;
    private bool _transferred;
    public int MaximumObservedNodeAdmissions { get; private set; }
    public double MaximumObservedStageMilliseconds { get; private set; }
    public int Revision { get; }

    public SceneAdmissionBudget(int revision,
        WatertightTiles.CheckedMeshSet checkedSet, IReadOnlyList<TileId> cover)
    {
        Revision = revision;
        _checked = checkedSet;
        _tiles = cover.ToArray();
        if (_tiles.Length != _checked.Meshes.Count ||
            _tiles.Any(t => !_checked.Meshes.ContainsKey(t)))
            throw new InvalidOperationException("Scene admission candidate incomplete.");
    }

    /// <summary>Called once per native Godot _Process, never from a task.</summary>
    public bool Pump(Func<TileId, ArrayMesh, MeshInstance3D> makeNode)
    {
        if (_transferred)
            throw new InvalidOperationException("Transferred candidate may not be staged again.");
        var watch = Stopwatch.StartNew();
        int processed = 0;
        while (_next < _tiles.Length && processed < MaxNodesPerFrame)
        {
            TileId tile = _tiles[_next];
            var instance = makeNode(tile, _checked.Meshes[tile]);
            _staged.Add(tile, instance);
            _next++;
            processed++;
        }
        watch.Stop();
        MaximumObservedNodeAdmissions = Math.Max(MaximumObservedNodeAdmissions, processed);
        MaximumObservedStageMilliseconds =
            Math.Max(MaximumObservedStageMilliseconds, watch.Elapsed.TotalMilliseconds);
        GD.Print($"GODOT_CSHARP_NODE_STAGE_PROGRESS revision={Revision} added={processed} staged={_staged.Count} total={_tiles.Length} ms={watch.Elapsed.TotalMilliseconds:F3}");
        return _staged.Count == _tiles.Length;
    }

    public IReadOnlyList<MeshInstance3D> TakeComplete()
    {
        if (_transferred || _staged.Count != _tiles.Length)
            throw new InvalidOperationException("Cannot commit incomplete staged scene nodes.");
        _transferred = true;
        var result = _tiles.Select(t => _staged[t]).ToArray();
        _staged.Clear();
        GD.Print($"GODOT_CSHARP_NODE_STAGE_PASS revision={Revision} nodes={result.Length} maxPerFrame={MaxNodesPerFrame} observed={MaximumObservedNodeAdmissions} maxStageMs={MaximumObservedStageMilliseconds:F3}");
        return result;
    }

    public void Dispose()
    {
        if (!_transferred)
        {
            foreach (var node in _staged.Values)
                node.Free(); // all nodes are unparented, therefore not in SceneTree
            foreach (var mesh in _checked.Meshes.Values)
                mesh.Dispose(); // cancelled, never owned by live scene
        }
        _staged.Clear();
    }
}
