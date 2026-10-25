extends RefCounted
## Godot-native translation of PR #349 cubed-sphere addressing.
## Math-space vectors use (X=equatorial 0°, Y=equatorial 90°, Z=north pole).
## Godot rendering vectors use Y-up and are converted separately via Geometry.
const MAX_LEVEL := 12

static func level_size(level: int) -> int:
    assert(level >= 0 and level <= MAX_LEVEL, "GLOBE_TILE_LEVEL_INVALID")
    return 1 << level

static func _basis(face: String) -> Array:
    match face:
        "px": return [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
        "nx": return [Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, 1)]
        "py": return [Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1)]
        "ny": return [Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)]
        "pz": return [Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0)]
        "nz": return [Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0)]
    assert(false, "GLOBE_TILE_FACE_INVALID")
    return []

static func coordinates_to_unit(lat_deg: float, lon_deg: float) -> Vector3:
    assert(is_finite(lat_deg) and is_finite(lon_deg), "GLOBE_TILE_COORD_INVALID")
    var lat := deg_to_rad(lat_deg)
    var lon := deg_to_rad(lon_deg)
    return Vector3(cos(lat)*cos(lon), cos(lat)*sin(lon), sin(lat))

static func unit_to_coordinates(vec: Vector3) -> Vector2:
    assert(vec.is_finite() and vec.length_squared() > 0.0, "GLOBE_TILE_VECTOR_INVALID")
    var v := vec.normalized()
    var latitude := rad_to_deg(atan2(v.z, sqrt(v.x*v.x + v.y*v.y)))
    var longitude := fposmod(rad_to_deg(atan2(v.y, v.x)) + 180.0, 360.0) - 180.0
    return Vector2(latitude, longitude)

static func face_uv_from_vector(vec: Vector3) -> Dictionary:
    assert(vec.is_finite() and vec.length_squared() > 0.0, "GLOBE_TILE_VECTOR_INVALID")
    var v := vec.normalized()
    var x := absf(v.x)
    var y := absf(v.y)
    var z := absf(v.z)
    var face: String
    if x >= y and x >= z:
        face = "px" if v.x >= 0.0 else "nx"
    elif y >= z:
        face = "py" if v.y >= 0.0 else "ny"
    else:
        face = "pz" if v.z >= 0.0 else "nz"
    var b := _basis(face)
    var scale: float = v.dot(b[0])
    return {"face": face, "u": v.dot(b[1])/scale, "v": v.dot(b[2])/scale}

static func vector_from_face_uv(face: String, u: float, v: float) -> Vector3:
    assert(is_finite(u) and is_finite(v), "GLOBE_TILE_UV_INVALID")
    var b := _basis(face)
    return (b[0] + b[1]*u + b[2]*v).normalized()

static func address(face: String, u: float, v: float, level: int) -> Dictionary:
    var size := level_size(level)
    _basis(face) # Fail closed for unknown face.
    assert(is_finite(u) and is_finite(v), "GLOBE_TILE_UV_INVALID")
    assert(u >= -1.0000000001 and u <= 1.0000000001 and v >= -1.0000000001 and v <= 1.0000000001,
            "GLOBE_TILE_UV_RANGE_INVALID")
    return {"face":face,"level":level,
            "x":clampi(int(floor((u+1.0)*size*0.5)),0,size-1),
            "y":clampi(int(floor((v+1.0)*size*0.5)),0,size-1)}

static func tile_at(lat_deg: float, lon_deg: float, level: int) -> Dictionary:
    var face_uv := face_uv_from_vector(coordinates_to_unit(lat_deg, lon_deg))
    return address(str(face_uv["face"]),float(face_uv["u"]),float(face_uv["v"]),level)

static func validate_tile(tile: Dictionary) -> int:
    assert(tile.has("face") and tile.has("level") and tile.has("x") and tile.has("y"), "GLOBE_TILE_REQUIRED")
    var face := str(tile["face"])
    _basis(face)
    var level: int = int(tile["level"])
    var size := level_size(level)
    var x: int = int(tile["x"])
    var y: int = int(tile["y"])
    assert(x >= 0 and y >= 0 and x < size and y < size, "GLOBE_TILE_ADDRESS_INVALID")
    return size

static func key(tile: Dictionary) -> String:
    validate_tile(tile)
    return "%s/%d/%d/%d" % [str(tile["face"]), int(tile["level"]),int(tile["x"]),int(tile["y"])]

static func tile_center(tile: Dictionary) -> Vector2:
    var size := validate_tile(tile)
    var u: float = -1.0 + (float(tile["x"])+0.5)*2.0/size
    var v: float = -1.0 + (float(tile["y"])+0.5)*2.0/size
    return unit_to_coordinates(vector_from_face_uv(str(tile["face"]),u,v))

static func neighbor(tile: Dictionary, dx: int, dy: int) -> Dictionary:
    var size := validate_tile(tile)
    assert(abs(dx) <= 1 and abs(dy) <= 1, "GLOBE_TILE_NEIGHBOR_STEP_INVALID")
    if dx == 0 and dy == 0:
        return tile.duplicate()
    var u: float = -1.0+(float(tile["x"])+dx+0.5)*2.0/size
    var v: float = -1.0+(float(tile["y"])+dy+0.5)*2.0/size
    var new_uv := face_uv_from_vector(vector_from_face_uv(str(tile["face"]),u,v))
    return address(str(new_uv["face"]),float(new_uv["u"]),float(new_uv["v"]),int(tile["level"]))

static func neighborhood(center: Dictionary, rings: int = 1) -> Array[Dictionary]:
    validate_tile(center)
    assert(rings >= 0 and rings <= 5, "GLOBE_TILE_RINGS_INVALID")
    var collected: Dictionary = {}
    collected[key(center)] = center
    var frontier: Array[Dictionary] = [center]
    for ring in range(rings):
        var next_frontier: Array[Dictionary] = []
        for tile in frontier:
            for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
                var adjacent := neighbor(tile,direction.x,direction.y)
                var id := key(adjacent)
                if not collected.has(id):
                    collected[id] = adjacent
                    next_frontier.append(adjacent)
        frontier = next_frontier
    var output: Array[Dictionary] = []
    for tile in collected.values():
        output.append(tile)
    return output
