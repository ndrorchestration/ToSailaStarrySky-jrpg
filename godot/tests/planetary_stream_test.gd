extends SceneTree
const Geometry = preload("res://scripts/planetary/planetary_geometry.gd")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
const Stream = preload("res://scripts/planetary/planetary_streaming.gd")
const Cache = preload("res://scripts/planetary/planetary_tile_cache.gd")
const R := 6371.0
var failed: Array[String] = []
func check(ok: bool, name: String) -> void:
    if not ok:
        failed.append(name)
func create_value(tile: Dictionary) -> String:
    return Tiles.key(tile)
func _initialize() -> void:
    var observer := Geometry.position(13.0,179.95,2.0)
    var result := Stream.plan(observer,R,64,7)
    check(int(result["level"]) <= 7,"LOD never exceeds request")
    check(result["tiles"].size() <= 64,"tile budget enforced")
    check(result["tiles"].size() > 0,"nonempty visibility")
    check(result["keys"].size() == result["tiles"].size(),"stable key count")
    check(float(result["horizonKm"]) > 0.0,"physical horizon telemetry")
    var high := Stream.plan(Geometry.position(89.99,-179.9,20.0),R,32,12)
    check(high["tiles"].size() <= 32,"pole/high altitude budget")
    check(high["downgraded"] == (int(high["level"]) < 12),"downgrade flag accurate")
    var cache := Cache.new(2)
    var t0 := Tiles.tile_at(0,0,4)
    var t1 := Tiles.tile_at(0,90,4)
    var t2 := Tiles.tile_at(0,180,4)
    var a: Variant = cache.use_tile(t0,Callable(self,"create_value"))
    cache.use_tile(t1,Callable(self,"create_value"))
    check(cache.use_tile(t0,Callable(self,"create_value")) == a,"LRU retains repeated tile")
    cache.use_tile(t2,Callable(self,"create_value"))
    check(cache.has_tile(t0) and not cache.has_tile(t1),"LRU eviction order")
    var stats := cache.stats()
    check(int(stats["hits"]) == 1 and int(stats["misses"]) == 3 and int(stats["evictions"]) == 1,"LRU stats")
    cache.clear()
    check(int(cache.stats()["size"]) == 0,"LRU clear")
    if failed.is_empty():
        print("GODOT_PLANETARY_STREAM_PASS (11 assertions)")
        quit(0)
    else:
        push_error("GODOT_PLANETARY_STREAM_FAIL: " + ", ".join(failed))
        quit(1)
