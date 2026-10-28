extends Node2D
## Visual-only Chapter I dock integration laboratory.
## Reuses the ACTUAL native Chapter I scene, authored dock and opt-in Ender art.
## Does not dispatch combat, grant spells, open dialogue or mutate chapter state.
const Chapter = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const MagicVFX = preload("res://scripts/magic_vfx.gd")
const LightRig = preload("res://scripts/magic_vfx_environment_light.gd")
const Atmosphere = preload("res://scripts/magic_vfx_chapter1_atmosphere.gd")
# Lighting and atmosphere conditions are experimental contrast presets, NOT canon time/weather.
const LIGHT_PROFILES = {
    "daylight": Color(1.0, 1.0, 1.0),
    "dusk": Color(0.78, 0.73, 0.66),
    "night": Color(0.44, 0.53, 0.69)
}
const KEYFRAMES = [0.08, 0.29, 0.49, 0.67, 0.89]
# The review VFX center sits to Ender's right: readable silhouette, still a local casting composition.
const EFFECT_OFFSET = Vector2(64.0, -57.0)
const EFFECT_SCALE = Vector2(0.58, 0.58)
const DEFAULT_CAMERA = Vector2(480.0, 320.0)
const CLOSEUP_OFFSET = Vector2(0.0, -70.0)

var world: Node2D
var actor_layer: Node2D
var effect: Node2D
var light_rig: Node2D
var camera: Camera2D
var active_index: int = 0
var phase_index: int = 1
var reduced_motion: bool = true
var magic_visible: bool = true
var lighting_enabled: bool = true
var front_composite: bool = false
var closeup_enabled: bool = false
var lighting_preset: String = "daylight"
var weather_preset: String = "clear"
var ambient: CanvasModulate
var atmosphere: Node2D
var _camera_ui_scrims: Array[ColorRect] = []

func _ready() -> void:
    world = Chapter.instantiate()
    world.name = "ChapterOneOriginalReview"
    add_child(world)
    # The wrapper is a read-only visual fixture. Disable gameplay input and
    # actor physics without touching the original scene's scripts or resources.
    world.set_process_unhandled_key_input(false)
    world.set_process_unhandled_input(false)
    world.ender.player_controlled = false
    world.ender.set_physics_process(false)
    for actor in world.contacts.values():
        actor.set_physics_process(false)
    actor_layer = world.get_node("ChapterOneMigrationActors")
    ambient = CanvasModulate.new()
    ambient.name = "VisualQAOnlyAmbient"
    world.add_child(ambient)
    ambient.color = LIGHT_PROFILES["daylight"]
    camera = Camera2D.new()
    camera.name = "ReviewCamera"
    camera.position = DEFAULT_CAMERA
    camera.zoom = Vector2.ONE
    camera.position_smoothing_enabled = false
    add_child(camera)
    camera.make_current()

    effect = MagicVFX.new()
    effect.name = "DockMagicVisualOnly"
    effect.position = world.ender.position + EFFECT_OFFSET
    effect.scale = EFFECT_SCALE
    effect.z_index = -1
    actor_layer.add_child(effect)
    effect.set_quality(0)

    light_rig = LightRig.new()
    light_rig.name = "DockMagicLightOnly"
    light_rig.position = effect.position
    world.add_child(light_rig)
    light_rig.set_shadow_enabled(false) # Existing dock has no authorized 2D occluder geometry.
    atmosphere = Atmosphere.new()
    atmosphere.name = "VisualQAOnlyWeather"
    atmosphere.z_index = 6
    add_child(atmosphere)
    choose_affinity(0)

    var canvas_ui := CanvasLayer.new()
    canvas_ui.name = "VisualQAOnlyOverlay"
    canvas_ui.layer = 3
    add_child(canvas_ui)
    var notice := Label.new()
    notice.name = "VisualQAStatus"
    notice.position = Vector2(646.0, 108.0)
    notice.add_theme_font_size_override("font_size", 14)
    notice.add_theme_color_override("font_color", Color("#f5eacf"))
    notice.text = "MAGIC LOOK DEV ONLY - NO SPELL CAST"
    canvas_ui.add_child(notice)
    _install_camera_ui_scrims()

