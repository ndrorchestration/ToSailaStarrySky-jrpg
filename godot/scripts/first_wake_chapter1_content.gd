extends RefCounted
## Native Chapter I content authority migrated from the verified packaged runtime.
## This file preserves current packaged text/rules for migration parity. It does
## not independently elevate that content to final canon or production approval.

const PACKAGED_SOURCE_SHA := "b2a1d7774168b3f7ef6c914f262137fd8b5fd4bb"

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
    },
    "sky_lane_warning": {
        "label": "Dock Shield Warning",
        "contact_id": "corporate_salvager",
    },
    "below_frequency": {
        "label": "Lyra's Frequency Sketch",
        "contact_id": "child_prophet",
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
        "name": "Captain Ionia",
        "title": "Captain of the Aureate Wake",
        "intro": [
            "\"The Aureate Wake can fly. That is not the mystery. The mystery is why some systems answer like a ship, and some answer like they are waiting for a crew I have not yet found.\"",
            "\"Captain Denith left me a vessel, a set of impossible notes, and the bad habit of telling the truth when a comforting lie would travel faster. So here it is: the dock shield is failing, the storm is early, and this ship may be our best shelter.\"",
            "\"Lyra has been able to coax responses from the Wake that my instruments only half-record. Useful responses. Incomplete ones. Then you came aboard, and the panels started disagreeing with their own limits.\"",
            "\"I do not need a miracle from you, Ender. I need honest hands, a clear head, and someone willing to stand beside Lyra while we find out what the Wake is actually hearing.\"",
            "\"If the storm reaches the berths before the colony shield steadies, the ships beside us take the shear first. We either leave early, hold dock, or ask the Wake to do something it has only hinted it can do.\"",
        ],
        "class_ender": [
            "\"Your hands are on the rigging. You are not a navigator or a captain, and that may be why the ship is listening differently. You fix from inside the problem.\"",
            "\"The frequencies settle when you cross the deck. Not enough for a doctrine. Enough for me to notice.\"",
            "\"Do not mistake this for destiny. Ships do not need worship. They need crews who can hear one another under pressure.\"",
        ],
        "class_farmer": [
            "\"Navigation teaches the same lesson every watch: the sky tells the truth if you know how to read it. You notice wrongness before most people can name it. I can work with that.\"",
            "\"Captain Denith taught me to trust instruments, weather, and people in that order only when the first two agree. Today, none of them agree cleanly.\"",
        ],
        "generic_follow": [
            "\"Check the dock reports, then the shield console. Meaning can wait until the shielding holds.\"",
        ],
        "deep": [
            "\"You have heard Lyra, the Wakeheart, and Verrick. None of them are wrong. That is what makes command unpleasant.\"",
            "\"A captain can order a ship to leave. A crew decides whether leaving is the only kind of survival left.\"",
            "\"If the Wake answers, it will not be because one person is special. It will be because, for one dangerous moment, we finally become legible to one another.\"",
        ],
    },
    "engine_spirit": {
        "name": "Wakeheart",
        "title": "Harmonic Console of the Aureate Wake",
        "intro": [
            "\"Primary lift: nominal. Solar intake: nominal. Shield lattice: partial. Crew resonance: unstable, increasing.\"",
            "\"Captain authority recognized. Lyra-pattern recognized. New harmonic variable recognized. Cross-response exceeds prior thresholds.\"",
            "\"Storm vectors converging on Wake Dock. Colony shield cycling below reliable tolerance. Adjacent berth stress rising.\"",
            "\"Directional projection routine available. Warning: lateral shield faces will weaken while forward umbrella is extended.\"",
            "\"Request: captain confirmation, reach stabilization, stranger-current consent.\"",
        ],
        "class_ender": [
            "\"Ender-pattern produces nonstandard agreement across helm, reach, and hull. Diagnostic category unavailable.\"",
            "\"Your adjustments do not add power. They reduce disagreement.\"",
            "\"If command is given, shield geometry can widen beyond the Wake's own silhouette. Survival probability improves for adjacent berths.\"",
        ],
        "class_witch": [
            "\"Listening pattern recognized. Harmonic access improves when observation is gentle.\"",
            "\"The Wake does not require force. It requires accord.\"",
        ],
        "generic_follow": [
            "\"Awaiting stable chord.\"",
        ],
        "deep": [
            "\"Earlier crews produced flight. Current pattern suggests shelter.\"",
            "\"Future capability cannot be extrapolated from present crew state. Additional voices may alter combat response, environmental envelope, and lane access.\"",
            "\"Auroral-lane topology remains inaccessible. Requirement unknown. Crew-state insufficient.\"",
        ],
    },
    "child_prophet": {
        "name": "Lyra",
        "title": "Frequency-Sensitive Dreamer of the Aureate Wake",
        "intro": [
            "\"The ship is not asleep. People keep saying that because it makes them feel better. It is awake in the way a hand is awake before it knows what it is reaching for.\"",
            "\"I can hear the shield lattice when it tries to open. It gets lonely halfway through.\"",
            "\"When Ionia gives an order, the Wake stands up straighter. When you touch the console, Ender, it stops bracing for the wrong kind of answer.\"",
            "\"The storm has teeth on the front edge. The little ships beside us are going to feel it first.\"",
            "\"If the Wake can make an umbrella, we should let it. I know that sounds impossible. It also sounds kind.\"",
        ],
        "class_ender": [
            "\"You hear it too, just lower than I do. Like something green under a floorboard.\"",
            "\"Ionia is the helm. I am the reach. You are... I do not know yet. The place where the answer says yes, maybe.\"",
            "\"Do not tell the ship what it is. Ask what it can hold.\"",
        ],
        "class_witch": [
            "\"The frequencies get shy when people stare at them. Listen sideways.\"",
            "\"The Wake hums better when nobody is trying to win an argument with it.\"",
        ],
        "generic_follow": [
            "\"The storm is closer. The ship knows. I think it wants us to notice the same thing at the same time.\"",
        ],
        "deep": [
            "\"I heard the wide shield before I saw the alert. It sounded like opening both hands.\"",
            "\"If we leave now, we live smaller. If we stay, we might learn what the Wake thinks shelter means.\"",
            "\"I am scared. That does not make the listening wrong.\"",
        ],
    },
    "corporate_salvager": {
        "name": "Verrick",
        "title": "Harbor Shield Officer",
        "intro": [
            "\"Verrick, harbor shield office. If you are with the Wake, tell your captain the colony shield is cycling dirty and I am out of polite ways to describe bad math.\"",
            "\"Procedure says every vessel clears dock before stormfall unless its berth shield is certified. Your berth shield is not certified. Your ship, however, keeps returning numbers my board insists are impossible.\"",
            "\"The two craft beside you are lighter than they should be and crewed by people who waited too long to undock. If shear hits from the east, they peel before you do.\"",
            "\"I do not care about legends. I care about vectors, hull stress, and whether somebody is about to turn a solvable weather event into paperwork with names on it.\"",
            "\"So make a choice: launch before the front arrives, stay and stabilize your own berth, or prove the Wake can throw a shield wide without tearing herself open.\"",
        ],
        "class_corporate": [
            "\"You understand systems, so here is the system: authority hates uncertainty, weather exploits delay, and captains hate being told both at once.\"",
            "\"If you can give me a stable projection number, I can keep the dock from ordering you out.\"",
            "\"A clean evacuation is a victory. A heroic mess is still a mess.\"",
        ],
        "class_ender": [
            "\"You are the new variable? Good. Variables are annoying, but sometimes they are where the answer is hiding.\"",
            "\"If your ledger can track shield draw, track it now. I need proof before the dock board panics.\"",
            "\"Do not sell me poetry, Ender. Give me a number I can defend and a reason not to clear this berth.\"",
        ],
        "generic_follow": [
            "\"My hold order stands until the stormfront crosses the outer pylons. After that, math gets rude.\"",
        ],
        "deep": [
            "\"I have watched captains gamble with other people's hulls and call it vision. I have also watched cautious people preserve a rule while a person died beside it.\"",
            "\"If the Wake can shield the neighboring berths, I will sign the exception myself.\"",
            "\"Just understand the cost. Push every shield face forward and your sides go soft. One bad cross-gust and the heroic answer becomes an expensive wreck.\"",
            "\"Choose something you can live with after the sky clears.\"",
        ],
    },
}

