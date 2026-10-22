extends RefCounted
## Native content authority for the packaged First Wake Chapter I slice.
## This migrates authored labels/dialogue/outcome/epilogue text into Godot while
## deliberately keeping epilogue SELECTION outside this layer until hull,
## morale and engine-integration state are migrated.

const SIGNAL_IDS: Array[String] = [
    "harmonic_buoy",
    "sky_lane_warning",
    "below_frequency",
]

const HAZARD_IDS: Array[String] = [
    "sky_predator",
    "wind_shear",
    "corporate_intercept",
]

const CONTACT_IDS: Array[String] = [
    "elder_farmer",
    "engine_spirit",
    "child_prophet",
    "corporate_salvager",
]

const CHOICE_IDS: Array[String] = [
    "path_a",
    "path_b",
    "path_c",
]

const SIGNALS := {
    "harmonic_buoy": {
        "label": "Wakeheart Diagnostic",
        "contact_id": "engine_spirit",
        "contact_name": "Wakeheart",
    },
    "sky_lane_warning": {
        "label": "Dock Shield Warning",
        "contact_id": "corporate_salvager",
        "contact_name": "Verrick",
    },
    "below_frequency": {
        "label": "Lyra's Frequency Sketch",
        "contact_id": "child_prophet",
        "contact_name": "Lyra",
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
        "full_name": "Captain Ionia",
        "title": "Captain of the Aureate Wake",
        "intro": [
            "\"The Aureate Wake can fly. That is not the mystery. The mystery is why some systems answer like a ship, and some answer like they are waiting for a crew I have not yet found.\"",
            "\"Captain Denith left me a vessel, a set of impossible notes, and the bad habit of telling the truth when a comforting lie would travel faster. So here it is: the dock shield is failing, the storm is early, and this ship may be our best shelter.\"",
            "\"Lyra has been able to coax responses from the Wake that my instruments only half-record. Useful responses. Incomplete ones. Then you came aboard, and the panels started disagreeing with their own limits.\"",
            "\"I do not need a miracle from you, Ender. I need honest hands, a clear head, and someone willing to stand beside Lyra while we find out what the Wake is actually hearing.\"",
            "\"If the storm reaches the berths before the colony shield steadies, the ships beside us take the shear first. We either leave early, hold dock, or ask the Wake to do something it has only hinted it can do.\"",
        ],
        "review_excerpt": "\"A captain can order a ship to leave. A crew decides whether leaving is the only kind of survival left.\"",
    },
    "engine_spirit": {
        "name": "Wakeheart",
        "full_name": "Wakeheart",
        "title": "Harmonic Console of the Aureate Wake",
        "intro": [
            "\"Primary lift: nominal. Solar intake: nominal. Shield lattice: partial. Crew resonance: unstable, increasing.\"",
            "\"Captain authority recognized. Lyra-pattern recognized. New harmonic variable recognized. Cross-response exceeds prior thresholds.\"",
            "\"Storm vectors converging on Wake Dock. Colony shield cycling below reliable tolerance. Adjacent berth stress rising.\"",
            "\"Directional projection routine available. Warning: lateral shield faces will weaken while forward umbrella is extended.\"",
            "\"Request: captain confirmation, reach stabilization, stranger-current consent.\"",
        ],
        "review_excerpt": "\"Awaiting stable chord.\"",
    },
    "child_prophet": {
        "name": "Lyra",
        "full_name": "Lyra",
        "title": "Frequency-Sensitive Dreamer of the Aureate Wake",
        "intro": [
            "\"The ship is not asleep. People keep saying that because it makes them feel better. It is awake in the way a hand is awake before it knows what it is reaching for.\"",
            "\"I can hear the shield lattice when it tries to open. It gets lonely halfway through.\"",
            "\"When Ionia gives an order, the Wake stands up straighter. When you touch the console, Ender, it stops bracing for the wrong kind of answer.\"",
            "\"The storm has teeth on the front edge. The little ships beside us are going to feel it first.\"",
            "\"If the Wake can make an umbrella, we should let it. I know that sounds impossible. It also sounds kind.\"",
        ],
        "review_excerpt": "\"If we leave now, we live smaller. If we stay, we might learn what the Wake thinks shelter means.\"",
    },
    "corporate_salvager": {
        "name": "Verrick",
        "full_name": "Verrick",
        "title": "Harbor Shield Officer",
        "intro": [
            "\"Verrick, harbor shield office. If you are with the Wake, tell your captain the colony shield is cycling dirty and I am out of polite ways to describe bad math.\"",
            "\"Procedure says every vessel clears dock before stormfall unless its berth shield is certified. Your berth shield is not certified. Your ship, however, keeps returning numbers my board insists are impossible.\"",
            "\"The two craft beside you are lighter than they should be and crewed by people who waited too long to undock. If shear hits from the east, they peel before you do.\"",
            "\"I do not care about legends. I care about vectors, hull stress, and whether somebody is about to turn a solvable weather event into paperwork with names on it.\"",
            "\"So make a choice: launch before the front arrives, stay and stabilize your own berth, or prove the Wake can throw a shield wide without tearing herself open.\"",
        ],
        "review_excerpt": "\"Choose something you can live with after the sky clears.\"",
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
        "selection_dependency": "hullIntegrity < 40 OR morale < 20",
    },
    "epiline_1": {
        "name": "The Clear Departure",
        "text": "The Wake beats the storm into open sky. You are alive, the ship is steady, and the unanswered shield alert follows you like a question waiting for better weather.",
        "selection_dependency": "hullIntegrity >= 60 AND morale >= 45 AND (engineIntegration < 50 OR path_a)",
    },
    "epiline_2": {
        "name": "The Shield-Bound",
        "text": "The Wake's shield lattice remembers the three of you. After stormfall, the console keeps offering patterns no captain has seen since Denith.",
        "selection_dependency": "hullIntegrity >= 50 AND engineIntegration >= 70",
    },
    "epiline_3": {
        "name": "Verrick's Weather Ledger",
        "text": "Verrick files the exception with no jokes in the margins. The colony shield held because the Wake stayed, and official records become a little less certain about what counts as impossible.",
        "selection_dependency": "morale >= 40 AND hullIntegrity >= 40 AND path_b",
    },
    "epiline_4": {
        "name": "Lyra's Wide Wing",
        "text": "Lyra draws the storm afterward: one bright wing, three small ships, and a crew shaped like a chord. She does not know what it means yet. She only knows it happened.",
        "selection_dependency": "path_c AND morale >= 60",
    },
    "epiline_6": {
        "name": "The First Chord",
        "text": "The umbrella vector becomes the first real secret the Wake gives back. Not a prophecy. Not a chosen one. A crew, briefly aligned, and a ship that can do more when it is understood.",
        "selection_dependency": "path_c AND engineIntegration >= 60 AND hullIntegrity >= 50",
    },
}

