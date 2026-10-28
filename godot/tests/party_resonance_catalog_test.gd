extends SceneTree
## Native design-only contract; cannot admit new abilities or mutate battle turns.
const Catalog = preload("res://scripts/party_resonance_catalog.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")

func _initialize() -> void:
    var c = Catalog.new()
    if not c.validate_catalog():
        _fail("catalog validation failed")
        return
    if c.list_definitions().size() != 4 or not c.definition_for("unknown").is_empty():
        _fail("catalog identity drift")
        return
    if Catalog.CREATOR_SIGILS != {
        "ender": "spirit", "lyra": "water", "ionia": "earth",
        "reson": "fire", "aepex": "air",
    }:
        _fail("sigil identity drift")
        return
    for art in c.list_definitions():
        if str(art["runtimeStatus"]) != "DESIGN_ONLY" or bool(c.try_execute(str(art["id"]), {}).get("canExecute", true)):
            _fail("art accidentally executable")
            return

    var party := ["ender", "lyra"]
    var states := {"ender": {"alive": true, "canAct": true}, "lyra": {"alive": true, "canAct": true}}
    var unlocks := ["tidebound_promise"]
    var before := states.duplicate(true)
    var candidate := c.inspect_candidate("tidebound_promise", party, states, unlocks)
    if not bool(candidate.get("canPreview", false)) or bool(candidate.get("canExecute", true)):
        _fail("design preview status invalid")
        return
    if str(candidate.get("reason", "")) != "design_only":
        _fail("design preview reason invalid")
        return
    var copied := c.definition_for("tidebound_promise")
    copied["name"] = "forged"
    if str(c.definition_for("tidebound_promise")["name"]) == "forged":
        _fail("defensive copy failed")
        return
    if str(c.inspect_candidate("missing", party, states, unlocks)["reason"]) != "unknown_art":
        _fail("unknown-art gate")
        return
    if str(c.inspect_candidate("tidebound_promise", party, states, [])["reason"]) != "art_not_unlocked":
        _fail("unlock gate")
        return
    if str(c.inspect_candidate("tidebound_promise", ["ender"], states, unlocks)["reason"]) != "participant_missing":
        _fail("missing-member gate")
        return
    if str(c.inspect_candidate("tidebound_promise", ["ender", "ender"], states, unlocks)["reason"]) != "invalid_party":
        _fail("duplicate-member gate")
        return
    if str(c.inspect_candidate("tidebound_promise", ["ender", "alien"], states, unlocks)["reason"]) != "invalid_party":
        _fail("unknown-member gate")
        return
    var dead := states.duplicate(true)
    dead["lyra"]["alive"] = false
    if str(c.inspect_candidate("tidebound_promise", party, dead, unlocks)["reason"]) != "participant_unavailable":
        _fail("incapacitation gate")
        return
    var malformed := states.duplicate(true)
    malformed["lyra"]["canAct"] = "yes"
    if str(c.inspect_candidate("tidebound_promise", party, malformed, unlocks)["reason"]) != "participant_state_invalid":
        _fail("malformed actor gate")
        return
    if str(c.inspect_candidate("horizon_relay", party, states, ["horizon_relay"])["reason"]) != "participant_missing":
        _fail("triple-member gate")
        return
    if states != before:
        _fail("preview mutated state")
        return
    var authority = Authority.new()
    if not authority.validate() or authority.can_take_formula_turn("lyra"):
        _fail("previous native party authority widened")
        return
    if authority.can_use_formula_action("ender", "tidebound_promise"):
        _fail("resonance became authorized formula action")
        return
    print("GODOT_PARTY_RESONANCE_DESIGN_PASS: four arts; preview-only; execution denied")
    quit(0)

func _fail(reason: String) -> void:
    push_error("GODOT_PARTY_RESONANCE_DESIGN_FAIL: " + reason)
    quit(1)
