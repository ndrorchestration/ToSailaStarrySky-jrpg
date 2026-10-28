extends Node2D
## Real player-controlled post-splashdown shipboard inspection scene.
## Reuses native Ender movement and Chapter I input. Art remains provisional.
const Actor = preload("res://scripts/pilot_actor.gd")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const BOUNDS := Rect2(Vector2(112, 404), Vector2(736, 122))
const RESERVE_STATION := Vector2(420, 467)
const INTERACT_DISTANCE := 82.0

var session
var ender: CharacterBody2D
var ionia: CharacterBody2D
var objective: Label
var hint: Label
var text_label: Label
var reserve_dialogue_open: bool = false
var messages: Array[String] = [
    "ENDER: The engine reserve reads empty. Whatever powered the first lift is gone.",
    "IONIA: Denith knew more about this vessel than he could teach me. We need evidence, not guesses.",
    "ENDER: I'll record the depletion. The actual fuel composition is still unknown.",
]
var dialogue_index: int = 0
var inspected_station: bool = false
var checkpoint_message: String = ""

func configure(the_session) -> bool:
    if is_inside_tree() or the_session == null:
        return false
    if the_session.opening.step_key() not in ["waterborne", "postflight_diagnosis"]:
        return false
    if not the_session.physical_landing_observed:
        return false
    if the_session.opening.active_party_ids != ["ender", "ionia"]:
        return false
    session = the_session
    return true

func _ready() -> void:
    InputPolicy.ensure_defaults()
    var actors := Node2D.new()
    actors.name = "LocalShipboardActors"
    actors.y_sort_enabled = true
    add_child(actors)

    ender = Actor.new()
    ender.name = "PlayableEnderAfterSplashdown"
    ender.character_name = "Ender"
    ender.player_controlled = true
    ender.walking_bounds = BOUNDS
    ender.position = Vector2(223, 466)
    actors.add_child(ender)
    ender.set_walk_review_enabled(true)

    ionia = Actor.new()
    ionia.name = "IoniaAtEngineeringAfterSplashdown"
    ionia.character_name = "Ionia"
    ionia.player_controlled = false
    ionia.walking_bounds = BOUNDS
    ionia.position = Vector2(718, 464)
    actors.add_child(ionia)
    ionia.set_ionia_stage_art_enabled(true, "west")

    var layer := CanvasLayer.new()
    layer.name = "PostflightGameHUD"
    add_child(layer)
    objective = _label(layer, Vector2(26, 17), 23)
    hint = _label(layer, Vector2(27, 556), 17)
    text_label = _label(layer, Vector2(92, 572), 17)
    text_label.custom_minimum_size = Vector2(786, 58)
    _sync_ui()
    queue_redraw()

func _label(parent: Node, at: Vector2, font_size: int) -> Label:
    var out := Label.new()
    out.position = at
    out.custom_minimum_size.x = 890
    out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    out.add_theme_font_size_override("font_size", font_size)
    out.add_theme_color_override("font_color", Color("#f4e4c8"))
    out.add_theme_color_override("font_shadow_color", Color("#142337"))
    parent.add_child(out)
    return out

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 640), Color("#1a3446"))
    draw_rect(Rect2(0, 178, 960, 222), Color("#2e4855"))
    draw_rect(Rect2(0, 400, 960, 135), Color("#705947"))
    for k in range(8):
        draw_line(Vector2(0, 404 + k * 18), Vector2(960, 404 + k * 18),
            Color("#99816b"), 1.0)
    for x in [88.0, 320.0, 662.0, 883.0]:
        draw_line(Vector2(x, 205), Vector2(x, 395), Color("#c2a57b"), 4.0)
    draw_rect(Rect2(335, 278, 176, 116), Color("#182d39"))
    draw_rect(Rect2(350, 290, 144, 89), Color("#31525b"))
    draw_arc(RESERVE_STATION + Vector2(0, -116), 38, 0, TAU, 48,
        Color("#c37b60") if not inspected_station else Color("#88b9ad"), 4.0)
    draw_line(Vector2(372, 355), Vector2(472, 355), Color("#d5b68b"), 2.0)
    draw_rect(Rect2(0, 0, 960, 112), Color(0.04, 0.08, 0.14, 0.92))
    draw_rect(Rect2(0, 537, 960, 103), Color(0.04, 0.08, 0.14, 0.96))

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(InputPolicy.INTERACT) and not event.is_echo():
        if interact_reserve():
            get_viewport().set_input_as_handled()

func interact_reserve() -> bool:
    if session == null:
        return false
    if reserve_dialogue_open:
        if dialogue_index < messages.size() - 1:
            dialogue_index += 1
            _sync_ui()
            return true
        reserve_dialogue_open = false
        dialogue_index = 0
        ender.player_controlled = true
        if not inspected_station:
            if not session.inspect_depleted_reserve():
                _sync_ui()
                return false
            inspected_station = true
            # Clear any earlier refused-save notice once the player earns the checkpoint.
            checkpoint_message = ""
        _sync_ui()
        return true
    if ender.position.distance_to(RESERVE_STATION) > INTERACT_DISTANCE:
        return false
    if inspected_station:
        checkpoint_message = "Reserve confirmed empty. F5 saves the postflight checkpoint."
        _sync_ui()
        return true
    reserve_dialogue_open = true
    ender.player_controlled = false
    dialogue_index = 0
    _sync_ui()
    return true

func notify_checkpoint(message: String) -> void:
    checkpoint_message = message
    _sync_ui()

func _sync_ui() -> void:
    if objective == null:
        return
    var done: bool = session != null and session.can_checkpoint()
    objective.text = "FIRST WAKE / POST-SPLASHDOWN — ENDER + IONIA\n" + (
        "Reserve inspected. F5: save  |  R: request staged safe berth (two confirmations)" if done else
        "Ship stable. Examine the depleted engine reserve (E).")
    if reserve_dialogue_open:
        text_label.text = messages[dialogue_index]
        hint.text = "E: continue  |  " + str(dialogue_index + 1) + "/" + str(messages.size())
        text_label.visible = true
    else:
        hint.text = checkpoint_message if not checkpoint_message.is_empty() else (
            "Arrows: move  |  E: inspect  |  F5: checkpoint  |  F9: reload")
        text_label.visible = false
    queue_redraw()
