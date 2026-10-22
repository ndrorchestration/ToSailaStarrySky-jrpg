extends RefCounted
## Deterministic, review-only state for the first playable dock choice.
## No canon, saves, analytics, networking, or player-identifying data.

enum Choice { UNSET, HELP_CREW, REPAIR_BEACON }

var choice: Choice = Choice.UNSET
var discovered_signal: bool = false
var challenge_completed: bool = false

func discover_signal() -> void:
    discovered_signal = true

func choose(next_choice: Choice) -> bool:
    if not discovered_signal or choice != Choice.UNSET:
        return false
    if next_choice != Choice.HELP_CREW and next_choice != Choice.REPAIR_BEACON:
        return false
    choice = next_choice
    return true

func complete_challenge() -> bool:
    if choice == Choice.UNSET:
        return false
    challenge_completed = true
    return true

func dock_payoff_key() -> String:
    if not challenge_completed:
        return ""
    match choice:
        Choice.HELP_CREW:
            return "crew_reconnected"
        Choice.REPAIR_BEACON:
            return "beacon_restored"
    return ""