func _install_camera_ui_scrims() -> void:
    # Only a reversible close-up review fixture. The production Chapter I HUD
    # currently draws dark panels in world space; Camera2D zoom can displace them
    # behind fixed CanvasLayer labels. Attach duplicate dark panels *within* the
    # actual Chapter I UI CanvasLayer, below all text, ONLY while close-up is on.
    var chapter_ui: CanvasLayer = world.get_node("ChapterOneMigrationUI") as CanvasLayer
    for region in [Rect2(10.0, 8.0, 940.0, 90.0), Rect2(10.0, 550.0, 940.0, 82.0)]:
        var scrim := ColorRect.new()
        scrim.name = "VisualQACameraSafeHudPanel"
        scrim.position = region.position
        scrim.size = region.size
        scrim.color = Color(0.035, 0.07, 0.13, 0.96)
        scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
        scrim.visible = false
        chapter_ui.add_child(scrim)
        chapter_ui.move_child(scrim, 0)
        _camera_ui_scrims.append(scrim)

func choose_affinity(index: int) -> bool:
    if index < 0 or index >= Catalog.CHARACTER_ORDER.size():
        return false
    active_index = index
    phase_index = 1
    var identity: String = Catalog.CHARACTER_ORDER[active_index]
    if not effect.play_affinity(identity, reduced_motion):
        return false
    effect.seek_visual_phase(KEYFRAMES[phase_index])
    light_rig.configure(identity, KEYFRAMES[phase_index], reduced_motion)
    light_rig.set_light_enabled(lighting_enabled and magic_visible)
    effect.visible = magic_visible
    return true

func seek_phase(index: int) -> bool:
    if index < 0 or index >= KEYFRAMES.size():
        return false
    phase_index = index
    if not effect.seek_visual_phase(KEYFRAMES[index]):
        return false
    light_rig.configure(Catalog.CHARACTER_ORDER[active_index], KEYFRAMES[index], reduced_motion)
    return true

func set_magic_visible(enabled: bool) -> void:
    magic_visible = enabled
    effect.visible = enabled
    light_rig.set_light_enabled(enabled and lighting_enabled)

func set_lighting_enabled(enabled: bool) -> void:
    lighting_enabled = enabled
    light_rig.set_light_enabled(enabled and magic_visible)

func set_front_composite(enabled: bool) -> void:
    front_composite = enabled
    # Deliberate A/B z-index test. Actor and effect world positions remain fixed.
    effect.z_index = 1 if enabled else -1

func set_lighting_preset(next_preset: String) -> bool:
    if not LIGHT_PROFILES.has(next_preset):
        return false
    lighting_preset = next_preset
    ambient.color = LIGHT_PROFILES[next_preset]
    return true

func set_weather_preset(next_preset: String) -> bool:
    if not atmosphere.set_weather(next_preset):
        return false
    weather_preset = next_preset
    return true

func set_camera_closeup(enabled: bool) -> void:
    closeup_enabled = enabled
    for scrim in _camera_ui_scrims:
        scrim.visible = enabled
    camera.position = world.ender.global_position + CLOSEUP_OFFSET if enabled else DEFAULT_CAMERA
    camera.zoom = Vector2(1.16, 1.16) if enabled else Vector2.ONE

func set_reduced_motion(enabled: bool) -> void:
    reduced_motion = enabled
    atmosphere.set_reduced_motion(enabled)
    choose_affinity(active_index)

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode >= KEY_1 and event.keycode <= KEY_5:
        choose_affinity(event.keycode - KEY_1)
    elif event.keycode == KEY_LEFT:
        seek_phase(maxi(phase_index - 1, 0))
    elif event.keycode == KEY_RIGHT:
        seek_phase(mini(phase_index + 1, KEYFRAMES.size() - 1))
    elif event.keycode == KEY_O:
        set_front_composite(not front_composite)
    elif event.keycode == KEY_L:
        set_lighting_enabled(not lighting_enabled)
    elif event.keycode == KEY_C:
        set_camera_closeup(not closeup_enabled)
    elif event.keycode == KEY_M:
        set_reduced_motion(not reduced_motion)
    elif event.keycode == KEY_V:
        set_magic_visible(not magic_visible)
    elif event.keycode == KEY_T:
        var profiles := ["daylight", "dusk", "night"]
        set_lighting_preset(profiles[(profiles.find(lighting_preset) + 1) % profiles.size()])
    elif event.keycode == KEY_W:
        var weather_modes := ["clear", "mist", "rain"]
        set_weather_preset(weather_modes[(weather_modes.find(weather_preset) + 1) % weather_modes.size()])
    elif event.keycode == KEY_ESCAPE:
        get_tree().quit()
