extends Node3D
## Bounded visible-tile scene renderer, layered over the legacy smooth globe.
## Tiles are actual native 3D meshes on the full sphere, using the existing
## horizon planner + validated cubed-sphere keys. Seed geography is NON-CANON.
## This is an opt-in review mode: no physics, geomorphing or independent LOD.
const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
const Tile = preload("res://scripts/planetary/planetary_tiles.gd")
const Planner = preload("res://scripts/planetary/planetary_streaming.gd")
const Cache = preload("res://scripts/planetary/planetary_tile_cache.gd")
const Builder = preload("res://scripts/planetary/worldmap_cube_tile_mesh.gd")
const LocalTerrain = preload("res://scripts/planetary/worldmap_local_terrain.gd")

const TILE_BUDGET := 32
const CACHE_BUDGET := 64
const MAX_DETAIL_LEVEL := 7
const PLANET_KM := 6371.0
const PLANET_UNITS := 12.0

var _cache = Cache.new(CACHE_BUDGET)
var _active: Dictionary = {}
var _land_material: StandardMaterial3D
var _sea_material: ShaderMaterial
var _last_level := -1
var _built_tiles := 0
var _released_tiles := 0

func _ready() -> void:
    name = "NativeCubedSphereTerrain"
    visible = false
    _land_material = StandardMaterial3D.new()
    _land_material.vertex_color_use_as_albedo = true
    _land_material.roughness = 0.87
    _land_material.metallic = 0.02
    # Reuse the exact shader already tested on low-sky water, rather than
    # permitting the two modes to drift in material semantics.
    var source := LocalTerrain.new()
    _sea_material = source.call("_sea_material")
    source.free()

func _build_payload(tile: Dictionary) -> Dictionary:
    _built_tiles += 1
    return Builder.build(tile)

func _add_tile(tile: Dictionary) -> void:
    var data: Dictionary = _cache.use_tile(tile,Callable(self,"_build_payload"))
    var node := Node3D.new()
    node.name = str(data["key"]).replace("/","_")
    var land := MeshInstance3D.new()
    land.name = "SphericalLand"
    land.mesh = data["terrain"]
    land.material_override = _land_material
    node.add_child(land)
    if data["water"] != null:
        var sea := MeshInstance3D.new()
        sea.name = "SphericalOcean"
        sea.mesh = data["water"]
        sea.material_override = _sea_material
        node.add_child(sea)
    add_child(node)
    _active[str(data["key"])] = node

func refresh(observer: Dictionary) -> Dictionary:
    var planning := Planner.plan(observer,PLANET_KM,TILE_BUDGET,MAX_DETAIL_LEVEL)
    var selected: Dictionary = {}
    for key in planning["keys"]:
        selected[str(key)] = true
    for key in _active.keys():
        if not selected.has(key):
            var node: Node3D = _active[key]
            _active.erase(key)
            remove_child(node)
            node.queue_free()
            _released_tiles += 1
    for tile in planning["tiles"]:
        var tile_key := Tile.key(tile)
        if not _active.has(tile_key):
            _add_tile(tile)
    _last_level = int(planning["level"])
    return stats()

func stats() -> Dictionary:
    var cache_stats := _cache.stats()
    return {"visible":_active.size(),"max_visible":TILE_BUDGET,
            "level":_last_level,"cache_size":int(cache_stats["size"]),
            "cache_hits":int(cache_stats["hits"]),
            "cache_misses":int(cache_stats["misses"]),
            "cache_evictions":int(cache_stats["evictions"]),
            "generated":_built_tiles,"released":_released_tiles}

func active_keys() -> Array[String]:
    var keys: Array[String] = []
    for k in _active.keys():
        keys.append(str(k))
    keys.sort()
    return keys

func clear_view() -> void:
    for node in _active.values():
        (node as Node3D).queue_free()
    _active.clear()
    _last_level = -1

static func flight_camera(observer: Dictionary) -> Dictionary:
    var world := Geo.to_cartesian(observer,PLANET_KM) * (PLANET_UNITS/PLANET_KM)
    var up := world.normalized()
    var lat := deg_to_rad(float(observer["latDeg"]))
    var lon := deg_to_rad(float(observer["lonDeg"]))
    var east := Vector3(-sin(lon),0.0,cos(lon))
    var north := Vector3(-sin(lat)*cos(lon),cos(lat),-sin(lat)*sin(lon))
    var heading := deg_to_rad(float(observer["headingDeg"]))
    var forward := (north*cos(heading) + east*sin(heading)).normalized()
    var eye := world+up*0.0015-forward*0.014
    # Aim modestly below the geometric tangent. A near-horizontal view
    # showed only sky in intermittent actual GL captures, hiding terrain
    # behind the lower HUD. The lowered sightline exposes a genuine near-
    # field curved surface without changing the observer's geodesic state.
    var aim := world+forward*0.045-up*0.006
    return {"eye":eye,"aim":aim,"up":up,"forward":forward}
