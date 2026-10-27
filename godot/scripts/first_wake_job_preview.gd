extends Node2D
## Standalone playable First Wake employment / engineering preview.
## Forward story candidate, NOT an approved art pack or replacement of live Chapter I.
## Open directly: res://scenes/first_wake_job_preview.tscn (F6 in Godot).
## No flight, water physics, save migration, release or new combat permissions.

const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Actor = preload("res://scripts/pilot_actor.gd")
const Dock = preload("res://scripts/dock_depth_review.gd")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")

const FLYER_POSITION := Vector2(442, 463)
const IONIA_DOCK_POSITION := Vector2(677, 467)
const GANGWAY_POSITION := Vector2(794, 467)
const ROOM_POSITIONS := {
    "reference": Vector2(335, 465),
    "containment": Vector2(493, 465),
    "fuel": Vector2(654, 465),
    "checklist": Vector2(809, 465),
}
const INTERACT_RADIUS := 76.0
const ROOM_BOUNDS := Rect2(Vector2(110, 405), Vector2(735, 119))
const DOCK_BOUNDS := Rect2(Vector2(145, 410), Vector2(670, 112))
const ENGINEERING_ITEMS := ["reference", "containment", "fuel"]

var opening = Opening.new()
var room: String = "dock"
var flyer_read: bool = false
var inspected_items: Array[String] = []
var ender: CharacterBody2D
var ionia: CharacterBody2D
var dock_background: Node2D
var dock_foreground: Node2D
var headline: Label
var objective: Label
var hint: Label
var party_label: Label
var dialogue_speaker: Label
var dialogue_text: Label
var dialogue_open: bool = false
var dialogue_lines: Array = []
var dialogue_cursor: int = 0
var dialogue_event: String = ""
var dialogue_character: String = ""
var last_message: String = "Read the job notice, then speak to the captain."

func _ready() -> void:
    InputPolicy.ensure_defaults()

    dock_background = Dock.new()
    dock_background.name = "ExistingDockBackground"
    dock_background.z_index = -4
    add_child(dock_background)

    var actors := Node2D.new()
    actors.name = "ReviewActors"
    actors.y_sort_enabled = true
    add_child(actors)

    ender = Actor.new()
    ender.name = "Ender"
    ender.character_name = "Ender"
    ender.player_controlled = true
    ender.walking_bounds = DOCK_BOUNDS
    ender.position = Vector2(228, 468)
    actors.add_child(ender)
    ender.set_walk_review_enabled(true)

    ionia = Actor.new()
    ionia.name = "Ionia"
    ionia.character_name = "Ionia"
    ionia.player_controlled = false
    ionia.walking_bounds = DOCK_BOUNDS
    ionia.position = IONIA_DOCK_POSITION
    actors.add_child(ionia)
    ionia.set_ionia_stage_art_enabled(true, "west")

    dock_foreground = Dock.new()
    dock_foreground.name = "ExistingDockForeground"
    dock_foreground.foreground = true
    dock_foreground.z_index = 3
    add_child(dock_foreground)

    var ui := CanvasLayer.new()
    ui.name = "ReadableGameplayOverlay"
    add_child(ui)
    headline = _label(ui, Vector2(22, 17), 24, 900)
    objective = _label(ui, Vector2(24, 57), 17, 910)
    party_label = _label(ui, Vector2(24, 91), 15, 910)
    hint = _label(ui, Vector2(26, 569), 16, 908)
    dialogue_speaker = _label(ui, Vector2(120, 539), 16, 730)
    dialogue_text = _label(ui, Vector2(120, 566), 18, 730)
    dialogue_text.custom_minimum_size.y = 58.0
    _sync_presentation()

func _label(parent: Node, pos: Vector2, font_size: int, width: float) -> Label:
    var node := Label.new()
    node.position = pos
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", Color("#fff4db"))
    node.add_theme_color_override("font_shadow_color", Color("#142237"))
    node.add_theme_constant_override("shadow_offset_x", 1)
    node.add_theme_constant_override("shadow_offset_y", 2)
    node.custom_minimum_size = Vector2(width, 28)
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(node)
    return node

func _draw() -> void:
    if room == "dock":
        # Dock is the existing Godot stage, dressed with only new interactables.
        draw_rect(Rect2(408, 392, 69, 57), Color("#533d33"))
        draw_rect(Rect2(417, 397, 50, 45), Color("#e8d9ad"))
        draw_line(Vector2(421, 406), Vector2(461, 406), Color("#796451"), 2.0)
        for offset in [416.0, 424.0, 432.0]:
            draw_line(Vector2(425, offset), Vector2(459, offset), Color("#8c7a65"), 1.4)
        draw_rect(Rect2(772, 408, 76, 35), Color("#66503d"))
        draw_line(Vector2(772, 444), Vector2(848, 444), Color("#e3b875"), 3.0)
        draw_string(ThemeDB.fallback_font, Vector2(395, 377), "JOB NOTICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f2d59a"))
        draw_string(ThemeDB.fallback_font, Vector2(737, 384), "WAKE GANGWAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#f2d59a"))
        draw_circle(FLYER_POSITION + Vector2(0, -80), 5.0, Color("#e8d99f") if not flyer_read else Color("#90a99b"))
    else:
        _draw_engineering_room()

