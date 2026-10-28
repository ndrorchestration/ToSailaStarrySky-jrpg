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
const SaveStore = preload("res://scripts/first_wake_chapter1_save_store.gd")
const InputPolicy = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const FormulaEncounter = preload("res://scripts/first_wake_formula_encounter.gd")
const CurrentEnemyAdapter = preload("res://scripts/first_wake_current_enemy_adapter.gd")
const PartyCombatAuthority = preload("res://scripts/first_wake_party_combat_authority.gd")
const BattleLoadout = preload("res://scripts/battle_equipment_loadout.gd")
const BattleEquipmentVisual = preload("res://scripts/battle_equipment_visual.gd")
const EquipmentTraining = preload("res://scripts/battle_equipment_training_profile.gd")
const TrialInventory = preload("res://scripts/battle_equipment_trial_inventory.gd")
const GearInspector = preload("res://scripts/battle_equipment_inspector.gd")
const GearInspectorPanel = preload("res://scripts/battle_equipment_inspector_panel.gd")

const DECK_BOUNDS := SaveCodec.PLAYER_POSITION_BOUNDS
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
var last_restore_used_legacy_position: bool = false
var formula_encounter = FormulaEncounter.new()
var current_enemy_adapter = CurrentEnemyAdapter.new()
var party_combat_authority = PartyCombatAuthority.new()
var active_hazard_encounter_id: String = ""
var save_store = SaveStore.new()
var battle_loadout = BattleLoadout.new("ender")
var trial_inventory = TrialInventory.new()
var gear_inspector = GearInspector.new()
var gear_inspector_panel
var gear_inspector_open: bool = false
var equipment_training = EquipmentTraining.new()
var battle_equipment_view

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
    # Private native-preview presentation: use the already-authored directional
    # Ender candidate in-place. This does not admit it to a production field pack.
    ender.set_walk_review_enabled(true)

    for contact_id in ChapterState.CONTACT_IDS:
        var actor := Actor.new()
        actor.name = Content.contact_name(contact_id) + "MigrationPlaceholder"
        actor.character_name = Content.contact_name(contact_id)
        actor.player_controlled = false
        actor.walking_bounds = DECK_BOUNDS
        actor.position = CONTACT_POINTS[contact_id]
        actors.add_child(actor)
        # Wakeheart is explicitly a harmonic console, not a humanoid NPC. Its
        # authored signal marker/dialogue remains visible without a fake body.
        if contact_id == "engine_spirit":
            _set_actor_physical_presence(actor, false)
        contacts[contact_id] = actor

    _sync_stage_actor_presentation()

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
    battle_equipment_view = BattleEquipmentVisual.new()
    battle_equipment_view.name = "ChapterOneBattleEquipmentReviewOnly"
    battle_equipment_view.position = Vector2(738, 248)
    battle_equipment_view.set_appearance(battle_loadout.appearance())
    battle_equipment_view.visible = false
    add_child(battle_equipment_view)
    gear_inspector_panel = GearInspectorPanel.new()
    gear_inspector_panel.name = "TrialGearInspectionPanelReviewOnly"
    gear_inspector_panel.z_index = 40
    gear_inspector_panel.visible = false
    add_child(gear_inspector_panel)
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

func _set_actor_physical_presence(actor: CharacterBody2D, enabled: bool) -> void:
    actor.visible = enabled
    # A hidden CharacterBody2D still participates in collision unless its
    # layers are disabled. Presentation-only absences must therefore be
    # physically absent as well, or they become invisible navigation blockers.
    actor.collision_layer = 1 if enabled else 0
    actor.collision_mask = 1 if enabled else 0

