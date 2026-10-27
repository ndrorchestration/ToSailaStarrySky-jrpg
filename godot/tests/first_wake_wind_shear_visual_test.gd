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
    if WindShearVisual.ART_BOUNDS != Rect2(-91.0, -92.0, 182.0, 184.0):
        _fail("review-stage bounds drifted without layout review")
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
    if world.chapter.snapshot() != before:
        _fail("enemy art/combat animation mutated Chapter I progression")
        return

    # Scene-wide settings can hold a completely stable silhouette in
    # reduced-motion mode; no amber Gale Force flash survives the toggle.
    art.set_reduced_motion(true)
    if art.gale_accent_seconds != 0.0 or art.visual_clock != 0.0:
        _fail("reduced-motion mode did not remove ambient/retaliation motion")
        return
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
