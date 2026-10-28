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
const MaterialContext = preload("res://scripts/planetary/worldmap_material_context.gd")
const SurfaceLook = preload("res://scripts/planetary/worldmap_surface_material_preview.gd")

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
# Opt-in VISUAL REVIEW ONLY. This never enters a save or landing decision.
var _review_kind := "" # "", "snow", or "wet_ground" (synthetic rain look)
var _review_low_quality := false
var _review_key := ""
var _review_material: ShaderMaterial
var _review_observer: Dictionary = {}
const REVIEW_WIND := Vector3(0.68,0.17,-0.71)
const REVIEW_SUN := Vector3(0.54,0.68,-0.12)

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
    node.set_meta("surface_review_tile",tile.duplicate(true))
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
    _review_observer = observer.duplicate(true)
    _apply_surface_review()
    return stats()

func stats() -> Dictionary:
    var cache_stats := _cache.stats()
    return {"visible":_active.size(),"max_visible":TILE_BUDGET,
            "review_kind":_review_kind,"review_key":_review_key,
            "review_low_quality":_review_low_quality,
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

## Requests are intentionally explicit, ephemeral and non-persistent.
## "wet_ground" uses a fixed review-only rain cue, NOT the game weather.
func set_surface_review(kind: String, low_quality: bool = false) -> bool:
    if not ["","snow","wet_ground"].has(kind):
        return false
    _review_kind = kind
    _review_low_quality = low_quality
    _apply_surface_review()
    return true

func _apply_surface_review() -> void:
    var best_key := ""
    var best_context: Dictionary = {}
    var best_distance := INF
    if _review_kind != "" and not _review_low_quality and not _review_observer.is_empty():
        var keys: Array[String] = active_keys()
        for key in keys:
            var tile_node: Node3D = _active[key]
            var tile: Dictionary = tile_node.get_meta("surface_review_tile",{})
            if tile.is_empty():
                continue
            var center: Vector2 = Tile.tile_center(tile)
            var weather := "rain" if _review_kind == "wet_ground" else "clear"
            var context: Dictionary = MaterialContext.resolve(center.x,center.y,
                    weather,0.8 if weather == "rain" else 0.0,
                    REVIEW_WIND,REVIEW_SUN,false,false)
            if context.get("material","") != _review_kind:
                continue
            var distance: float = Geo.great_circle_distance_km(_review_observer,
                    {"latDeg":center.x,"lonDeg":center.y},PLANET_KM)
            if distance < best_distance:
                best_distance = distance
                best_key = key
                best_context = context
    # Avoid allocating a shader resource on every 0.35s flight refresh.
    if best_key == _review_key and (best_key == "" or _review_material != null):
        return
    if _review_key != "" and _active.has(_review_key):
        var previous: MeshInstance3D = _active[_review_key].get_node("SphericalLand")
        previous.material_override = _land_material
    _review_key = ""
    _review_material = null
    if best_key == "":
        return
    var candidate: ShaderMaterial = SurfaceLook.build(best_context,true)
    if candidate == null:
        return
    # Only the P2 preview's one selected tile receives border feather.
    # Source mesh, all other tiles and sea material remain untouched.
    var tile_info: Dictionary = _active[best_key].get_meta("surface_review_tile",{})
    if tile_info.is_empty() or not SurfaceLook.configure_review_tile_edge(
            candidate,tile_info,0.08):
        return
    var target: MeshInstance3D = _active[best_key].get_node("SphericalLand")
    target.material_override = candidate
    _review_key = best_key
    _review_material = candidate

func clear_view() -> void:
    for node in _active.values():
        (node as Node3D).queue_free()
    _active.clear()
    _last_level = -1
    _review_key = ""
    _review_material = null
    _review_observer = {}

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
