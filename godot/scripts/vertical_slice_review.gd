extends Node2D
## Opt-in, noncanonical, standalone First Wake playability experiment.
## Original Godot pilot, approved Ender assets and Ionia art-review controls are untouched.

const Actor = preload("res://scripts/pilot_actor.gd")
const DockDepthReview = preload("res://scripts/dock_depth_review.gd")
const ChoiceState = preload("res://scripts/vertical_slice_choice_state.gd")
const Encounter = preload("res://scripts/vertical_slice_encounter.gd")
const DECK_BOUNDS = Rect2(Vector2(110, 404), Vector2(740, 118))
const SIGNAL_POINT = Vector2(224, 465)
const IONIA_POINT = Vector2(560, 465)
const CHALLENGE_POINT = Vector2(756, 465)

var choice_state = ChoiceState.new()
var encounter = Encounter.new()
var stage: String = "search"
var ender: CharacterBody2D
var ionia: CharacterBody2D
var headline: Label
var story: Label
var hint: Label
var stage_label: Label
var elapsed_seconds: float = 0.0
var reduced_motion: bool = true
var text_size: int = 21
var trace_opt_in: bool = false
var trace_events: Array[Dictionary] = []
var _story_message: String = "Something on the dock is sending a faint signal. Look for the small blue light."

func _ready() -> void:
    # Reuse existing reversible 2.5D dock stage, without changing its collision or canon.
    var atmosphere := DockDepthReview.new()
    atmosphere.name = "DockAtmosphereReviewOnly"
    atmosphere.z_index = -2
    add_child(atmosphere)

    var actors := Node2D.new()
    actors.name = "ReviewActors"
    actors.y_sort_enabled = true
    add_child(actors)

    ender = Actor.new()
    ender.name = "EnderReviewPlayer"
    ender.character_name = "Ender"
    ender.player_controlled = true
    ender.walking_bounds = DECK_BOUNDS
    ender.position = Vector2(360, 465)
    actors.add_child(ender)

    ionia = Actor.new()
    ionia.name = "IoniaReviewPlaceholder"
    ionia.character_name = "Ionia"
    ionia.walking_bounds = DECK_BOUNDS
    ionia.position = IONIA_POINT
    actors.add_child(ionia)

    var ui := CanvasLayer.new()
    ui.name = "AccessibleReviewUI"
    add_child(ui)
    headline = _label(ui, Vector2(26, 18), 26)
    stage_label = _label(ui, Vector2(26, 57), 18)
    story = _label(ui, Vector2(30, 548), text_size)
    hint = _label(ui, Vector2(30, 594), 18)
    headline.text = "AETHERWAKE  /  FIRST WAKE — PLAYABILITY STUDY"
    _refresh_ui()

func _label(parent: Node, location: Vector2, size: int) -> Label:
    var label := Label.new()
    label.position = location
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", Color("#fff7df"))
    label.add_theme_color_override("font_shadow_color", Color("#111d2e"))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.custom_minimum_size = Vector2(890, 0)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label

func _process(delta: float) -> void:
    elapsed_seconds += delta
    _refresh_ui()
    if not reduced_motion:
        queue_redraw()

func _draw() -> void:
    # Native dock atmosphere is rendered by the existing isolated depth-review layer.
    # This child review branch only refines presentation chrome and diegetic markers.
    _draw_review_chrome()
    _draw_signal_device()
    _draw_challenge_device()
    if stage == "complete":
        _draw_choice_payoff()
    draw_string(ThemeDB.fallback_font, SIGNAL_POINT + Vector2(-39, 15), "SIGNAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fff7df"))
    draw_line(SIGNAL_POINT + Vector2(-40, 20), SIGNAL_POINT + Vector2(34, 20), Color(0.47, 0.88, 0.85, 0.62), 1.0)
    draw_string(ThemeDB.fallback_font, IONIA_POINT + Vector2(-23, 20), "IONIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fff7df"))
    draw_string(ThemeDB.fallback_font, CHALLENGE_POINT + Vector2(-45, 18), "CHALLENGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fff7df"))
    draw_line(CHALLENGE_POINT + Vector2(-46, 23), CHALLENGE_POINT + Vector2(43, 23), Color(0.85, 0.70, 0.43, 0.62), 1.0)