const JOURNAL := {
    "signal": "Ender boards the Aureate Wake as Wake Dock prepares for stormfall. The ship flies, but its deeper shield responses need the right crew to become clear.",
    "crossing": "Three dockside hazards stand between the crew and shield readiness. Each one tests whether the Wake can protect more than itself.",
    "contact": "Ender hears Ionia, Lyra, the Wakeheart, and Verrick. Each voice names a different cost of waiting, leaving, or reaching wider.",
    "choice": "The storm is turning. The crew must choose whether to leave early, hold dock, or project the Wake's shield across the neighboring berths.",
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

# The resolver intentionally preserves the current packaged first-match order.
# This is parity behavior, not a claim that the ordering is the final design.
const EPILOGUE_ORDER: Array[String] = [
    "epiline_5",
    "epiline_1",
    "epiline_2",
    "epiline_3",
    "epiline_4",
    "epiline_6",
]

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

func signal_label(signal_id: String) -> String:
    if not SIGNALS.has(signal_id):
        return signal_id.replace("_", " ")
    return str(SIGNALS[signal_id]["label"])

func signal_contact_id(signal_id: String) -> String:
    if not SIGNALS.has(signal_id):
        return ""
    return str(SIGNALS[signal_id]["contact_id"])

func hazard_label(hazard_id: String) -> String:
    if not HAZARDS.has(hazard_id):
        return hazard_id.replace("_", " ")
    return str(HAZARDS[hazard_id]["label"])

func contact_name(contact_id: String) -> String:
    if not CONTACTS.has(contact_id):
        return contact_id.replace("_", " ")
    return str(CONTACTS[contact_id]["name"])

func contact_title(contact_id: String) -> String:
    if not CONTACTS.has(contact_id):
        return ""
    return str(CONTACTS[contact_id]["title"])

func contact_dialogue(contact_id: String, batch: String = "intro") -> Array:
    if not CONTACTS.has(contact_id):
        return []
    var contact: Dictionary = CONTACTS[contact_id]
    if not contact.has(batch):
        return []
    return Array(contact[batch]).duplicate()

func choice(path_id: String) -> Dictionary:
    if not CHOICES.has(path_id):
        return {}
    return Dictionary(CHOICES[path_id]).duplicate(true)

func choice_label(path_id: String) -> String:
    var data := choice(path_id)
    return "" if data.is_empty() else str(data["label"])

func choice_description(path_id: String) -> String:
    var data := choice(path_id)
    return "" if data.is_empty() else str(data["description"])

func choice_outcome(path_id: String, variant: String) -> String:
    var data := choice(path_id)
    if data.is_empty():
        return ""
    var outcomes: Dictionary = data["outcomes"]
    return str(outcomes.get(variant, ""))

func epilogue(epilogue_id: String) -> Dictionary:
    if not EPILOGUES.has(epilogue_id):
        return {}
    var data := Dictionary(EPILOGUES[epilogue_id]).duplicate(true)
    data["id"] = epilogue_id
    return data

func objective_for(chapter) -> String:
    match chapter.stage_key():
        "signal":
            var remaining_signal_contacts: Array[String] = []
            for signal_id in SIGNAL_IDS:
                if signal_id in chapter.completed_signals:
                    continue
                remaining_signal_contacts.append(contact_name(signal_contact_id(signal_id)).replace("Captain ", ""))
            if not remaining_signal_contacts.is_empty():
                return "Talk to marked: " + ", ".join(remaining_signal_contacts)
            return "Signal readings complete. Prepare for the storm crossing."
        "crossing":
            var remaining_hazards: Array[String] = []
            for hazard_id in HAZARD_IDS:
                if hazard_id not in chapter.completed_hazards:
                    remaining_hazards.append(hazard_label(hazard_id))
            if not remaining_hazards.is_empty():
                return "Resolve orange hazard zones (%d remaining)." % remaining_hazards.size()
            return "Crossing clear. Find the four marked contacts."
        "contact":
            var remaining_contacts: Array[String] = []
            for contact_id in CONTACT_IDS:
                if contact_id not in chapter.contacts_met:
                    remaining_contacts.append(contact_name(contact_id).replace("Captain ", ""))
            if not remaining_contacts.is_empty():
                return "Talk to marked: " + ", ".join(remaining_contacts)
            return "All voices heard. Choose how the Wake answers the storm."
        "choice":
            return "Choose how the Wake answers the storm."
        "wake":
            return "Return your attention to the Wake as the consequence resolves."
        "done":
            return "Chapter I complete."
    return ""

func resolve_epilogue(path_id: String, hull_integrity: int, morale: int, engine_integration: int) -> Dictionary:
    for epilogue_id in EPILOGUE_ORDER:
        var matches := false
        match epilogue_id:
            "epiline_5":
                matches = hull_integrity < 40 or morale < 20
            "epiline_1":
                matches = hull_integrity >= 60 and morale >= 45 and (engine_integration < 50 or path_id == "path_a")
            "epiline_2":
                matches = hull_integrity >= 50 and engine_integration >= 70
            "epiline_3":
                matches = morale >= 40 and hull_integrity >= 40 and path_id == "path_b"
            "epiline_4":
                matches = path_id == "path_c" and morale >= 60
            "epiline_6":
                matches = path_id == "path_c" and engine_integration >= 60 and hull_integrity >= 50
        if matches:
            return epilogue(epilogue_id)
    return epilogue("epiline_5")
