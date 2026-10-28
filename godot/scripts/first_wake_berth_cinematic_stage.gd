extends Node2D
## Source-native painted/procedural scene dressing for the playable 2D
## local berth. Shares exactly the existing First Wake sky and water shaders.
## It owns ZERO world physics, berth proof, mooring, plot or save authority.
const SkyShader = preload("res://shaders/first_wake_cinematic_sky.gdshader")
const SeaShader = preload("res://shaders/first_wake_cinematic_sea.gdshader")
const PierArt = preload("res://scripts/first_wake_berth_pier_art.gd")
const SIZE := Vector2(960, 640)
const WATER_START := 323.0

var sky: ColorRect
var sea: ColorRect
var pier
var reduced_motion: bool = false

func _ready() -> void:
    sky = _layer("SourceStormbreakSky", Vector2.ZERO, Vector2(960, 425), SkyShader)
    sea = _layer("SourceOpenWater", Vector2(0, WATER_START), Vector2(960, 224), SeaShader)
    pier = PierArt.new()
    pier.name = "NonCanonicalLocalPierStudy"
    add_child(pier)
    set_reduced_motion(reduced_motion)

func _layer(title: String, at: Vector2, extent: Vector2, shader: Shader) -> ColorRect:
    var tile := ColorRect.new()
    tile.name = title
    tile.position = at
    tile.size = extent
    tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var material := ShaderMaterial.new()
    material.shader = shader
    tile.material = material
    add_child(tile)
    return tile

func set_reduced_motion(value: bool) -> void:
    reduced_motion = value
    if sea != null and sea.material is ShaderMaterial:
        (sea.material as ShaderMaterial).set_shader_parameter(
            "motion_scale", 0.0 if value else 1.0)

func set_berth_display(state: String, x: float, dwell: float) -> void:
    if pier != null:
        pier.set_berth_display(state, x, dwell)

func visual_snapshot() -> Dictionary:
    return {
        "native_source_sky_shader": sky != null and sky.material is ShaderMaterial
            and (sky.material as ShaderMaterial).shader == SkyShader,
        "native_source_sea_shader": sea != null and sea.material is ShaderMaterial
            and (sea.material as ShaderMaterial).shader == SeaShader,
        "source_native_pier_art": pier != null and pier.get_script() == PierArt,
        "art_only_no_physics": true,
        "has_collision_authority": false,
        "has_story_authority": false,
        "has_fuel_authority": false,
        "has_canonical_world_location": false,
        "production_art_approved": false,
        "reduced_motion": reduced_motion,
    }
