extends SceneTree
## Contract between the actual Ionia-first Chapter I scene and a neutral
## optional 3D presentation sink. No game flight/ship asset ever instantiated.
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
const Sink = preload("res://tests/first_wake_ship_pose_test_sink.gd")
const Port = preload("res://scripts/first_wake_ship_visual_pose_port.gd")
const Timeline = preload("res://scripts/ship_visual_pose_timeline.gd")

var failures: Array[String] = []
var checks: int = 0

func check(ok: bool, label_text: String) -> void:
    checks += 1
    if not ok:
        failures.append(label_text)

func finish_dialogue(world: Node) -> bool:
    for i in range(20):
        if not world.dialogue_open:
            return true
        if not world.interact():
            return false
    return false

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = Preview.instantiate()
    root.add_child(world)
    await process_frame
    var sink: Node3D = Sink.new()
    sink.name = "NeutralPresentationSinkReviewOnly"
    root.add_child(sink)
    var port = world.ship_pose_port as Port

    check(port != null, "actual Chapter I scene owns opt-in pose port")
    var authority: Dictionary = port.source_contract()
    check(authority["source_pr"] == 490 and
        authority["source_head"] == Port.SOURCE_HEAD and
        str(authority["source_head"]).length() == 40,
        "exact-source pure-GDScript wing timeline identified")
    check(Timeline.new() != null and authority["review_only"] and
        not authority["has_runtime_input"] and
        not authority["includes_3d_ship_assets"],
        "adapter uses no player action and imports no ship renderer")
    check(not world._ship_spaces_requested and
        not world.ship_spaces_handoff.visible,
        "no review capability exposed on ordinary scene boot")
    check(not world.request_ship_pose_review(sink, Port.CUE_GENTLE_SWEEP),
        "no presentation request during job search")
    check(not world.advance_ship_pose_review(sink, 0.9, false),
        "cannot advance an unadmitted pose before hiring")
    check(is_zero_approx(sink.current_fraction) and sink.updates == 0,
        "early request never mutates renderer")
    var before_story: Dictionary = world.opening.snapshot()
    var before_save: Dictionary = world.export_revised_checkpoint()
    check(world.opening.active_party_ids == ["ender"] and
        world.opening.snapshot() == before_story and
        world.export_revised_checkpoint() == before_save,
        "early adapter cannot create Ionia or change save/progression")

    world.ender.position = world.FLYER_POSITION
    check(world.interact() and finish_dialogue(world) and world.flyer_read,
        "the real Chapter I flyer is read first")
    world.ender.position = world.IONIA_DOCK_POSITION
    check(world.interact() and finish_dialogue(world) and
        world.opening.active_party_ids == ["ender", "ionia"],
        "the real Ionia hiring sequence runs before boarding")
    check(not world.request_ship_pose_review(sink, Port.CUE_GENTLE_SWEEP),
        "hiring alone does not grant visual review")
    world.ender.position = world.GANGWAY_POSITION
    check(world.interact() and world.room == "engineering",
        "real gangway admits legitimate engineering scene")
    check(not world.request_ship_pose_review(sink, Port.CUE_GENTLE_SWEEP),
        "boarded scene remains opt-out by default")
    check(world.set_ship_spaces_review_enabled(true),
        "existing ship-space review explicit test opt-in opens")
    var story: Dictionary = world.opening.snapshot()
    var checkpoint: Dictionary = world.export_revised_checkpoint()
    var position: Vector2 = world.ender.position
    var bounds: Rect2 = world.ender.walking_bounds
    var objective: String = world.objective.text
    var last_message: String = world.last_message
    var children: int = world.get_child_count()
    check(not world.request_ship_pose_review(null, Port.CUE_GENTLE_SWEEP),
        "no renderer yields fail-closed cue rejection")
    check(not world.request_ship_pose_review(sink, "unsupported"),
        "unknown appearance token rejected")
    check(sink.updates == 0, "invalid request does not touch renderer")

    check(world.request_ship_pose_review(sink, Port.CUE_GENTLE_SWEEP),
        "real scene can issue ordinary appearance-only pose cue")
    check(world.advance_ship_pose_review(sink, 0.9, false),
        "renderer sink receives 1.8-second midpoint")
    check(is_equal_approx(sink.current_fraction, 0.5),
        "source-pinned timeline halfway pose delivered")
    check(world.request_ship_pose_review(sink, Port.CUE_NEUTRAL),
        "neutral request interrupts current pose")
    check(world.advance_ship_pose_review(sink, 0.45, false),
        "reverse starts from current renderer pose")
    check(sink.current_fraction > 0.0 and sink.current_fraction < 0.5,
        "reversed pose is continuous")
    var prior: float = sink.current_fraction
    check(not world.advance_ship_pose_review(sink, NAN, false),
        "nonfinite frame time rejected")
    check(is_equal_approx(sink.current_fraction, prior),
        "bad timestamp never advances sink")
    check(world.request_ship_pose_review(sink, Port.CUE_GENTLE_SWEEP),
        "new ordinary pose request accepted")
    check(world.advance_ship_pose_review(sink, 0.0, true),
        "reduced motion stabilizes immediately")
    check(is_equal_approx(sink.current_fraction, 1.0),
        "M-equivalent reduced-motion path produces stable target")

    check(world.opening.snapshot() == story and
        world.export_revised_checkpoint() == checkpoint,
        "render-only cue preserves chapter state and checkpoint bytes")
    check(world.ender.position == position and
        world.ender.walking_bounds == bounds and
        world.objective.text == objective and
        world.last_message == last_message and
        world.get_child_count() == children,
        "no actor/scene/quest/overlay node authority changes")
    check(world.resonance_status_label.text.contains("LOCKED"),
        "presentation cannot unlock party resonance")
    check(not world.set_ship_spaces_review_enabled(false) and
        not world.ship_spaces_handoff.visible,
        "opt-out closes ship-space preview")
    check(not world.advance_ship_pose_review(sink, 0.6, false),
        "revoked opt-in prevents advancing a previously accepted cue")
    check(world.clear_ship_pose_review(sink) and
        is_zero_approx(sink.current_fraction),
        "transient sink can return safely to neutral after opt-out")
    check(world.set_ship_spaces_review_enabled(true),
        "review can be re-enabled for restore test")
    check(world.restore_revised_checkpoint(checkpoint),
        "real v2 checkpoint restores unchanged source state")
    check(not world._ship_spaces_requested and
        not world.ship_spaces_handoff.visible and
        not world.request_ship_pose_review(sink, Port.CUE_GENTLE_SWEEP),
        "restore discards review authorization, cannot re-trigger cue")
    check(world.opening.snapshot() == story and
        world.export_revised_checkpoint() == checkpoint,
        "restore reproduces exact original story/checkpoint")

    world.queue_free()
    sink.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_SHIP_POSE_PORT_PASS checks=", checks,
            " scene=REAL_NATIVE render=TEST_SINK_ONLY production=HOLD")
        quit(0)
    else:
        for failure in failures:
            push_error("FIRST_WAKE_SHIP_POSE_PORT_FAIL: " + failure)
        quit(1)
