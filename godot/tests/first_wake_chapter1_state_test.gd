extends SceneTree
## Deterministic migration contract for the packaged First Wake Chapter I FSM.

const ChapterState = preload("res://scripts/first_wake_chapter1_state.gd")

func _initialize() -> void:
    var chapter = ChapterState.new()

    if chapter.stage_key() != "signal":
        _fail("initial stage is not signal")
        return
    if chapter.desired_active_party_ids() != ["ender", "lyra"]:
        _fail("initial native party target must be Ender + Lyra")
        return
    if chapter.complete_hazard("sky_predator"):
        _fail("hazard accepted before crossing")
        return
    if chapter.choose_path("path_c", "10+"):
        _fail("choice accepted before decision boundary")
        return
    if chapter.complete_wake("epiline_6"):
        _fail("wake completed before choice")
        return

    # These three contacts are already encountered while gathering signal hooks
    # in the packaged Chapter I flow and must carry forward.
    for contact_id in ["engine_spirit", "child_prophet", "corporate_salvager"]:
        if not chapter.meet_contact(contact_id):
            _fail("signal-phase contact rejected: " + contact_id)
            return
    if chapter.meet_contact("engine_spirit"):
        _fail("duplicate contact counted twice")
        return

    for signal_id in ["harmonic_buoy", "sky_lane_warning", "below_frequency"]:
        if not chapter.complete_signal(signal_id):
            _fail("valid signal rejected: " + signal_id)
            return
    if chapter.stage_key() != "crossing":
        _fail("three signal hooks did not enter crossing")
        return
    if chapter.complete_signal("harmonic_buoy"):
        _fail("signal mutated after crossing")
        return

    for hazard_id in ["sky_predator", "wind_shear", "corporate_intercept"]:
        if not chapter.complete_hazard(hazard_id):
            _fail("valid crossing hazard rejected: " + hazard_id)
            return
    if chapter.stage_key() != "contact":
        _fail("three hazards did not enter contact")
        return
    if chapter.completed_hazards.size() != 3:
        _fail("hazard denominator is not exactly three")
        return

    if not chapter.meet_contact("elder_farmer"):
        _fail("Ionia contact rejected")
        return
    if chapter.stage_key() != "choice" or not chapter.ionia_joined_for_choice:
        _fail("four contacts did not recruit Ionia at choice boundary")
        return
    if chapter.desired_active_party_ids() != ["ender", "lyra", "ionia"]:
        _fail("choice party target is not Ender + Lyra + Ionia")
        return

    if not chapter.choose_path("path_c", "10+"):
        _fail("path_c choice rejected")
        return
    if chapter.stage_key() != "wake":
        _fail("choice did not enter wake")
        return
    if chapter.choose_path("path_a", "7-9"):
        _fail("exclusive choice mutated")
        return

    if not chapter.complete_wake("epiline_6"):
        _fail("valid epilogue did not complete Chapter I")
        return
    var snap := chapter.snapshot()
    if snap["stage"] != "done" or not snap["chapter_one_complete"]:
        _fail("Chapter I did not terminate in explicit done state")
        return
    if snap["choice_path"] != "path_c" or snap["choice_variant"] != "10+":
        _fail("choice identity was not preserved")
        return

    # Exercise the other two path IDs independently; state model does not infer
    # epilogue rules, it only preserves the resolved outcome identity.
    for path_id in ["path_a", "path_b"]:
        var alt = ChapterState.new()
        alt.contacts_met = ChapterState.CONTACT_IDS.duplicate()
        for signal_id in ChapterState.SIGNAL_IDS:
            alt.complete_signal(signal_id)
        for hazard_id in ChapterState.HAZARD_IDS:
            alt.complete_hazard(hazard_id)
        if alt.stage_key() != "choice" or not alt.ionia_joined_for_choice:
            _fail("pre-met contacts did not carry into choice for " + path_id)
            return
        if not alt.choose_path(path_id, "7-9"):
            _fail("alternate path rejected: " + path_id)
            return
        if not alt.complete_wake("migration_test_" + path_id):
            _fail("alternate path did not complete: " + path_id)
            return

    print("AETHERWAKE_GODOT_CHAPTER1_FSM_PASS: 3 signals, 3 hazards, 4 contacts, Ionia join, 3 paths, Wake and explicit completion")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_FSM_FAIL: " + reason)
    quit(1)
