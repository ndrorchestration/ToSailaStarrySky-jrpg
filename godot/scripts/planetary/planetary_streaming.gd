extends RefCounted
## Native metadata-only, horizon-capped cubed-sphere tile planner.
## Plans tile KEYS; it does not stream actual meshes or licensed world geography.
const Geometry = preload("res://scripts/planetary/planetary_geometry.gd")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")

static func target_level(horizon_angle_rad: float) -> int:
    assert(is_finite(horizon_angle_rad) and horizon_angle_rad >= 0.0, "GLOBE_STREAM_HORIZON_INVALID")
    return clampi(int(floor(log(10.0 / maxf(horizon_angle_rad,1.0e-8)) / log(2.0))),0,Tiles.MAX_LEVEL)

static func angular_padding(level: int) -> float:
    return atan(sqrt(2.0)/float(Tiles.level_size(level)))

static func _candidates(p: Dictionary, radius_km: float, level: int, max_tiles: int) -> Array[Dictionary]:
    var allowance := Geometry.horizon_angle_rad(float(p["altitudeKm"]), radius_km)+angular_padding(level)
    var seed := Tiles.tile_at(float(p["latDeg"]),float(p["lonDeg"]),level)
    var seen: Dictionary = {}
    seen[Tiles.key(seed)] = true
    var queue: Array[Dictionary] = [seed]
    var selected: Array[Dictionary] = []
    var index := 0
    while index < queue.size():
        var tile: Dictionary = queue[index]
        index += 1
        var center := Tiles.tile_center(tile)
        var loc := Geometry.position(center.x, center.y)
        if Geometry.separation_rad(p,loc) > allowance + 1.0e-12:
            continue
        selected.append(tile)
        if selected.size() > max_tiles:
            return []
        for step in [Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN]:
            var adjacent := Tiles.neighbor(tile,step.x,step.y)
            var id := Tiles.key(adjacent)
            if not seen.has(id):
                seen[id] = true
                queue.append(adjacent)
        if queue.size() > max_tiles*10:
            return []
    return selected

static func plan(position_data: Dictionary,radius_km: float,max_tiles: int = 256,requested_level: int = -1) -> Dictionary:
    assert(max_tiles >= 16 and max_tiles <= 1024,"GLOBE_STREAM_BUDGET_INVALID")
    assert(Geometry.valid_radius(radius_km),"GLOBE_STREAM_RADIUS_INVALID")
    var p := Geometry.position(float(position_data["latDeg"]),float(position_data["lonDeg"]),
            float(position_data.get("altitudeKm",0.0)))
    var horizon := Geometry.horizon_angle_rad(float(p["altitudeKm"]),radius_km)
    var level := target_level(horizon) if requested_level == -1 else requested_level
    Tiles.level_size(level)
    var initial_level := level
    var found: Array[Dictionary] = []
    while level >= 0:
        found = _candidates(p,radius_km,level,max_tiles)
        if not found.is_empty():
            break
        level -= 1
    assert(not found.is_empty(),"GLOBE_STREAM_PLAN_UNAVAILABLE")
    var keys: Array[String] = []
    for tile in found:
        keys.append(Tiles.key(tile))
    return {"level":level,"downgraded":level < initial_level,
            "horizonKm":Geometry.horizon_distance_km(float(p["altitudeKm"]),radius_km),
            "tiles":found,"keys":keys}
