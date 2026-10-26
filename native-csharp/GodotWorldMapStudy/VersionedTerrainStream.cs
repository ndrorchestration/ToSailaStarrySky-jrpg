using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Godot;
using StarrySky.WorldMap.Contracts;

/// <summary>
/// EXPERIMENTAL bounded terrain transaction. A worker prepares managed CPU
/// vertex arrays only. Exactly MaxTilesPerFrame Godot ArrayMeshes are admitted
/// on the main thread. Old active scene nodes stay until the whole set is
/// staged; only the current revision may be returned for an atomic scene swap.
/// This does not yet implement continuous movement-driven streaming, tile
/// caching, terrain budgets measured in milliseconds or parallel GPU work.
/// </summary>
public sealed class VersionedTerrainStream : IDisposable
{
    public const int MaxTilesPerFrame = 2;
    private CancellationTokenSource? _cancel;
    private Task<AdaptiveBoundaryTiles.PreparedCover>? _task;
    private AdaptiveBoundaryTiles.PreparedCover? _prepared;
    private readonly Dictionary<TileId, ArrayMesh> _staged = new();
    private int _stagedCursor;
    private int _revision;
    private int _requestRevision;
    private TileId[] _requestedCover = Array.Empty<TileId>();

    public int Revision => _revision;
    public IReadOnlyList<TileId> RequestedCover => _requestedCover;
    public int MaximumObservedFrameAdmissions { get; private set; }
    public bool HasOutstandingRequest => _task != null;
    public bool IsCurrent(int revision) => revision == _revision && _task != null;

    public int Request(IReadOnlyList<TileId> cover, float radius)
    {
        ArgumentNullException.ThrowIfNull(cover);
        var snapshot = cover.ToArray();
        // This call is on the main thread and cheap relative to mesh creation.
        if (!QuadtreeCoverage.IsCompleteSixFaceCover(snapshot))
            throw new InvalidOperationException("Incomplete terrain cover cannot be requested.");
        if (_revision == int.MaxValue)
            throw new InvalidOperationException("Terrain revision exhausted.");
        _revision++;
        _cancel?.Cancel();
        _cancel?.Dispose();
        _cancel = new CancellationTokenSource();
        foreach (var old in _staged.Values) old.Dispose();
        _staged.Clear();
        _stagedCursor = 0;
        _prepared = null;
        _requestRevision = _revision;
        _requestedCover = snapshot;
        // No Godot Resources or scene nodes are created inside Task.Run.
        var token = _cancel.Token;
        _task = Task.Run(() => AdaptiveBoundaryTiles.Prepare(snapshot, radius, token), token);
        return _revision;
    }

    /// <summary>
    /// Fail-closed stale receipt admission, independently testable even if
    /// work completes after cancellation or supersession.
    /// </summary>
    public bool WouldAdmit(int revision) => _task != null && revision == _revision
        && revision == _requestRevision && !_cancel!.IsCancellationRequested;

    /// <summary>
    /// Call from _Process ONLY. Builds at most two native ArrayMesh resources
    /// per frame and does not expose partially staged geometry to the scene.
    /// </summary>
    public bool Pump(out WatertightTiles.CheckedMeshSet? complete)
    {
        complete = null;
        if (_task == null) return false;
        if (!_task.IsCompleted) return false;
        if (_task.IsCanceled || _cancel == null || _cancel.IsCancellationRequested)
            return false;
        if (_task.IsFaulted)
            throw new InvalidOperationException("CPU terrain preparation failed.", _task.Exception);
        _prepared ??= _task.GetAwaiter().GetResult();
        if (!WouldAdmit(_requestRevision))
            return false;

        int admittedThisFrame = 0;
        while (_stagedCursor < _prepared.Tiles.Length &&
               admittedThisFrame < MaxTilesPerFrame)
        {
            TileId tile = _prepared.Tiles[_stagedCursor++];
            _staged.Add(tile, AdaptiveBoundaryTiles.BuildTile(_prepared, tile));
            admittedThisFrame++;
        }
        MaximumObservedFrameAdmissions = Math.Max(MaximumObservedFrameAdmissions, admittedThisFrame);
        if (_stagedCursor < _prepared.Tiles.Length)
            return false;

        if (_stagedCursor != _prepared.Tiles.Length || _staged.Count != _requestedCover.Length)
            throw new InvalidOperationException("Incomplete terrain admission denied.");
        // Assemble and log on the main thread after a completely staged set.
        complete = AdaptiveBoundaryTiles.Assemble(_prepared, _staged);
        GD.Print($"GODOT_CSHARP_STREAM_ADMIT_PASS revision={_revision} tiles={_staged.Count} maxPerFrame={MaxTilesPerFrame} observed={MaximumObservedFrameAdmissions}");
        _staged.Clear(); // transfer ArrayMesh ownership to scene
        _task = null;
        _prepared = null;
        _cancel.Dispose();
        _cancel = null;
        return true;
    }

    public void Dispose()
    {
        _cancel?.Cancel();
        _cancel?.Dispose();
        _cancel = null;
        _task = null;
        _prepared = null;
        foreach (var mesh in _staged.Values) mesh.Dispose();
        _staged.Clear();
    }
}