const EPILOGUE_IDS: Array[String] = [
    "epiline_5",
    "epiline_1",
    "epiline_2",
    "epiline_3",
    "epiline_4",
    "epiline_6",
]

# Explicitly a REVIEW fixture. This is not the packaged production resolver.
# The production resolver depends on hull/morale/engine-integration values that
# are intentionally not invented in the migration FSM.
const REVIEW_EPILOGUE_FIXTURES := {
    "path_a": "epiline_1",
    "path_b": "epiline_3",
    "path_c": "epiline_6",
}

static func signal_label(signal_id: String) -> String:
    var row: Dictionary = SIGNALS.get(signal_id, {})
    return str(row.get("label", signal_id))

static func signal_contact_name(signal_id: String) -> String:
    var row: Dictionary = SIGNALS.get(signal_id, {})
    return str(row.get("contact_name", signal_id))

static func signal_contact_id(signal_id: String) -> String:
    var row: Dictionary = SIGNALS.get(signal_id, {})
    return str(row.get("contact_id", ""))

static func hazard_label(hazard_id: String) -> String:
    var row: Dictionary = HAZARDS.get(hazard_id, {})
    return str(row.get("label", hazard_id))

static func contact_name(contact_id: String) -> String:
    var row: Dictionary = CONTACTS.get(contact_id, {})
    return str(row.get("name", contact_id))

static func contact_title(contact_id: String) -> String:
    var row: Dictionary = CONTACTS.get(contact_id, {})
    return str(row.get("title", ""))

static func contact_intro(contact_id: String) -> Array:
    var row: Dictionary = CONTACTS.get(contact_id, {})
    var lines: Array = row.get("intro", [])
    return lines.duplicate()

static func contact_review_excerpt(contact_id: String) -> String:
    var row: Dictionary = CONTACTS.get(contact_id, {})
    return str(row.get("review_excerpt", ""))

static func choice_label(path_id: String) -> String:
    var row: Dictionary = CHOICES.get(path_id, {})
    return str(row.get("label", path_id))

static func choice_description(path_id: String) -> String:
    var row: Dictionary = CHOICES.get(path_id, {})
    return str(row.get("description", ""))

static func choice_outcome(path_id: String, variant: String) -> String:
    var row: Dictionary = CHOICES.get(path_id, {})
    var outcomes: Dictionary = row.get("outcomes", {})
    return str(outcomes.get(variant, ""))

static func has_epilogue(epilogue_id: String) -> bool:
    return epilogue_id in EPILOGUES

static func epilogue_name(epilogue_id: String) -> String:
    var row: Dictionary = EPILOGUES.get(epilogue_id, {})
    return str(row.get("name", epilogue_id))

static func epilogue_text(epilogue_id: String) -> String:
    var row: Dictionary = EPILOGUES.get(epilogue_id, {})
    return str(row.get("text", ""))

static func review_epilogue_fixture(path_id: String) -> String:
    return str(REVIEW_EPILOGUE_FIXTURES.get(path_id, ""))

static func objective_text(chapter: Variant) -> String:
    match str(chapter.stage_key()):
        "signal":
            var remaining: Array[String] = []
            for signal_id in SIGNAL_IDS:
                if signal_id not in chapter.completed_signals:
                    remaining.append(signal_contact_name(signal_id))
            if not remaining.is_empty():
                return "Talk to marked: " + ", ".join(remaining)
            return "Signal readings complete. Prepare for the storm crossing."
        "crossing":
            var hazards_left: int = HAZARD_IDS.size() - chapter.completed_hazards.size()
            if hazards_left > 0:
                return "Resolve orange hazard zones (" + str(hazards_left) + " remaining)."
            return "Crossing clear. Find the four marked contacts."
        "contact":
            var contacts_left: Array[String] = []
            for contact_id in CONTACT_IDS:
                if contact_id not in chapter.contacts_met:
                    contacts_left.append(contact_name(contact_id))
            if not contacts_left.is_empty():
                return "Talk to marked: " + ", ".join(contacts_left)
            return "All voices heard. Choose how the Wake answers the storm."
        "choice":
            return "Choose: press 1, 2, or 3."
        "wake":
            return "Return your attention to the Wake as the consequence resolves."
        "done":
            return "Chapter I complete."
    return "Find your footing aboard the Wake."
