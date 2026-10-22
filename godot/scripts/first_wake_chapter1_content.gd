extends RefCounted
## Packaged First Wake Chapter I content authority for native Godot migration.
## Source-aligned to the verified packaged runtime as of 2026-10-22.
## Keeps authored labels, first-contact dialogue, choice outcomes, objectives, and
## epilogue selection policy separate from the deterministic progression FSM.

const SIGNALS := {
    "harmonic_buoy": {"label": "Wakeheart Diagnostic", "contact_id": "engine_spirit", "contact_name": "Wakeheart"},
    "sky_lane_warning": {"label": "Dock Shield Warning", "contact_id": "corporate_salvager", "contact_name": "Verrick"},
    "below_frequency": {"label": "Lyra's Frequency Sketch", "contact_id": "child_prophet", "contact_name": "Lyra"},
}

const HAZARDS := {
    "sky_predator": {"label": "Loose Cargo Sweep", "stat": "grace"},
    "wind_shear": {"label": "Wind Shear", "stat": "grace"},
    "corporate_intercept": {"label": "Dock Authority Hold", "stat": "wits"},
}

const CONTACTS := {
    "elder_farmer": {
        "name": "Captain Ionia",
        "short_name": "Ionia",
        "title": "Captain of the Aureate Wake",
        "intro": [
            "\"The Aureate Wake can fly. That is not the mystery. The mystery is why some systems answer like a ship, and some answer like they are waiting for a crew I have not yet found.\"",
            "\"Captain Denith left me a vessel, a set of impossible notes, and the bad habit of telling the truth when a comforting lie would travel faster. So here it is: the dock shield is failing, the storm is early, and this ship may be our best shelter.\"",
            "\"Lyra has been able to coax responses from the Wake that my instruments only half-record. Useful responses. Incomplete ones. Then you came aboard, and the panels started disagreeing with their own limits.\"",
            "\"I do not need a miracle from you, Ender. I need honest hands, a clear head, and someone willing to stand beside Lyra while we find out what the Wake is actually hearing.\"",
            "\"If the storm reaches the berths before the colony shield steadies, the ships beside us take the shear first. We either leave early, hold dock, or ask the Wake to do something it has only hinted it can do.\"",
        ],
    },
    "engine_spirit": {
        "name": "Wakeheart",
        "short_name": "Wakeheart",
        "title": "Harmonic Console of the Aureate Wake",
        "intro": [
            "\"Primary lift: nominal. Solar intake: nominal. Shield lattice: partial. Crew resonance: unstable, increasing.\"",
            "\"Captain authority recognized. Lyra-pattern recognized. New harmonic variable recognized. Cross-response exceeds prior thresholds.\"",
            "\"Storm vectors converging on Wake Dock. Colony shield cycling below reliable tolerance. Adjacent berth stress rising.\"",
            "\"Directional projection routine available. Warning: lateral shield faces will weaken while forward umbrella is extended.\"",
            "\"Request: captain confirmation, reach stabilization, stranger-current consent.\"",
        ],
    },
    "child_prophet": {
        "name": "Lyra",
        "short_name": "Lyra",
        "title": "Frequency-Sensitive Dreamer of the Aureate Wake",
        "intro": [
            "\"The ship is not asleep. People keep saying that because it makes them feel better. It is awake in the way a hand is awake before it knows what it is reaching for.\"",
            "\"I can hear the shield lattice when it tries to open. It gets lonely halfway through.\"",
            "\"When Ionia gives an order, the Wake stands up straighter. When you touch the console, Ender, it stops bracing for the wrong kind of answer.\"",
            "\"The storm has teeth on the front edge. The little ships beside us are going to feel it first.\"",
            "\"If the Wake can make an umbrella, we should let it. I know that sounds impossible. It also sounds kind.\"",
        ],
    },
    "corporate_salvager": {
        "name": "Verrick",
        "short_name": "Verrick",
        "title": "Harbor Shield Officer",
        "intro": [
            "\"Verrick, harbor shield office. If you are with the Wake, tell your captain the colony shield is cycling dirty and I am out of polite ways to describe bad math.\"",
            "\"Procedure says every vessel clears dock before stormfall unless its berth shield is certified. Your berth shield is not certified. Your ship, however, keeps returning numbers my board insists are impossible.\"",
            "\"The two craft beside you are lighter than they should be and crewed by people who waited too long to undock. If shear hits from the east, they peel before you do.\"",
            "\"I do not care about legends. I care about vectors, hull stress, and whether somebody is about to turn a solvable weather event into paperwork with names on it.\"",
            "\"So make a choice: launch before the front arrives, stay and stabilize your own berth, or prove the Wake can throw a shield wide without tearing herself open.\"",
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

# Exact current packaged resolver priority. This intentionally preserves runtime
# behavior even though a nearby legacy comment implies a different desired
# "best ending" ordering. Resolve that design discrepancy separately.
const PACKAGED_EPILOGUE_PRIORITY: Array[String] = [
    "epiline_5",
    "epiline_1",
    "epiline_2",
    "epiline_3",
    "epiline_4",
    "epiline_6",
]

static func signal_label(signal_id: String) -> String:
    return str(SIGNALS.get(signal_id, {}).get("label", signal_id.replace("_", " ")))

static func hazard_label(hazard_id: String) -> String:
    return str(HAZARDS.get(hazard_id, {}).get("label", hazard_id.replace("_", " ")))

static func contact_name(contact_id: String) -> String:
    return str(CONTACTS.get(contact_id, {}).get("short_name", contact_id.replace("_", " ")))

static func contact_title(contact_id: String) -> String:
    return str(CONTACTS.get(contact_id, {}).get("title", ""))

static func contact_intro(contact_id: String) -> Array:
    var record: Dictionary = CONTACTS.get(contact_id, {})
    return record.get("intro", []).duplicate()

static func choice_record(path_id: String) -> Dictionary:
    return CHOICES.get(path_id, {}).duplicate(true)

static func choice_label(path_id: String) -> String:
    return str(CHOICES.get(path_id, {}).get("label", path_id))

static func choice_description(path_id: String) -> String:
    return str(CHOICES.get(path_id, {}).get("description", ""))

static func outcome_text(path_id: String, variant: String) -> String:
    var record: Dictionary = CHOICES.get(path_id, {})
    var outcomes: Dictionary = record.get("outcomes", {})
    return str(outcomes.get(variant, ""))

static func epilogue_record(epilogue_id: String) -> Dictionary:
    return EPILOGUES.get(epilogue_id, {}).duplicate(true)

static func resolve_epilogue_id(choice_path: String, hull_integrity: int, morale: int, engine_integration: int) -> String:
    # Mirrors the current packaged ordered trigger evaluation.
    if hull_integrity < 40 or morale < 20:
        return "epiline_5"
    if hull_integrity >= 60 and morale >= 45 and (engine_integration < 50 or choice_path == "path_a"):
        return "epiline_1"
    if hull_integrity >= 50 and engine_integration >= 70:
        return "epiline_2"
    if morale >= 40 and hull_integrity >= 40 and choice_path == "path_b":
        return "epiline_3"
    if choice_path == "path_c" and morale >= 60:
        return "epiline_4"
    if choice_path == "path_c" and engine_integration >= 60 and hull_integrity >= 50:
        return "epiline_6"
    return "epiline_5"

static func objective_text(snapshot: Dictionary) -> String:
    var stage := str(snapshot.get("stage", ""))

    if stage == "signal":
        var completed: Array = snapshot.get("signals_completed", [])
        var remaining_names: Array[String] = []
        for signal_id in SIGNALS.keys():
            if signal_id not in completed:
                remaining_names.append(str(SIGNALS[signal_id]["contact_name"]))
        return "Talk to marked: " + ", ".join(remaining_names) if not remaining_names.is_empty() else "Signal readings complete. Prepare for the storm crossing."

    if stage == "crossing":
        var completed: Array = snapshot.get("hazards_completed", [])
        var remaining := HAZARDS.size() - completed.size()
        return "Resolve orange hazard zones (%d remaining)." % remaining if remaining > 0 else "Crossing clear. Find the four marked contacts."

    if stage == "contact":
        var met: Array = snapshot.get("contacts_met", [])
        var remaining_names: Array[String] = []
        for contact_id in CONTACTS.keys():
            if contact_id not in met:
                remaining_names.append(contact_name(contact_id))
        return "Talk to marked: " + ", ".join(remaining_names) if not remaining_names.is_empty() else "All voices heard. Choose how the Wake answers the storm."

    if stage == "choice":
        return "Your choice is set. Watch how the Wake answers." if not str(snapshot.get("choice_path", "")).is_empty() else "Choose: press 1, 2, or 3."

    if stage == "wake":
        return "Return your attention to the Wake as the consequence resolves."

    if stage == "done":
        return "Chapter I complete."

    return "Find your footing aboard the Wake."
