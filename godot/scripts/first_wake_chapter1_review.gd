extends Node2D
## Native Chapter I migration review scene.
## Exercises the packaged First Wake progression in Godot without claiming
## production migration, canon epilogue resolution, save compatibility, or art admission.

const Actor = preload("res://scripts/pilot_actor.gd")
const DockDepthReview = preload("res://scripts/dock_depth_review.gd")
const ChapterState = preload("res://scripts/first_wake_chapter1_state.gd")
const Content = preload("res://scripts/first_wake_chapter1_content.gd")
const DialogueState = preload("res://scripts/first_wake_chapter1_dialogue_state.gd")
const SaveCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const FormulaEncounter = preload("res://scripts/first_wake_formula_encounter.gd")

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
var dialogue_speaker: Label
var dialogue_body: Label
var dialogue = DialogueState.new()
var pending_signal_id: String = ""
var pending_contact_id: String = ""
var last_message: String = "Read the three marked signals before the storm crossing."
var deterministic_review_variant: String = "10+"
var review_hull_integrity: int = 100
var review_morale: int = 50
var review_engine_integration: int = 0
var resolved_epilogue: Dictionary = {}
var formula_encounter = FormulaEncounter.new()

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
        actor.name = Content.contact_name(contact_id) + "MigrationPlaceholder"
        actor.character_name = Content.contact_name(contact_id)
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
    hint = _label(ui, Vector2(28, 568), 18)
    dialogue_speaker = _label(ui, Vector2(142, 374), 18)
    dialogue_body = _label(ui, Vector2(142, 408), 17)

    dialogue_speaker.custom_minimum_size = Vector2(680, 28)
    dialogue_body.custom_minimum_size = Vector2(680, 120)
    dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_speaker.visible = false
    dialogue_body.visible = false

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
            _draw_target(SIGNAL_POINTS[signal_id], Content.signal_label(signal_id).to_upper(), Color("#9dd9ee"), signal_id in chapter.completed_signals)
    elif stage_key == "crossing":
        for hazard_id in ChapterState.HAZARD_IDS:
            _draw_target(HAZARD_POINTS[hazard_id], Content.hazard_label(hazard_id).to_upper(), Color("#f0a072"), hazard_id in chapter.completed_hazards)
    elif stage_key == "contact":
        _draw_target(CONTACT_POINTS["elder_farmer"], "IONIA", Color("#8cdbc8"), "elder_farmer" in chapter.contacts_met)
    elif stage_key == "choice":
        draw_rect(Rect2(126, 120, 708, 226), Color(0.035, 0.07, 0.13, 0.94))
        draw_rect(Rect2(130, 124, 700, 218), Color("#355168"), false, 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(154, 162), "THE STORM ASKS FOR A DECISION", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#fff1ce"))
        draw_string(ThemeDB.fallback_font, Vector2(154, 205), "1  " + Content.choice_label("path_a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#d7eaf0"))
        draw_string(ThemeDB.fallback_font, Vector2(154, 245), "2  " + Content.choice_label("path_b"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#d7eaf0"))
        draw_string(ThemeDB.fallback_font, Vector2(154, 285), "3  " + Content.choice_label("path_c"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#d7eaf0"))
    elif stage_key == "wake":
        draw_circle(CONTACT_POINTS["elder_farmer"] + Vector2(0, -52), 34.0, Color(0.55, 0.92, 0.82, 0.13))
        draw_circle(CONTACT_POINTS["elder_farmer"] + Vector2(0, -52), 14.0, Color("#8cdbc8"))
        draw_string(ThemeDB.fallback_font, CONTACT_POINTS["elder_farmer"] + Vector2(-66, -88), "WAKE RESOLUTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))
    elif stage_key == "done":
        draw_rect(Rect2(180, 160, 600, 210), Color(0.035, 0.07, 0.13, 0.95))
        draw_rect(Rect2(184, 164, 592, 202), Color("#8cdbc8"), false, 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(292, 222), "CHAPTER I COMPLETE", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#fff1ce"))
        var epilogue_name := str(resolved_epilogue.get("name", "Migration boundary"))
        draw_string(ThemeDB.fallback_font, Vector2(258, 278), epilogue_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#d7eaf0"))

    if dialogue.open:
        draw_rect(Rect2(120, 350, 720, 190), Color(0.035, 0.07, 0.13, 0.97))
        draw_rect(Rect2(124, 354, 712, 182), Color("#8cdbc8"), false, 2.0)

    if formula_encounter.active:
        _draw_formula_review()

func _draw_formula_review() -> void:
    var panel := Rect2(145, 112, 670, 390)
    draw_rect(panel, Color(0.025, 0.055, 0.10, 0.98))
    draw_rect(Rect2(149, 116, 662, 382), Color("#355168"), false, 2.0)

    var target_hp := int(formula_encounter.target.get("hp", 0))
    var target_max := maxi(1, int(formula_encounter.target.get("maxHp", 1)))
    var player_vit := int(formula_encounter.player.get("vit", 0))
    var player_max_vit := maxi(1, int(formula_encounter.player.get("maxVit", 1)))
    var staff_charges := int(formula_encounter.player.get("staffCharges", 0))
    var max_staff_charges := int(formula_encounter.player.get("maxStaffCharges", 0))
    var heat: Dictionary = formula_encounter.player.get("heat", {"current": 0, "max": 3})

    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 154),
        "FORMULA REVIEW ENCOUNTER",
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        24,
        Color("#fff1ce")
    )
    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 184),
        "Production JRPG math · noncanonical target · Chapter I progress unchanged",
        HORIZONTAL_ALIGNMENT_LEFT,
        610,
        14,
        Color("#9dd9ee")
    )

    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 232),
        "ENDER  VIT %d/%d   STAFF %d/%d   HEAT %d/%d" % [
            player_vit,
            player_max_vit,
            staff_charges,
            max_staff_charges,
            int(heat.get("current", 0)),
            int(heat.get("max", 3)),
        ],
        HORIZONTAL_ALIGNMENT_LEFT,
        610,
        18,
        Color("#d7eaf0")
    )
    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 270),
        "%s  HP %d/%d" % [
            str(formula_encounter.target.get("name", "Review target")),
            target_hp,
            target_max,
        ],
        HORIZONTAL_ALIGNMENT_LEFT,
        610,
        19,
        Color("#f0a072")
    )

    var analysis_text := "Weakness hidden.  2: Uncover Truth"
    if formula_encounter.weakness_revealed():
        analysis_text = "ANALYZED: " + str(formula_encounter.target.get("weakness", ""))
    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 306),
        analysis_text,
        HORIZONTAL_ALIGNMENT_LEFT,
        610,
        15,
        Color("#8cdbc8")
    )

    draw_string(ThemeDB.fallback_font, Vector2(176, 356), "1  Staff Strike", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))
    draw_string(ThemeDB.fallback_font, Vector2(390, 356), "2  Uncover Truth", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))
    draw_string(ThemeDB.fallback_font, Vector2(176, 390), "3  Hold", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))
    draw_string(ThemeDB.fallback_font, Vector2(390, 390), "4  Rest", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))

    var status := formula_encounter.last_log()
    if formula_encounter.completed:
        status = "TARGET CLEARED. C closes review; Chapter I state remains unchanged."
    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 438),
        status,
        HORIZONTAL_ALIGNMENT_LEFT,
        610,
        15,
        Color("#d7eaf0")
    )

    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 474),
        "C: close review",
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        13,
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

