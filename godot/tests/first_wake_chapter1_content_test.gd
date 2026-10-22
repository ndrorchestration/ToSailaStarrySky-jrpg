extends SceneTree
## Contract for the native First Wake Chapter I authored-content migration.

const Content = preload("res://scripts/first_wake_chapter1_content.gd")
const ChapterState = preload("res://scripts/first_wake_chapter1_state.gd")

func _initialize() -> void:
    if Content.SIGNAL_IDS != ChapterState.SIGNAL_IDS:
        _fail("signal catalog drifted from FSM")
        return
    if Content.HAZARD_IDS != ChapterState.HAZARD_IDS:
        _fail("hazard catalog drifted from FSM")
        return
    if Content.CONTACT_IDS != ChapterState.CONTACT_IDS:
        _fail("contact catalog drifted from FSM")
        return
    if Content.CHOICE_IDS != ChapterState.CHOICE_IDS:
        _fail("choice catalog drifted from FSM")
        return

    if Content.signal_label("harmonic_buoy") != "Wakeheart Diagnostic":
        _fail("Wakeheart signal label mismatch")
        return
    if Content.signal_label("sky_lane_warning") != "Dock Shield Warning":
        _fail("dock warning label mismatch")
        return
    if Content.signal_label("below_frequency") != "Lyra's Frequency Sketch":
        _fail("Lyra signal label mismatch")
        return

    if Content.hazard_label("sky_predator") != "Loose Cargo Sweep":
        _fail("cargo hazard label mismatch")
        return
    if Content.hazard_label("corporate_intercept") != "Dock Authority Hold":
        _fail("dock hold label mismatch")
        return

    for contact_id in Content.CONTACT_IDS:
        if Content.contact_name(contact_id).is_empty():
            _fail("contact name missing: " + contact_id)
            return
        if Content.contact_title(contact_id).is_empty():
            _fail("contact title missing: " + contact_id)
            return
        if Content.contact_intro(contact_id).size() != 5:
            _fail("packaged intro corpus is not five lines for " + contact_id)
            return

    if Content.contact_name("elder_farmer") != "Ionia":
        _fail("Ionia content identity mismatch")
        return
    if Content.contact_name("engine_spirit") != "Wakeheart":
        _fail("Wakeheart content identity mismatch")
        return
    if Content.contact_name("child_prophet") != "Lyra":
        _fail("Lyra content identity mismatch")
        return
    if Content.contact_name("corporate_salvager") != "Verrick":
        _fail("Verrick content identity mismatch")
        return

    if Content.choice_label("path_a") != "Leave early / Beat the storm":
        _fail("path_a label mismatch")
        return
    if Content.choice_label("path_b") != "Hold dock / Stabilize the colony shield":
        _fail("path_b label mismatch")
        return
    if Content.choice_label("path_c") != "Project shield / Cover the berths":
        _fail("path_c label mismatch")
        return
    for path_id in Content.CHOICE_IDS:
        for variant in ChapterState.VALID_VARIANTS:
            if Content.choice_outcome(path_id, variant).is_empty():
                _fail("choice outcome missing: " + path_id + " / " + variant)
                return

    if Content.EPILOGUE_IDS.size() != 6:
        _fail("epilogue catalog is not six entries")
        return
    if Content.epilogue_name("epiline_6") != "The First Chord":
        _fail("First Chord epilogue identity mismatch")
        return
    if Content.epilogue_text("epiline_6").find("A crew, briefly aligned") < 0:
        _fail("First Chord epilogue text mismatch")
        return
    if Content.has_epilogue("migration_review_path_c"):
        _fail("synthetic migration epilogue leaked into canonical catalog")
        return

    var chapter = ChapterState.new()
    if Content.objective_text(chapter) != "Talk to marked: Wakeheart, Verrick, Lyra":
        _fail("initial objective did not derive packaged signal contacts")
        return
    chapter.meet_contact("engine_spirit")
    chapter.complete_signal("harmonic_buoy")
    if Content.objective_text(chapter).find("Wakeheart") >= 0:
        _fail("completed signal contact remained in objective")
        return

    if Content.review_epilogue_fixture("path_a") != "epiline_1":
        _fail("path_a review fixture mismatch")
        return
    if Content.review_epilogue_fixture("path_b") != "epiline_3":
        _fail("path_b review fixture mismatch")
        return
    if Content.review_epilogue_fixture("path_c") != "epiline_6":
        _fail("path_c review fixture mismatch")
        return

    print("AETHERWAKE_GODOT_CHAPTER1_CONTENT_PASS: packaged labels, dialogue corpus, outcomes and six epilogues are bound without a production resolver")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_CONTENT_FAIL: " + reason)
    quit(1)
