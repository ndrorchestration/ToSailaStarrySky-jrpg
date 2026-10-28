extends SceneTree
## Actual Chapter I action signal: emitted only after successful formula turn,
## feeds opt-in presenter, cannot execute a second turn or write a save.
const SaveCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")
const Presenter = preload("res://scripts/first_wake_staff_signal_visual_presenter.gd")
var events: Array[Dictionary] = []

func _initialize() -> void:
    call_deferred("_run")

func _record(event: Dictionary) -> void:
    events.append(event.duplicate(true))

func _run() -> void:
    var packed: PackedScene = load("res://scenes/first_wake_staff_signal_pilot_review.tscn")
    if packed == null:
        _fail("optional real First Wake pilot scene not imported")
        return
    var wrapper = packed.instantiate()
    get_root().add_child(wrapper)
    await process_frame
    var world: Node2D = wrapper.chapter_scene
    var presenter: Node2D = wrapper.presenter
    if world == null or presenter == null or not presenter.visual_contract()["attached"] \
        or world.formula_visual_event_serial != 0 or presenter.accepted_visual_count != 0:
        _fail("default controller/presenter has unexpected state")
        return
    world.formula_action_resolved.connect(_record)
    var chapter_before: Dictionary = world.chapter.snapshot()
    var saved_before: Dictionary = SaveCodec.encode(
        world.chapter,{"hull_integrity":100,"morale":50,"engine_integration":0},
        world.ender.position)
    if not world.start_formula_review():
        _fail("real Chapter I formula review cannot start")
        return
    if world.take_formula_review_action("sharedDream") or events.size()!=0:
        _fail("blocked ability emitted action result")
        return
    if not world.take_formula_review_action("uncoverTruth") or events.size()!=1 \
        or world.formula_visual_event_serial != 1:
        _fail("accepted non-staff formula action did not produce one result")
        return
    if presenter.accepted_visual_count != 0 or presenter.visible \
        or presenter.ignored_nonstaff_count != 1:
        _fail("non-staff action erroneously played staff rig")
        return
    var before: Dictionary = world.formula_encounter.snapshot()
    if not world.take_formula_review_action("staffStrike"):
        _fail("real authorized staffStrike not accepted")
        return
    var after: Dictionary = world.formula_encounter.snapshot()
    if events.size()!=2 or world.formula_visual_event_serial!=2 \
        or presenter.accepted_visual_count!=1 or not presenter.visible:
        _fail("one accepted staffStrike did not produce one live visual")
        return
    var e: Dictionary = events[1]
    if str(e["source"]) != str(world.VISUAL_EVENT_SOURCE) \
        or int(e["sequence"]) != 2 \
        or Dictionary(e["combatBefore"]) != before \
        or Dictionary(e["combatAfter"]) != after \
        or Dictionary(e["chapterBefore"]) != chapter_before \
        or Dictionary(e["chapterAfter"]) != chapter_before:
        _fail("resolution event does not match the actual scene's snapshots")
        return
    if int(after["turns"])-int(before["turns"])!=1 \
        or int(after["player"]["staffCharges"])!=int(before["player"]["staffCharges"])-1:
        _fail("authentic formula action accounting drifted")
        return
    var old_count: int = presenter.accepted_visual_count
    presenter._on_action_resolved(e.duplicate(true))
    if presenter.accepted_visual_count != old_count or presenter.rejected_event_count < 1:
        _fail("duplicate event replayed staff visuals")
        return
    var duration: float = presenter.observer.bridge.timeline.duration("full_length_staff","attack")
    if not presenter.seek_review_seconds(duration*0.695) \
        or float(presenter.visual_contract()["visualContactStrength"]) < 0.95:
        _fail("event-driven staff contact timing did not render in original scene")
        return
    var snap_before: Dictionary = world.formula_encounter.snapshot()
    presenter.set_reduced_motion(true)
    if float(presenter.visual_contract()["visualContactStrength"]) != 0.0:
        _fail("live reduced-motion preference left contact flash")
        return
    if world.formula_encounter.snapshot() != snap_before \
        or SaveCodec.encode(world.chapter,
            {"hull_integrity":100,"morale":50,"engine_integration":0},
            world.ender.position) != saved_before:
        _fail("presenter changed combat outcome or durable save format")
        return
    presenter.set_pilot_enabled(false)
    if presenter.visible:
        _fail("disabling optional visual pilot left drawing visible")
        return
    if not world.take_formula_review_action("hold") or events.size()!=3 \
        or presenter.accepted_visual_count!=1:
        _fail("allowed hold action did not remain an unrelated combat event")
        return
    if world.chapter.snapshot()!=chapter_before or not world.close_formula_review():
        _fail("noncanonical formula review leaked into chapter story")
        return
    for signal_id in ["harmonic_buoy","below_frequency","sky_lane_warning"]:
        if not world.complete_signal_contact(signal_id):
            _fail("signal progression failed at "+signal_id)
            return
    if not world.start_hazard_encounter("wind_shear"):
        _fail("actual Wind Shear hazard unavailable")
        return
    presenter.set_pilot_enabled(true)
    presenter.set_reduced_motion(false)
    var hazard_before: Dictionary = world.formula_encounter.snapshot()
    if not world.take_formula_review_action("staffStrike"):
        _fail("authorized Wind Shear turn did not execute")
        return
    var hazard_after: Dictionary = world.formula_encounter.snapshot()
    if events.size()!=4 or presenter.accepted_visual_count!=2 \
        or not presenter.visible or int(events[3]["sequence"])!=4 \
        or str(hazard_before["target"]["id"]) != "windShear" \
        or int(hazard_after["turns"])-int(hazard_before["turns"])!=1:
        _fail("live Wind Shear event failed or was replayed")
        return
    var hazard_chapter: Dictionary = world.chapter.snapshot()
    if str(hazard_chapter["stage"]) != "crossing" \
        or world.formula_encounter.snapshot()!=hazard_after:
        _fail("visual animation changed real hazard resolution")
        return
    presenter.detach()
    if presenter.visual_contract()["attached"] or presenter.visible:
        _fail("visual presenter did not detach cleanly")
        return
    wrapper.queue_free()
    await process_frame
    print("FIRST_WAKE_STAFF_SIGNAL_PILOT_PASS: real formula + Wind Shear signal, one visual per authorized staff turn, rejects replay, no new gameplay or save")
    quit(0)

func _fail(reason: String) -> void:
    push_error("FIRST_WAKE_STAFF_SIGNAL_PILOT_FAIL: "+reason)
    quit(1)