func start_formula_review() -> bool:
    if formula_encounter.active or dialogue.open or chapter.stage_key() in ["choice", "done"]:
        return false
    formula_encounter.reset()
    if not formula_encounter.start():
        return false
    ender.player_controlled = false
    last_message = formula_encounter.last_log()
    _refresh_ui()
    queue_redraw()
    return true

func close_formula_review() -> bool:
    if not formula_encounter.close():
        return false
    ender.player_controlled = (not dialogue.open) and chapter.stage_key() not in ["choice", "done"]
    last_message = "Formula review closed. Chapter I progression was not changed."
    _refresh_ui()
    queue_redraw()
    return true

func take_formula_review_action(action_id: String) -> bool:
    if not formula_encounter.active:
        return false
    if not formula_encounter.take_action(action_id):
        last_message = formula_encounter.last_log()
        _refresh_ui()
        queue_redraw()
        return false
    last_message = formula_encounter.last_log()
    _refresh_ui()
    queue_redraw()
    return true

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
    var signal_to_contact: Dictionary = {
        "harmonic_buoy": "engine_spirit",
        "below_frequency": "child_prophet",
        "sky_lane_warning": "corporate_salvager",
    }
    var contact_id: String = str(signal_to_contact[signal_id])
    chapter.meet_contact(contact_id)
    if not chapter.complete_signal(signal_id):
        return false
    last_message = Content.contact_name(contact_id) + ": " + Content.signal_line(signal_id)
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
    last_message = "Ionia: " + Content.contact_line("elder_farmer")
    _after_progress()
    return true

