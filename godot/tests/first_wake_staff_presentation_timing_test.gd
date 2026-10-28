extends SceneTree
## Proves contact-synchronized *display* while the real First Wake action
## resolves immediately. Presentation is a read-only projection, never a turn.
const SaveCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")
const Queue = preload("res://scripts/first_wake_staff_presentation_queue.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/first_wake_staff_signal_pilot_review.tscn")
    if scene == null:
        _fail("opt-in First Wake pilot unavailable")
        return
    var wrapper = scene.instantiate()
    get_root().add_child(wrapper)
    await process_frame
    var world: Node2D = wrapper.chapter_scene
    var presenter: Node2D = wrapper.presenter
    var hud: Control = wrapper.presentation_hud
    if world == null or presenter == null or hud == null \
        or not bool(hud.visual_contract()["noninteractive"]) \
        or not presenter.presentation_projection().is_empty():
        _fail("opt-in presentational layer installed incorrectly")
        return
    var chapter_before: Dictionary = world.chapter.snapshot()
    var saved_before: Dictionary = SaveCodec.encode(
        world.chapter,{"hull_integrity":100,"morale":50,"engine_integration":0},
        world.ender.position)
    if not world.start_formula_review():
        _fail("real Chapter I formula encounter failed to start")
        return
    if world.take_formula_review_action("sharedDream") \
        or presenter.presentation_queue.active:
        _fail("blocked action started a presentation")
        return
    var before: Dictionary = world.formula_encounter.snapshot()
    if not world.take_formula_review_action("staffStrike"):
        _fail("genuine staff action rejected")
        return
    var after: Dictionary = world.formula_encounter.snapshot()
    var duration: float = presenter.observer.bridge.timeline.duration(
        "full_length_staff","attack")
    var p: Dictionary = presenter.presentation_projection()
    if p.is_empty() or str(p["phase"]) != "pending" \
        or int(p["targetHp"]) != int(before["target"]["hp"]) \
        or int(p["staffCharges"]) != int(before["player"]["staffCharges"]) \
        or bool(p["damageNumberVisible"]):
        _fail("pending strike failed to display pre-action values")
        return
    if int(after["target"]["hp"]) >= int(before["target"]["hp"]) \
        or int(after["player"]["staffCharges"]) != int(before["player"]["staffCharges"])-1 \
        or int(after["turns"])-int(before["turns"]) != 1:
        _fail("authority failed to resolve immediately")
        return
    if not presenter.seek_review_seconds(duration*0.68) \
        or str(presenter.presentation_projection()["phase"]) != "pending":
        _fail("damage revealed before keyed contact")
        return
    if not presenter.seek_review_seconds(duration*0.695):
        _fail("contact seek refused")
        return
    p=presenter.presentation_projection()
    if str(p["phase"]) != "revealed" \
        or int(p["targetHp"]) != int(after["target"]["hp"]) \
        or int(p["staffCharges"]) != int(after["player"]["staffCharges"]) \
        or int(p["formulaDamage"]) != int(before["target"]["hp"])-int(after["target"]["hp"]) \
        or not bool(p["damageNumberVisible"]):
        _fail("contact did not reveal already-authoritative result")
        return
    if presenter.presentation_queue.revealed_count != 1 \
        or not presenter.seek_review_seconds(duration*0.25) \
        or str(presenter.presentation_projection()["phase"]) != "revealed":
        _fail("committed reveal rolled backward or appeared twice")
        return
    await process_frame
    if str(hud.visual_contract()["phase"]) != "revealed" \
        or int(hud.visual_contract()["targetHpDisplayed"]) != int(after["target"]["hp"]) \
        or not bool(hud.visual_contract()["noninteractive"]):
        _fail("real HUD overlay did not track resolved contact projection")
        return

    var snapshot_after_first: Dictionary = world.formula_encounter.snapshot()
    if not world.take_formula_review_action("hold") \
        or presenter.presentation_queue.active \
        or not presenter.presentation_projection().is_empty():
        _fail("new legitimate nonstaff turn did not flush pending presentation")
        return
    var after_hold: Dictionary = world.formula_encounter.snapshot()
    if int(after_hold["turns"])-int(snapshot_after_first["turns"]) != 1:
        _fail("visual queue interrupted host combat command")
        return
    presenter.set_reduced_motion(true)
    var before_second: Dictionary = world.formula_encounter.snapshot()
    if not world.take_formula_review_action("staffStrike"):
        _fail("reduced-motion genuine staff action rejected")
        return
    var after_second: Dictionary = world.formula_encounter.snapshot()
    var reduced: Dictionary = presenter.presentation_projection()
    if str(reduced.get("phase","")) != "revealed" \
        or int(reduced.get("targetHp",-1)) != int(after_second["target"]["hp"]) \
        or not bool(reduced.get("motionReduced",false)) \
        or float(presenter.visual_contract()["visualContactStrength"]) != 0.0:
        _fail("reduced motion delayed outcome or left a contact flash")
        return
    if int(after_second["turns"])-int(before_second["turns"]) != 1 \
        or presenter.accepted_visual_count != 2 \
        or presenter.presentation_queue.revealed_count != 2:
        _fail("second real turn/visual was not counted exactly once")
        return
    if world.formula_encounter.snapshot() != after_second \
        or world.chapter.snapshot() != chapter_before \
        or SaveCodec.encode(world.chapter,
            {"hull_integrity":100,"morale":50,"engine_integration":0},
            world.ender.position) != saved_before:
        _fail("presentation projection changed formula, story or save")
        return
    presenter.set_pilot_enabled(false)
    await process_frame
    if not presenter.presentation_projection().is_empty() \
        or hud.visible or presenter.presentation_queue.active:
        _fail("disabling projection did not reveal actual HUD")
        return
    if not world.close_formula_review():
        _fail("actual encounter could not close")
        return
    wrapper.queue_free()
    await process_frame
    print("FIRST_WAKE_TIMED_HUD_PASS: real formula immediate, one-time display at contact, reduced immediate, interrupts safe, no save")
    quit(0)

func _fail(reason: String) -> void:
    push_error("FIRST_WAKE_TIMED_HUD_FAIL: "+reason)
    quit(1)
