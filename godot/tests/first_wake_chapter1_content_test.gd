extends SceneTree
## Contract for packaged Chapter I content imported into native Godot.

const Content = preload("res://scripts/first_wake_chapter1_content.gd")

func _initialize() -> void:
    if Content.signal_label("harmonic_buoy") != "Wakeheart Diagnostic":
        _fail("Wakeheart signal label drifted")
        return
    if Content.hazard_label("corporate_intercept") != "Dock Authority Hold":
        _fail("Dock Authority hazard label drifted")
        return
    if Content.contact_name("elder_farmer") != "Ionia":
        _fail("Ionia contact identity drifted")
        return

    for contact_id in ["elder_farmer", "engine_spirit", "child_prophet", "corporate_salvager"]:
        var intro := Content.contact_intro(contact_id)
        if intro.size() != 5:
            _fail("packaged first-contact dialogue line count drifted for " + contact_id)
            return

    if Content.choice_label("path_a") != "Leave early / Beat the storm":
        _fail("path_a label drifted")
        return
    if Content.choice_label("path_b") != "Hold dock / Stabilize the colony shield":
        _fail("path_b label drifted")
        return
    if Content.choice_label("path_c") != "Project shield / Cover the berths":
        _fail("path_c label drifted")
        return

    var projected := Content.outcome_text("path_c", "10+")
    if not projected.begins_with("The Wake turns her shield like a bright wing into the storm."):
        _fail("path_c 10+ outcome drifted")
        return

    # These metrics intentionally distinguish the three authored paths while
    # preserving the exact current packaged resolver priority.
    if Content.resolve_epilogue_id("path_a", 72, 58, 64) != "epiline_1":
        _fail("path_a review metrics did not resolve Clear Departure")
        return
    if Content.resolve_epilogue_id("path_b", 72, 58, 64) != "epiline_3":
        _fail("path_b review metrics did not resolve Verrick's Weather Ledger")
        return
    if Content.resolve_epilogue_id("path_c", 72, 58, 64) != "epiline_6":
        _fail("path_c review metrics did not resolve The First Chord")
        return

    # Preserve packaged ordered-trigger behavior even where legacy comments
    # imply a different desired ending precedence.
    if Content.resolve_epilogue_id("path_c", 80, 80, 80) != "epiline_2":
        _fail("packaged epilogue priority was silently changed")
        return

    var initial := {
        "stage": "signal",
        "signals_completed": [],
        "hazards_completed": [],
        "contacts_met": [],
        "choice_path": "",
    }
    if Content.objective_text(initial) != "Talk to marked: Wakeheart, Verrick, Lyra":
        _fail("initial native objective does not match packaged guidance")
        return

    var ending: Dictionary = Content.epilogue_record("epiline_6")
    if str(ending.get("name", "")) != "The First Chord":
        _fail("epiline_6 identity drifted")
        return

    print("AETHERWAKE_GODOT_CHAPTER1_CONTENT_PASS: packaged labels, 20 first-contact lines, 3 choices, outcomes, objectives and epilogue resolver are native-bound")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_CONTENT_FAIL: " + reason)
    quit(1)
