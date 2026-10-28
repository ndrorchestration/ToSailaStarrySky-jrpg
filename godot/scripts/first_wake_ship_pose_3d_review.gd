extends CanvasLayer
## Explicit test-only real Godot 3D inset inside Ionia-first Chapter I.
## This is not the game's physical ship. No collision, player input or saves.
const ShipRig = preload("res://scripts/ship_visual_3d_rig_study.gd")
const SOURCE_PR: int = 490
const SOURCE_BLOB := "b21327071e2120fd75113d6051af17dd2c45dbfd"
const PREVIEW_SIZE := Vector2i(480, 270)
const PREVIEW_POSITION := Vector2(548.0, 248.0)
const PREVIEW_DISPLAY_SIZE := Vector2(394.0, 222.0)

var ship: Node3D
var viewport: SubViewport
var review_texture: TextureRect

func _ready() -> void:
    name = "OptionalNative3DShipReview"
    layer = 3
    viewport = SubViewport.new()
    viewport.name = "IndependentArtReviewViewport"
    viewport.size = PREVIEW_SIZE
    viewport.own_world_3d = true
    viewport.transparent_bg = false
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(viewport)

    var world_environment := WorldEnvironment.new()
    world_environment.name = "PreviewEnvironment"
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color(0.035, 0.085, 0.13)
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color(0.62, 0.70, 0.75)
    settings.ambient_light_energy = 0.7
    world_environment.environment = settings
    viewport.add_child(world_environment)

    ship = ShipRig.new()
    ship.name = "AureateWakeOriginalFourWingArtStudy"
    viewport.add_child(ship)
    ship.set_motion(0.0, true)

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
    key.light_energy = 1.4
    viewport.add_child(key)

    var camera := Camera3D.new()
    camera.name = "ReviewCamera"
    camera.current = true
    camera.fov = 35.0
    camera.position = Vector3(7.8, 4.8, 9.6)
    viewport.add_child(camera)
    camera.look_at(Vector3(0.0, 0.0, -0.15), Vector3.UP)

    review_texture = TextureRect.new()
    review_texture.name = "VisibleShipRendererOnly"
    review_texture.position = PREVIEW_POSITION
    review_texture.size = PREVIEW_DISPLAY_SIZE
    review_texture.texture = viewport.get_texture()
    review_texture.stretch_mode = TextureRect.STRETCH_SCALE
    review_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(review_texture)

    var label := Label.new()
    label.name = "NoncanonicalAssetNotice"
    label.position = PREVIEW_POSITION + Vector2(9, 6)
    label.text = "SOURCE-PINNED 3D / REVIEW ONLY"
    label.add_theme_font_size_override("font_size", 13)
    label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.73))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(label)

func source_contract() -> Dictionary:
    return {
        "source_pr": SOURCE_PR,
        "source_blob": SOURCE_BLOB,
        "render_isolated": true,
        "swept_collision_certified": false,
        "human_scale_certified": false,
        "visible_by_default": false,
        "has_ship_physics": false,
        "has_gameplay_input": false,
        "modifies_story_or_save": false
    }

func neutral_restored() -> bool:
    if ship == null:
        return false
    for name in ShipRig.WING_NAMES:
        var rig: Node3D = ship.get_node_or_null("WingRig_" + name) as Node3D
        if rig == null or not is_zero_approx(rig.rotation.y):
            return false
    return true