func _draw_review_chrome() -> void:
    var deep := Color(0.035, 0.075, 0.13, 0.82)
    var deep_soft := Color(0.035, 0.075, 0.13, 0.76)
    var ivory := Color("#fff7df")
    var brass := Color("#d8b475")
    var aether := Color("#78d9d1")
    # Two lighter instrument-like bands preserve more of the sky than the old monolithic HUD.
    draw_rect(Rect2(12, 9, 936, 43), deep)
    draw_rect(Rect2(12, 54, 936, 38), deep_soft)
    draw_rect(Rect2(12, 540, 936, 94), Color(0.028, 0.067, 0.12, 0.88))
    for rect in [Rect2(12, 9, 936, 43), Rect2(12, 54, 936, 38), Rect2(12, 540, 936, 94)]:
        draw_rect(rect, Color(brass, 0.58), false, 1.0)
    draw_line(Vector2(26, 52), Vector2(934, 52), Color(aether, 0.44), 1.0)
    draw_line(Vector2(30, 540), Vector2(930, 540), Color(brass, 0.72), 2.0)
    draw_line(Vector2(24, 548), Vector2(24, 625), Color(aether, 0.72), 3.0)
    # Small crafted corner fasteners read as ship instrumentation rather than generic boxes.
    for p in [Vector2(20, 17), Vector2(940, 17), Vector2(20, 626), Vector2(940, 626)]:
        draw_circle(p, 3.0, Color(brass, 0.86))
        draw_circle(p, 1.2, ivory)

func _draw_signal_device() -> void:
    var center := SIGNAL_POINT + Vector2(0, -38)
    var brass := Color("#d8b475")
    var aether := Color("#8be5df")
    draw_line(center + Vector2(0, 11), SIGNAL_POINT + Vector2(0, -5), Color("#665446"), 4.0)
    draw_line(center + Vector2(-11, 13), center + Vector2(11, 13), brass, 3.0)
    draw_circle(center, 20.0, Color(0.25, 0.86, 0.84, 0.08))
    draw_arc(center, 14.0, 0.0, TAU, 28, Color(brass, 0.88), 2.0)
    draw_circle(center, 8.0, Color("#17364d"))
    draw_circle(center, 4.5, aether)
    if not reduced_motion:
        var pulse: float = 2.0 + 2.0 * (0.5 + 0.5 * sin(elapsed_seconds * 1.25))
        draw_arc(center, 20.0 + pulse, -2.55, -0.58, 18, Color(aether, 0.46), 2.0)
        draw_arc(center, 20.0 + pulse, 0.58, 2.55, 18, Color(aether, 0.46), 2.0)

func _draw_challenge_device() -> void:
    var center := CHALLENGE_POINT + Vector2(0, -42)
    var brass := Color("#d8b475")
    var violet := Color("#8178a8")
    var points := [
        center + Vector2(0, -24),
        center + Vector2(24, 0),
        center + Vector2(0, 24),
        center + Vector2(-24, 0)
    ]
    draw_colored_polygon(PackedVector2Array(points), Color(0.16, 0.17, 0.30, 0.94))
    draw_polyline(PackedVector2Array(points + [points[0]]), Color(brass, 0.82), 2.0)
    draw_circle(center, 15.0, violet)
    draw_circle(center, 8.0, Color("#302c54"))
    draw_line(center + Vector2(-6, 0), center + Vector2(6, 0), Color("#efe1ba"), 2.0)
    if stage == "encounter":
        var telegraph_color := Color("#f1d88e") if encounter.telegraph_winding_up else Color("#8be5df")
        draw_arc(center, 30.0, -2.55, -0.58, 18, telegraph_color, 3.0)
        draw_arc(center, 30.0, 0.58, 2.55, 18, telegraph_color, 3.0)
        if encounter.echo_focus > 0:
            draw_arc(center, 35.0, 0.0, TAU, 32, Color("#f1d88e"), 2.0)

func _draw_choice_payoff() -> void:
    var center := SIGNAL_POINT + Vector2(0, -38)
    var payoff := Color("#f1d88e") if choice_state.choice == ChoiceState.Choice.REPAIR_BEACON else Color("#8cdbc8")
    draw_circle(center, 32.0, Color(payoff, 0.10))
    draw_arc(center, 25.0, 0.0, TAU, 32, Color(payoff, 0.82), 3.0)
    draw_arc(center, 31.0, -2.75, -0.40, 22, Color(payoff, 0.48), 2.0)
    draw_line(center + Vector2(0, -27), center + Vector2(0, -53), Color(payoff, 0.54), 3.0)

func discover_signal() -> bool:
    if stage != "search":
        return false
    choice_state.discover_signal()
    stage = "meet"
    _story_message = "A broken signal repeats two notes. Ionia might know who is waiting for an answer."
    _record("clue_discovered")
    _refresh_ui()
    return true

func open_choice() -> bool:
    if stage != "meet" or not choice_state.discovered_signal:
        return false
    stage = "choose"
    ender.player_controlled = false
    _story_message = "Ionia: The crew needs a hand, but the beacon could guide others home."
    _record("dialogue_open")
    _refresh_ui()
    return true

