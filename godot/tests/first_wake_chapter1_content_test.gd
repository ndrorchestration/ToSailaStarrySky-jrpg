extends SceneTree
## Contract for native First Wake Chapter I packaged-content binding.

const Content = preload("res://scripts/first_wake_chapter1_content.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    if Content.signal_label("harmonic_buoy") != "Wakeheart Diagnostic":
        _fail("Wakeheart signal label drifted")
        return
    if Content.signal_label("sky_lane_warning") != "Dock Shield Warning":
        _fail("Verrick signal label drifted")
        return
    if Content.signal_label("below_frequency") != "Lyra's Frequency Sketch":
        _fail("Lyra signal label drifted")
        return

    if Content.hazard_label("sky_predator") != "Loose Cargo Sweep":
        _fail("cargo hazard label drifted")
        return
    if Content.hazard_label("wind_shear") != "Wind Shear":
        _fail("wind hazard label drifted")
        return
    if Content.hazard_label("corporate_intercept") != "Dock Authority Hold":
        _fail("dock hold label drifted")
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

    for path_id in ["path_a", "path_b", "path_c"]:
        for variant in ["10+", "7-9"]:
            if Content.choice_outcome(path_id, variant).strip_edges().is_empty():
                _fail("missing choice outcome: " + path_id + " / " + variant)
                return

    # Exact current packaged-default behavior. This looks surprising for path_c,
    # but migration must preserve implementation truth until canon explicitly changes.
    var default_path_c := Content.resolve_legacy_epilogue("path_c", 100, 50, 0)
    if default_path_c.get("id", "") != "epiline_1":
        _fail("default packaged path_c resolver behavior drifted")
        return

    var weather_bruised := Content.resolve_legacy_epilogue("path_a", 30, 50, 0)
    if weather_bruised.get("id", "") != "epiline_5":
        _fail("low-hull fallback did not resolve Weather-Bruised")
        return

    # Legacy first-match ordering means high engineIntegration resolves
    # Shield-Bound before the path_b-specific Weather Ledger rule.
    var shield_bound := Content.resolve_legacy_epilogue("path_b", 70, 50, 80)
    if shield_bound.get("id", "") != "epiline_2":
        _fail("legacy first-match Shield-Bound ordering drifted")
        return

    var verrick_ledger := Content.resolve_legacy_epilogue("path_b", 50, 50, 50)
    if verrick_ledger.get("id", "") != "epiline_3":
        _fail("path_b Weather Ledger branch not reachable with explicit stats")
        return

    var lyras_wing := Content.resolve_legacy_epilogue("path_c", 50, 60, 50)
    if lyras_wing.get("id", "") != "epiline_4":
        _fail("path_c Lyra's Wide Wing branch not reachable")
        return

    var first_chord := Content.resolve_legacy_epilogue("path_c", 50, 50, 60)
    if first_chord.get("id", "") != "epiline_6":
        _fail("path_c First Chord branch not reachable")
        return

    if Content.contact_line("elder_farmer").find("honest hands") < 0:
        _fail("Ionia authored line missing")
        return
    if Content.signal_line("harmonic_buoy").find("Shield lattice: partial") < 0:
        _fail("Wakeheart authored line missing")
        return

    print("AETHERWAKE_GODOT_CHAPTER1_CONTENT_PASS: packaged labels, authored lines, six choice outcomes, and exact legacy epilogue ordering")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_CONTENT_FAIL: " + reason)
    quit(1)
