extends SceneTree
## Asset-independent native contract for the review-only echo encounter.

const Encounter = preload("res://scripts/vertical_slice_encounter.gd")

func _initialize() -> void:
    var informed = Encounter.new()
    if not informed.telegraph_winding_up or informed.echo_focus != 0:
        _fail("initial telegraph state invalid")
        return
    if not informed.take_turn("guard") or informed.echo_focus != 1 or informed.player_hp != 16:
        _fail("guard did not reduce warned-pulse damage and build echo")
        return
    if not informed.take_turn("strike") or informed.echo_focus != 0 or informed.challenge_hp != 12:
        _fail("quiet strike did not consume echo for 18 damage")
        return
    if not informed.take_turn("guard") or informed.player_hp != 14:
        _fail("second warned pulse not guarded correctly")
        return
    if not informed.take_turn("strike") or not informed.completed or informed.challenge_hp != 0:
        _fail("readable guard-strike loop did not complete")
        return

    var blind = Encounter.new()
    for i in range(4):
        if blind.is_failed():
            break
        if not blind.take_turn("strike"):
            _fail("blind strike unexpectedly rejected")
            return
    if not blind.is_failed() or blind.completed:
        _fail("ignoring warned pulses carries no meaningful failure risk")
        return
    if blind.take_turn("guard"):
        _fail("failed encounter accepted another turn")
        return
    print("AETHERWAKE_ECHO_ENCOUNTER_PASS: telegraph guard builds echo, quiet strike cashes it, blind attack fails")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_ECHO_ENCOUNTER_FAIL: " + reason)
    quit(1)
