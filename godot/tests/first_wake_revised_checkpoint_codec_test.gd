extends SceneTree
## Strongly validated v2 review-only opening evidence. No old v1 migration or
## persistent combat/Resonance entitlement can enter this checkpoint schema.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const OldCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var opening = Opening.new()
    var start: Dictionary = Codec.encode(opening, false, "dock", [], Vector2(228, 468))
    if start.is_empty() or not Codec.validate(start).get("ok", false):
        _fail("start checkpoint could not encode")
        return
    var restored: Dictionary = Codec.restore(start)
    if not restored.get("ok", false) or restored["opening"].active_party_ids != ["ender"]:
        _fail("Ender-only start reconstruction failed")
        return
    if Codec.restore(start).get("reviewOnly", false) != true:
        _fail("restored opening was not review-scoped")
        return
    if OldCodec.validate(start).get("ok", false):
        _fail("older Chapter I v1 codec accepted unrelated revised checkpoint")
        return
    if Codec.validate(OldCodec.encode(preload("res://scripts/first_wake_chapter1_state.gd").new())).get("ok", false):
        _fail("v2 codec accepted old Lyra-first stage")
        return

    if not opening.accept_ionia_job():
        _fail("Ionia-first join failed")
        return
    var engineering: Dictionary = Codec.encode(opening, true, "engineering", ["reference"], Vector2(335, 465))
    if engineering.is_empty():
        _fail("ordered engineering evidence rejected")
        return
    restored = Codec.restore(engineering)
    if not restored.get("ok", false) or restored["opening"].active_party_ids != ["ender", "ionia"]:
        _fail("reconstructed employer/crew state diverged")
        return
    if restored["opening"].step_key() != "engineering" or restored["inspections"] != ["reference"]:
        _fail("engineering stage or evidence round-trip failed")
        return

    if not opening.complete_engineering_checks():
        _fail("revised preflight transition rejected")
        return
    var preflight: Dictionary = Codec.encode(opening, true, "engineering", ["fuel", "reference", "containment"], Vector2(809, 465))
    if preflight.is_empty():
        _fail("full checklist checkpoint could not encode")
        return
    restored = Codec.restore(preflight)
    if not restored.get("ok", false) or restored["opening"].step_key() != "preflight":
        _fail("preflight reconstruction failed")
        return
    if "lyra" in restored["opening"].active_party_ids or "talen" in restored["opening"].active_party_ids:
        _fail("pre-splashdown checkpoint invented Lyra/Talen recruitment")
        return
    var corrupted: Dictionary = preflight.duplicate(true)
    var cases := [
        {"field": "schema", "value": OldCodec.SCHEMA_VERSION},
        {"field": "step", "value": "working_theory"},
        {"field": "room", "value": "dock"},
        {"field": "flyer_read", "value": false},
        {"field": "inspections", "value": ["reference", "fuel"]},
        {"field": "inspections", "value": ["reference", "reference", "containment"]},
        {"field": "inspections", "value": ["reference", "fuel", "invented_spell"]},
        {"field": "player_position", "value": {"x": 9999, "y": 465}},
        {"field": "player_position", "value": {"x": "809", "y": 465}},
        {"field": "player_position", "value": {"x": NAN, "y": 465}},
    ]
    for case in cases:
        corrupted = preflight.duplicate(true)
        corrupted[case["field"]] = case["value"]
        if Codec.validate(corrupted).get("ok", false) or Codec.restore(corrupted).get("ok", false):
            _fail("malformed checkpoint restored: " + str(case["field"]))
            return
    for forbidden in ["active_party_ids", "trainingGrants", "canExecute", "save_art_unlock", "spell_mastery"]:
        corrupted = preflight.duplicate(true)
        corrupted[forbidden] = true
        if Codec.validate(corrupted).get("ok", false):
            _fail("forbidden authority field persisted: " + forbidden)
            return

    corrupted = start.duplicate(true)
    corrupted["inspections"] = ["reference"]
    if Codec.validate(corrupted).get("ok", false):
        _fail("pre-employment evidence accepted")
        return
    corrupted = engineering.duplicate(true)
    corrupted["room"] = "dock"
    if Codec.validate(corrupted).get("ok", false):
        _fail("engineering inspection persisted before boarding")
        return
    if Codec.validate([]).get("ok", false):
        _fail("non-object checkpoint accepted")
        return
    if Codec.encode(opening, true, "engineering", ["reference"], Vector2(809, 465)) != {}:
        _fail("preflight encoder wrote partial checklist")
        return
    print("TSTSS_REVISED_OPENING_CHECKPOINT_CODEC_PASS: independent v2, staged reconstruction, typed room evidence, no old save or combat entitlements")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_REVISED_OPENING_CHECKPOINT_CODEC_FAIL: " + reason)
    quit(1)
