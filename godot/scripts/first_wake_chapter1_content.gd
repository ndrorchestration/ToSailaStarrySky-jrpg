extends RefCounted
## Native Chapter I content authority for migration review.
## Mirrors packaged player-facing labels, selected authored contact lines,
## choice outcomes, and current legacy epilogue ordering without silently
## repairing legacy stat/progression inconsistencies.

const SIGNALS := {
    "harmonic_buoy": {
        "label": "Wakeheart Diagnostic",
        "contact_id": "engine_spirit",
        "contact_name": "Wakeheart",
        "line": "Primary lift: nominal. Solar intake: nominal. Shield lattice: partial. Crew resonance: unstable, increasing.",
    },
    "sky_lane_warning": {
        "label": "Dock Shield Warning",
        "contact_id": "corporate_salvager",
        "contact_name": "Verrick",
        "line": "If you are with the Wake, tell your captain the colony shield is cycling dirty and I am out of polite ways to describe bad math.",
    },
    "below_frequency": {
        "label": "Lyra's Frequency Sketch",
        "contact_id": "child_prophet",
        "contact_name": "Lyra",
        "line": "The ship is not asleep. It is awake in the way a hand is awake before it knows what it is reaching for.",
    },
}

const HAZARDS := {
    "sky_predator": {
        "label": "Loose Cargo Sweep",
        "stat": "grace",
    },
    "wind_shear": {
        "label": "Wind Shear",
        "stat": "grace",
    },
    "corporate_intercept": {
        "label": "Dock Authority Hold",
        "stat": "wits",
    },
}

const CONTACTS := {
    "elder_farmer": {
        "name": "Ionia",
        "title": "Captain of the Aureate Wake",
        "representative_index": 3,
        "intro": [
            "The Aureate Wake can fly. That is not the mystery. The mystery is why some systems answer like a ship, and some answer like they are waiting for a crew I have not yet found.",
            "Captain Denith left me a vessel, a set of impossible notes, and the bad habit of telling the truth when a comforting lie would travel faster. So here it is: the dock shield is failing, the storm is early, and this ship may be our best shelter.",
            "Lyra has been able to coax responses from the Wake that my instruments only half-record. Useful responses. Incomplete ones. Then you came aboard, and the panels started disagreeing with their own limits.",
            "I do not need a miracle from you, Ender. I need honest hands, a clear head, and someone willing to stand beside Lyra while we find out what the Wake is actually hearing.",
            "If the storm reaches the berths before the colony shield steadies, the ships beside us take the shear first. We either leave early, hold dock, or ask the Wake to do something it has only hinted it can do.",
        ],
    },
    "engine_spirit": {
        "name": "Wakeheart",
        "title": "Harmonic Console of the Aureate Wake",
        "representative_index": 4,
        "intro": [
            "Primary lift: nominal. Solar intake: nominal. Shield lattice: partial. Crew resonance: unstable, increasing.",
            "Captain authority recognized. Lyra-pattern recognized. New harmonic variable recognized. Cross-response exceeds prior thresholds.",
            "Storm vectors converging on Wake Dock. Colony shield cycling below reliable tolerance. Adjacent berth stress rising.",
            "Directional projection routine available. Warning: lateral shield faces will weaken while forward umbrella is extended.",
            "Request: captain confirmation, reach stabilization, stranger-current consent.",
        ],
    },
    "child_prophet": {
        "name": "Lyra",
        "title": "Frequency-Sensitive Dreamer of the Aureate Wake",
        "representative_index": 4,
        "intro": [
            "The ship is not asleep. People keep saying that because it makes them feel better. It is awake in the way a hand is awake before it knows what it is reaching for.",
            "I can hear the shield lattice when it tries to open. It gets lonely halfway through.",
            "When Ionia gives an order, the Wake stands up straighter. When you touch the console, Ender, it stops bracing for the wrong kind of answer.",
            "The storm has teeth on the front edge. The little ships beside us are going to feel it first.",
            "If the Wake can make an umbrella, we should let it. I know that sounds impossible. It also sounds kind.",
        ],
    },
    "corporate_salvager": {
        "name": "Verrick",
        "title": "Harbor Shield Officer",
        "representative_index": 4,
        "intro": [
            "Verrick, harbor shield office. If you are with the Wake, tell your captain the colony shield is cycling dirty and I am out of polite ways to describe bad math.",
            "Procedure says every vessel clears dock before stormfall unless its berth shield is certified. Your berth shield is not certified. Your ship, however, keeps returning numbers my board insists are impossible.",
            "The two craft beside you are lighter than they should be and crewed by people who waited too long to undock. If shear hits from the east, they peel before you do.",
            "I do not care about legends. I care about vectors, hull stress, and whether somebody is about to turn a solvable weather event into paperwork with names on it.",
            "So make a choice: launch before the front arrives, stay and stabilize your own berth, or prove the Wake can throw a shield wide without tearing herself open.",
        ],
    },
}

