extends Node2D
## Chapter I REHEARSAL ONLY: Lyra/Talen safe-reunion dialogue and three-party
## working fuel hypothesis. A QA fixture stands in for OPEN geography.
## Cannot automatically authorize rescue, replace the chapter save schema,
## or permit any combat ability, finished fuel formula or production travel.

const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")

const INTRO_LINES: Array[String] = [
    "LYRA: Ionia. I heard there was trouble. Are you and the new engineer safe?",
    "IONIA: The Wake settled safely onto the water. Her engines are offline.",
    "LYRA: You landed in the sea. That's a very captainly account of it.",
    "TALEN: Does the ship swim?",
    "IONIA: She floats. And yes, the crew is safe.",
    "ENDER: I'm Ender. The phase drift and containment strain appeared in flight.",
    "LYRA: I'm Lyra, and this is Talen. I'll help you compare what we know.",
]
const CLUE_LINES := {
    "phase_readings": "ENDER / PHASE CHART — OBSERVED: alignment drifted under working load, not during static inspection.",
    "depleted_reserve": "IONIA / RESERVE LOG — OBSERVED: the specialized usable reserve is depleted. Denith's handling rules remain incomplete.",
    "lyra_observation": "LYRA / LISTENING — OBSERVED: one note seems unable to settle when the regulator changes. Cause not established.",
}
const CLUE_KEYS: Array[String] = ["phase_readings", "depleted_reserve", "lyra_observation"]
const THEORY_LINES: Array[String] = [
    "ENDER: Phase drift, containment strain and reserve loss may be connected.",
    "IONIA: Denith said the Wake could not fly on power alone. I don't know the mechanism.",
    "LYRA: The change I hear may be relevant, but it doesn't prove what the fuel contains.",
    "ENDER: Working hypothesis: the specialized fuel may also help maintain alignment. Not a formula.",
]

var opening
var phase: String = "unconfigured"
var qa_recovery_fixture_admitted: bool = false
var dialogue_cursor: int = 0
var pending_clue: String = ""
var headline: Label
var subtitle: Label
var objective: Label
var scene_dialogue: Label
var footer: Label
var party: Label

func configure_from_postflight(flight: Node) -> bool:
    if is_inside_tree() or flight == null or opening != null:
        return false
    if not flight.has_method("review_snapshot"):
        return false
    var snapshot: Dictionary = flight.review_snapshot()
    if str(snapshot.get("story_step", "")) != "postflight_diagnosis":
        return false
    if not bool(snapshot.get("actual_2d_area_contact_observed", false)):
        return false
    if not bool(snapshot.get("stable_buoyant_hull_observed", false)):
        return false
    if not bool(snapshot.get("postflight_reserve_observed", false)):
        return false
    if snapshot.get("party", []) != ["ender", "ionia"]:
        return false
    if not flight.opening.has_method("introduce_lyra_and_talen"):
        return false
    opening = flight.opening
    phase = "recovery_unverified"
    return true

func authorize_qa_reunion_fixture(proof: Dictionary) -> bool:
    # Intentionally no in-game control can call this. It does NOT attest to a
    # real voyage, approved coastline, port, rescue method or family position.
    if phase != "recovery_unverified" or qa_recovery_fixture_admitted:
        return false
    var exact_keys := ["source", "fixture_only", "crew_safe", "family_contact_safe"]
    if proof.keys().size() != exact_keys.size():
        return false
    for key in exact_keys:
        if not proof.has(key):
            return false
    if str(proof["source"]) != "isolated_qa_fixture":
        return false
    if typeof(proof["fixture_only"]) != TYPE_BOOL or not proof["fixture_only"]:
        return false
    if typeof(proof["crew_safe"]) != TYPE_BOOL or not proof["crew_safe"]:
        return false
    if typeof(proof["family_contact_safe"]) != TYPE_BOOL or not proof["family_contact_safe"]:
        return false
    qa_recovery_fixture_admitted = true
    phase = "reunion_ready"
    _refresh()
    return true

