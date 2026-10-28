extends Node3D
## A NONCANON S2/S3 review fixture: *actual #367 cubed-sphere meshes*.
## Deliberately never added to worldmap runtime, chapter saves or landing rules.
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
const Builder = preload("res://scripts/planetary/worldmap_cube_tile_mesh.gd")
const Context = preload("res://scripts/planetary/worldmap_material_context.gd")
const Preview = preload("res://scripts/planetary/worldmap_surface_material_preview.gd")
const WIND := Vector3(0.68,0.17,-0.71)
const SUN := Vector3(0.54,0.68,-0.12)
const LEVEL := 5
const DIVISIONS := 12
var instances: Array[MeshInstance3D] = []
var materials: Array[ShaderMaterial] = []
var selected_tiles: Array[Dictionary] = []
var selected_contexts: Array[Dictionary] = []
var mesh_stats: Array[Dictionary] = []
var planet_focus := Vector3.UP

static func _context(tile: Dictionary, weather: String) -> Dictionary:
    var center: Vector2 = Tiles.tile_center(tile)
    return Context.resolve(center.x,center.y,
        weather,0.8 if weather == "rain" else 0.0,WIND,SUN)

static func find_pair(kind: String) -> Array[Dictionary]:
    var weather := "rain" if kind == "wet_ground" else "clear"
    if not ["snow","wet_ground","sand"].has(kind):
        return []
    for lat in range(-80,81,5):
        for lon in range(-175,176,10):
            var first: Dictionary = Tiles.tile_at(float(lat),float(lon),LEVEL)
            var next: Dictionary = Tiles.neighbor(first,1,0)
            if Tiles.key(first) == Tiles.key(next):
                continue
            if _context(first,weather).get("material") == kind and \
                    _context(next,weather).get("material") == kind:
                return [first,next]
    return []

func make_pair(kind: String) -> bool:
    var tiles: Array[Dictionary] = find_pair(kind)
    if tiles.size() != 2:
        return false
    var weather := "rain" if kind == "wet_ground" else "clear"
    var directions: Array[Vector3] = []
    for tile in tiles:
        var context: Dictionary = _context(tile,weather)
        var candidate: ShaderMaterial = Preview.build(context,false)
        if candidate == null:
            return false
        var payload: Dictionary = Builder.build(tile,DIVISIONS)
        var mesh: ArrayMesh = payload["terrain"]
        if mesh == null:
            return false
        var node := MeshInstance3D.new()
        node.name = "SphericalTile_" + Tiles.key(tile).replace("/","_")
        node.mesh = mesh
        node.material_override = candidate
        add_child(node)
        instances.append(node)
        materials.append(candidate)
        selected_tiles.append(tile.duplicate(true))
        selected_contexts.append(context.duplicate(true))
        mesh_stats.append({
            "key":payload["key"],"vertex_count":int(payload["vertex_count"]),
            "land_cells":int(payload["land_cells"]),
            "water_cells":int(payload["water_cells"]),
            "vertices":(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).duplicate()
        })
        directions.append(Builder.sample_border(tile,6,6,DIVISIONS))
    planet_focus = (directions[0]+directions[1]).normalized()
    return true

func effect(enabled: bool) -> void:
    for i in range(materials.size()):
        materials[i].set_shader_parameter("effect_strength",
            float(selected_contexts[i]["optics_strength"]) if enabled else 0.0)

func make_camera() -> Camera3D:
    var camera := Camera3D.new()
    camera.name = "MatchedSphericalMaterialCamera"
    camera.fov = 54.0
    camera.near = 0.025
    camera.far = 300.0
    add_child(camera)
    var tangent: Vector3 = planet_focus.cross(Vector3(0,0,1))
    if tangent.length_squared() < 0.0001:
        tangent = planet_focus.cross(Vector3.RIGHT)
    tangent = tangent.normalized()
    camera.position = planet_focus*13.15+tangent*0.08
    var up := Vector3.FORWARD if absf(planet_focus.y) > 0.92 else Vector3.UP
    camera.look_at(planet_focus*12.0,up)
    camera.current = true
    return camera
