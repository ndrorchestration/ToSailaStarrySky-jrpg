extends SceneTree
## Proof of explicit fixture-only ability admission. NO production unlock.
const Grants = preload("res://scripts/resonance_review_grant_policy.gd")
const Ability = preload("res://scripts/combat_ability_contract.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")

func _initialize() -> void:
    var policy = Grants.new()
    var record: Dictionary = policy.create_training_grant("tidebound_promise")
    var context := {"reviewOnly": true, "phase": "player"}
    if record.is_empty() or record["scope"] != Grants.SCOPE or record["origin"] != Grants.ORIGIN:
        _fail("explicit training grant construction failed")
        return
    if policy.check("tidebound_promise", context, []).get("reason", "") != "art_not_granted_for_review":
        _fail("innate Light/party membership incorrectly unlocked art")
        return
    var ledger: Array = [record.duplicate(true)]
    var original: Array = ledger.duplicate(true)
    if not bool(policy.check("tidebound_promise", context, ledger).get("ok", false)):
        _fail("explicit lab grant did not admit matching Art")
        return
    if ledger != original:
        _fail("grant admission mutated caller ledger")
        return
    if policy.check("horizon_relay", context, ledger).get("reason", "") != "art_not_granted_for_review":
        _fail("grant for one Art authorized a second Art")
        return
    if policy.check("unknown_art", context, ledger).get("reason", "") != "unknown_or_invalid_art":
        _fail("unknown art accepted")
        return
    if not policy.create_training_grant("unknown_art").is_empty():
        _fail("unknown grant minted")
        return
    if policy.check("tidebound_promise", {"reviewOnly": false, "phase": "player"}, ledger).get("reason", "") != "review_scope_required":
        _fail("production-shaped state accepted review credential")
        return
    if policy.check("tidebound_promise", {"reviewOnly": true, "phase": "enemy"}, ledger).get("reason", "") != "wrong_phase":
        _fail("enemy phase accepted art grant")
        return
    if policy.check("tidebound_promise", context, {}).get("reason", "") != "invalid_grant_set":
        _fail("non-array grants accepted")
        return
    if policy.check("tidebound_promise", context, ["tidebound_promise"]).get("reason", "") != "malformed_grant":
        _fail("string bypassed structured grant")
        return
    var mutated: Dictionary = record.duplicate(true)
    mutated["scope"] = "production"
    if policy.check("tidebound_promise", context, [mutated]).get("reason", "") != "grant_provenance_invalid":
        _fail("scope escalation accepted")
        return
    mutated = record.duplicate(true)
    mutated["origin"] = "automatic-plot-energy"
    if policy.check("tidebound_promise", context, [mutated]).get("reason", "") != "grant_provenance_invalid":
        _fail("plot energy accepted as unlock authority")
        return
    mutated = record.duplicate(true)
    mutated["participants"] = ["ender", "aepex"]
    if policy.check("tidebound_promise", context, [mutated]).get("reason", "") != "grant_members_invalid":
        _fail("changed participant binding accepted")
        return
    mutated = record.duplicate(true)
    mutated["canExecute"] = true
    if policy.check("tidebound_promise", context, [mutated]).get("reason", "") != "malformed_grant":
        _fail("extra execution field accepted")
        return
    if policy.check("tidebound_promise", context, [record, record]).get("reason", "") != "duplicate_grant":
        _fail("duplicate grant accepted")
        return
    mutated = record.duplicate(true)
    mutated["artId"] = "unknown_art"
    if policy.check("tidebound_promise", context, [mutated]).get("reason", "") != "unknown_grant_art":
        _fail("unknown entry silently ignored")
        return
    if policy.check_production("tidebound_promise", record).get("reason", "") != "production_art_authority_not_implemented":
        _fail("test grant claimed canonical ability authority")
        return
    if Authority.new().can_take_formula_turn("lyra") or Authority.new().can_use_formula_action("ender", "tidebound_promise"):
        _fail("First Wake production authority widened")
        return
    if bool(Ability.new().for_resonance("tidebound_promise").get("canExecute", true)):
        _fail("nonexecuting shared catalog granted execution")
        return
    print("GODOT_RESONANCE_EXPLICIT_GRANT_PASS: scoped laboratory unlock, replay guard and production denial")
    quit(0)

func _fail(reason: String) -> void:
    push_error("GODOT_RESONANCE_EXPLICIT_GRANT_FAIL: " + reason)
    quit(1)