func _ready() -> void:
    InputPolicy.ensure_defaults()
    var layer := CanvasLayer.new()
    layer.name = "ReviewOnlyReunionUI"
    add_child(layer)
    headline = _make_label(layer, Vector2(24, 18), 22, 912)
    subtitle = _make_label(layer, Vector2(24, 53), 16, 912)
    party = _make_label(layer, Vector2(24, 88), 16, 912)
    objective = _make_label(layer, Vector2(45, 296), 17, 855)
    scene_dialogue = _make_label(layer, Vector2(48, 378), 19, 850)
    scene_dialogue.custom_minimum_size.y = 134
    footer = _make_label(layer, Vector2(25, 577), 16, 910)
    _refresh()

func _make_label(parent: Node, at: Vector2, size: int, width: float) -> Label:
    var label := Label.new()
    label.position = at
    label.custom_minimum_size = Vector2(width, 35)
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", Color("#f9edd2"))
    label.add_theme_color_override("font_shadow_color", Color("#101e32"))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label

func _draw() -> void:
    # Neutral review-room imagery. NOT a canon shore or shipboard room.
    draw_rect(Rect2(0, 0, 960, 640), Color("#172f41"))
    draw_rect(Rect2(38, 155, 886, 405), Color("#254653"))
    draw_rect(Rect2(68, 199, 823, 91), Color("#5c5348"))
    for index in range(3):
        var x := 202.0 + float(index) * 280.0
        var active := phase in ["investigation", "clue_dialogue", "theory_ready", "theory_dialogue", "working_theory"]
        var completed: bool = opening != null and (CLUE_KEYS[index] in opening.clues)
        draw_circle(Vector2(x, 236), 28, Color("#7ad7bd") if completed else Color("#c3a978") if active else Color("#596b70"))
        draw_string(ThemeDB.fallback_font, Vector2(x - 65, 285), "%d  %s" % [index + 1, ["PHASE", "RESERVE", "LISTEN"][index]], HORIZONTAL_ALIGNMENT_LEFT, 155, 15, Color("#f3e6c6"))
    draw_rect(Rect2(30, 348, 902, 193), Color(0.03, 0.07, 0.13, 0.94))
    draw_rect(Rect2(0, 0, 960, 133), Color(0.03, 0.07, 0.13, 0.92))
    draw_rect(Rect2(0, 560, 960, 80), Color(0.03, 0.07, 0.13, 0.94))

func _unhandled_input(event: InputEvent) -> void:
    if event.is_echo():
        return
    if event.is_action_pressed(InputPolicy.INTERACT):
        if interact():
            get_viewport().set_input_as_handled()
    elif event.is_action_pressed(InputPolicy.CHOICE_A):
        if inspect_clue("phase_readings"):
            get_viewport().set_input_as_handled()
    elif event.is_action_pressed(InputPolicy.CHOICE_B):
        if inspect_clue("depleted_reserve"):
            get_viewport().set_input_as_handled()
    elif event.is_action_pressed(InputPolicy.CHOICE_C):
        if inspect_clue("lyra_observation"):
            get_viewport().set_input_as_handled()

func interact() -> bool:
    match phase:
        "reunion_ready":
            phase = "reunion_dialogue"
            dialogue_cursor = 0
        "reunion_dialogue":
            if dialogue_cursor < INTRO_LINES.size() - 1:
                dialogue_cursor += 1
            else:
                if not opening.introduce_lyra_and_talen(qa_recovery_fixture_admitted):
                    return false
                phase = "investigation"
                dialogue_cursor = 0
        "clue_dialogue":
            if pending_clue.is_empty() or not opening.record_clue(pending_clue):
                return false
            pending_clue = ""
            phase = "investigation"
        "investigation":
            if opening.clues.size() < 2:
                return false
            phase = "theory_dialogue"
            dialogue_cursor = 0
        "theory_dialogue":
            if dialogue_cursor < THEORY_LINES.size() - 1:
                dialogue_cursor += 1
            else:
                if not opening.form_working_fuel_theory():
                    return false
                phase = "working_theory"
        _:
            return false
    _refresh()
    return true