const CHOICES := {
    "path_a": {
        "label": "Leave early / Beat the storm",
        "description": "Launch before the front arrives. Save the Wake by refusing the wider risk.",
        "outcomes": {
            "10+": "The Wake clears the dock ahead of the storm. Ionia keeps everyone alive, but the berths behind you vanish into weather static. Lyra watches the empty horizon and says the ship wanted to try.",
            "7-9": "The Wake launches late and takes shear along the port wing. You survive, but the flight is rough and the dock calls after you until the signal breaks.",
        },
    },
    "path_b": {
        "label": "Hold dock / Stabilize the colony shield",
        "description": "Stay moored and route power into the local shield grid.",
        "outcomes": {
            "10+": "The colony shield steadies long enough for the neighboring crews to brace. The Wake remains safe, though the deeper alert on the console fades unanswered.",
            "7-9": "The local shield catches, but only in pulses. The Wake holds her berth while smaller craft take damage at the edge of the umbrella.",
        },
    },
    "path_c": {
        "label": "Project shield / Cover the berths",
        "description": "Let the Wake front-load her shield into a wide stormward umbrella.",
        "outcomes": {
            "10+": "The Wake turns her shield like a bright wing into the storm. For one impossible minute, three vessels survive under one shelter. Ionia, Lyra, and Ender feel the ship answer as if a hidden circuit finally closed.",
            "7-9": "The umbrella holds, but the Wake pays for it. Side shielding thins, alarms bloom, and everyone aboard learns that miracles still need engineering.",
        },
    },
}

const EPILOGUES := {
    "epiline_5": {
        "name": "The Weather-Bruised",
        "text": "The Wake survives stormfall damaged and shaken. The crew has proof that the ship can answer them, but also proof that courage without balance has a cost.",
    },
    "epiline_1": {
        "name": "The Clear Departure",
        "text": "The Wake beats the storm into open sky. You are alive, the ship is steady, and the unanswered shield alert follows you like a question waiting for better weather.",
    },
    "epiline_2": {
        "name": "The Shield-Bound",
        "text": "The Wake's shield lattice remembers the three of you. After stormfall, the console keeps offering patterns no captain has seen since Denith.",
    },
    "epiline_3": {
        "name": "Verrick's Weather Ledger",
        "text": "Verrick files the exception with no jokes in the margins. The colony shield held because the Wake stayed, and official records become a little less certain about what counts as impossible.",
    },
    "epiline_4": {
        "name": "Lyra's Wide Wing",
        "text": "Lyra draws the storm afterward: one bright wing, three small ships, and a crew shaped like a chord. She does not know what it means yet. She only knows it happened.",
    },
    "epiline_6": {
        "name": "The First Chord",
        "text": "The umbrella vector becomes the first real secret the Wake gives back. Not a prophecy. Not a chosen one. A crew, briefly aligned, and a ship that can do more when it is understood.",
    },
}

static func signal_label(signal_id: String) -> String:
    return str(SIGNALS.get(signal_id, {}).get("label", signal_id.replace("_", " ")))

static func signal_line(signal_id: String) -> String:
    return str(SIGNALS.get(signal_id, {}).get("line", ""))

static func hazard_label(hazard_id: String) -> String:
    return str(HAZARDS.get(hazard_id, {}).get("label", hazard_id.replace("_", " ")))

static func contact_name(contact_id: String) -> String:
    return str(CONTACTS.get(contact_id, {}).get("name", contact_id.replace("_", " ")))

static func contact_intro(contact_id: String) -> Array[String]:
    var raw: Array = CONTACTS.get(contact_id, {}).get("intro", [])
    var lines: Array[String] = []
    for line in raw:
        lines.append(str(line))
    return lines

static func contact_line(contact_id: String) -> String:
    var lines := contact_intro(contact_id)
    if lines.is_empty():
        return ""
    var index := int(CONTACTS.get(contact_id, {}).get("representative_index", 0))
    if index < 0 or index >= lines.size():
        index = 0
    return lines[index]

static func choice_label(path_id: String) -> String:
    return str(CHOICES.get(path_id, {}).get("label", path_id))

static func choice_description(path_id: String) -> String:
    return str(CHOICES.get(path_id, {}).get("description", ""))

static func choice_outcome(path_id: String, variant: String) -> String:
    var choice: Dictionary = CHOICES.get(path_id, {})
    var outcomes: Dictionary = choice.get("outcomes", {})
    return str(outcomes.get(variant, ""))

static func epilogue(epilogue_id: String) -> Dictionary:
    var data: Dictionary = EPILOGUES.get(epilogue_id, {})
    if data.is_empty():
        return {}
    return {
        "id": epilogue_id,
        "name": str(data.get("name", epilogue_id)),
        "text": str(data.get("text", "")),
    }

static func resolve_legacy_epilogue(
    choice_path: String,
    hull_integrity: int,
    morale: int,
    engine_integration: int
) -> Dictionary:
    # Mirrors the current packaged resolver's first-match ordering exactly.
    # This intentionally exposes, rather than repairs, the legacy default-stat
    # behavior where engineIntegration starts at zero and is not choice-mutated.
    if hull_integrity < 40 or morale < 20:
        return epilogue("epiline_5")
    if hull_integrity >= 60 and morale >= 45 and (engine_integration < 50 or choice_path == "path_a"):
        return epilogue("epiline_1")
    if hull_integrity >= 50 and engine_integration >= 70:
        return epilogue("epiline_2")
    if morale >= 40 and hull_integrity >= 40 and choice_path == "path_b":
        return epilogue("epiline_3")
    if choice_path == "path_c" and morale >= 60:
        return epilogue("epiline_4")
    if choice_path == "path_c" and engine_integration >= 60 and hull_integrity >= 50:
        return epilogue("epiline_6")
    return epilogue("epiline_5")

static func objective_text(stage_key: String) -> String:
    match stage_key:
        "signal":
            return "Talk to marked: Wakeheart, Verrick, Lyra."
        "crossing":
            return "Resolve all 3 marked crossing hazards."
        "contact":
            return "Talk to Ionia; Wakeheart, Lyra, and Verrick carry forward."
        "choice":
            return "Choose how the Wake answers the storm."
        "wake":
            return "Return to Ionia as the consequence resolves."
        "done":
            return "Chapter I complete."
    return ""
