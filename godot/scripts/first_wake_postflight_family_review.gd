extends Node2D
## Chapter I review: safe mooring / reunion / shared fuel theory.
## A bounded REVIEW SETTING, not approved geographic travel or family art.
## Only accepts the existing revised opening contract after actual 2D water
## contact, explicit reserve inspection, and staged safe return to a berth.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Actor = preload("res://scripts/pilot_actor.gd")
const Inputs = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const WorkshopScene = preload("res://scenes/first_wake_core_alignment_review.tscn")
const CinematicStageArt = preload("res://scripts/first_wake_cinematic_environment.gd")

const LYRA_POSITION := Vector2(690, 470)
const TALEN_POSITION := Vector2(812, 470)
const IONIA_LOG := Vector2(278, 470)
const PHASE_CHART := Vector2(445, 470)
const THEORY_TABLE := Vector2(568, 470)
const INTERACT_RADIUS := 53.0
const BOUNDS := Rect2(Vector2(132, 414), Vector2(706, 109))

var opening
var scene_phase: String = "not_configured"
var ender: CharacterBody2D
var safe_mooring_review: bool = false
var dialogue_open: bool = false
var dialogue_lines: Array[String] = []
var dialogue_cursor: int = 0
var dialogue_event: String = ""
var child_block_ship_viewed: bool = false
var dialogue_panel: ColorRect
var speaker_label: Label
var dialogue_label: Label
var objective_label: Label
var party_label: Label
var hint_label: Label
var ui_layer: CanvasLayer
var repair_review: Node2D
var cinematic_environment_enabled: bool = true
var last_message: String = "A temporary safe mooring review; exact shoreline geography is not established."

func configure_after_safe_review(story: Variant, physical_water_verified: bool, stable_float_verified: bool, reserve_inspected: bool, mooring_confirmed: bool) -> bool:
    if is_inside_tree() or opening != null:
        return false
    if not (story is RefCounted) or story.get_script() != Opening:
        return false
    var report: Dictionary = story.snapshot()
    if report.get("step", "") != "postflight_diagnosis":
        return false
    if report.get("active_party_ids", []) != ["ender", "ionia"] or bool(report.get("safe_reunion_confirmed", false)):
        return false
    if not physical_water_verified or not stable_float_verified or not reserve_inspected or not mooring_confirmed:
        return false
    opening = story
    safe_mooring_review = true
    scene_phase = "family_arrival"
    return true

func _ready() -> void:
    Inputs.ensure_defaults()
    if opening == null or not safe_mooring_review:
        push_error("TSTSS_FAMILY_REVIEW_REQUIRES_SAFE_MOORING")
        return
    ender = Actor.new()
    ender.name = "EnderPostflightReview"
    ender.character_name = "Ender"
    ender.player_controlled = true
    ender.walking_bounds = BOUNDS
    ender.position = Vector2(162, 475)
    add_child(ender)
    ender.set_walk_review_enabled(true)
    ui_layer = CanvasLayer.new()
    var ui := ui_layer
    ui.name = "PostflightFamilyReadableUI"
    add_child(ui)
    objective_label = _label(ui, Vector2(23, 22), 20, 917)
    party_label = _label(ui, Vector2(24, 63), 16, 912)
    hint_label = _label(ui, Vector2(25, 568), 15, 909)
    dialogue_panel = ColorRect.new()
    dialogue_panel.color = Color("#101b2d")
    dialogue_panel.position = Vector2(18, 524)
    dialogue_panel.size = Vector2(924, 111)
    dialogue_panel.visible = false
    ui.add_child(dialogue_panel)
    speaker_label = _label(dialogue_panel, Vector2(16, 5), 15, 890)
    dialogue_label = _label(dialogue_panel, Vector2(16, 30), 17, 884)
    dialogue_label.custom_minimum_size.y = 77.0
    _refresh()

func _label(parent: Node, pos: Vector2, font_size: int, width: float) -> Label:
    var node := Label.new()
    node.position = pos
    node.custom_minimum_size = Vector2(width, 35)
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", Color("#fff0d4"))
    node.add_theme_color_override("font_shadow_color", Color("#142334"))
    parent.add_child(node)
    return node

