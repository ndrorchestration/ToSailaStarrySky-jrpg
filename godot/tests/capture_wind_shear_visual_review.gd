extends SceneTree
## Original Wind Shear pixel-art presentation review: four true Godot 960x640
## framebuffer captures. Three secondary poses are previewed by setting only
## the visual presentation state; this does not simulate a gameplay outcome.
##
## Noncanonical art study / no screenshot equals creator acceptance.

const REVIEW_SCENE = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")
const OUTPUT_ENV := "STARRY_SKY_ENEMY_CAPTURE_DIR"
const DEFAULT_OUTPUT := "res://review-evidence/wind-shear/"

var _output_dir: String = ""
var _frames: Array[Image] = []

class Sequence:
    extends RefCounted
    var values: Array
    var index: int = 0

    func _init(next_values: Array) -> void:
        values = next_values.duplicate()

    func next():
        if index >= values.size():
            return 0.5
        var value = values[index]
        index += 1
        return value

func _initialize() -> void:
    var requested := OS.get_environment(OUTPUT_ENV).strip_edges()
    _output_dir = (
        ProjectSettings.globalize_path(DEFAULT_OUTPUT)
        if requested.is_empty()
        else requested
    )
    _output_dir = _output_dir.replace("\\", "/").trim_suffix("/")
    call_deferred("_capture")

func _snapshot(name: String) -> bool:
    await RenderingServer.frame_post_draw
    var picture: Image = root.get_texture().get_image()
    if picture.is_empty() or picture.get_size() != Vector2i(960, 640):
        push_error("WIND_SHEAR_CAPTURE_FAIL: expected real native 960x640 viewport")
        return false
    var destination := _output_dir.path_join(name + ".png")
    if picture.save_png(destination) != OK:
        push_error("WIND_SHEAR_CAPTURE_FAIL: could not write " + destination)
        return false
    _frames.append(picture)
    print("WIND_SHEAR_NATIVE_FRAME:" + name + ":" + FileAccess.get_sha256(destination))
    return true

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(_output_dir) != OK:
        _fail("capture directory not writable")
        return

    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame
    world.ender.set_physics_process(false)
    for actor in world.contacts.values():
        actor.set_physics_process(false)
    for signal_id in ["harmonic_buoy", "below_frequency", "sky_lane_warning"]:
        if not world.complete_signal_contact(signal_id):
            _fail("could not enter current Crossing")
            return
    # Deterministic review-input only; formula authority and damage math remain
    # unchanged. It avoids a random critical result obscuring the hit pose.
    var strike_rng := Sequence.new([0.5, 0.99, 0.5, 0.99])
    world.formula_encounter = Encounter.new(strike_rng.next)
    if not world.start_hazard_encounter("wind_shear"):
        _fail("the current-story Wind Shear encounter did not open")
        return
    var art = world.wind_shear_visual
    if art == null or not art.visible or art.atlas_texture == null:
        _fail("pixel atlas missing from live encounter")
        return
    art.set_reduced_motion(true)
    await process_frame
    if not (await _snapshot("wind-shear-idle-native-960x640")):
        _fail("idle capture")
        return

    # Uncover Truth is a real, authorized combat action.
    if not world.take_formula_review_action("uncoverTruth"):
        _fail("Uncover Truth did not resolve")
        return
    # Freeze the short post-action accent for a distinct analyzed core pose.
    art.set_reduced_motion(true)
    await process_frame
    if not art.analyzed:
        _fail("visual analyzed state not updated")
        return
    if not (await _snapshot("wind-shear-analyzed-native-960x640")):
        _fail("analyzed capture")
        return

    # A real, authorized Staff Strike provides the *post-resolution* hit frame.
    var hp_before_strike: int = int(world.formula_encounter.target.get("hp", 0))
    if not world.take_formula_review_action("staffStrike"):
        _fail("authorized Staff Strike could not resolve")
        return
    if world.formula_encounter.completed or int(world.formula_encounter.target.get("hp", 0)) >= hp_before_strike:
        _fail("review strike was expected to be a nonlethal confirmed hit")
        return
    if art.hit_feedback_seconds <= 0.0:
        _fail("actual HP loss was not reflected in pixel hit state")
        return
    # The same real action also caused Gale Force. Isolate the new hit accent
    # in this screenshot; this direct art-state edit changes NO combat fields.
    art.gale_accent_seconds = 0.0
    art.queue_redraw()
    await process_frame
    if not (await _snapshot("wind-shear-hit-native-960x640")):
        _fail("post-resolution hit capture")
        return

    # Review-only visual state, NOT an extra enemy turn or gameplay mutation.
    art.set_reduced_motion(false)
    art.hit_feedback_seconds = 0.0
    art.set_encounter_state(true, false, art.last_enemy_turn + 1)
    await process_frame
    if not (await _snapshot("wind-shear-gale-native-960x640")):
        _fail("Gale Force art capture")
        return

    # Review-only dissipated pose, NOT a credited victory.
    art.set_encounter_state(true, true, art.last_enemy_turn)
    await process_frame
    if not (await _snapshot("wind-shear-dispersed-native-960x640")):
        _fail("dissipated art capture")
        return

    if _frames.size() != 5:
        _fail("five native captures missing")
        return
    var target := Rect2i(588, 185, 196, 192)
    for i in range(4):
        if _frames[i].get_region(target).get_data() == _frames[i + 1].get_region(target).get_data():
            _fail("adjacent combat-art states visually identical: " + str(i))
            return
    if "wind_shear" in world.chapter.completed_hazards:
        _fail("visual-only pose review mutated story progression")
        return
    world.queue_free()
    await process_frame
    print("WIND_SHEAR_NATIVE_RENDER_PASS: five distinct 960x640 state captures, including observed hit; creator acceptance pending")
    quit(0)

func _fail(reason: String) -> void:
    push_error("WIND_SHEAR_CAPTURE_FAIL: " + reason)
    quit(1)
