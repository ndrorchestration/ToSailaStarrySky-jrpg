extends SceneTree
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
var failed: Array[String] = []
func check(ok: bool, name: String) -> void:
    if not ok:
        failed.append(name)
func _initialize() -> void:
    var seam1 := Tiles.tile_at(0.0,179.999,8)
    var seam2 := Tiles.tile_at(0.0,-179.999,8)
    var seam_neighbors := Tiles.neighborhood(seam1, 1)
    var seam_connected := false
    for tile in seam_neighbors:
        if Tiles.key(tile) == Tiles.key(seam2):
            seam_connected = true
    check(seam_connected,"antimeridian adjacent tile continuity")
    var middle := Tiles.tile_at(0.0,0.0,3)
    check(Tiles.key(middle).begins_with("px/3/"),"equator face address")
    check(Tiles.level_size(12) == 4096,"level size limit")
    var nearby := Tiles.neighborhood(middle,1)
    check(nearby.size() >= 4 and nearby.size() <= 5,"one-ring neighbors")
    var polar := Tiles.tile_at(89.95,100.0,8)
    check(str(polar["face"]) == "pz","polar cap face")
    var directions := Tiles.neighborhood(polar,2)
    var unique: Dictionary = {}
    for tile in directions:
        unique[Tiles.key(tile)] = true
    check(directions.size() == unique.size(),"polar BFS unique")
    var center := Tiles.tile_center(polar)
    check(is_finite(center.x) and is_finite(center.y),"polar center finite")
    var vector := Tiles.coordinates_to_unit(30.0,-91.0)
    var inverse := Tiles.unit_to_coordinates(vector)
    check(absf(inverse.x-30.0) < 0.00001 and absf(inverse.y+91.0) < 0.00001,"vector geodetic round trip")
    var face_vec := Tiles.vector_from_face_uv("nx",0.2,-0.8)
    var uv := Tiles.face_uv_from_vector(face_vec)
    check(str(uv["face"]) == "nx" and absf(float(uv["u"])-0.2) < 0.0001,"face UV round trip")
    if failed.is_empty():
        print("GODOT_PLANETARY_TILE_PASS (9 assertions)")
        quit(0)
    else:
        push_error("GODOT_PLANETARY_TILE_FAIL: " + ", ".join(failed))
        quit(1)
