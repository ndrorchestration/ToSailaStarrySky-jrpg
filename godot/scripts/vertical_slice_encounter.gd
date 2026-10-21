extends RefCounted
## Deterministic, noncanonical encounter model for a review-only ten-minute slice.
## Deliberately separate from the existing training arena and story runtime.

var challenge_hp: int = 24
var player_hp: int = 24
var telegraph_winding_up: bool = true
var turns: int = 0
var guarded_telegraphs: int = 0
var completed: bool = false

func take_turn(action: String) -> bool:
    if completed or player_hp <= 0:
        return false
    if action != "strike" and action != "guard":
        return false
    turns += 1
    if action == "strike":
        challenge_hp = maxi(0, challenge_hp - 8)
    if action == "guard" and telegraph_winding_up:
        guarded_telegraphs += 1
    if challenge_hp == 0:
        completed = true
        return true
    if telegraph_winding_up:
        player_hp = maxi(0, player_hp - (2 if action == "guard" else 8))
    telegraph_winding_up = not telegraph_winding_up
    return true

func is_failed() -> bool:
    return player_hp == 0 and not completed

func telegraph_text() -> String:
    return "Signal gathering: GUARD to soften the next pulse" if telegraph_winding_up else "Signal quiet: safe moment to STRIKE"
