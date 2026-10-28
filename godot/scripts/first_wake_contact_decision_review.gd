extends Node2D
## P-02 real-scene recoverability investigation: reads physical splashdown
## and shipboard readiness from ONE Godot story object, never a QA family fixture.
## All three possible recovery methods remain nonexecuting until creator-approved
## geography, communication evidence, and an actual route are available.
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const OPTION_IDS: Array[String] = ["sea_route", "signal_link", "external_tow"]
const OPTION_LINES := {
    "sea_route": [
        "IONIA: The Wake is seaworthy, but the hull floating doesn't tell us where a safe shore lies.",
        "ENDER: We need a verified coastline, distance and navigable conditions before plotting a route."
    ],
    "signal_link": [
        "ENDER: The emergency message is drafted. We have not confirmed an outgoing link or acknowledgement.",
        "IONIA: Keep the status precise. No contact, recipient or delivery claim until the equipment proves it."
    ],
    "external_tow": [
        "IONIA: Assistance by another vessel is a possibility, not a scheduled rescue.",
        "ENDER: Nobody has agreed to a rendezvous. Even the tow approach needs a safe position and route."
    ]
}
var source_readiness: Node
var source_flight: Node
var opening
var phase: String = "unconfigured"
var active_option: String = ""
var line_cursor: int = 0
var reviewed_options: Array[String] = []
var header: Label
var status: Label
var instruction: Label
var dialogue: Label
var footer: Label

func configure_from_readiness(readiness: Node) -> bool:
    if is_inside_tree() or source_readiness != null or readiness == null:
        return false
    if not readiness.has_method("review_snapshot"):
        return false
    if not readiness.is_inside_tree():
        return false
    if readiness.get_script() == null or readiness.get_script().resource_path != "res://scripts/first_wake_recovery_readiness_review.gd":
        return false
    var receipt: Dictionary = readiness.review_snapshot()
    if receipt.get("review_source") != "isolated_first_wake_recovery_checklist":
        return false
    if not bool(receipt.get("readiness_review_complete", false)):
        return false
    if receipt.get("phase") != "ready_for_route_review":
        return false
    if receipt.get("party", []) != ["ender", "ionia"]:
        return false
    if receipt.get("story_step") != "postflight_diagnosis":
        return false
    for forbidden in ["actual_sailing_route_verified", "message_delivered",
            "safe_family_meeting_verified", "recovery_success_certified",
            "fuel_formula_verified"]:
        if bool(receipt.get(forbidden, true)):
            return false
    if receipt.get("route_status") != "awaiting_creator_geography":
        return false
    if receipt.get("observations", []).size() != 3:
        return false
    for id in ["crew_accounting", "systems_isolation", "contact_plan"]:
        if id not in receipt["observations"]:
            return false
    var flight: Node = readiness.get("source_flight")
    if flight == null or not flight.has_method("review_snapshot"):
        return false
    if not flight.is_inside_tree():
        return false
    if flight.get_script() == null or flight.get_script().resource_path != "res://scripts/first_wake_flight_water_review.gd":
        return false
    var ship: RigidBody2D = flight.get("ship_body")
    if ship == null or not ship.freeze:
        return false
    var water: Dictionary = flight.review_snapshot()
    if not bool(water.get("actual_2d_area_contact_observed", false)):
        return false
    if not bool(water.get("stable_buoyant_hull_observed", false)):
        return false
    if not bool(water.get("postflight_reserve_observed", false)):
        return false
    if bool(water.get("production_ocean_verified", true)):
        return false
    if water.get("story_step") != "postflight_diagnosis":
        return false
    if water.get("party", []) != ["ender", "ionia"]:
        return false
    if readiness.get("opening") != flight.get("opening"):
        return false
    source_readiness = readiness
    source_flight = flight
    opening = flight.get("opening")
    phase = "survey"
    return true

func _ready() -> void:
    InputPolicy.ensure_defaults()
    var layer := CanvasLayer.new()
    layer.name = "NoncanonicalRecoveryDecisionUI"
    add_child(layer)
    header = _label(layer, Vector2(24, 19), 22)
    status = _label(layer, Vector2(24, 57), 16)
    instruction = _label(layer, Vector2(42, 291), 18)
    dialogue = _label(layer, Vector2(43, 368), 18)
    dialogue.custom_minimum_size.y = 137
    footer = _label(layer, Vector2(25, 576), 16)
    _refresh()

func _label(parent: Node, at: Vector2, size: int) -> Label:
    var l := Label.new()
    l.position = at
    l.custom_minimum_size = Vector2(900, 38)
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color("#fff0d8"))
    l.add_theme_color_override("font_shadow_color", Color("#112232"))
    l.add_theme_constant_override("shadow_offset_x", 1)
    l.add_theme_constant_override("shadow_offset_y", 2)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(l)
    return l

