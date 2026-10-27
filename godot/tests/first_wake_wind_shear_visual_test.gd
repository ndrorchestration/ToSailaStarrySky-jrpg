extends SceneTree
## Presentation identity/regression contract for original provisional Wind Shear art.
## Tests real native Chapter I scene behavior; no final sprite/art acceptance.

const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")
const REVIEW_SCENE = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const WindShearVisual = preload("res://scripts/first_wake_wind_shear_visual.gd")

class Sequence:
    extends RefCounted
    var values: Array
    var index: int = 0

    func _init(next_values: Array) -> void:
        values = next_values.duplicate()

    func next():
        if index >= values.size():
            return 0.5
        var result = values[index]
        index += 1
        return result

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame

    var art = world.wind_shear_visual
    if art == null or art.name != "HarmonicShearElementalVisualStudy":
        _fail("current enemy visual not attached to live native scene")
        return
    if art.visible:
        _fail("enemy art visible during exploration")
        return
    if WindShearVisual.ART_ID != "windShear":
        _fail("art identity no longer matches admitted current enemy")
        return
    if WindShearVisual.FRAME_SIZE != Vector2i(80, 92) or WindShearVisual.FRAME_COUNT != 4:
        _fail("pixel atlas grid contract drifted")
        return
    if art.atlas_texture == null:
        _fail("authored provisional enemy pixel atlas missing or not importable")
        return
    if art.atlas_texture.get_size() != Vector2(320, 92):
        _fail("native imported atlas has incorrect frame dimensions")
        return
    if art.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
        _fail("enemy sprite atlas is not rendered with nearest pixel filtering")
        return
    if WindShearVisual.ART_BOUNDS != Rect2(-91.0, -92.0, 182.0, 184.0):
        _fail("review-stage bounds drifted without layout review")
        return
    if WindShearVisual.DISPLAY_SCALE != 2.0:
        _fail("enemy atlas must use exact integer-pixel 2x sampling")
        return
    # Test all authored idle fracture phases without advancing encounter time.
    var expected_offsets := [
        PackedInt32Array([0, 0, 0]),
        PackedInt32Array([0, 2, -2]),
        PackedInt32Array([-2, 0, 2]),
        PackedInt32Array([2, -2, 0]),
        PackedInt32Array([0, 0, 0]),
    ]
    for i in range(expected_offsets.size()):
        art.visual_clock = float(i) * WindShearVisual.IDLE_POSE_STEP_SECONDS + 0.01
        if art.idle_band_offsets() != expected_offsets[i]:
            _fail("authored idle-shear pose %d drifted" % i)
            return
    art.set_reduced_motion(true)
    art.visual_clock = 0.73
    if art.idle_band_offsets() != PackedInt32Array([0, 0, 0]):
        _fail("reduced motion did not freeze procedural in-between offsets")
        return
    art.set_reduced_motion(false)
    art.begin_encounter()
    if art.idle_band_offsets() != PackedInt32Array([0, 0, 0]):
        _fail("fresh encounters retained idle fracture state")
        return

    # The synthetic, explicitly noncanonical formula target has no authority to
    # display this character's art even if the formula controller is active.
    var synthetic_rng := Sequence.new([0.5, 0.99])
    world.formula_encounter = Encounter.new(synthetic_rng.next)
    if not world.start_formula_review() or art.visible:
        _fail("formula review incorrectly displayed the current-story enemy")
        return
    if not world.close_formula_review() or art.visible:
        _fail("formula review cleanup did not hide the visual")
        return

    for signal_id in ["harmonic_buoy", "below_frequency", "sky_lane_warning"]:
        if not world.complete_signal_contact(signal_id):
            _fail("could not enter the current Crossing state")
            return
    if world.chapter.stage_key() != "crossing":
        _fail("not in Crossing")
        return

    var before: Dictionary = world.chapter.snapshot()
    var rng := Sequence.new([
        0.5, 0.99, 0.5, 0.99, 0.5, 0.99, 0.5, 0.99
    ])
    world.formula_encounter = Encounter.new(rng.next)
    if not world.start_hazard_encounter("wind_shear"):
        _fail("current-story Wind Shear did not open")
        return
    if not art.visible or art.analyzed or art.dissipated:
        _fail("opening presentation state incorrect")
        return
    if not world.take_formula_review_action("uncoverTruth"):
        _fail("real encounter could not analyze harmonic weakness")
        return
    if not art.analyzed or art.last_enemy_turn != 1:
        _fail("analyzed/retaliation appearance not bound to real combat state")
        return
    if art.hit_feedback_seconds != 0.0:
        _fail("analysis or enemy retaliation fabricated a player hit")
        return
    if art.register_resolved_damage(14, 14):
        _fail("unchanged enemy HP must not trigger hit confirmation")
        return
    if art.register_resolved_damage(-1, 0):
        _fail("invalid enemy HP must not trigger hit confirmation")
        return

    # Authorized player attack: the scene observes actual damage *after*
    # the combat controller resolves it, not from the command selection.
    var enemy_before_strike: int = int(world.formula_encounter.target.get("hp", 0))
    if not world.take_formula_review_action("staffStrike"):
        _fail("authorized Staff Strike rejected")
        return
    var enemy_after_strike: int = int(world.formula_encounter.target.get("hp", 0))
    if enemy_after_strike >= enemy_before_strike or world.formula_encounter.completed:
        _fail("deterministic review strike was expected to deal nonlethal damage")
        return
    if art.hit_feedback_seconds <= 0.0:
        _fail("confirmed enemy HP loss did not trigger brief hit feedback")
        return
    if art.idle_band_offsets() != PackedInt32Array([0, 0, 0]):
        _fail("impact feedback must suppress idle pose shearing")
        return

    var reaction_duration: float = art.hit_feedback_seconds
    for _frame in range(6):
        art._process(0.05)
    if art.hit_feedback_seconds != 0.0 or reaction_duration <= 0.0:
        _fail("post-hit accent did not decay to zero")
        return
    if world.chapter.snapshot() != before:
        _fail("enemy art/combat animation mutated Chapter I progression")
        return

    # Scene-wide settings can hold a completely stable silhouette in
    # reduced-motion mode; no amber Gale Force flash survives the toggle.
    art.set_reduced_motion(true)
    if art.gale_accent_seconds != 0.0 or art.visual_clock != 0.0 or art.hit_feedback_seconds != 0.0:
        _fail("reduced-motion mode did not remove ambient/retaliation motion")
        return
    art.visual_clock = 0.5
    if art.idle_band_offsets() != PackedInt32Array([0, 0, 0]):
        _fail("reduced motion allowed shear offsets at nonzero sampled clock")
        return
    art.visual_clock = 0.0
    art._process(0.4)
    if art.visual_clock != 0.0:
        _fail("ambient motion advanced despite reduced-motion mode")
        return

    if not world.close_formula_review() or art.visible:
        _fail("cancel did not hide visual")
        return
    if world.chapter.snapshot() != before:
        _fail("cancel credited Wind Shear without completing the encounter")
        return

    world.queue_free()
    await process_frame
    print("STARRY_SKY_WIND_SHEAR_ART_CONTRACT_PASS: authored identity, gameplay isolation, analyzed/retaliation presentation, reduced motion, cancel cleanup")
    quit(0)

func _fail(reason: String) -> void:
    push_error("STARRY_SKY_WIND_SHEAR_ART_CONTRACT_FAIL: " + reason)
    quit(1)
