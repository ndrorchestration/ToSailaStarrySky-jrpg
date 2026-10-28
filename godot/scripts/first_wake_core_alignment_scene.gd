extends Node2D
## Isolated physical-repair and remembered-melody story review. This scene
## uses two anonymous test pickups; it is NOT real Chapter I, fuel art, sound,
## ship flight, DSP verification, or an approved mainline story destination.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Core = preload("res://scripts/first_wake_core_alignment_review.gd")
const MelodyAnalysis = preload("res://scripts/first_wake_melody_analysis_review.gd")
const Actor = preload("res://scripts/pilot_actor.gd")
const Inputs = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const CinematicStageArt = preload("res://scripts/first_wake_cinematic_environment.gd")

const PICKUP_A := Vector2(260, 470)
const PICKUP_B := Vector2(410, 470)
const INSTALL := Vector2(560, 470)
const ENGINE := Vector2(730, 470)
const IONIA := Vector2(266, 470)
const CHART := Vector2(560, 470)
const LYRA := Vector2(410, 470)
const RANGE := 78.0
const BOUNDS := Rect2(Vector2(130, 404), Vector2(680, 116))

var story = Opening.new()
var core = Core.new()
var has_external_story_handoff: bool = false

func configure_from_working_theory(story_state: Variant) -> bool:
    # Only preinstantiation, identical creator-directed opening contract.
    # A player cannot skip the Lyra reunion or two evidence clues.
    if is_inside_tree() or has_external_story_handoff:
        return false
    if not (story_state is RefCounted) or story_state.get_script() != Opening:
        return false
    var report: Dictionary = story_state.snapshot()
    if report.get("step", "") != "working_theory":
        return false
    if report.get("active_party_ids", []) != ["ender", "ionia", "lyra"]:
        return false
    if not bool(report.get("safe_reunion_confirmed", false)) or int(report.get("evidence_count", 0)) < 2:
        return false
    if not core.begin(story_state):
        return false
    story = story_state
    has_external_story_handoff = true
    last_message = "Shared crew theory received; physical recovery is still required."
    return true
var analysis = MelodyAnalysis.new()
var ender: CharacterBody2D
var headline: Label
var objective: Label
var status_label: Label
var hint: Label
var analysis_backdrop: ColorRect
var analysis_lines: Label
var analysis_feedback: Label
var cinematic_environment_enabled: bool = true
var last_message: String = "Review fixture: the splashdown and family reunion are not playable here."

func _ready() -> void:
    Inputs.ensure_defaults()
    # Standalone F6 test retains its isolated fixture. The connected Chapter I
    # review path instead injects the actual postflight crew/clue state.
    if not has_external_story_handoff:
        story.accept_ionia_job()
        story.complete_engineering_checks()
        story.begin_test_flight()
        story.record_engine_failure(true, true, true)
        story.complete_ocean_splashdown(true, true)
        story.inspect_postflight_reserve(true)
        story.introduce_lyra_and_talen(true)
        story.record_clue("phase_readings")
        story.record_clue("lyra_observation")
        story.form_working_fuel_theory()
        if not core.begin(story):
            push_error("CORE_REVIEW_FIXTURE_INVALID")
            return

    ender = Actor.new()
    ender.name = "EnderReviewPlayer"
    ender.character_name = "Ender"
    ender.player_controlled = true
    ender.walking_bounds = BOUNDS
    ender.position = Vector2(165, 477)
    add_child(ender)
    ender.set_walk_review_enabled(true)

    var ui := CanvasLayer.new()
    ui.name = "RepairReviewUI"
    add_child(ui)
    headline = _label(ui, Vector2(25, 17), 24)
    objective = _label(ui, Vector2(27, 68), 18)
    status_label = _label(ui, Vector2(27, 111), 16)
    hint = _label(ui, Vector2(27, 559), 16)

    analysis_backdrop = ColorRect.new()
    analysis_backdrop.name = "HarmonicAnalysisReadablePanel"
    analysis_backdrop.position = Vector2(82, 167)
    analysis_backdrop.size = Vector2(796, 366)
    analysis_backdrop.color = Color("#101d30")
    analysis_backdrop.visible = false
    ui.add_child(analysis_backdrop)
    analysis_lines = _label(analysis_backdrop, Vector2(23, 22), 17)
    analysis_lines.custom_minimum_size = Vector2(745, 244)
    analysis_feedback = _label(analysis_backdrop, Vector2(23, 271), 16)
    analysis_feedback.custom_minimum_size = Vector2(745, 84)
    _refresh()

