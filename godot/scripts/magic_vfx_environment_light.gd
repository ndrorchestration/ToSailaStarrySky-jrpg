extends Node2D
## Optional 2D light rig for the native magic VFX review. Not volumetrics or gameplay light.
## Lighting and shadows are renderer work, never encounter or time-of-day mutations.
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")

var light: PointLight2D
var character_id: String = "ender"
var lit: bool = true
var phase_progress: float = 0.29
var reduced_motion: bool = true
var _base_energy: float = 0.54

func _ready() -> void:
    var ramp := Gradient.new()
    ramp.set_color(0, Color(1.0, 1.0, 1.0, 0.91))
    ramp.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
    var radial := GradientTexture2D.new()
    radial.width = 256
    radial.height = 256
    radial.fill = GradientTexture2D.FILL_RADIAL
    radial.fill_from = Vector2(0.5, 0.5)
    radial.fill_to = Vector2(0.5, 0.0)
    radial.gradient = ramp
    light = PointLight2D.new()
    light.name = "PhysicalCanvasLight"
    light.texture = radial
    light.texture_scale = 1.96
    light.shadow_enabled = true
    light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
    light.shadow_filter_smooth = 2.0
    light.shadow_color = Color(0.03, 0.04, 0.07, 0.62)
    light.range_item_cull_mask = 1
    light.shadow_item_cull_mask = 1
    add_child(light)
    configure(character_id, phase_progress, reduced_motion)

func configure(identity: String, progress: float, motion_reduced: bool) -> bool:
    if not Catalog.has_character(identity) or is_nan(progress) or is_inf(progress):
        return false
    character_id = identity
    phase_progress = clampf(progress, 0.0, 1.0)
    reduced_motion = motion_reduced
    if light != null:
        var profile: Dictionary = Catalog.profile(identity)
        light.color = Color(str(profile["color"]))
        # No unbounded flashes, and no camera exposure changes.
        var envelope: float = 0.78 if reduced_motion else clampf(sin(phase_progress * PI), 0.0, 1.0)
        light.energy = minf(0.70, _base_energy * envelope + 0.12)
        light.visible = lit
    return true

func set_light_enabled(enabled: bool) -> void:
    lit = enabled
    if light != null:
        light.visible = enabled

func set_shadow_enabled(enabled: bool) -> void:
    if light != null:
        light.shadow_enabled = enabled
