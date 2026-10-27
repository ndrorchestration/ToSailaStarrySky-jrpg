extends SceneTree
## Exact real Godot viewport evidence from actual Chapter I combat UI.
## Never uploads draft art to public artifacts or grants art approval.
const REVIEW_SCENE = preload("res://scenes/first_wake_chapter1_review.tscn")
const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")
const OUTPUT := "res://review-evidence"
var observed_hashes: Array[String] = []

class FixedRng:
    extends RefCounted
    func next() -> float:
        return 0.5

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960,640)
    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame
    if world.weapon_visual == null:
        _fail("missing integrated staff preview")
        return
    var rng = FixedRng.new()
    world.formula_encounter = Encounter.new(rng.next)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("cannot create runner capture directory")
        return
    var chapter_before: Dictionary = world.chapter.snapshot()
    if not world.start_formula_review():
        _fail("formula encounter start failed")
        return
    if not await _frame("staff-battle-idle"):
        return
    if not world.take_formula_review_action("staffStrike"):
        _fail("strike did not resolve")
        return
    world._process(0.77)
    if not await _frame("staff-battle-impact"):
        return
    world.set_weapon_visual_reduced_motion(true)
    if not await _frame("staff-battle-reduced"):
        return
    if not world.close_formula_review():
        _fail("could not close review")
        return
    if world.chapter.snapshot() != chapter_before or world.weapon_visual.visible:
        _fail("visual effects leaked into chapter progress")
        return
    if not await _frame("staff-battle-closed"):
        return

    for signal_id in ["harmonic_buoy","below_frequency","sky_lane_warning"]:
        if not world.complete_signal_contact(signal_id):
            _fail("could not reach Crossing")
            return
    world.formula_encounter = Encounter.new(rng.next)
    if not world.start_hazard_encounter("wind_shear"):
        _fail("could not start admitted Wind Shear battle")
        return
    if not await _frame("staff-wind-shear-idle"):
        return
    if not world.take_formula_review_action("staffStrike"):
        _fail("Wind Shear strike failed")
        return
    world._process(0.77)
    if not await _frame("staff-wind-shear-impact"):
        return

    if observed_hashes.size() != 6 \
        or observed_hashes[0] == observed_hashes[1] \
        or observed_hashes[1] == observed_hashes[2] \
        or observed_hashes[2] == observed_hashes[3] \
        or observed_hashes[4] == observed_hashes[5]:
        _fail("authentic battle comparison frames were not distinct")
        return
    world.queue_free()
    print("FIRST_WAKE_EQUIPPED_STAFF_RENDER_PASS: six distinct authentic 960x640 Godot viewport frames")
    print("FIRST_WAKE_EQUIPPED_STAFF_ARTISTIC_ACCEPTANCE=NOT_ESTABLISHED")
    quit(0)

func _frame(label: String) -> bool:
    await RenderingServer.frame_post_draw
    var screenshot: Image = root.get_texture().get_image()
    if screenshot.is_empty() or screenshot.get_width() != 960 or screenshot.get_height() != 640:
        _fail("native viewport dimensions invalid: "+label)
        return false
    var file := OUTPUT+"/"+label+"-native-960x640.png"
    if screenshot.save_png(file) != OK:
        _fail("PNG save failed: "+label)
        return false
    var digest := FileAccess.get_sha256(file)
    observed_hashes.append(digest)
    print("FIRST_WAKE_EQUIPPED_STAFF_SHA256 "+label+" "+digest)
    return true

func _fail(reason: String) -> void:
    push_error("FIRST_WAKE_EQUIPPED_STAFF_RENDER_FAIL: "+reason)
    quit(1)