func _label(parent: Node, location: Vector2, font_size: int) -> Label:
    var node := Label.new()
    node.position = location
    node.custom_minimum_size = Vector2(900, 52)
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", Color("#ffeed8"))
    node.add_theme_color_override("font_shadow_color", Color("#122438"))
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(node)
    return node

func set_cinematic_environment_enabled(enabled: bool) -> void:
    cinematic_environment_enabled = enabled
    queue_redraw()

func _draw() -> void:
    if cinematic_environment_enabled:
        CinematicStageArt.draw_workshop(self,str(core.snapshot()["phase"]))
    else:
        draw_rect(Rect2(0, 0, 960, 640), Color("#142d3e"))
        draw_rect(Rect2(12, 8, 936, 157), Color("#0b1726"))
        draw_rect(Rect2(0, 385, 960, 159), Color("#5e5045"))
        for y in [403.0, 429.0, 455.0, 481.0, 507.0, 533.0]:
            draw_line(Vector2(70, y), Vector2(890, y), Color("#85705c"), 1.0)
    for item in [
        {"id": "recovered_supply", "pos": PICKUP_A, "label": "STOCK"},
        {"id": "recovered_part", "pos": PICKUP_B, "label": "PART"},
    ]:
        var done: bool = item["id"] in core.recovered
        var pos: Vector2 = item["pos"]
        if cinematic_environment_enabled:
            CinematicStageArt.draw_workshop_station(self,pos,str(item["id"]),done)
        else:
            draw_rect(Rect2(pos + Vector2(-34, -77), Vector2(68, 46)), Color("#4e7c75") if done else Color("#c3965f"))
        draw_string(ThemeDB.fallback_font, pos + Vector2(-34, -86), item["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f8e8ce"))
    draw_rect(Rect2(INSTALL + Vector2(-46, -79), Vector2(92, 48)), Color("#496776"))
    draw_string(ThemeDB.fallback_font, INSTALL + Vector2(-39, -88), "ASSEMBLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f4dfbd"))
    draw_rect(Rect2(ENGINE + Vector2(-47, -92), Vector2(94, 62)), Color("#223845"))
    var glow: Color = Color("#8cc4b0") if core.snapshot()["alignment_candidate"] else Color("#ca825d")
    draw_arc(ENGINE + Vector2(0, -61), 19, 0, TAU, 32, glow, 3.0)
    draw_string(ThemeDB.fallback_font, ENGINE + Vector2(-29, -100), "CORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f4dfbd"))
    draw_rect(Rect2(16, 548, 928, 84), Color("#0b1726"))
    # Keep crew context separated from the workbench labels and core gizmo.
    if cinematic_environment_enabled:
        draw_rect(Rect2(18,168,627,30),Color("#0b1928",0.90))
        draw_line(Vector2(19,198),Vector2(644,198),Color("#c5a37a"),1)
        draw_string(ThemeDB.fallback_font,Vector2(27,188),
            "CREW: ENDER / IONIA / LYRA  |  TALEN SAFE, NONCOMBAT",
            HORIZONTAL_ALIGNMENT_LEFT,603,15,Color("#d9e6e2"))
    else:
        draw_string(ThemeDB.fallback_font, Vector2(23, 362), "Crew present after safe reunion: ENDER / IONIA / LYRA  |  Talen: noncombat", HORIZONTAL_ALIGNMENT_LEFT, 900, 17, Color("#d9e6e2"))

func _unhandled_input(event: InputEvent) -> void:
    if event.is_echo():
        return
    if analysis.open:
        var handled: bool = true
        if event.is_action_pressed(Inputs.CHOICE_A):
            choose_analysis(0)
        elif event.is_action_pressed(Inputs.CHOICE_B):
            choose_analysis(1)
        elif event.is_action_pressed(Inputs.CHOICE_C):
            choose_analysis(2)
        elif event.is_action_pressed(Inputs.INTERACT):
            submit_analysis()
        elif event.is_action_pressed(Inputs.FORMULA_REVIEW) or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
            close_analysis()
        else:
            handled = false
        if handled:
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed(Inputs.INTERACT):
        interact()
        get_viewport().set_input_as_handled()