func set_cinematic_environment_enabled(enabled: bool) -> void:
    cinematic_environment_enabled = enabled
    queue_redraw()

func _draw() -> void:
    if cinematic_environment_enabled:
        CinematicStageArt.draw_family(self)
    else:
        # Original draft blocking, not approved character portraits or geography.
        draw_rect(Rect2(0, 0, 960, 640), Color("#183347"))
        draw_rect(Rect2(0, 328, 960, 220), Color("#42616a"))
        draw_rect(Rect2(0, 395, 960, 148), Color("#735d47"))
        for y in [413.0, 439.0, 465.0, 491.0, 517.0]:
            draw_line(Vector2(65, y), Vector2(904, y), Color("#9f8060"), 2.0)
        draw_rect(Rect2(0, 0, 960, 116), Color("#0c1d2e"))
        draw_string(ThemeDB.fallback_font, Vector2(28, 191), "TEMPORARY SAFE BERTH — REVIEW SPACE / SITE UNASSIGNED", HORIZONTAL_ALIGNMENT_LEFT, 900, 17, Color("#f1d9ad"))
    for item in [
        {"at": IONIA_LOG, "label": "DENITH'S LOG", "color": Color("#c59b6e")},
        {"at": PHASE_CHART, "label": "PHASE CHART", "color": Color("#87b6bd")},
        {"at": THEORY_TABLE, "label": "THEORY TABLE", "color": Color("#bb9274")},
        {"at": LYRA_POSITION, "label": "LYRA", "color": Color("#d4a9bd")},
        {"at": TALEN_POSITION, "label": "TALEN (SAFE)", "color": Color("#e6bd83")},
    ]:
        var p: Vector2 = item["at"]
        if cinematic_environment_enabled and str(item["label"]) in [
                "DENITH'S LOG","PHASE CHART","THEORY TABLE"]:
            CinematicStageArt.draw_family_station(self,p,str(item["label"]))
        else:
            draw_rect(Rect2(p + Vector2(-37, -92), Vector2(74, 55)), item["color"])
        draw_string(ThemeDB.fallback_font, p + Vector2(-62, -101), str(item["label"]), HORIZONTAL_ALIGNMENT_LEFT, 160, 14, Color("#fff1d3"))
    if child_block_ship_viewed:
        draw_rect(Rect2(TALEN_POSITION + Vector2(-25, -69), Vector2(50, 13)), Color("#77a8c6"))
        draw_rect(Rect2(TALEN_POSITION + Vector2(-9, -80), Vector2(17, 12)), Color("#f1c376"))

func _unhandled_input(event: InputEvent) -> void:
    if repair_review != null:
        return
    if event.is_action_pressed(Inputs.INTERACT) and not event.is_echo():
        interact()
        get_viewport().set_input_as_handled()

