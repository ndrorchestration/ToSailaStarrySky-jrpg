extends SceneTree
## Parity contract for the packaged Chapter I content authority migrated into Godot.

const ChapterState = preload("res://scripts/first_wake_chapter1_state.gd")
const ChapterContent = preload("res://scripts/first_wake_chapter1_content.gd")

func _initialize() -> void:
    var content = ChapterContent.new()

    if ChapterContent.PACKAGED_SOURCE_SHA != "b2a1d7774168b3f7ef6c914f262137fd8b5fd4bb":
        _fail("packaged source identity drifted")
        return

    if content.signal_label("harmonic_buoy") != "Wakeheart Diagnostic":
        _fail("Wakeheart signal label drifted")
        return
    if content.signal_contact_id("below_frequency") != "child_prophet":
        _fail("Lyra signal/contact binding drifted")
        return
    if content.hazard_label("corporate_intercept") != "Dock Authority Hold":
        _fail("dock hold hazard label drifted")
        return
    if content.contact_name("elder_farmer") != "Captain Ionia":
        _fail("Ionia contact identity drifted")
        return

    var lyra_intro := content.contact_dialogue("child_prophet", "intro")
    if lyra_intro.size() != 5 or "The ship is not asleep." not in str(lyra_intro[0]):
        _fail("Lyra packaged intro corpus is incomplete")
        return
    var wakeheart_deep := content.contact_dialogue("engine_spirit", "deep")
    if wakeheart_deep.size() != 3 or "Auroral-lane topology remains inaccessible." not in str(wakeheart_deep[2]):
        _fail("Wakeheart packaged deep corpus is incomplete")
        return
    var verrick_ender := content.contact_dialogue("corporate_salvager", "class_ender")
    if verrick_ender.size() != 3 or "new variable" not in str(verrick_ender[0]):
        _fail("Verrick packaged Ender corpus is incomplete")
        return

    if content.choice_label("path_c") != "Project shield / Cover the berths":
        _fail("path_c label drifted")
        return
    if "three vessels survive" not in content.choice_outcome("path_c", "10+"):
        _fail("path_c strong outcome drifted")
        return
    if "Side shielding thins" not in content.choice_outcome("path_c", "7-9"):
        _fail("path_c mixed outcome drifted")
        return

    # Preserve the current packaged first-match resolver order exactly.
    if str(content.resolve_epilogue("path_c", 100, 50, 0)["id"]) != "epiline_1":
        _fail("default packaged resolver parity drifted")
        return
    if str(content.resolve_epilogue("path_c", 100, 50, 60)["id"]) != "epiline_6":
        _fail("First Chord resolver parity drifted")
        return
    if str(content.resolve_epilogue("path_c", 100, 60, 50)["id"]) != "epiline_4":
        _fail("Lyra Wide Wing resolver parity drifted")
        return
    if str(content.resolve_epilogue("path_b", 100, 50, 50)["id"]) != "epiline_3":
        _fail("Verrick ledger resolver parity drifted")
        return
    if str(content.resolve_epilogue("path_c", 30, 80, 80)["id"]) != "epiline_5":
        _fail("Weather-Bruised fail-first resolver parity drifted")
        return

    var chapter = ChapterState.new()
    var signal_objective := content.objective_for(chapter)
    if "Wakeheart" not in signal_objective or "Lyra" not in signal_objective or "Verrick" not in signal_objective:
        _fail("signal objective did not derive packaged contact names")
        return

    print("AETHERWAKE_GODOT_CHAPTER1_CONTENT_PASS: packaged labels, dialogue corpus, choices, outcomes, objectives and epilogue order preserved")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_CONTENT_FAIL: " + reason)
    quit(1)