func _draw_engineering_room() -> void:
    draw_rect(Rect2(0, 0, 960, 640), Color("#1b3444"))
    draw_rect(Rect2(0, 212, 960, 323), Color("#294651"))
    draw_rect(Rect2(0, 393, 960, 147), Color("#715847"))
    for row in range(7):
        draw_line(Vector2(0, 399 + row * 22), Vector2(960, 399 + row * 22), Color("#9c7856"), 1.0)
    for x in [65.0, 220.0, 430.0, 625.0, 845.0]:
        draw_line(Vector2(x, 204), Vector2(x, 392), Color("#ba9063"), 5.0)
    draw_rect(Rect2(267, 273, 613, 118), Color("#182a38"))
    draw_rect(Rect2(279, 284, 590, 91), Color("#314956"))
    for item in ENGINEERING_ITEMS:
        var p: Vector2 = ROOM_POSITIONS[item]
        var completed: bool = item in inspected_items
        var color := Color("#8db7ad") if completed else Color("#e8be83")
        draw_circle(p + Vector2(0, -131), 31, Color("#244758"))
        draw_arc(p + Vector2(0, -131), 25, 0, TAU, 24, color, 4.0)
        draw_line(p + Vector2(-18, -131), p + Vector2(18, -131), color, 3.0)
        draw_rect(Rect2(p + Vector2(-45, -115), Vector2(90, 25)), Color("#243a4a"))
        draw_string(ThemeDB.fallback_font, p + Vector2(-43, -99), item.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f3dbb3"))
    var check: Vector2 = ROOM_POSITIONS["checklist"]
    draw_rect(Rect2(check + Vector2(-41, -150), Vector2(91, 76)), Color("#5b4439"))
    draw_rect(Rect2(check + Vector2(-34, -143), Vector2(77, 61)), Color("#d5c094") if inspected_items.size() == 3 else Color("#8b7f6c"))
    draw_string(ThemeDB.fallback_font, check + Vector2(-29, -111), "SAFETY", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#342e28"))
    draw_string(ThemeDB.fallback_font, check + Vector2(-29, -95), "CHECK", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#342e28"))
    draw_string(ThemeDB.fallback_font, Vector2(42, 250), "AUREATE WAKE / ENGINEERING", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#dec395"))
    draw_rect(Rect2(94, 535, 780, 94), Color(0.04, 0.08, 0.16, 0.92))
    draw_line(Vector2(96, 535), Vector2(872, 535), Color("#bfa075"), 2.0)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(InputPolicy.INTERACT) and not event.is_echo():
        interact()
        get_viewport().set_input_as_handled()

func interact() -> bool:
    if dialogue_open:
        return _advance_dialogue()
    if room == "dock":
        if not flyer_read and _is_near(FLYER_POSITION):
            _start_dialogue("ENDER", [
                "Filled. Filled. And this one wants someone with six years of sky-lane experience.",
                "Wait. 'Harmonic levitation systems. Phase-alignment familiarity preferred.'",
                "Captain Ionia, aboard the Aureate Wake. 'Assistance,' not 'miracle.' I should ask.",
            ], "flyer")
            return true
        if flyer_read and not "ionia" in opening.active_party_ids and _is_near(IONIA_DOCK_POSITION):
            _start_dialogue("IONIA / ENDER", [
                "IONIA: If you're here about the flyer, give me a moment. This panel only behaves when I don't watch it.",
                "ENDER: I'm Ender. I understand harmonic systems. At least, the parts that behave on paper.",
                "IONIA: The Wake hasn't behaved anywhere for a year. Months of repairs, and I need a careful second set of hands.",
                "ENDER: Is this paid work? I could really use the job.",
                "IONIA: Modestly, at first. Tell me what you can verify, not what you wish were true.",
                "ENDER: Then I should start in engineering.",
                "IONIA: Welcome aboard. I'll take you down to the regulators.",
            ], "hire")
            return true
        if "ionia" in opening.active_party_ids and _is_near(GANGWAY_POSITION):
            _enter_engineering_room()
            return true
        last_message = "Find the flyer, speak to Ionia, then use the gangway."
        _sync_presentation()
        return false
    if opening.step_key() == "preflight":
        last_message = "Engineering checklist complete. Flight scene not connected in this preview."
        _sync_presentation()
        return false
    for item in ENGINEERING_ITEMS:
        if item not in inspected_items and _is_near(ROOM_POSITIONS[item]):
            match item:
                "reference":
                    _start_dialogue("ENDER / IONIA", [
                        "ENDER: The reference reads steady while the ship is stationary. That may be misleading.",
                        "IONIA: Denith taught me to watch the readings in flight. I never learned every unusual setting.",
                        "ENDER: We'll note what we know, and not assume a static calibration proves stability.",
                    ], "inspect_reference")
                "containment":
                    _start_dialogue("ENDER / IONIA", [
                        "ENDER: Containment is holding in this test. That doesn't guarantee it can handle full lift.",
                        "IONIA: No one leaves dock until we agree on an abort procedure.",
                    ], "inspect_containment")
                "fuel":
                    _start_dialogue("ENDER / IONIA", [
                        "ENDER: This isn't an ordinary fuel intake. The remaining reserve is limited.",
                        "IONIA: Denith insisted on a specific supply. He never finished teaching me all its specifications.",
                        "ENDER: Then we're testing cautiously. We haven't proved what the medium actually does.",
                    ], "inspect_fuel")
            return true
    if _is_near(ROOM_POSITIONS["checklist"]) and inspected_items.size() == ENGINEERING_ITEMS.size():
        _start_dialogue("IONIA / ENDER", [
            "IONIA: Engineering, are we ready for one short controlled test?",
            "ENDER: Static phase checks are within tolerance. Containment holds at idle. Fuel reserves are limited.",
            "IONIA: One short circuit. I'll be at the helm, you take the engineering station. Abort to open water if readings drift.",
            "ENDER: Understood. A test, not a promise that everything is fixed.",
            "IONIA: Exactly. We fly only as far as the evidence allows.",
        ], "preflight")
        return true
    last_message = "Inspect phase reference, containment and fuel, then use SAFETY CHECK."
    _sync_presentation()
    return false

func _enter_engineering_room() -> void:
    if not ("ionia" in opening.active_party_ids) or opening.step_key() != "engineering":
        return
    room = "engineering"
    dock_background.visible = false
    dock_foreground.visible = false
    ender.position = Vector2(226, 470)
    ender.walking_bounds = ROOM_BOUNDS
    ionia.position = Vector2(149, 470)
    ionia.walking_bounds = ROOM_BOUNDS
    ionia.set_ionia_stage_art_enabled(true, "east")
    last_message = "Inspect the three engine stations. Use Interact / E."
    _sync_presentation()

func _is_near(pos: Vector2) -> bool:
    return ender.position.distance_to(pos) <= INTERACT_RADIUS

func _start_dialogue(speaker: String, lines: Array, event_id: String) -> void:
    if dialogue_open or lines.is_empty():
        return
    dialogue_open = true
    dialogue_speaker.text = speaker
    dialogue_lines = lines.duplicate()
    dialogue_cursor = 0
    dialogue_event = event_id
    ender.player_controlled = false
    _sync_presentation()

func _advance_dialogue() -> bool:
    if not dialogue_open:
        return false
    if dialogue_cursor < dialogue_lines.size() - 1:
        dialogue_cursor += 1
        _sync_presentation()
        return true
    var completed_event: String = dialogue_event
    dialogue_open = false
    dialogue_event = ""
    dialogue_lines = []
    dialogue_cursor = 0
    ender.player_controlled = opening.step_key() != "preflight"
    match completed_event:
        "flyer":
            flyer_read = true
            last_message = "Flyer read. Introduce yourself to Captain Ionia."
        "hire":
            if opening.accept_ionia_job():
                last_message = "Ionia joined the story party. Use the ship's gangway."
        "inspect_reference", "inspect_containment", "inspect_fuel":
            var item: String = completed_event.trim_prefix("inspect_")
            if item not in inspected_items:
                inspected_items.append(item)
            last_message = "Engineering inspection %d / 3 recorded." % inspected_items.size()
        "preflight":
            if opening.complete_engineering_checks():
                last_message = "Preflight complete: chapter opening handoff is now ready for review."
                ender.player_controlled = false
    _sync_presentation()
    return true

func _sync_presentation() -> void:
    if headline == null:
        return
    headline.text = "TO SAIL THE STARRY SKY  /  FIRST WAKE — PLAYABLE REVIEW"
    if room == "dock":
        if not flyer_read:
            objective.text = "Find work: inspect the notice posted at the dock."
        elif not ("ionia" in opening.active_party_ids):
            objective.text = "Speak to Captain Ionia about harmonic levitation repairs."
        else:
            objective.text = "Take the gangway aboard the Aureate Wake."
    elif opening.step_key() == "preflight":
        objective.text = "PRE-FLIGHT READY — This preview ends before the test flight."
    else:
        objective.text = "Engineering: inspect reference, containment and fuel (%d / 3)." % inspected_items.size()
    party_label.text = "Story party: " + " + ".join(opening.active_party_ids) + "  |  Review-only art / no live game integration"
    if dialogue_open:
        dialogue_speaker.visible = true
        dialogue_text.visible = true
        dialogue_text.text = str(dialogue_lines[dialogue_cursor])
        hint.text = "Interact / E: next line   |   " + str(dialogue_cursor + 1) + " / " + str(dialogue_lines.size())
    else:
        dialogue_speaker.visible = false
        dialogue_text.visible = false
        hint.text = last_message + "    [Arrows: move  |  E: interact]"
    hint.visible = not dialogue_open
    queue_redraw()
