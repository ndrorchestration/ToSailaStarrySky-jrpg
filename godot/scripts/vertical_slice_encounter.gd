extends RefCounted
## Deterministic, noncanonical encounter model for a review-only ten-minute slice.
## Guarding a warned pulse creates an echo that empowers the next quiet strike.

var challenge_hp: int = 30
var player_hp: int = 18
var telegraph_winding_up: bool = true
var echo_focus: int = 0
var turns: int = 0
var guarded_telegraphs: int = 0
var completed: bool = false

func take_turn(action: String) -> bool:
    if completed or player_hp <= 0:
        return false
    if action != "strike" and action != "guard":
        return false
    turns += 1
    if action == "guard" and telegraph_winding_up:
        guarded_telegraphs += 1
        echo_focus = mini(1, echo_focus + 1)
    if action == "strike":
        # Reading the telegraph is mechanically meaningful, not merely cosmetic.
        var damage: int = 4 if telegraph_winding_up else 12 + echo_focus * 6
        challenge_hp = maxi(0, challenge_hp - damage)
        echo_focus = 0
    if challenge_hp == 0:
        completed = true
        return true
    if telegraph_winding_up:
        player_hp = maxi(0, player_hp - (2 if action == "guard" else 9))
    telegraph_winding_up = not telegraph_winding_up
    return true

func is_failed() -> bool:
    return player_hp == 0 and not completed

func telegraph_text() -> String:
    return "Pulse gathering: GUARD to build an echo" if telegraph_winding_up else "Pulse quiet: STRIKE for a stronger answer"
