extends RefCounted
## Pure, asset-independent context prompt policy for the First Wake review slice.

const RANGE := 85.0

static func prompt(stage: String, signal_distance: float, ionia_distance: float, challenge_distance: float) -> String:
    match stage:
        "search":
            return "E: Inspect the signal" if signal_distance <= RANGE else "Find the labeled SIGNAL"
        "meet":
            return "E: Talk to Ionia" if ionia_distance <= RANGE else "Bring the clue to Ionia"
        "approach":
            return "E: Begin the signal challenge" if challenge_distance <= RANGE else "Cross the dock to CHALLENGE"
        "return":
            return "E: See what changed" if signal_distance <= RANGE else "Return to the SIGNAL"
        _:
            return ""