func _sync_stage_actor_presentation() -> void:
    # Presentation follows authored story availability; it does not change party
    # membership or progression. Ionia must not be physically present on the dock
    # before the Contact boundary.
    if ender != null:
        ender.set_walk_review_enabled(true)

    var wakeheart = contacts.get("engine_spirit", null)
    if wakeheart != null:
        _set_actor_physical_presence(wakeheart, false)

    var ionia = contacts.get("elder_farmer", null)
    if ionia == null:
        return
    var show_ionia := chapter.stage_key() in ["contact", "choice", "wake", "done"]
    _set_actor_physical_presence(ionia, show_ionia)
    ionia.set_ionia_stage_art_enabled(show_ionia, "west")

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

    var authored_hazard := not active_hazard_encounter_id.is_empty()
    var encounter_title := "CROSSING ENCOUNTER" if authored_hazard else "FORMULA REVIEW ENCOUNTER"
    var encounter_subtitle := (
        "Current-story Wind Shear · Gale Force retaliates · progress confirms on clear"
        if authored_hazard
        else "Production JRPG math · noncanonical target · Chapter I progress unchanged"
    )

    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 154),
        encounter_title,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        24,
        Color("#fff1ce")
    )
    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 184),
        encounter_subtitle,
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

    var party_rows := party_combat_authority.surface_for_party(chapter.desired_active_party_ids())
    var party_bits: Array[String] = []
    for row in party_rows:
        var actor_id := str(row.get("actorId", "")).to_upper()
        var turn_status := "ACTIVE" if bool(row.get("canTakeFormulaTurn", false)) else "ACTIONS PENDING"
        party_bits.append(actor_id + ": " + turn_status)
    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 294),
        "PARTY  " + "  |  ".join(party_bits),
        HORIZONTAL_ALIGNMENT_LEFT,
        610,
        13,
        Color("#9dd9ee")
    )

    var analysis_text := "Weakness hidden.  2: Uncover Truth"
    if formula_encounter.weakness_revealed():
        analysis_text = "ANALYZED: " + str(formula_encounter.target.get("weakness", ""))
    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 322),
        analysis_text,
        HORIZONTAL_ALIGNMENT_LEFT,
        610,
        15,
        Color("#8cdbc8")
    )

    var gear_line := "GEAR: LOOK ONLY (story combat unchanged)"
    if not authored_hazard:
        var profile: Dictionary = equipment_training.project(
            battle_loadout,
            Dictionary(formula_encounter.player.get("productionStats", {})),
            int(formula_encounter.player.get("level", 1))
        )
        if not profile.is_empty():
            gear_line = "PRACTICE STRIKE %d > %d  ARMOR +%d  WARD +%d" % [
                int(profile["baselineDamage"]),
                int(profile["equippedDamage"]),
                int(profile["physicalDefenseDelta"]),
                int(profile["aetherDefenseDelta"]),
            ]
    draw_string(ThemeDB.fallback_font, Vector2(176, 348), gear_line, HORIZONTAL_ALIGNMENT_LEFT, 480, 11, Color("#8cdbc8"))
    draw_string(ThemeDB.fallback_font, Vector2(679, 348), "5 Staff  6 Armor  7 Charm", HORIZONTAL_ALIGNMENT_LEFT, 137, 10, Color("#add5dc"))

    var pressure_text := "8  Practice pressure OFF (physical/aether turns)"
    if authored_hazard:
        pressure_text = "Practice pressure unavailable in story combat"
    elif formula_encounter.training_pressure_enabled:
        pressure_text = "8  Practice pressure ON"
        if not formula_encounter.last_training_hit.is_empty():
            var hit: Dictionary = formula_encounter.last_training_hit
            pressure_text += "  %s %d/%d, gear prevented %d" % [
                str(hit.get("kind", "")).to_upper(),
                int(hit.get("damage", 0)),
                int(hit.get("rawDamage", 0)),
                int(hit.get("mitigatedByGear", 0)),
            ]
    draw_string(ThemeDB.fallback_font, Vector2(176, 428), pressure_text, HORIZONTAL_ALIGNMENT_LEFT, 500, 11, Color("#b5d8c5"))

    draw_string(ThemeDB.fallback_font, Vector2(176, 370), "1  Staff Strike", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))
    draw_string(ThemeDB.fallback_font, Vector2(390, 370), "2  Uncover Truth", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))
    draw_string(ThemeDB.fallback_font, Vector2(176, 404), "3  Hold", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))
    draw_string(ThemeDB.fallback_font, Vector2(390, 404), "4  Rest", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff1ce"))

    var status := formula_encounter.last_log()
    if formula_encounter.player_defeated:
        status = "ENDER DOWN. C closes encounter; Crossing progress remains unchanged."
    elif formula_encounter.completed:
        if authored_hazard:
            status = "WIND SHEAR CLEARED. C confirms this Crossing hazard."
        else:
            status = "TARGET CLEARED. C closes review; Chapter I state remains unchanged."
    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 448),
        status,
        HORIZONTAL_ALIGNMENT_LEFT,
        610,
        15,
        Color("#d7eaf0")
    )

    var inventory_line := "TRIAL BAG  STAFF %d  ARMOR %d  CHARM %d" % [
        trial_inventory.count_in_bag("ender-staff-inlay-review"),
        trial_inventory.count_in_bag("ender-armor-overlay-review"),
        trial_inventory.count_in_bag("ender-charm-review"),
    ]
    draw_string(ThemeDB.fallback_font, Vector2(411, 482), inventory_line, HORIZONTAL_ALIGNMENT_LEFT, 385, 11, Color("#c2dbc8"))

    draw_string(
        ThemeDB.fallback_font,
        Vector2(176, 482),
        ("C: confirm / close encounter" if authored_hazard else "C: close review"),
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

## The modal never authorizes a new action or enters the story inventory.
func open_gear_inspector() -> bool:
    if not formula_encounter.active or not active_hazard_encounter_id.is_empty():
        return false
    if formula_encounter.completed or formula_encounter.player_defeated:
        return false
    if not trial_inventory.validate(battle_loadout) or not gear_inspector.reset(battle_loadout, trial_inventory):
        return false
    gear_inspector_open = true
    gear_inspector_panel.visible = true
    return refresh_gear_inspector()

func refresh_gear_inspector() -> bool:
    if not gear_inspector_open:
        return false
    var data: Dictionary = gear_inspector.describe(
        battle_loadout,
        trial_inventory,
        Dictionary(formula_encounter.player.get("productionStats", {})),
        int(formula_encounter.player.get("level", 1))
    )
    if data.is_empty():
        close_gear_inspector()
        return false
    gear_inspector_panel.set_inspection(data)
    return true

func close_gear_inspector() -> void:
    gear_inspector_open = false
    if gear_inspector_panel != null:
        gear_inspector_panel.visible = false
        gear_inspector_panel.set_inspection({})
    queue_redraw()

func move_gear_inspector_slot(delta: int) -> bool:
    if not gear_inspector_open or not gear_inspector.move_slot(delta, battle_loadout, trial_inventory):
        return false
    return refresh_gear_inspector()

func move_gear_inspector_item(delta: int) -> bool:
    if not gear_inspector_open or not gear_inspector.move_choice(delta, battle_loadout, trial_inventory):
        return false
    return refresh_gear_inspector()

func confirm_gear_inspector_item() -> bool:
    if not gear_inspector_open or not gear_inspector.selection_is_valid(battle_loadout, trial_inventory):
        return false
    var selected_slot: String = gear_inspector.current_slot()
    var item_id: String = gear_inspector.selected_item(battle_loadout, trial_inventory)
    if not equip_review_item(selected_slot, item_id):
        return false
    if not gear_inspector.reset(battle_loadout, trial_inventory):
        close_gear_inspector()
        return false
    # Keep the player's selected equipment category after a real transaction.
    for idx in GearInspector.SLOTS.size():
        if str(GearInspector.SLOTS[idx]) == selected_slot:
            gear_inspector.slot_index = idx
            break
    if not gear_inspector.move_slot(0, battle_loadout, trial_inventory):
        close_gear_inspector()
        return false
    return refresh_gear_inspector()

func start_formula_review() -> bool:
    if formula_encounter.active or dialogue.open or chapter.stage_key() in ["choice", "done"]:
        return false
    active_hazard_encounter_id = ""
    close_gear_inspector()
    if not trial_inventory.validate(battle_loadout):
        return false
    formula_encounter.reset()
    if not formula_encounter.start():
        return false
    if not formula_encounter.set_training_loadout(battle_loadout):
        formula_encounter.close()
        return false
    battle_equipment_view.set_pose("idle")
    battle_equipment_view.visible = true
    ender.player_controlled = false
    last_message = formula_encounter.last_log()
    _refresh_ui()
    queue_redraw()
    return true

func start_hazard_encounter(hazard_id: String) -> bool:
    if formula_encounter.active or dialogue.open or chapter.stage_key() != "crossing":
        return false
    if hazard_id in chapter.completed_hazards:
        return false

    var target_profile := current_enemy_adapter.target_for_hazard(hazard_id)
    if target_profile.is_empty() or not current_enemy_adapter.validate_target(target_profile):
        return false
    if not formula_encounter.start_with_target(target_profile):
        return false

    active_hazard_encounter_id = hazard_id
    close_gear_inspector()
    battle_equipment_view.set_pose("idle")
    battle_equipment_view.visible = true
    ender.player_controlled = false
    last_message = formula_encounter.last_log()
    _refresh_ui()
    queue_redraw()
    return true

func close_formula_review() -> bool:
    if not formula_encounter.active:
        return false

    var hazard_id: String = active_hazard_encounter_id
    var hazard_cleared: bool = (not hazard_id.is_empty()) and bool(formula_encounter.completed)

    # Chapter progression mutates only after the authored encounter is actually
    # cleared and the player confirms closure. Canceling early is fail-closed.
    if hazard_cleared and not chapter.complete_hazard(hazard_id):
        return false
    if not formula_encounter.close():
        return false

    active_hazard_encounter_id = ""
    close_gear_inspector()
    battle_equipment_view.set_pose("idle")
    battle_equipment_view.visible = false
    if not hazard_id.is_empty():
        if hazard_cleared:
            last_message = "Crossing cleared: " + Content.hazard_label(hazard_id) + "."
        else:
            last_message = Content.hazard_label(hazard_id) + " encounter canceled; Crossing progress unchanged."
        _after_progress()
        return true

    ender.player_controlled = (not dialogue.open) and chapter.stage_key() not in ["choice", "done"]
    last_message = "Formula review closed. Chapter I progression was not changed."
    _refresh_ui()
    queue_redraw()
    return true

func take_formula_review_action(action_id: String) -> bool:
    if not formula_encounter.active or gear_inspector_open:
        return false

    # The scene boundary must consult actor authority before the formula
    # controller. This keeps party/turn authorization fail-closed even if the
    # production formula catalog grows later.
    var actor_id := str(formula_encounter.player.get("id", ""))
    if not party_combat_authority.can_use_formula_action(actor_id, action_id):
        last_message = "ACTION_AUTHORITY_BLOCKED:%s:%s" % [actor_id, action_id]
        _refresh_ui()
        queue_redraw()
        return false

    if not formula_encounter.take_action(action_id):
        last_message = formula_encounter.last_log()
        _refresh_ui()
        queue_redraw()
        return false
    var pose := "idle"
    match action_id:
        "staffStrike":
            pose = "strike"
        "uncoverTruth":
            pose = "analyze"
        "hold":
            pose = "guard"
        "rest":
            pose = "rest"
    battle_equipment_view.set_pose(pose)
    last_message = formula_encounter.last_log()
    _refresh_ui()
    queue_redraw()
    return true

## This is an ownership-conserving practice transaction, not story loot.
## It consumes no turn and cannot replace the approved formula/action authority.
func equip_review_item(slot_id: String, item_id: String) -> bool:
    if not formula_encounter.active or not trial_inventory.transfer(battle_loadout, slot_id, item_id):
        return false
    battle_equipment_view.set_appearance(battle_loadout.appearance())
    # Training-only: intentional no-op in authored Wind Shear encounters.
    formula_encounter.set_training_loadout(battle_loadout)
    last_message = "Equipment study: " + str(battle_loadout.appearance().get("weaponName", ""))
    _refresh_ui()
    queue_redraw()
    return true

func cycle_equipment_review(slot_id: String) -> bool:
    if not formula_encounter.active or not trial_inventory.cycle_ender_review(battle_loadout, slot_id):
        return false
    battle_equipment_view.set_appearance(battle_loadout.appearance())
    formula_encounter.set_training_loadout(battle_loadout)
    _refresh_ui()
    queue_redraw()
    return true

## Training-only, opt-in counterpressure; never modifies authored combat.
func toggle_training_pressure_review() -> bool:
    if not formula_encounter.active or not active_hazard_encounter_id.is_empty():
        return false
    if not formula_encounter.set_training_pressure(not formula_encounter.training_pressure_enabled):
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
    if current_enemy_adapter.supports_hazard(nearest_id):
        return start_hazard_encounter(nearest_id)
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
    # Modal inputs preempt combat, story, save and movement actions. They do
    # not enqueue a formula turn or mutate the Chapter I save codec.
    if gear_inspector_open:
        if event.is_action_pressed(InputPolicy.EQUIP_INSPECT) or event.is_action_pressed(InputPolicy.INSPECT_CLOSE):
            close_gear_inspector()
        elif event.is_action_pressed(InputPolicy.INSPECT_UP):
            move_gear_inspector_slot(-1)
        elif event.is_action_pressed(InputPolicy.INSPECT_DOWN):
            move_gear_inspector_slot(1)
        elif event.is_action_pressed(InputPolicy.INSPECT_PREVIOUS):
            move_gear_inspector_item(-1)
        elif event.is_action_pressed(InputPolicy.INSPECT_NEXT):
            move_gear_inspector_item(1)
        elif event.is_action_pressed(InputPolicy.INSPECT_CONFIRM):
            confirm_gear_inspector_item()
        return

    if event.is_action_pressed(InputPolicy.SAVE_PROGRESS):
        save_progress_to_disk()
        return
    if event.is_action_pressed(InputPolicy.LOAD_PROGRESS):
        load_progress_from_disk()
        return
    if formula_encounter.active:
        if event.is_action_pressed(InputPolicy.FORMULA_REVIEW):
            close_formula_review()
        elif event.is_action_pressed(InputPolicy.EQUIP_INSPECT):
            open_gear_inspector()
        elif event.is_action_pressed(InputPolicy.EQUIP_WEAPON_PREVIEW):
            cycle_equipment_review("mainWeapon")
        elif event.is_action_pressed(InputPolicy.EQUIP_ARMOR_PREVIEW):
            cycle_equipment_review("bodyArmor")
        elif event.is_action_pressed(InputPolicy.EQUIP_ACCESSORY_PREVIEW):
            cycle_equipment_review("accessory")
        elif event.is_action_pressed(InputPolicy.EQUIP_TRAINING_PRESSURE):
            toggle_training_pressure_review()
        elif event.is_action_pressed(InputPolicy.COMBAT_STRIKE):
            take_formula_review_action("staffStrike")
        elif event.is_action_pressed(InputPolicy.COMBAT_ANALYZE):
            take_formula_review_action("uncoverTruth")
        elif event.is_action_pressed(InputPolicy.COMBAT_HOLD):
            take_formula_review_action("hold")
        elif event.is_action_pressed(InputPolicy.COMBAT_REST):
            take_formula_review_action("rest")
        return
    if event.is_action_pressed(InputPolicy.FORMULA_REVIEW):
        start_formula_review()
        return
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
    _sync_stage_actor_presentation()
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
        hint.text = "%s: Strike   %s: Analyze   %s: Hold   %s: Rest   %s: Close   F5: Save   F9: Load" % [
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
        hint.text = InputPolicy.primary_label(InputPolicy.INTERACT) + ": interact   |   F5: save   F9: load   |   " + last_message

func save_progress_to_disk(path: String = SaveStore.DEFAULT_PATH) -> bool:
    var result := save_store.save_snapshot(export_save_snapshot(), path)
    if not bool(result.get("ok", false)):
        last_message = "Save failed: " + str(result.get("error", "unknown error"))
        _refresh_ui()
        queue_redraw()
        return false
    last_message = "Chapter I progress saved. Dialogue and active encounters remain transient."
    _refresh_ui()
    queue_redraw()
    return true

func load_progress_from_disk(path: String = SaveStore.DEFAULT_PATH) -> bool:
    var result := save_store.load_snapshot(path)
    if not bool(result.get("ok", false)):
        last_message = "Load failed: no valid Chapter I save found."
        _refresh_ui()
        queue_redraw()
        return false
    var snapshot: Dictionary = result.get("snapshot", {})
    if not restore_save_snapshot(snapshot):
        last_message = "Load failed: saved Chapter I state was rejected."
        _refresh_ui()
        queue_redraw()
        return false
    last_message = "Chapter I progress loaded" + (" from backup recovery." if bool(result.get("recovered", false)) else ".")
    if last_restore_used_legacy_position:
        last_message += " Legacy save used the safe deck spawn because it predates position persistence."
    _refresh_ui()
    queue_redraw()
    return true

func export_save_snapshot() -> Dictionary:
    return SaveCodec.encode(chapter, {
        "hull_integrity": review_hull_integrity,
        "morale": review_morale,
        "engine_integration": review_engine_integration,
    }, ender.position)

func restore_save_snapshot(snapshot: Dictionary) -> bool:
    var restored := SaveCodec.restore(snapshot)
    if not bool(restored.get("ok", false)):
        return false

    chapter = restored["chapter"]
    var stats: Dictionary = restored.get("resolver_stats", {})
    review_hull_integrity = int(stats.get("hull_integrity", 100))
    review_morale = int(stats.get("morale", 50))
    review_engine_integration = int(stats.get("engine_integration", 0))
    last_restore_used_legacy_position = not bool(restored.get("player_position_present", false))
    var restored_position: Vector2 = restored.get("player_position", SaveCodec.LEGACY_PLAYER_POSITION)
    ender.position = restored_position

    # Dialogue and formula-review combat are transient UI state and intentionally
    # not part of durable Chapter I saves.
    dialogue.close()
    formula_encounter.reset()
    battle_loadout.reset_to_starter()
    trial_inventory.reset()
    close_gear_inspector()
    battle_equipment_view.set_pose("idle")
    battle_equipment_view.set_appearance(battle_loadout.appearance())
    battle_equipment_view.visible = false
    active_hazard_encounter_id = ""
    pending_signal_id = ""
    pending_contact_id = ""

    resolved_epilogue = {}
    if chapter.stage_key() == "done" and not chapter.epilogue_id.is_empty():
        resolved_epilogue = Content.epilogue(chapter.epilogue_id)

    ender.player_controlled = chapter.stage_key() not in ["choice", "done"]
    _sync_stage_actor_presentation()
    last_message = "Restored Chapter I save at " + chapter.stage_key().to_upper() + "."
    _refresh_ui()
    queue_redraw()
    return true

func _objective_text() -> String:
    return Content.objective_text(chapter.stage_key())
