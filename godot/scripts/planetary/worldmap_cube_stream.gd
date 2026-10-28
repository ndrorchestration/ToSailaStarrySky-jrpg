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
const Context = preload("res://scripts/planetary/worldmap_material_context.gd")
const Preview = preload("res://scripts/planetary/worldmap_surface_material_preview.gd")

const TILE_BUDGET := 32
const CACHE_BUDGET := 64
const MAX_DETAIL_LEVEL := 7
const PLANET_KM := 6371.0
const PLANET_UNITS := 12.0

var _cache = Cache.new(CACHE_BUDGET)
var _active: Dictionary = {}
var _active_addresses: Dictionary = {}
var _review_enabled := false
var _review_weather := "clear"
var _review_rain := 0.0
var _review_low_quality := false
var _review_selected_key := ""
var _review_selected_material := "base"
const REVIEW_WIND := Vector3(0.68,0.17,-0.71)
const REVIEW_SUN := Vector3(0.54,0.68,-0.12)
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
    # Cubed-sphere faces can change winding orientation in the screen-space
    # path. The *review* material is double-sided to distinguish culling from
    # missing mesh uploads; final tile winding/art acceptance remains open.
    _land_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    _land_material.roughness = 0.87
    _land_material.metallic = 0.02
    # Reuse the exact shader already tested on low-sky water, rather than
    # permitting the two modes to drift in material semantics.
    var source := LocalTerrain.new()
    _sea_material = source.call("_sea_material")
    # This shader is private to the cubed-sphere preview. Keep the approved
    # mode-4 sea shader unchanged while disabling face culling for diagnostics.
    var ocean_shader := Shader.new()
    ocean_shader.code = _sea_material.shader.code.replace("render_mode cull_back;","render_mode cull_disabled;")
    _sea_material.shader = ocean_shader
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
    _active_addresses[str(data["key"])] = tile.duplicate(true)

func refresh(observer: Dictionary) -> Dictionary:
    var planning := Planner.plan(observer,PLANET_KM,TILE_BUDGET,MAX_DETAIL_LEVEL)
    var selected: Dictionary = {}
    for key in planning["keys"]:
        selected[str(key)] = true
    for key in _active.keys():
        if not selected.has(key):
            var node: Node3D = _active[key]
            _active.erase(key)
            _active_addresses.erase(key)
            remove_child(node)
            node.queue_free()
            _released_tiles += 1
    for tile in planning["tiles"]:
        var tile_key := Tile.key(tile)
        if not _active.has(tile_key):
            _add_tile(tile)
    _last_level = int(planning["level"])
    _refresh_material_review(observer)
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

func set_material_review(enabled: bool, weather: String = "clear",
        rain_strength: float = 0.0, low_quality: bool = false) -> bool:
    # Volatile REVIEW ONLY: never saved and does not create any weather.
    # Never allow a malformed request to mutate the previous settings.
    if not ["clear","rain"].has(weather) or not is_finite(rain_strength) \
            or rain_strength < 0.0 or rain_strength > 1.0 \
            or (weather == "clear" and rain_strength != 0.0):
        return false
    _review_enabled = enabled
    _review_weather = weather
    _review_rain = rain_strength
    _review_low_quality = low_quality
    return true

func review_stats() -> Dictionary:
    return {"enabled":_review_enabled,"weather":_review_weather,
        "rain":_review_rain,"low_quality":_review_low_quality,
        "selected_key":_review_selected_key,
        "selected_material":_review_selected_material}

func _refresh_material_review(observer: Dictionary) -> void:
    # Always restore the exact original renderer surface before (re)binding.
    # A single preview tile is changed. All other tiles and ALL oceans keep
    # original materials regardless of cache movement or rendering mode.
    for node in _active.values():
        var land := (node as Node3D).get_node_or_null("SphericalLand") as MeshInstance3D
        if land != null:
            land.material_override = _land_material
    _review_selected_key = ""
    _review_selected_material = "base"
    if not _review_enabled or _review_low_quality:
        return
    var candidates: Array[Dictionary] = []
    for key in _active.keys():
        var address: Dictionary = _active_addresses[key]
        var center: Vector2 = Tile.tile_center(address)
        var context: Dictionary = Context.resolve(center.x,center.y,
            _review_weather,_review_rain,REVIEW_WIND,REVIEW_SUN)
        var kind: String = str(context.get("material","base"))
        if not ["snow","sand","wet_ground"].has(kind):
            continue
        var point: Dictionary = Geo.position(center.x,center.y)
        var observer_point: Dictionary = Geo.position(
            float(observer["latDeg"]),float(observer["lonDeg"]))
        candidates.append({"key":str(key),"context":context,
            "kind":kind,"distance":Geo.separation_rad(point,observer_point)})
    # Nearest eligible tile wins; tie broken by canonical tile key.
    candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        if absf(float(a["distance"])-float(b["distance"])) < 0.0000001:
            return str(a["key"]) < str(b["key"])
        return float(a["distance"]) < float(b["distance"]))
    if candidates.is_empty():
        return
    var chosen: Dictionary=candidates[0]
    var material: ShaderMaterial=Preview.build(chosen["context"],true)
    if material == null:
        return
    var tile_node: Node3D=_active[str(chosen["key"])]
    var mesh := tile_node.get_node_or_null("SphericalLand") as MeshInstance3D
    if mesh != null:
        mesh.material_override=material
        _review_selected_key=str(chosen["key"])
        _review_selected_material=str(chosen["kind"])

func clear_view() -> void:
    for node in _active.values():
        (node as Node3D).queue_free()
    _active.clear()
    _active_addresses.clear()
    _review_selected_key = ""
    _review_selected_material = "base"
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
