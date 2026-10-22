extends Node2D
## Opt-in, noncanonical, standalone First Wake playability experiment.
## Original Godot pilot, approved Ender assets and Ionia art-review controls are untouched.

const Actor = preload("res://scripts/pilot_actor.gd")
const DockDepthReview = preload("res://scripts/dock_depth_review.gd")
const ChoiceState = preload("res://scripts/vertical_slice_choice_state.gd")
const Encounter = preload("res://scripts/vertical_slice_encounter.gd")
const PromptModel = preload("res://scripts/vertical_slice_prompt_model.gd")
const InputPolicy = preload("res://scripts/vertical_slice_input_policy.gd")
const SignalAudio = preload("res://scripts/vertical_slice_signal_audio.gd")
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
var audio_enabled: bool = true
var signal_audio_player: AudioStreamPlayer
var trace_events: Array[Dictionary] = []
var post_payoff_reaction_seen: bool = false
var _story_message: String = "Something on the dock is sending a faint signal. Look for the small blue light."

func _ready() -> void:
    InputPolicy.ensure_defaults()
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

    signal_audio_player = AudioStreamPlayer.new()
    signal_audio_player.name = "OriginalSignalAudioReviewOnly"
    signal_audio_player.volume_db = -8.0
    add_child(signal_audio_player)

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
    draw_rect(Rect2(12, 9, 936, 86), Color(0.045, 0.085, 0.15, 0.92))
    draw_rect(Rect2(12, 536, 936, 98), Color(0.045, 0.085, 0.15, 0.94))
    # Readable symbols and labels accompany every colored object.
    var light_radius: float = 16.0 if reduced_motion else 16.0 + 2.0 * sin(elapsed_seconds * 1.3)
    draw_circle(SIGNAL_POINT + Vector2(0, -38), light_radius, Color("#a8e4ee"))
    draw_line(SIGNAL_POINT + Vector2(-9, -48), SIGNAL_POINT + Vector2(9, -28), Color("#17364d"), 3.0)
    draw_line(SIGNAL_POINT + Vector2(9, -48), SIGNAL_POINT + Vector2(-9, -28), Color("#17364d"), 3.0)
    draw_circle(CHALLENGE_POINT + Vector2(0, -44), 24, Color("#b8a3ce"))
    draw_circle(CHALLENGE_POINT + Vector2(0, -44), 13, Color("#403c65"))
    if stage == "encounter" and encounter.echo_focus > 0:
        draw_arc(CHALLENGE_POINT + Vector2(0, -44), 29.0, 0.0, TAU, 32, Color("#f1d88e"), 3.0)
    if stage == "complete":
        draw_circle(SIGNAL_POINT + Vector2(0, -38), 30, Color("#f1d88e") if choice_state.choice == ChoiceState.Choice.REPAIR_BEACON else Color("#8cdbc8"))
    draw_string(ThemeDB.fallback_font, SIGNAL_POINT + Vector2(-45, 15), "SIGNAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
    draw_string(ThemeDB.fallback_font, IONIA_POINT + Vector2(-23, 20), "IONIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
    draw_string(ThemeDB.fallback_font, CHALLENGE_POINT + Vector2(-50, 18), "CHALLENGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

func discover_signal() -> bool:
    if stage != "search":
        return false
    choice_state.discover_signal()
    stage = "meet"
    _story_message = "A broken signal repeats two notes. Ionia might know who is waiting for an answer."
    _record("clue_discovered")
    _play_signal_audio(SignalAudio.make_question())
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
    _play_signal_audio(SignalAudio.make_answer())
    _refresh_ui()
    queue_redraw()
    return true

func hear_ionia_reaction() -> bool:
    if stage != "complete" or post_payoff_reaction_seen:
        return false
    post_payoff_reaction_seen = true
    if choice_state.choice == ChoiceState.Choice.HELP_CREW:
        _story_message = "Ionia: You chose the people standing here. That kind of answer travels farther than you think."
    else:
        _story_message = "Ionia: One light cannot mend the whole sky. But someone out there can see a way home now."
    _record("ionia_post_payoff_reaction")
    _refresh_ui()
    return true

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(InputPolicy.CHOICE_PRIMARY):
        if stage == "choose":
            choose_path(true)
            return
        if stage == "encounter":
            encounter_action("strike")
            return
    if event.is_action_pressed(InputPolicy.CHOICE_SECONDARY):
        if stage == "choose":
            choose_path(false)
            return
        if stage == "encounter":
            encounter_action("guard")
            return
    if event.is_action_pressed(InputPolicy.INTERACT) and ender.player_controlled:
        if stage == "search" and ender.global_position.distance_to(SIGNAL_POINT) <= 85.0:
            discover_signal()
        elif stage == "meet" and ender.global_position.distance_to(IONIA_POINT) <= 85.0:
            open_choice()
        elif stage == "approach" and ender.global_position.distance_to(CHALLENGE_POINT) <= 85.0:
            start_encounter()
        elif stage == "return" and ender.global_position.distance_to(SIGNAL_POINT) <= 85.0:
            finish_at_dock()
        elif stage == "complete" and ender.global_position.distance_to(IONIA_POINT) <= 85.0:
            hear_ionia_reaction()
        return
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode == KEY_M:
        reduced_motion = not reduced_motion
        queue_redraw()
    elif event.keycode == KEY_S:
        audio_enabled = not audio_enabled
        if not audio_enabled and signal_audio_player != null:
            signal_audio_player.stop()
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

func context_prompt_text() -> String:
    if ender == null:
        return ""
    return PromptModel.prompt(
        stage,
        ender.global_position.distance_to(SIGNAL_POINT),
        ender.global_position.distance_to(IONIA_POINT),
        ender.global_position.distance_to(CHALLENGE_POINT),
        InputPolicy.primary_label(InputPolicy.INTERACT),
        post_payoff_reaction_seen
    )

func _refresh_ui() -> void:
    if stage_label == null:
        return
    stage_label.text = "STUDY: " + stage.to_upper() + "   |   Movement: arrows   |   M: reduced motion   |   S: sound   |   +/-: text size"
    story.text = _story_message
    if stage == "choose":
        hint.text = "1: Help the crew   |   2: Repair the beacon   |   Esc: later"
    elif stage == "encounter":
        hint.text = "HP %d  |  Signal %d  |  Echo %d  |  1: Strike  2: Guard  Esc: exit" % [encounter.player_hp, encounter.challenge_hp, encounter.echo_focus]
    elif stage == "complete":
        var optional_prompt := context_prompt_text()
        hint.text = ("Prototype complete. " if optional_prompt.is_empty() else optional_prompt + "  |  ") + "No save or story canon."
    else:
        hint.text = context_prompt_text() + "  |  P: local review trace %s" % ("ON" if trace_opt_in else "OFF")

func _play_signal_audio(stream: AudioStreamWAV) -> void:
    if not audio_enabled or signal_audio_player == null:
        return
    signal_audio_player.stream = stream
    signal_audio_player.play()

func _record(event_name: String) -> void:
    if trace_opt_in:
        trace_events.append({"event": event_name, "seconds": snappedf(elapsed_seconds, 0.1)})