func choose_path(help_crew: bool) -> bool:
    if stage != "choose":
        return false
    var selection: int = ChoiceState.Choice.HELP_CREW if help_crew else ChoiceState.Choice.REPAIR_BEACON
    if not choice_state.choose(selection):
        return false
    stage = "approach"
    ender.player_controlled = true
    _story_message = "Your promise is made. Try the signal challenge on the far side of the dock."
    _record("choice_crew" if help_crew else "choice_beacon")
    _refresh_ui()
    return true

func start_encounter() -> bool:
    if stage != "approach" or choice_state.choice == ChoiceState.Choice.UNSET:
        return false
    encounter = Encounter.new()
    stage = "encounter"
    ender.player_controlled = false
    _story_message = "A pulse gathers. Guard the warning to build an echo; strike when it quiets."
    _record("encounter_started")
    _refresh_ui()
    return true

func encounter_action(action: String) -> bool:
    if stage != "encounter" or not encounter.take_turn(action):
        return false
    if encounter.completed:
        if not choice_state.complete_challenge():
            return false
        stage = "return"
        ender.player_controlled = true
        _story_message = "The signal is calm. Return to the blue light to see what changed."
        _record("encounter_completed")
    elif encounter.is_failed():
        stage = "approach"
        ender.player_controlled = true
        _story_message = "The pulse overwhelmed you. Try again with guard when it gathers."
        _record("encounter_retry")
    else:
        _story_message = ("Your guard built an echo. " if action == "guard" and encounter.echo_focus > 0 else "Your action: " + action + ". ") + encounter.telegraph_text()
    _refresh_ui()
    queue_redraw()
    return true

func finish_at_dock() -> bool:
    if stage != "return" or choice_state.dock_payoff_key().is_empty():
        return false
    stage = "complete"
    if choice_state.dock_payoff_key() == "crew_reconnected":
        _story_message = "The crew lights a welcome lantern. Someone answers the signal at last."
    else:
        _story_message = "The beacon shines again. A distant vessel sends a grateful reply."
    _record("payoff_reached")
    _refresh_ui()
    queue_redraw()
    return true

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode == KEY_M:
        reduced_motion = not reduced_motion
        queue_redraw()
    elif event.keycode == KEY_P:
        trace_opt_in = not trace_opt_in
        if not trace_opt_in:
            trace_events.clear()
    elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
        text_size = mini(30, text_size + 2)
        story.add_theme_font_size_override("font_size", text_size)
    elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
        text_size = maxi(18, text_size - 2)
        story.add_theme_font_size_override("font_size", text_size)
    elif stage == "choose" and event.keycode == KEY_1:
        choose_path(true)
    elif stage == "choose" and event.keycode == KEY_2:
        choose_path(false)
    elif stage == "encounter" and event.keycode == KEY_1:
        encounter_action("strike")
    elif stage == "encounter" and event.keycode == KEY_2:
        encounter_action("guard")
    elif event.keycode == KEY_ESCAPE and stage == "choose":
        stage = "meet"
        ender.player_controlled = true
        _story_message = "You can talk to Ionia again whenever you're ready."
        _refresh_ui()
    elif event.keycode == KEY_ESCAPE and stage == "encounter":
        stage = "approach"
        ender.player_controlled = true
        _story_message = "The challenge can be retried at any time."
        _refresh_ui()
    elif event.keycode == KEY_E and ender.player_controlled:
        if stage == "search" and ender.global_position.distance_to(SIGNAL_POINT) <= 85.0:
            discover_signal()
        elif stage == "meet" and ender.global_position.distance_to(IONIA_POINT) <= 85.0:
            open_choice()
        elif stage == "approach" and ender.global_position.distance_to(CHALLENGE_POINT) <= 85.0:
            start_encounter()
        elif stage == "return" and ender.global_position.distance_to(SIGNAL_POINT) <= 85.0:
            finish_at_dock()

func _refresh_ui() -> void:
    if stage_label == null:
        return
    stage_label.text = "STUDY: " + stage.to_upper() + "   |   Movement: arrows   |   M: reduced motion   |   +/-: text size"
    story.text = _story_message
    if stage == "choose":
        hint.text = "1: Help the crew   |   2: Repair the beacon   |   Esc: later"
    elif stage == "encounter":
        hint.text = "HP %d  |  Signal %d  |  Echo %d  |  1: Strike  2: Guard  Esc: exit" % [encounter.player_hp, encounter.challenge_hp, encounter.echo_focus]
    elif stage == "complete":
        hint.text = "Prototype complete. Choice and consequence shown; no save or story canon."
    else:
        hint.text = "E: interact near labeled marker  |  P: local review trace %s" % ("ON" if trace_opt_in else "OFF")

func _record(event_name: String) -> void:
    if trace_opt_in:
        trace_events.append({"event": event_name, "seconds": snappedf(elapsed_seconds, 0.1)})