func choose_path_review(path_id: String) -> bool:
    if not chapter.choose_path(path_id, deterministic_review_variant):
        return false
    var outcome := Content.choice_outcome(path_id, deterministic_review_variant)
    last_message = Content.choice_label(path_id) + " — " + outcome
    ender.player_controlled = true
    _after_progress()
    return true

func resolve_wake_review() -> bool:
    if chapter.stage_key() != "wake":
        return false
    resolved_epilogue = Content.resolve_legacy_epilogue(
        chapter.choice_path,
        review_hull_integrity,
        review_morale,
        review_engine_integration
    )
    if resolved_epilogue.is_empty():
        return false
    var epilogue_id := str(resolved_epilogue.get("id", ""))
    if not chapter.complete_wake(epilogue_id):
        return false
    last_message = str(resolved_epilogue.get("name", epilogue_id)) + " — " + str(resolved_epilogue.get("text", ""))
    ender.player_controlled = false
    _after_progress()
    return true

func _interact_signal() -> bool:
    var nearest_id := _nearest_pending(SIGNAL_POINTS, chapter.completed_signals)
    if nearest_id.is_empty():
        return false
    if ender.global_position.distance_to(SIGNAL_POINTS[nearest_id]) > INTERACT_DISTANCE:
        return false
    var signal_to_contact: Dictionary = {
        "harmonic_buoy": "engine_spirit",
        "below_frequency": "child_prophet",
        "sky_lane_warning": "corporate_salvager",
    }
    pending_signal_id = nearest_id
    pending_contact_id = str(signal_to_contact[nearest_id])
    if not dialogue.begin_contact(pending_contact_id):
        pending_signal_id = ""
        pending_contact_id = ""
        return false
    ender.player_controlled = false
    _refresh_ui()
    queue_redraw()
    return true

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
    pending_contact_id = "elder_farmer"
    if not dialogue.begin_contact(pending_contact_id):
        pending_contact_id = ""
        return false
    ender.player_controlled = false
    _refresh_ui()
    queue_redraw()
    return true

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
    if dialogue.open and event.is_action_pressed(InputPolicy.INTERACT):
        _advance_dialogue_review()
        return
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

func _advance_dialogue_review() -> bool:
    if not dialogue.open:
        return false
    var closing_contact: String = str(dialogue.contact_id)
    var was_last: bool = dialogue.line_index == dialogue.lines.size() - 1
    if not dialogue.advance_or_close():
        return false
    if was_last:
        if not pending_signal_id.is_empty():
            var signal_id := pending_signal_id
            pending_signal_id = ""
            pending_contact_id = ""
            if not complete_signal_contact(signal_id):
                return false
        elif closing_contact == "elder_farmer" and chapter.stage_key() == "contact":
            pending_contact_id = ""
            if not meet_ionia_for_choice():
                return false
        else:
            pending_contact_id = ""
            ender.player_controlled = chapter.stage_key() not in ["choice", "done"]
    _refresh_ui()
    queue_redraw()
    return true

