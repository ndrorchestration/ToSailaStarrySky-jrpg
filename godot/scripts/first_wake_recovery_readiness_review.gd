extends Node2D
## Review-only recovery readiness on the afloat Aureate Wake.
## This is a playable three-station CHECKLIST, not a physical rescue, approved
## sailing route, confirmed signal delivery or permission to meet the family.

const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")

const STATION_IDS: Array[String] = ["crew_accounting", "systems_isolation", "contact_plan"]
const CREW_LINES: Array[String] = [
    "IONIA: Both of us are accounted for. Check the hull spaces before we promise anyone a journey.",
    "ENDER: The ship is floating, but we haven't surveyed every compartment. Mark that limitation.",
]
const SYSTEM_LINES: Array[String] = [
    "ENDER: The harmonic engine remains offline. We must not mistake buoyancy for recovered flight.",
    "IONIA: Secure the controls. A sea route or tow is still an option to investigate, not a chosen route.",
]
const CONTACT_LINES: Array[String] = [
    "IONIA: Draft a status message for the people waiting. We haven't established a working contact link.",
    "ENDER: We'll say we're afloat and investigating. No invented location, arrival time or fuel recipe.",
]

var source_flight: Node
var opening
var phase: String = "unconfigured"
var completed_stations: Array[String] = []
var pending_station: String = ""
var dialogue_cursor: int = 0
var headline: Label
var state_label: Label
var instruction: Label
var dialogue: Label
var footer: Label

func configure_from_postflight(flight: Node) -> bool:
    if is_inside_tree() or source_flight != null or flight == null:
        return false
    if not flight.has_method("review_snapshot"):
        return false
    var snap: Dictionary = flight.review_snapshot()
    if snap.get("story_step", "") != "postflight_diagnosis":
        return false
    if not bool(snap.get("actual_2d_area_contact_observed", false)):
        return false
    if not bool(snap.get("stable_buoyant_hull_observed", false)):
        return false
    if not bool(snap.get("postflight_reserve_observed", false)):
        return false
    if bool(snap.get("inspection_dialogue_open", false)):
        return false
    if snap.get("party", []) != ["ender", "ionia"]:
        return false
    if not flight.opening.has_method("step_key") or flight.opening.step_key() != "postflight_diagnosis":
        return false
    source_flight = flight
    opening = flight.opening
    phase = "inspect"
    return true

func _ready() -> void:
    InputPolicy.ensure_defaults()
    var overlay := CanvasLayer.new()
    overlay.name = "RecoveryReadinessReviewUI"
    add_child(overlay)
    headline = _make_label(overlay, Vector2(24, 18), 22, 900)
    state_label = _make_label(overlay, Vector2(24, 56), 16, 900)
    instruction = _make_label(overlay, Vector2(47, 301), 17, 856)
    dialogue = _make_label(overlay, Vector2(48, 371), 18, 850)
    dialogue.custom_minimum_size.y = 145
    footer = _make_label(overlay, Vector2(26, 574), 16, 906)
    _refresh()

func _make_label(parent: Node, at: Vector2, font_size: int, width: float) -> Label:
    var lbl := Label.new()
    lbl.position = at
    lbl.custom_minimum_size = Vector2(width, 33)
    lbl.add_theme_font_size_override("font_size", font_size)
    lbl.add_theme_color_override("font_color", Color("#f5edd7"))
    lbl.add_theme_color_override("font_shadow_color", Color("#111e32"))
    lbl.add_theme_constant_override("shadow_offset_x", 1)
    lbl.add_theme_constant_override("shadow_offset_y", 2)
    lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(lbl)
    return lbl

func _draw() -> void:
    # Neutral shipboard diagnostics wall. No fabricated shoreline or coastline.
    draw_rect(Rect2(0, 0, 960, 640), Color("#183343"))
    draw_rect(Rect2(35, 137, 888, 425), Color("#274653"))
    draw_rect(Rect2(57, 181, 847, 122), Color("#4f4e4c"))
    for i in range(3):
        var p := Vector2(196 + 283 * i, 232)
        var inspected: bool = STATION_IDS[i] in completed_stations
        draw_circle(p, 31, Color("#76d4b9") if inspected else Color("#d2b17b"))
        draw_circle(p, 21, Color("#294653"))
        draw_string(ThemeDB.fallback_font, p + Vector2(-62, 60), "%d: %s" % [i + 1, ["CREW", "ENGINE", "MESSAGE"][i]], HORIZONTAL_ALIGNMENT_LEFT, 145, 17, Color("#e8dbbc"))
    draw_rect(Rect2(31, 348, 897, 202), Color(0.04, 0.07, 0.12, 0.94))
    draw_rect(Rect2(0, 0, 960, 124), Color(0.04, 0.07, 0.12, 0.95))
    draw_rect(Rect2(0, 560, 960, 80), Color(0.04, 0.07, 0.12, 0.95))

