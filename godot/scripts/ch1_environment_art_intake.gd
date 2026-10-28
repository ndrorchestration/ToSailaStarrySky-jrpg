extends Node2D
## Optional, noncanonical native Chapter I environmental material admission.
## Original source PNGs are unchanged (see pinned exact Git blobs in manifest).
## The layered water/planter presentation reads the existing 2D dock stage;
## it does not define any new coast, collision surface, chapter or save field.
const WATER: Texture2D = preload("res://art-staging/environment-study/water_ripple_detail.png")
const FOLIAGE: Texture2D = preload("res://art-staging/environment-study/foliage_microdetail.png")
const TERRAIN: Texture2D = preload("res://art-staging/environment-study/terrain_microdetail.png")
const BIOME: Texture2D = preload("res://art-staging/environment-study/biome_macrodetail.png")
const SURFACE_MATERIAL: Shader = preload("res://shaders/environment_material_adapter.gdshader")

# Legacy rects retained exactly for independent identical-pose art comparison.
const WATER_RECTS: Array[Rect2] = [
    Rect2(0.0, 403.0, 91.0, 124.0),
    Rect2(886.0, 403.0, 74.0, 124.0)
]
const PLANT_RECTS: Array[Rect2] = [
    Rect2(105.0, 381.0, 25.0, 32.0),
    Rect2(819.0, 380.0, 27.0, 34.0)
]
const ORIGINAL_SOURCE_RECT := Rect2(0.0, 0.0, 128.0, 128.0)

# Slightly larger *presentation* footprints allow feathering to zero before
# any art-region edge. They do not expand the playable dock.
const BLENDED_WATER_RECTS: Array[Rect2] = [
    Rect2(0.0, 388.0, 98.0, 154.0),
    Rect2(871.0, 388.0, 89.0, 154.0)
]
const BLENDED_PLANT_RECTS: Array[Rect2] = [
    Rect2(98.0, 369.0, 40.0, 54.0),
    Rect2(811.0, 369.0, 44.0, 54.0)
]

var _preview_variant: String = "blended"
var _low_detail: bool = false
var _painters: Array[TextureRect] = []

func _ready() -> void:
    visible = false
    z_index = -1
    for region in BLENDED_WATER_RECTS:
        _paint_region(region, WATER, 0)
    for region in BLENDED_PLANT_RECTS:
        _paint_region(region, FOLIAGE, 1)
    _apply_presentation()

func _paint_region(area: Rect2, source: Texture2D, family: int) -> void:
    var patch := TextureRect.new()
    patch.name = "WaterMaterialStudy" if family == 0 else "PlanterMaterialStudy"
    patch.position = area.position
    patch.size = area.size
    patch.texture = source
    patch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    patch.stretch_mode = TextureRect.STRETCH_SCALE
    patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
    patch.focus_mode = Control.FOCUS_NONE
    var shader_material := ShaderMaterial.new()
    shader_material.shader = SURFACE_MATERIAL
    shader_material.set_shader_parameter("micro_detail", source)
    shader_material.set_shader_parameter("region_detail", BIOME)
    shader_material.set_shader_parameter("surface_family", family)
    shader_material.set_shader_parameter("material_strength", 0.88)
    shader_material.set_shader_parameter("mask_quality", 1.0)
    patch.material = shader_material
    add_child(patch)
    _painters.append(patch)

func source_resources() -> Dictionary:
    return {"terrain": TERRAIN, "foliage": FOLIAGE, "water": WATER, "biome": BIOME}

func material_patches() -> Array[TextureRect]:
    return _painters.duplicate()

func preview_variant() -> String:
    return _preview_variant

func set_preview_variant(variant: String) -> void:
    # Legacy candidate exists for testing only; original scene remains OFF.
    if variant not in ["legacy", "blended"]:
        return
    _preview_variant = variant
    _apply_presentation()

func set_low_detail(enabled: bool) -> void:
    _low_detail = enabled
    _apply_presentation()

func is_low_detail() -> bool:
    return _low_detail

func _apply_presentation() -> void:
    var show_blended: bool = _preview_variant == "blended" and not _low_detail
    for patch in _painters:
        patch.visible = show_blended
    queue_redraw()

func _draw() -> void:
    if _preview_variant != "legacy" or _low_detail:
        return
    # Exact previous PR #494 patch for controlled before/after comparison.
    for area in WATER_RECTS:
        draw_texture_rect_region(WATER, area, ORIGINAL_SOURCE_RECT,
            Color(0.32, 0.67, 0.75, 0.22), false)
    for area in PLANT_RECTS:
        draw_texture_rect_region(FOLIAGE, area, ORIGINAL_SOURCE_RECT,
            Color(0.33, 0.58, 0.30, 0.26), false)
