extends Node2D
## Isolated 2D composition test for spell light, foreground ordering and shadows.
## This is not a 3D occlusion, volumetric scattering, spell-cast or battle scene.
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const MagicVFX = preload("res://scripts/magic_vfx.gd")
const LightRig = preload("res://scripts/magic_vfx_environment_light.gd")
const Foreground = preload("res://scripts/magic_vfx_environment_front.gd")

const SPELL_CENTER = Vector2(425.0, 307.0)
const KEYFRAME_POSITIONS = [0.08, 0.29, 0.49, 0.67, 0.89]

var active_index: int = 0
var phase_index: int = 1
var reduced_motion: bool = true
var lighting_enabled: bool = true
var foreground_enabled: bool = true
var effect: Node2D
var light_rig: Node2D
var foreground: Node2D

func _ready() -> void:
    # The backdrop is drawn on the root. Children receive real CanvasItem light.
    var architecture := Node2D.new()
    architecture.name = "LitArchitecture"
    architecture.set_script(load("res://scripts/magic_vfx_environment_stage.gd"))
    add_child(architecture)
    light_rig = LightRig.new()
    light_rig.name = "AffinityLightRig"
    light_rig.position = SPELL_CENTER
    add_child(light_rig)
    effect = MagicVFX.new()
    effect.name = "MagicVFX"
    effect.position = SPELL_CENTER
    add_child(effect)
    foreground = Foreground.new()
    foreground.name = "OccludingStoneColumn"
    foreground.position = Vector2(548.0, 222.0)
    add_child(foreground)
    choose_affinity(active_index)

func choose_affinity(index: int) -> bool:
    if index < 0 or index >= Catalog.CHARACTER_ORDER.size():
        return false
    active_index = index
    phase_index = 1
    var identity: String = Catalog.CHARACTER_ORDER[index]
    effect.play_affinity(identity, reduced_motion)
    effect.seek_visual_phase(KEYFRAME_POSITIONS[phase_index])
    light_rig.configure(identity, KEYFRAME_POSITIONS[phase_index], reduced_motion)
    queue_redraw()
    return true

func seek_phase(index: int) -> bool:
    if index < 0 or index >= KEYFRAME_POSITIONS.size():
        return false
    phase_index = index
    if not effect.seek_visual_phase(KEYFRAME_POSITIONS[index]):
        return false
    light_rig.configure(Catalog.CHARACTER_ORDER[active_index], KEYFRAME_POSITIONS[index], reduced_motion)
    queue_redraw()
    return true

func set_light_enabled(enabled: bool) -> void:
    lighting_enabled = enabled
    light_rig.set_light_enabled(enabled)

func set_foreground_enabled(enabled: bool) -> void:
    foreground_enabled = enabled
    foreground.visible = enabled

func set_reduced_motion(enabled: bool) -> void:
    reduced_motion = enabled
    choose_affinity(active_index)

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode >= KEY_1 and event.keycode <= KEY_5:
        choose_affinity(event.keycode - KEY_1)
    elif event.keycode == KEY_LEFT:
        seek_phase(maxi(phase_index - 1, 0))
    elif event.keycode == KEY_RIGHT:
        seek_phase(mini(phase_index + 1, KEYFRAME_POSITIONS.size() - 1))
    elif event.keycode == KEY_L:
        set_light_enabled(not lighting_enabled)
    elif event.keycode == KEY_O:
        set_foreground_enabled(not foreground_enabled)
    elif event.keycode == KEY_M:
        set_reduced_motion(not reduced_motion)
    elif event.keycode == KEY_ESCAPE:
        get_tree().quit()

func _draw() -> void:
    var font := ThemeDB.fallback_font
    var profile: Dictionary = Catalog.profile(Catalog.CHARACTER_ORDER[active_index])
    draw_string(font, Vector2(38.0, 40.0), "TO SAIL THE STARRY SKY / ENVIRONMENT MAGIC LIGHT STUDY", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#ebeadc"))
    draw_string(font, Vector2(40.0, 76.0), str(profile["character"]).to_upper() + " / " + str(profile["affinity"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(str(profile["color"])))
    draw_string(font, Vector2(40.0, 571.0), "1-5 Affinity    LEFT/RIGHT Cinematic phase    L Lighting    O Occlusion", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d8dce0"))
    draw_string(font, Vector2(40.0, 605.0), "M Reduced motion (ON by default)    ESC Exit    [REVIEW ONLY]", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c5d1d4"))
