extends Node2D
## Native Chapter I migration review scene.
## Exercises the packaged First Wake progression in Godot without claiming
## production migration, canon epilogue resolution, save compatibility, or art admission.

const Actor = preload("res://scripts/pilot_actor.gd")
const DockDepthReview = preload("res://scripts/dock_depth_review.gd")
const ChapterState = preload("res://scripts/first_wake_chapter1_state.gd")
const Content = preload("res://scripts/first_wake_chapter1_content.gd")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")

const DECK_BOUNDS := Rect2(Vector2(110, 404), Vector2(740, 118))
const INTERACT_DISTANCE := 74.0

const SIGNAL_POINTS := {
    "harmonic_buoy": Vector2(250, 465),
    "below_frequency": Vector2(390, 465),
    "sky_lane_warning": Vector2(530, 465),
}

const HAZARD_POINTS := {
    "sky_predator": Vector2(170, 465),
    "wind_shear": Vector2(470, 465),
    "corporate_intercept": Vector2(785, 465),
}

const CONTACT_POINTS := {
    "elder_farmer": Vector2(675, 465),
    "engine_spirit": Vector2(250, 465),
    "child_prophet": Vector2(390, 465),
    "corporate_salvager": Vector2(530, 465),
}




var chapter = ChapterState.new()
var ender: CharacterBody2D
var contacts: Dictionary = {}
var headline: Label
var objective: Label
var hint: Label
var party_label: Label
var last_message: String = "Read the three marked signals before the storm crossing."
var deterministic_review_variant: String = "10+"

func _ready() -> void:
    InputPolicy.ensure_defaults()

    var background := DockDepthReview.new()
    background.name = "ChapterOneDockBackgroundReviewOnly"
    background.z_index = -2
    add_child(background)

    var actors := Node2D.new()
    actors.name = "ChapterOneMigrationActors"
    actors.y_sort_enabled = true
    add_child(actors)

    ender = Actor.new()
    ender.name = "EnderChapterOneReviewPlayer"
    ender.character_name = "Ender"
    ender.player_controlled = true
    ender.walking_bounds = DECK_BOUNDS
    ender.position = Vector2(360, 465)
    actors.add_child(ender)

    for contact_id in ChapterState.CONTACT_IDS:
        var actor := Actor.new()
        var contact_name := Content.contact_name(contact_id)
        actor.name = contact_name + "MigrationPlaceholder"
        actor.character_name = contact_name
        actor.player_controlled = false
        actor.walking_bounds = DECK_BOUNDS
        actor.position = CONTACT_POINTS[contact_id]
        actors.add_child(actor)
        contacts[contact_id] = actor

    var foreground := DockDepthReview.new()
    foreground.name = "ChapterOneDockForegroundReviewOnly"
    foreground.foreground = true
    foreground.z_index = 8
    add_child(foreground)

    var ui := CanvasLayer.new()
    ui.name = "ChapterOneMigrationUI"
    add_child(ui)

    headline = _label(ui, Vector2(24, 16), 23)
    objective = _label(ui, Vector2(24, 54), 16)
    party_label = _label(ui, Vector2(650, 18), 15)
    hint = _label(ui, Vector2(28, 568), 15)

    headline.autowrap_mode = TextServer.AUTOWRAP_OFF
    headline.custom_minimum_size = Vector2(540, 32)
    objective.custom_minimum_size = Vector2(570, 36)
    party_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    party_label.custom_minimum_size = Vector2(290, 30)
    hint.custom_minimum_size = Vector2(900, 54)

    headline.text = "AETHERWAKE  /  FIRST WAKE"
    _refresh_ui()
    queue_redraw()

func _label(parent: Node, location: Vector2, size: int) -> Label:
    var label := Label.new()
    label.position = location
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", Color("#fff7df"))
    label.add_theme_color_override("font_shadow_color", Color("#111d2e"))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.custom_minimum_size = Vector2(560, 0)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label