func _unhandled_input(event: InputEvent) -> void:
    if event.is_echo():
        return
    var used := false
    if event.is_action_pressed(InputPolicy.INTERACT):
        used = interact()
    elif event.is_action_pressed(InputPolicy.CHOICE_A):
        used = inspect_station("crew_accounting")
    elif event.is_action_pressed(InputPolicy.CHOICE_B):
        used = inspect_station("systems_isolation")
    elif event.is_action_pressed(InputPolicy.CHOICE_C):
        used = inspect_station("contact_plan")
    if used:
        get_viewport().set_input_as_handled()

func inspect_station(station_id: String) -> bool:
    if phase != "inspect" or opening == null:
        return false
    if station_id not in STATION_IDS or station_id in completed_stations:
        return false
    if opening.step_key() != "postflight_diagnosis" or opening.active_party_ids != ["ender", "ionia"]:
        return false
    pending_station = station_id
    dialogue_cursor = 0
    phase = "dialogue"
    _refresh()
    return true

func interact() -> bool:
    if phase != "dialogue" or pending_station.is_empty():
        return false
    var lines: Array[String] = _station_lines(pending_station)
    if lines.is_empty():
        return false
    if dialogue_cursor < lines.size() - 1:
        dialogue_cursor += 1
    else:
        completed_stations.append(pending_station)
        pending_station = ""
        dialogue_cursor = 0
        phase = "ready_for_route_review" if completed_stations.size() == STATION_IDS.size() else "inspect"
    _refresh()
    return true

func _station_lines(station_id: String) -> Array[String]:
    match station_id:
        "crew_accounting":
            return CREW_LINES
        "systems_isolation":
            return SYSTEM_LINES
        "contact_plan":
            return CONTACT_LINES
    return []

func review_snapshot() -> Dictionary:
    return {
        "review_source": "isolated_first_wake_recovery_checklist",
        "phase": phase,
        "party": opening.active_party_ids.duplicate() if opening != null else [],
        "story_step": opening.step_key() if opening != null else "unconfigured",
        "observations": completed_stations.duplicate(),
        "readiness_review_complete": phase == "ready_for_route_review" and completed_stations.size() == STATION_IDS.size(),
        "route_status": "awaiting_creator_geography",
        "actual_sailing_route_verified": false,
        "message_delivered": false,
        "safe_family_meeting_verified": false,
        "recovery_success_certified": false,
        "fuel_formula_verified": false,
    }

func _refresh() -> void:
    if headline == null:
        return
    headline.text = "AUREATE WAKE / WATERBORNE RECOVERY READINESS — REVIEW"
    state_label.text = "ENDER + IONIA  |  CHECKS %d / 3  |  RECOVERY ROUTE UNKNOWN" % completed_stations.size()
    dialogue.text = ""
    match phase:
        "inspect":
            instruction.text = "Select a shipboard check: crew, engine isolation, or contact plan."
            dialogue.text = "Inspect each station and read the two lines before marking it observed."
            footer.text = "1 Crew  |  2 Engine  |  3 Message   —   E continue after selecting."
        "dialogue":
            var lines: Array[String] = _station_lines(pending_station)
            instruction.text = "Observation: %s (%d / %d)" % [pending_station.replace("_", " "), dialogue_cursor + 1, lines.size()]
            dialogue.text = lines[dialogue_cursor]
            footer.text = "E: next line / record observation. This does not validate a rescue route."
        "ready_for_route_review":
            instruction.text = "THREE CHECKS RECORDED. SAFE TRAVEL PLAN NOT YET APPROVED."
            dialogue.text = "Crew accounted for; engine isolated; contact message drafted. No transmission, destination or safe meeting has been established."
            footer.text = "ROUTE HOLD: creator geography, communications and family contact are open."
        _:
            instruction.text = "Needs prior native splashdown and postflight diagnosis."
            footer.text = "No safe recovery claim without validated story and navigation."
    queue_redraw()