func _draw() -> void:
    # Visual-only planning tabletop: not a new coastline, ocean map or rescue.
    draw_rect(Rect2(0, 0, 960, 640), Color("#162b3d"))
    draw_rect(Rect2(30, 140, 900, 415), Color("#304856"))
    draw_rect(Rect2(53, 177, 855, 114), Color("#3d4850"))
    for i in range(OPTION_IDS.size()):
        var center: Vector2 = Vector2(195.0 + float(i) * 283.0, 225.0)
        var complete: bool = OPTION_IDS[i] in reviewed_options
        var c: Color = Color("#9bd6be") if complete else Color("#d7b784")
        draw_circle(center, 31, c)
        draw_circle(center, 23, Color("#294652"))
        var names: Array[String] = ["SEA", "SIGNAL", "TOW"]
        draw_string(ThemeDB.fallback_font,
            center + Vector2(-38, 61), "%d %s" % [i + 1, names[i]],
            HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f3e3c1"))
    draw_rect(Rect2(27, 346, 907, 206), Color(0.035, 0.07, 0.13, 0.96))
    draw_rect(Rect2(0, 0, 960, 132), Color(0.03, 0.06, 0.12, 0.95))
    draw_rect(Rect2(0, 558, 960, 82), Color(0.03, 0.06, 0.12, 0.95))

func _unhandled_input(event: InputEvent) -> void:
    if event.is_echo():
        return
    var used: bool = false
    if event.is_action_pressed(InputPolicy.INTERACT):
        used = interact()
    elif event.is_action_pressed(InputPolicy.CHOICE_A):
        used = inspect_option("sea_route")
    elif event.is_action_pressed(InputPolicy.CHOICE_B):
        used = inspect_option("signal_link")
    elif event.is_action_pressed(InputPolicy.CHOICE_C):
        used = inspect_option("external_tow")
    if used:
        get_viewport().set_input_as_handled()

func inspect_option(option_id: String) -> bool:
    if phase != "survey" or opening == null:
        return false
    if opening.step_key() != "postflight_diagnosis":
        return false
    if opening.active_party_ids != ["ender", "ionia"]:
        return false
    if option_id not in OPTION_IDS or option_id in reviewed_options:
        return false
    active_option = option_id
    line_cursor = 0
    phase = "reading"
    _refresh()
    return true

func interact() -> bool:
    if phase == "reading" and active_option in OPTION_IDS:
        var lines: Array = OPTION_LINES.get(active_option, [])
        if line_cursor < lines.size() - 1:
            line_cursor += 1
        else:
            reviewed_options.append(active_option)
            active_option = ""
            line_cursor = 0
            phase = "decision_reviewed" if reviewed_options.size() == OPTION_IDS.size() else "survey"
        _refresh()
        return true
    if phase == "decision_reviewed":
        # The player completes analysis, not an imaginary transmission/voyage.
        if reviewed_options.size() != OPTION_IDS.size():
            return false
        phase = "route_hold"
        _refresh()
        return true
    return false

func review_snapshot() -> Dictionary:
    return {
        "source": "physically_bound_first_wake_recovery_decision",
        "phase": phase,
        "story_step": opening.step_key() if opening != null else "unconfigured",
        "party": opening.active_party_ids.duplicate() if opening != null else [],
        "reviewed_options": reviewed_options.duplicate(),
        "decision_reviewed": phase == "route_hold",
        "route_status": "awaiting_creator_geography",
        "physical_water_contact_required": true,
        "delivery_confirmed": false,
        "contact_recipient_identified": false,
        "tow_arranged": false,
        "shore_reached": false,
        "route_authorized": false,
        "family_reunion_authorized": false,
        "lyra_joined": false,
        "fuel_formula_verified": false,
        "can_launch": false
    }

func _refresh() -> void:
    if header == null:
        return
    header.text = "AUREATE WAKE — POSTFLIGHT CONTACT & ROUTE DESK (REVIEW)"
    status.text = "ENDER + IONIA | OPTIONS %d / 3 | NO VERIFIED ROUTE" % reviewed_options.size()
    dialogue.text = ""
    match phase:
        "survey":
            instruction.text = "Consider three recovery options. None is yet authorized."
            dialogue.text = "1  Examine sea navigation   2  Examine communications   3  Examine tow possibility"
            footer.text = "1 / 2 / 3: examine | E: continue dialogue. No route or contact is assumed."
        "reading":
            var lines: Array = OPTION_LINES.get(active_option, [])
            instruction.text = "%s (%d / %d)" % [active_option.replace("_", " ").to_upper(), line_cursor + 1, lines.size()]
            dialogue.text = lines[line_cursor]
            footer.text = "E: next observation. Completing the lines does not execute this option."
        "decision_reviewed":
            instruction.text = "ALL THREE OPTIONS EVALUATED — E to conclude"
            dialogue.text = "No validated coastline, contact acknowledgement, or accepted tow. The crew must hold until new evidence arrives."
            footer.text = "E: record an evidence-limited route hold, not a rescue."
        "route_hold":
            instruction.text = "ROUTE HOLD — WAIT FOR VERIFIED GEOGRAPHY OR CONTACT"
            dialogue.text = "The Wake remains afloat with its engines offline. No rescue, safe Lyra/Talen meeting or specialized fuel recipe is established."
            footer.text = "P-02 review complete. Future journey still needs creator-approved geography."
        _:
            instruction.text = "Actual local splashdown, diagnosis and recovery checks required."
            footer.text = "Cannot invent navigation, family contact or fuel."
    queue_redraw()