func _draw() -> void:
    draw_rect(Rect2(10, 8, 940, 90), Color(0.035, 0.07, 0.13, 0.92))
    draw_rect(Rect2(10, 550, 940, 82), Color(0.035, 0.07, 0.13, 0.94))

    var stage_key := chapter.stage_key()
    if stage_key == "signal":
        for signal_id in ChapterState.SIGNAL_IDS:
            _draw_target(SIGNAL_POINTS[signal_id], Content.signal_contact_name(signal_id), Color("#9dd9ee"), signal_id in chapter.completed_signals)
    elif stage_key == "crossing":
        for hazard_id in ChapterState.HAZARD_IDS:
            _draw_target(HAZARD_POINTS[hazard_id], Content.hazard_label(hazard_id), Color("#f0a072"), hazard_id in chapter.completed_hazards)
    elif stage_key == "contact":
        _draw_target(CONTACT_POINTS["elder_farmer"], Content.contact_name("elder_farmer").to_upper(), Color("#8cdbc8"), "elder_farmer" in chapter.contacts_met)
    elif stage_key == "choice":
        draw_rect(Rect2(126, 108, 708, 266), Color(0.035, 0.07, 0.13, 0.94))
        draw_rect(Rect2(130, 112, 700, 258), Color("#355168"), false, 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(154, 148), "THE STORM ASKS FOR A DECISION", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#fff1ce"))
        var choice_y := 188.0
        for path_id in ChapterState.CHOICE_IDS:
            var choice_number := ChapterState.CHOICE_IDS.find(path_id) + 1
            draw_string(
                ThemeDB.fallback_font,
                Vector2(154, choice_y),
                str(choice_number) + "  " + Content.choice_label(path_id),
                HORIZONTAL_ALIGNMENT_LEFT,
                648,
                18,
                Color("#d7eaf0")
            )
            draw_string(
                ThemeDB.fallback_font,
                Vector2(174, choice_y + 22),
                Content.choice_description(path_id),
                HORIZONTAL_ALIGNMENT_LEFT,
                620,
                13,
                Color("#9dd9ee")
            )
            choice_y += 60.0
    elif stage_key == "wake":
        draw_circle(CONTACT_POINTS["elder_farmer"] + Vector2(0, -52), 34.0, Color(0.55, 0.92, 0.82, 0.13))
        draw_circle(CONTACT_POINTS["elder_farmer"] + Vector2(0, -52), 14.0, Color("#8cdbc8"))
        draw_string(ThemeDB.fallback_font, CONTACT_POINTS["elder_farmer"] + Vector2(-66, -88), "WAKE RESOLUTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))
    elif stage_key == "done":
        draw_rect(Rect2(150, 142, 660, 244), Color(0.035, 0.07, 0.13, 0.95))
        draw_rect(Rect2(154, 146, 652, 236), Color("#8cdbc8"), false, 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(286, 198), "CHAPTER I COMPLETE", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#fff1ce"))
        draw_string(
            ThemeDB.fallback_font,
            Vector2(246, 246),
            Content.epilogue_name(chapter.epilogue_id),
            HORIZONTAL_ALIGNMENT_LEFT,
            500,
            21,
            Color("#d7eaf0")
        )
        draw_string(
            ThemeDB.fallback_font,
            Vector2(246, 282),
            "Injected review fixture — production epilogue resolver not migrated.",
            HORIZONTAL_ALIGNMENT_LEFT,
            520,
            14,
            Color("#9dd9ee")
        )

func _draw_target(point: Vector2, label_text: String, target_color: Color, completed: bool) -> void:
    var color := Color(target_color, 0.20 if completed else 0.38)
    draw_circle(point + Vector2(0, -45), 24.0, color)
    draw_circle(point + Vector2(0, -45), 9.0, target_color.darkened(0.25) if completed else target_color)
    draw_string(
        ThemeDB.fallback_font,
        point + Vector2(-34, -82),
        ("DONE " if completed else "") + label_text,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        15,
        Color("#e8f5f5")
    )

func interact_nearest() -> bool:
    match chapter.stage_key():
        "signal":
            return _interact_signal()
        "crossing":
            return _interact_hazard()
        "contact":
            return _interact_contact()
        "wake":
            if ender.global_position.distance_to(CONTACT_POINTS["elder_farmer"]) <= INTERACT_DISTANCE:
                return resolve_wake_review()
    return false

func complete_signal_contact(signal_id: String) -> bool:
    if signal_id not in ChapterState.SIGNAL_IDS:
        return false
    var contact_id := Content.signal_contact_id(signal_id)
    if contact_id.is_empty():
        return false
    chapter.meet_contact(contact_id)
    if not chapter.complete_signal(signal_id):
        return false
    last_message = Content.signal_contact_name(signal_id) + ": " + Content.contact_review_excerpt(contact_id)
    _after_progress()
    return true

func complete_hazard_review(hazard_id: String) -> bool:
    if not chapter.complete_hazard(hazard_id):
        return false
    last_message = "Crossing cleared: " + Content.hazard_label(hazard_id) + "."
    _after_progress()
    return true

func meet_ionia_for_choice() -> bool:
    if chapter.stage_key() != "contact":
        return false
    if not chapter.meet_contact("elder_farmer"):
        return false
    last_message = "Ionia: " + Content.contact_review_excerpt("elder_farmer")
    _after_progress()
    return true

func choose_path_review(path_id: String) -> bool:
    if not chapter.choose_path(path_id, deterministic_review_variant):
        return false
    last_message = Content.choice_outcome(path_id, deterministic_review_variant)
    ender.player_controlled = true
    _after_progress()
    return true

func resolve_wake_review() -> bool:
    if chapter.stage_key() != "wake":
        return false
    var injected_epilogue_id := Content.review_epilogue_fixture(chapter.choice_path)
    if injected_epilogue_id.is_empty():
        return false
    if not chapter.complete_wake(injected_epilogue_id):
        return false
    last_message = "REVIEW FIXTURE — " + Content.epilogue_name(injected_epilogue_id) + ": " + Content.epilogue_text(injected_epilogue_id)
    ender.player_controlled = false
    _after_progress()
    return true

func _interact_signal() -> bool:
    var nearest_id := _nearest_pending(SIGNAL_POINTS, chapter.completed_signals)
    if nearest_id.is_empty():
        return false
    if ender.global_position.distance_to(SIGNAL_POINTS[nearest_id]) > INTERACT_DISTANCE:
        return false
    return complete_signal_contact(nearest_id)

func _interact_hazard() -> bool:
    var nearest_id := _nearest_pending(HAZARD_POINTS, chapter.completed_hazards)
    if nearest_id.is_empty():
        return false
    if ender.global_position.distance_to(HAZARD_POINTS[nearest_id]) > INTERACT_DISTANCE:
        return false
    return complete_hazard_review(nearest_id)

func _interact_contact() -> bool:
    if ender.global_position.distance_to(CONTACT_POINTS["elder_farmer"]) > INTERACT_DISTANCE:
        return false
    return meet_ionia_for_choice()

func _nearest_pending(points: Dictionary, completed: Array[String]) -> String:
    var best_id := ""
    var best_distance := INF
    for target_id in points.keys():
        if target_id in completed:
            continue
        var distance := ender.global_position.distance_to(points[target_id])
        if distance < best_distance:
            best_distance = distance
            best_id = target_id
    return best_id

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(InputPolicy.INTERACT) and ender.player_controlled:
        interact_nearest()
        return
    if chapter.stage_key() != "choice":
        return
    if event.is_action_pressed(InputPolicy.CHOICE_A):
        choose_path_review("path_a")
    elif event.is_action_pressed(InputPolicy.CHOICE_B):
        choose_path_review("path_b")
    elif event.is_action_pressed(InputPolicy.CHOICE_C):
        choose_path_review("path_c")

func _after_progress() -> void:
    ender.player_controlled = chapter.stage_key() not in ["choice", "done"]
    _refresh_ui()
    queue_redraw()

func _refresh_ui() -> void:
    if objective == null:
        return
    objective.text = chapter.stage_key().to_upper() + "  /  " + _objective_text()
    party_label.text = "ACTIVE  " + " + ".join(chapter.desired_active_party_ids()).to_upper()
    if chapter.stage_key() == "choice":
        hint.text = "%s: Leave early   %s: Hold dock   %s: Project shield" % [
            InputPolicy.primary_label(InputPolicy.CHOICE_A),
            InputPolicy.primary_label(InputPolicy.CHOICE_B),
            InputPolicy.primary_label(InputPolicy.CHOICE_C),
        ]
    elif chapter.stage_key() == "done":
        hint.text = last_message
    else:
        hint.text = InputPolicy.primary_label(InputPolicy.INTERACT) + ": interact   |   " + last_message

func _objective_text() -> String:
    return Content.objective_text(chapter)
