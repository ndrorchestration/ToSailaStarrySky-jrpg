extends Node2D
## Noncanonical presentation adapter: transfers the original, exact Git-blob
## terrain/foliage/ocean texture family into a genuine Chapter One Godot scene.
## Only the sea-channel and existing planter areas are drawn in this first
## 2D integration pilot. This does not import 3D coast or world geometry.
const WATER: Texture2D = preload("res://art-staging/environment-study/water_ripple_detail.png")
const FOLIAGE: Texture2D = preload("res://art-staging/environment-study/foliage_microdetail.png")
const TERRAIN: Texture2D = preload("res://art-staging/environment-study/terrain_microdetail.png")
const BIOME: Texture2D = preload("res://art-staging/environment-study/biome_macrodetail.png")

const WATER_RECTS: Array[Rect2] = [
    Rect2(0.0, 403.0, 91.0, 124.0),
    Rect2(886.0, 403.0, 74.0, 124.0)
]
const PLANT_RECTS: Array[Rect2] = [
    Rect2(105.0, 381.0, 25.0, 32.0),
    Rect2(819.0, 380.0, 27.0, 34.0)
]
const ORIGINAL_SOURCE_RECT := Rect2(0.0, 0.0, 128.0, 128.0)

func _ready() -> void:
    # Explicitly noninteractive, hidden even if instantiated from code.
    visible = false
    z_index = -1
    mouse_filter = Control.MOUSE_FILTER_IGNORE if self is Control else 0

func source_resources() -> Dictionary:
    return {
        "terrain": TERRAIN,
        "foliage": FOLIAGE,
        "water": WATER,
        "biome": BIOME
    }

func _draw() -> void:
    # Color modulation overlays actual original bitmap RGB masks at low opacity.
    # Positions are constrained to the EXISTING stage's open water and planter
    # zones. They do not paint over playable planks, actors or dialogue UI.
    for area in WATER_RECTS:
        draw_texture_rect_region(WATER, area, ORIGINAL_SOURCE_RECT,
            Color(0.32, 0.67, 0.75, 0.22), false)
    for area in PLANT_RECTS:
        draw_texture_rect_region(FOLIAGE, area, ORIGINAL_SOURCE_RECT,
            Color(0.33, 0.58, 0.30, 0.26), false)
