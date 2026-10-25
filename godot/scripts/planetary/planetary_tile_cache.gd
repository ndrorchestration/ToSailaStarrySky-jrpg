extends RefCounted
## Bounded in-memory LRU for native tile payloads; no disk/network access.
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
var max_entries: int = 256
var _data: Dictionary = {}
var _order: Array[String] = []
var _hits: int = 0
var _misses: int = 0
var _evictions: int = 0

func _init(capacity: int = 256) -> void:
    assert(capacity >= 1 and capacity <= 16384,"GLOBE_STREAM_CACHE_BUDGET_INVALID")
    max_entries = capacity

func has_tile(tile: Dictionary) -> bool:
    return _data.has(Tiles.key(tile))

func use_tile(tile: Dictionary, factory: Callable) -> Variant:
    var id := Tiles.key(tile)
    if _data.has(id):
        _hits += 1
        _order.erase(id)
        _order.append(id)
        return _data[id]
    assert(factory.is_valid(),"GLOBE_STREAM_FACTORY_REQUIRED")
    var value: Variant = factory.call(tile)
    _data[id] = value
    _order.append(id)
    _misses += 1
    if _order.size() > max_entries:
        var oldest: String = str(_order.pop_front())
        _data.erase(oldest)
        _evictions += 1
    return value

func stats() -> Dictionary:
    return {"size":_data.size(),"hits":_hits,"misses":_misses,
            "evictions":_evictions,"maxEntries":max_entries}

func clear() -> void:
    _data.clear()
    _order.clear()
    _hits = 0
    _misses = 0
    _evictions = 0