func interact() -> bool:
    if repair_review != null:
        return false
    if dialogue_open:
        return advance_dialogue()
    if ender == null or not safe_mooring_review:
        return false
    # The child remains present with a safe adult but has no combat/job permissions.
    if _near(TALEN_POSITION):
        if child_block_ship_viewed:
            last_message = "Talen's little block ship stays on the table, with two more engines than the Wake."
            _refresh()
            return false
        _begin_dialogue("TALEN / ENDER", [
            "TALEN: Does Ionia's ship swim?",
            "ENDER: Today it did. She stayed afloat when it mattered.",
            "TALEN: Mine has extra engines. And a place for everyone to sit.",
            "ENDER: That's thoughtful engineering. Can I have a look?",
            "TALEN: You can, but one of the wings comes off. I'm fixing that part.",
        ], "blocks")
        return true
    if scene_phase == "family_arrival":
        if not _near(LYRA_POSITION):
            last_message = "Speak with Lyra after the Wake has reached a safe berth."
            _refresh()
            return false
        _begin_dialogue("LYRA / IONIA / ENDER", [
            "LYRA: Ionia. We heard something happened on the water.",
            "IONIA: An unexpected change of travel plans. Everyone's safe. The engines aren't.",
            "LYRA: Talen was worried about you. So was I.",
            "IONIA: We were careful. Ender caught the drift before containment was lost.",
            "LYRA: You're Ender, then. I'm Lyra, and that is my son, Talen.",
            "ENDER: I was hired to get the Wake flying. I suppose I'm still on the job.",
            "LYRA: Then I'd like to help. First, tell me what you actually observed.",
            "IONIA: Welcome aboard our investigation. No rushed second flight.",
        ], "reunion")
        return true
    if scene_phase == "investigation":
        if _near(IONIA_LOG):
            if "depleted_reserve" in opening.clues:
                last_message = "Already logged: the specialized reserve was empty after splashdown."
                _refresh()
                return false
            _begin_dialogue("IONIA / ENDER", [
                "IONIA: Denith always checked when the reserve was replenished, not only how much remained.",
                "ENDER: So those times might matter as much as the amount.",
                "IONIA: Possibly. He left me careful notes, but not an explanation for every setting.",
                "ENDER: Then we call it a clue, not a formula.",
            ], "depleted_reserve")
            return true
        if _near(PHASE_CHART):
            if "phase_readings" in opening.clues:
                last_message = "Already logged: the reference only drifted under real engine load."
                _refresh()
                return false
            _begin_dialogue("ENDER / IONIA", [
                "ENDER: At dock the regulator looked steady. Under load the reference started moving.",
                "IONIA: And containment had to work harder just to hold that difference.",
                "ENDER: Right. The measurements don't yet tell us why.",
            ], "phase_readings")
            return true
        if _near(LYRA_POSITION):
            if "lyra_observation" in opening.clues:
                last_message = "Lyra already described the unstable note she noticed."
                _refresh()
                return false
            _begin_dialogue("LYRA / ENDER", [
                "LYRA: When you touch that regulator, I can feel a change in the vibration.",
                "ENDER: You can hear something the gauge doesn't capture?",
                "LYRA: Not louder. Just a note that can't quite settle.",
                "ENDER: I'll write that down exactly as you described it.",
            ], "lyra_observation")
            return true
        if _near(THEORY_TABLE):
            if opening.clues.size() < 2:
                last_message = "We need two independent observations before attempting a theory."
                _refresh()
                return false
            _begin_dialogue("ENDER / IONIA / LYRA", [
                "ENDER: We're looking at phase drift, pressure on containment, and an empty reserve.",
                "IONIA: Denith told me the Wake wouldn't fly on power alone. I thought he meant the crew.",
                "LYRA: Maybe he did. But the sound of that regulator has something to do with it.",
                "ENDER: The fuel might help keep the core aligned as well as keep it running.",
                "IONIA: Might. We still need actual materials, and another safe test.",
                "LYRA: We find what we need together. Talen stays away from the dangerous work.",
                "ENDER: This is our first working theory. It is not yet the answer.",
            ], "theory")
            return true
        last_message = "Investigate the log, chart, and Lyra's observation; then gather at the table."
        _refresh()
        return false
    if scene_phase == "working_theory":
        if not _near(THEORY_TABLE):
            last_message = "Return to the theory table to proceed to the repair workshop review."
            _refresh()
            return false
        return open_connected_workshop()
    last_message = "The working theory is recorded. Recovery materials and harmonic resolution are next."
    _refresh()
    return false

func open_connected_workshop() -> bool:
    if scene_phase != "working_theory" or dialogue_open or repair_review != null:
        return false
    if opening.step_key() != "working_theory" or opening.active_party_ids != ["ender", "ionia", "lyra"]:
        return false
    if not safe_mooring_review or opening.clues.size() < 2:
        return false
    if ender == null or not _near(THEORY_TABLE):
        return false
    var review := WorkshopScene.instantiate()
    if not bool(review.call("configure_from_working_theory", opening)):
        review.free()
        return false
    repair_review = review
    scene_phase = "repair_review"
    ender.player_controlled = false
    ender.visible = false
    ui_layer.visible = false
    add_child(repair_review)
    queue_redraw()
    return true