func interact() -> bool:
    if analysis.open:
        return false
    if ender == null:
        return false
    var before: Dictionary = core.snapshot()
    var phase: String = str(before["phase"])
    var target: Vector2 = target_for_phase()
    if ender.position.distance_to(target) > RANGE:
        last_message = "Move closer to the highlighted repair station."
        _refresh()
        return false
    var success := false
    match phase:
        "recover":
            var pickup_id: String = "recovered_supply" if core.recovered.is_empty() else "recovered_part"
            success = core.take_world_item(pickup_id, "world_pickup")
            last_message = "Recovered physical review item: " + pickup_id + "."
        "install":
            var installation_id: String = "recovered_supply" if core.installed.is_empty() else "recovered_part"
            success = core.install_part(installation_id, true)
            last_message = "Checked physical installation: " + installation_id + "."
        "retest":
            success = core.retest_with_supplies(true, true, true)
            last_message = "The supplies are installed. The core still refuses phase-lock. No flight."
        "listen":
            success = core.ionia_hums_unprompted(true)
            last_message = "Ionia hums softly, worried. Ender hears an unusual relationship in the phrase."
        "repeat":
            success = core.ionia_repeats_denith_song(true, true)
            last_message = "Ender asks her to come closer. Ionia sings Denith's old shanty again."
        "analyze":
            success = analysis.show_for(core)
            if success:
                ender.player_controlled = false
            last_message = "Compare Ionia's four-note memory against the measured phase changes."
        "observe":
            success = core.lyra_confirms_response(true)
            last_message = "Lyra: The vibration stopped wandering when Ionia held that note."
        "authorize":
            success = core.ionia_approves_bench_test(true, true)
            last_message = "Ionia authorizes a contained calibration test, not a new flight."
        "verify":
            success = core.verify_stable_core(true, true)
            last_message = "Bench alignment candidate confirmed. Flight remains independently locked."
        "candidate":
            last_message = "Bench candidate only: a future tested flight requires real ship physics."
    if not success and phase != "candidate":
        last_message = "Evidence rejected; no progression granted."
    _refresh()
    return success

func choose_analysis(index: int) -> bool:
    var ok: bool = analysis.choose(index)
    _refresh()
    return ok

func submit_analysis() -> bool:
    var result: Dictionary = analysis.submit(core)
    if bool(result.get("ok", false)):
        last_message = "Ender resolves the rhythmic alignment hypothesis. Ask Lyra to confirm."
        ender.player_controlled = true
    _refresh()
    return bool(result.get("ok", false))

func close_analysis() -> bool:
    if not analysis.dismiss():
        return false
    ender.player_controlled = true
    last_message = "Chart review closed. Revisit the chart to reconsider the melody."
    _refresh()
    return true

func target_for_phase() -> Vector2:
    match str(core.snapshot()["phase"]):
        "recover":
            return PICKUP_A if core.recovered.is_empty() else PICKUP_B
        "install":
            return INSTALL
        "retest", "verify", "candidate":
            return ENGINE
        "listen", "repeat", "authorize":
            return IONIA
        "analyze":
            return CHART
        "observe":
            return LYRA
    return ENGINE

func _refresh() -> void:
    if headline == null:
        return
    var s: Dictionary = core.snapshot()
    headline.text = "AUREATE WAKE  /  POST-SPLASHDOWN REPAIR — " + ("CONNECTED REVIEW" if has_external_story_handoff else "ISOLATED FIXTURE")
    objective.text = "NEXT: %s  |  Samples: %d/2 recovered, %d/2 installed" % [str(s["phase"]).to_upper(), core.recovered.size(), core.installed.size()]
    status_label.text = "SUPPLY CHECK: %s  |  HARMONIC ALIGNMENT: %s  |  FLIGHT: LOCKED" % [
        "COMPLETE" if bool(s["materialReady"]) else "INCOMPLETE",
        "BENCH CANDIDATE" if bool(s["alignment_candidate"]) else "UNRESOLVED",
    ]
    analysis_backdrop.visible = analysis.open
    if analysis.open:
        analysis_lines.text = (
            "ENDER / HARMONIC CHART — ORIGINAL REVIEW NUMBERS (NOT CANON)\n"
            + "Ionia's remembered contour: 0, +2, +5, +3\n"
            + "Measured phase changes: 0, +2, +6, -2\n"
            + "Which relative phrase and held-note duration fits?\n\n"
            + analysis.option_lines()
        )
        analysis_feedback.text = analysis.feedback
        hint.text = "1/2/3 or pad X/Y/B: choose  |  E/pad A: test  |  C/pad RB or Esc: close"
    else:
        hint.text = last_message + "  [Arrows: move; E: interact; no voice input required]"
    queue_redraw()
