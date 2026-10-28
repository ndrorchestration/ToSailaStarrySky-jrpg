extends SceneTree
## The normalized schema cannot grant a new production action. Both native
## formula metadata and proposal Arts flow through this same metadata format.
const Ability = preload("res://scripts/combat_ability_contract.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")

func _initialize() -> void:
    var a = Ability.new()
    var gate = Authority.new()
    if not gate.validate():
        _fail("native party authority drifted")
        return
    for action_id in ["staffStrike", "uncoverTruth", "hold", "rest"]:
        var d: Dictionary = a.for_formula(action_id)
        if not a.validate_definition(d) or d.get("sourceKind", "") != "formula":
            _fail("formula metadata was not normalized: " + action_id)
            return
        if bool(d.get("canExecute", true)) or d.get("runtimeStatus", "") != Ability.FORMULA_STATUS:
            _fail("normalizer tried to authorize a formula")
            return
        if d["resolution"]["formulaId"] != action_id or not gate.can_use_formula_action("ender", action_id):
            _fail("normalized formula identity diverged from existing authority")
            return
    if not a.for_formula("aetherSeal").is_empty() or not a.for_formula("sharedDream").is_empty():
        _fail("separate/blocked contracts were laundered into formula metadata")
        return
    var arts := ["tidebound_promise", "skyroot_bastion", "embermist_veil", "horizon_relay"]
    for art_id in arts:
        var d: Dictionary = a.for_resonance(art_id)
        if not a.validate_definition(d):
            _fail("known art failed normalizer: " + art_id)
            return
        if bool(d.get("canExecute", true)) or d["runtimeStatus"] != Ability.REVIEW_STATUS:
            _fail("art accidentally gained execution permission")
            return
        if gate.can_use_formula_action("ender", art_id) or gate.can_take_formula_turn("lyra"):
            _fail("proposal art widened native combat permissions")
            return
    if not a.for_resonance("unknown_art").is_empty():
        _fail("unknown art normalized")
        return
    var good: Dictionary = a.for_resonance("tidebound_promise")
    var corrupted: Dictionary = good.duplicate(true)
    corrupted["canExecute"] = true
    if a.validate_definition(corrupted):
        _fail("forgeable execution flag")
        return
    corrupted = good.duplicate(true)
    corrupted["participants"] = ["ender", "ender"]
    if a.validate_definition(corrupted):
        _fail("duplicate actor accepted")
        return
    corrupted = good.duplicate(true)
    corrupted["participants"] = ["lyra", "ender"]
    if a.validate_definition(corrupted):
        _fail("wrong participant ordering accepted")
        return
    corrupted = good.duplicate(true)
    corrupted["sigils"] = ["water", "spirit"]
    if a.validate_definition(corrupted):
        _fail("sigils misbound to protagonists")
        return
    corrupted = good.duplicate(true)
    corrupted["resolution"]["model"] = "jrpg-stat-formula"
    if a.validate_definition(corrupted):
        _fail("design art forged formula resolver")
        return
    corrupted = good.duplicate(true)
    corrupted["id"] = "fake_art"
    corrupted["resolution"]["effectId"] = "fake_art"
    if a.validate_definition(corrupted):
        _fail("fake art accepted")
        return
    corrupted = a.for_formula("staffStrike")
    corrupted["runtimeStatus"] = Ability.REVIEW_STATUS
    if a.validate_definition(corrupted):
        _fail("formula status rewritten")
        return
    if a.validate_definition([]) or a.validate_definition({}) or a.validate_definition("tidebound"):
        _fail("nondefinitions accepted")
        return
    print("GODOT_SHARED_ABILITY_CONTRACT_PASS: formula and four Arts normalized with no execution authority")
    quit(0)

func _fail(reason: String) -> void:
    push_error("GODOT_SHARED_ABILITY_CONTRACT_FAIL: " + reason)
    quit(1)