func _after_progress() -> void:
    ender.player_controlled = (not dialogue.open) and (not formula_encounter.active) and chapter.stage_key() not in ["choice", "done"]
    _refresh_ui()
    queue_redraw()

func _refresh_ui() -> void:
    if objective == null:
        return
    objective.text = chapter.stage_key().to_upper() + "  /  " + _objective_text()
    party_label.text = "ACTIVE  " + " + ".join(chapter.desired_active_party_ids()).to_upper()
    dialogue_speaker.visible = dialogue.open and not formula_encounter.active
    dialogue_body.visible = dialogue.open and not formula_encounter.active
    if formula_encounter.active:
        hint.text = "%s: Strike   %s: Analyze   %s: Hold   %s: Rest   %s: Close" % [
            InputPolicy.primary_label(InputPolicy.COMBAT_STRIKE),
            InputPolicy.primary_label(InputPolicy.COMBAT_ANALYZE),
            InputPolicy.primary_label(InputPolicy.COMBAT_HOLD),
            InputPolicy.primary_label(InputPolicy.COMBAT_REST),
            InputPolicy.primary_label(InputPolicy.FORMULA_REVIEW),
        ]
    elif dialogue.open:
        dialogue_speaker.text = dialogue.speaker_name().to_upper()
        dialogue_body.text = dialogue.current_line()
        hint.text = "%s: continue   |   line %d / %d" % [
            InputPolicy.primary_label(InputPolicy.INTERACT),
            dialogue.line_index + 1,
            dialogue.lines.size(),
        ]
    elif chapter.stage_key() == "choice":
        hint.text = "%s: Leave early   %s: Hold dock   %s: Project shield" % [
            InputPolicy.primary_label(InputPolicy.CHOICE_A),
            InputPolicy.primary_label(InputPolicy.CHOICE_B),
            InputPolicy.primary_label(InputPolicy.CHOICE_C),
        ]
    elif chapter.stage_key() == "done":
        hint.text = last_message
    else:
        hint.text = InputPolicy.primary_label(InputPolicy.INTERACT) + ": interact   |   " + last_message

func export_save_snapshot() -> Dictionary:
    return SaveCodec.encode(chapter, {
        "hull_integrity": review_hull_integrity,
        "morale": review_morale,
        "engine_integration": review_engine_integration,
    })

func restore_save_snapshot(snapshot: Dictionary) -> bool:
    var restored := SaveCodec.restore(snapshot)
    if not bool(restored.get("ok", false)):
        return false

    chapter = restored["chapter"]
    var stats: Dictionary = restored.get("resolver_stats", {})
    review_hull_integrity = int(stats.get("hull_integrity", 100))
    review_morale = int(stats.get("morale", 50))
    review_engine_integration = int(stats.get("engine_integration", 0))

    # Dialogue and formula-review combat are transient UI state and intentionally
    # not part of durable Chapter I saves.
    dialogue.close()
    formula_encounter.reset()
    pending_signal_id = ""
    pending_contact_id = ""

    resolved_epilogue = {}
    if chapter.stage_key() == "done" and not chapter.epilogue_id.is_empty():
        resolved_epilogue = Content.epilogue(chapter.epilogue_id)

    ender.player_controlled = chapter.stage_key() not in ["choice", "done"]
    last_message = "Restored Chapter I save at " + chapter.stage_key().to_upper() + "."
    _refresh_ui()
    queue_redraw()
    return true

func _objective_text() -> String:
    return Content.objective_text(chapter.stage_key())