func inspect_clue(clue_id: String) -> bool:
    if phase != "investigation" or opening == null:
        return false
    if clue_id not in CLUE_KEYS or clue_id in opening.clues:
        return false
    pending_clue = clue_id
    phase = "clue_dialogue"
    _refresh()
    return true

func review_snapshot() -> Dictionary:
    return {
        "review_phase": phase,
        "stage": opening.step_key() if opening != null else "unconfigured",
        "party": opening.active_party_ids.duplicate() if opening != null else [],
        "clues": opening.clues.duplicate() if opening != null else [],
        "recovery_fixture_only": qa_recovery_fixture_admitted,
        "real_recovery_route_verified": false,
        "geography_authorized": false,
        "talen_combat_authorized": false,
        "fuel_explanation": "working_hypothesis" if phase == "working_theory" else "unknown",
        "fuel_formula_verified": false,
    }

func _refresh() -> void:
    if headline == null:
        return
    headline.text = "FIRST WAKE / REUNION AND WORKING THEORY — QA REHEARSAL"
    subtitle.text = "SAFE MEETING LOCATION: NOT ESTABLISHED  |  REVIEW FIXTURE IS NOT A RESCUE"
    party.text = "STORY PARTY: " + (" + ".join(opening.active_party_ids).to_upper() if opening != null else "NOT CONFIGURED") + "  |  TALEN: NONPLAYABLE"
    scene_dialogue.text = ""
    match phase:
        "recovery_unverified":
            objective.text = "BLOCKED: external safe-recovery verification required before reunion."
            footer.text = "No in-game bypass: 2D afloat is not proof of a safe family meeting."
        "reunion_ready":
            objective.text = "QA-ONLY SAFE-MEETING FIXTURE: read the family introduction."
            footer.text = "E: start rehearsal dialogue; no world location has been chosen."
        "reunion_dialogue":
            objective.text = "Family introduction (%d / %d)." % [dialogue_cursor + 1, INTRO_LINES.size()]
            scene_dialogue.text = INTRO_LINES[dialogue_cursor]
            footer.text = "E: continue. Lyra joins only after dialogue finishes."
        "investigation":
            objective.text = "Compare independent clues (%d / 3). Two allow a provisional theory." % opening.clues.size()
            scene_dialogue.text = "1: Phase chart     2: Reserve log     3: Lyra's listening"
            footer.text = "1 / 2 / 3: inspect  |  E: discuss theory after 2 different observations."
        "clue_dialogue":
            objective.text = "Investigate: " + pending_clue.replace("_", " ").to_upper()
            scene_dialogue.text = str(CLUE_LINES.get(pending_clue, ""))
            footer.text = "E: record observation. This does not prove fuel composition."
        "theory_dialogue":
            objective.text = "Provisional shared fuel theory (%d / %d)." % [dialogue_cursor + 1, THEORY_LINES.size()]
            scene_dialogue.text = THEORY_LINES[dialogue_cursor]
            footer.text = "E: discuss. Hypothesis only; no definitive formula."
        "working_theory":
            objective.text = "WORKING THEORY RECORDED — NOT CONFIRMED"
            scene_dialogue.text = "The team has reasons to investigate a stabilization role, but no verified formula or source."
            footer.text = "Rehearsal ends here. Geography, safe route, and production game remain open."
        _:
            objective.text = "Awaiting postflight diagnosis and externally authorized QA-only meeting fixture."
            footer.text = "No reunion while the ship remains in flight or recovery is unverified."
    queue_redraw()