func advance_dialogue() -> bool:
    if not dialogue_open:
        return false
    if dialogue_cursor + 1 < dialogue_lines.size():
        dialogue_cursor += 1
        _refresh()
        return true
    var completed: String = dialogue_event
    dialogue_open = false
    dialogue_cursor = 0
    dialogue_lines.clear()
    dialogue_event = ""
    ender.player_controlled = true
    match completed:
        "blocks":
            child_block_ship_viewed = true
            last_message = "Talen's block-built Wake can be examined. He remains noncombat."
        "reunion":
            if not opening.introduce_lyra_and_talen(true):
                push_error("TSTSS_FAMILY_REVIEW_REUNION_CONTRACT_REJECTED")
                return false
            scene_phase = "investigation"
            last_message = "Lyra joins only after the safe family introduction. Talen stays with the household."
        "depleted_reserve", "phase_readings", "lyra_observation":
            if not opening.record_clue(completed):
                push_error("TSTSS_FAMILY_REVIEW_CLUE_CONTRACT_REJECTED")
                return false
            last_message = "Independent observation recorded: %s." % completed
        "theory":
            if not opening.form_working_fuel_theory():
                push_error("TSTSS_FAMILY_REVIEW_THEORY_CONTRACT_REJECTED")
                return false
            scene_phase = "working_theory"
            last_message = "Working fuel theory only. Physical recovery and the missing sequence remain unresolved."
    _refresh()
    return true

func _begin_dialogue(speaker: String, lines: Array, event_id: String) -> void:
    dialogue_open = true
    dialogue_lines.clear()
    for line in lines:
        dialogue_lines.append(str(line))
    dialogue_cursor = 0
    dialogue_event = event_id
    speaker_label.text = speaker
    ender.player_controlled = false
    _refresh()

func _near(pos: Vector2) -> bool:
    return ender.position.distance_to(pos) <= INTERACT_RADIUS

func review_snapshot() -> Dictionary:
    return {
        "phase": scene_phase,
        "safe_mooring_review": safe_mooring_review,
        "family_intro_complete": opening.safe_reunion_confirmed if opening != null else false,
        "child_noncombat": true,
        "lyra_joined": ("lyra" in opening.active_party_ids) if opening != null else false,
        "independent_clues": opening.clues.duplicate() if opening != null else [],
        "theory_only": scene_phase == "working_theory",
        "real_return_route_verified": false,
        "canonical_geography_assigned": false,
        "production_family_art_verified": false,
        "combat_art_granted": false,
        "connected_repair_review": repair_review != null,
        "review_only": true,
    }

func _refresh() -> void:
    if objective_label == null:
        return
    # A single compact line preserves the separate party/status line at y=63
    # in the 960x640 native review viewport. Required next actions remain explicit.
    var task := "MEET LYRA & TALEN" if scene_phase == "family_arrival" else (
        "GATHER TWO CLUES" if scene_phase == "investigation" else (
            "GO TO THEORY TABLE" if scene_phase == "working_theory" else "REPAIR WORKSHOP"
        )
    )
    objective_label.text = "FIRST WAKE / SAFE BERTH REVIEW — " + task
    party_label.text = "Story party: " + " + ".join(opening.active_party_ids) + "  |  Talen: noncombat  |  Safely moored: review fixture"
    dialogue_panel.visible = dialogue_open
    if dialogue_open:
        speaker_label.text = "CONVERSATION (E: NEXT): " + speaker_label.text.trim_prefix("CONVERSATION (E: NEXT): ")
        dialogue_label.text = dialogue_lines[dialogue_cursor]
        hint_label.text = "E: next line  |  %d / %d" % [dialogue_cursor + 1, dialogue_lines.size()]
    else:
        hint_label.text = last_message + "  [Arrows: move  |  E: interact]"
    queue_redraw()
