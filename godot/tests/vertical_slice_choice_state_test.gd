extends SceneTree
## Native Godot 4 test: two exclusive dock decisions and their gated outcomes.

const DockChoice = preload("res://scripts/vertical_slice_choice_state.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var crew = DockChoice.new()
    var beacon = DockChoice.new()
    var valid: bool = true
    valid = valid and crew.dock_payoff_key() == ""
    valid = valid and not crew.choose(DockChoice.Choice.HELP_CREW)
    valid = valid and not crew.complete_challenge()
    crew.discover_signal()
    valid = valid and not crew.choose(DockChoice.Choice.UNSET)
    valid = valid and crew.choose(DockChoice.Choice.HELP_CREW)
    valid = valid and not crew.choose(DockChoice.Choice.REPAIR_BEACON)
    valid = valid and crew.dock_payoff_key() == ""
    valid = valid and crew.complete_challenge()
    valid = valid and crew.dock_payoff_key() == "crew_reconnected"
    beacon.discover_signal()
    valid = valid and beacon.choose(DockChoice.Choice.REPAIR_BEACON)
    valid = valid and beacon.complete_challenge()
    valid = valid and beacon.dock_payoff_key() == "beacon_restored"
    valid = valid and crew.dock_payoff_key() != beacon.dock_payoff_key()
    if not valid:
        push_error("AETHERWAKE_CHOICE_STATE_FAIL: invalid gated or branch outcome")
        quit(1)
        return
    print("AETHERWAKE_CHOICE_STATE_PASS: exclusive, gated, deterministic consequences")
    quit(0)
