extends SceneTree
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Gate = preload("res://scripts/combat/first_wake_party_preview.gd")

func _initialize() -> void:
    var opening = Opening.new()
    var roster := {}
    for id in ["ender", "ionia", "lyra", "foe"]:
        roster[id] = {"hp": 40, "max_hp": 40, "mp": 8, "max_mp": 8, "stamina": 6, "max_stamina": 6}
    var attempt := Gate.preview_party(opening, roster, ["ender", "ionia"], ["foe"])
    if attempt.get("ok", true):
        _fail("Ionia available before recruitment")
        return
    if not opening.accept_ionia_job():
        _fail("job transition")
        return
    var state_before: Dictionary = opening.snapshot()
    var allowed := Gate.preview_party(opening, roster, ["ender", "ionia"], ["foe"])
    if not allowed.get("ok", false) or allowed["encounter_authorized"]:
        _fail("review party admission")
        return
    if allowed["state"]["order"] != ["ender", "ionia", "foe"] or opening.snapshot() != state_before:
        _fail("order or story mutation")
        return
    if Gate.preview_party(opening, roster, ["ender", "lyra"], ["foe"]).get("ok", true):
        _fail("Lyra early access")
        return
    if Gate.preview_party(opening, roster, ["ender", "ender"], ["foe"]).get("ok", true):
        _fail("duplicate member")
        return
    if Gate.preview_party(opening, roster, ["ender"], ["ender"]).get("ok", true):
        _fail("overlapping factions")
        return
    print("FIRST_WAKE_PARTY_PREVIEW_PASS")
    quit(0)

func _fail(reason: String) -> void:
    push_error("FIRST_WAKE_PARTY_PREVIEW_FAIL: " + reason)
    quit(1)
