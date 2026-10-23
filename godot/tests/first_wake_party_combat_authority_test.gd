extends SceneTree
## Contract for fail-closed party combat authority in native First Wake.

const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")

func _initialize() -> void:
    var authority = Authority.new()

    if not authority.validate():
        _fail("authority contract validation failed")
        return
    if Authority.CURRENT_CROSSING_PARTY != ["ender", "lyra"]:
        _fail("Crossing party identity drifted")
        return
    if authority.authorized_actions("ender") != ["staffStrike", "uncoverTruth", "hold", "rest"]:
        _fail("Ender formula authority drifted")
        return
    if authority.can_use_formula_action("ender", "sharedDream"):
        _fail("blocked Shared Dream entered native formula authority")
        return
    if authority.can_use_formula_action("ender", "windWard"):
        _fail("unresolved Wind Ward entered native formula authority")
        return
    if not authority.authorized_actions("lyra").is_empty() or authority.can_take_formula_turn("lyra"):
        _fail("Lyra received fabricated native combat actions")
        return
    if not authority.authorized_actions("ionia").is_empty() or authority.can_take_formula_turn("ionia"):
        _fail("Ionia received fabricated native combat actions")
        return
    if authority.separate_contract_actions("ender") != ["mycelialLedger", "aetherSeal"]:
        _fail("Ender separate-contract actions drifted")
        return

    var crossing_surface := authority.surface_for_party(["ender", "lyra"])
    if crossing_surface.size() != 2:
        _fail("Crossing combat party surface size drifted")
        return
    if not bool(crossing_surface[0]["canTakeFormulaTurn"]):
        _fail("Ender lost active formula-turn authority")
        return
    if bool(crossing_surface[1]["canTakeFormulaTurn"]):
        _fail("Lyra incorrectly gained a formula turn")
        return

    print("AETHERWAKE_GODOT_PARTY_COMBAT_AUTHORITY_PASS: Ender formula turn authorized; Lyra/Ionia visible without fabricated actions")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_PARTY_COMBAT_AUTHORITY_FAIL: " + reason)
    quit(1)
