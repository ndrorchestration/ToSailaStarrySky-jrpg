extends RefCounted
## Pure, asset-independent context prompt policy for the First Wake review slice.

const RANGE := 85.0

static func prompt(stage: String, signal_distance: float, ionia_distance: float, challenge_distance: float, interact_label: String = "E") -> String:
    match stage:
        "search":
            return interact_label + ": Inspect the signal" if signal_distance <= RANGE else "Find the labeled SIGNAL"
        "meet":
            return interact_label + ": Talk to Ionia" if ionia_distance <= RANGE else "Bring the clue to Ionia"
        "approach":
            return interact_label + ": Begin the signal challenge" if challenge_distance <= RANGE else "Cross the dock to CHALLENGE"
        "return":
            return interact_label + ": See what changed" if signal_distance <= RANGE else "Return to the SIGNAL"
        _:
            return ""
