extends Node2D
## Neutral Battle Lab v0 — a real Godot scene, NOT the Chapter I screenplay.
## One FormulaEncounter action drives read-only weapon and enemy visuals.
## No chapter, party, ship, quest, save, collision or story position is loaded.
const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")
const EnemyMetadata = preload("res://scripts/first_wake_current_enemy_adapter.gd")
const Gate = preload("res://scripts/neutral_enemy_weapon_visual_cue.gd")
const Staff = preload("res://scripts/ender_staff_combat_keyframe_review.gd")
const EnemyView = preload("res://scripts/first_wake_wind_shear_visual.gd")

const LOGICAL_SIZE := Vector2i(960, 640)
const DEMO_ONLY := "NONCANON BATTLE LAB — PREVIEW ONLY"

class Sequence:
    extends RefCounted
    var items: Array
    var index: int = 0
    func _init(values: Array) -> void:
        items = values.duplicate()
    func next() -> float:
        if index >= items.size():
            return 0.5
        var result: float = float(items[index])
        index += 1
        return result

var rng: Sequence
var encounter
var visual_gate = Gate.new()
var enemy_view: Node2D
var staff_view: Node2D
var reduced_motion: bool = false
var last_visual_receipt: Dictionary = {}
var accepted_actions: int = 0
var finished_visual_receipts: int = 0

func _ready() -> void:
    enemy_view = EnemyView.new()
    enemy_view.name = "NeutralLabEnemyView"
    enemy_view.position = Vector2(692.0, 323.0)
    enemy_view.z_index = 2
    add_child(enemy_view)
    staff_view = Staff.new()
    staff_view.name = "ReadOnlyStaffPose"
    staff_view.position = Vector2(294.0, 332.0)
    staff_view.z_index = 2
    staff_view.visible = false
    add_child(staff_view)
    enemy_view.visible = false
    set_process_unhandled_key_input(true)

func _unhandled_key_input(event: InputEvent) -> void:
    # Human reviewer controls exist ONLY in this isolated lab scene.
    # Key input never routes to Chapter I or grants an external battle turn.
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
        if encounter == null or not encounter.active:
            start_lab(reduced_motion)
            get_viewport().set_input_as_handled()
    elif event.keycode == KEY_1:
        if encounter != null and encounter.active:
            resolve_one_staff_strike()
            get_viewport().set_input_as_handled()
    elif event.keycode == KEY_R:
        if encounter != null and encounter.active:
            close_lab()
        start_lab(reduced_motion)
        get_viewport().set_input_as_handled()

func start_lab(enable_reduced_motion: bool = false) -> bool:
    if encounter != null and encounter.active:
        return false
    rng = Sequence.new([0.5, 0.99, 0.5, 0.99, 0.5, 0.99])
    var metadata = EnemyMetadata.new()
    var profile: Dictionary = metadata.target_for_hazard("wind_shear")
    if not metadata.validate_target(profile):
        return false
    encounter = Encounter.new(rng.next)
    if not encounter.start_with_target(profile):
        return false
    visual_gate.reset()
    accepted_actions = 0
    finished_visual_receipts = 0
    last_visual_receipt = {}
    reduced_motion = enable_reduced_motion
    enemy_view.begin_encounter()
    enemy_view.set_reduced_motion(reduced_motion)
    enemy_view.visible = true
    staff_view.visible = false
    queue_redraw()
    return true

func resolve_one_staff_strike() -> bool:
    # This is the ONLY authorized controller call in the host scene. No
    # visual class is ever allowed to submit a second action.
    if encounter == null or not encounter.active or encounter.completed:
        return false
    var before: Dictionary = encounter.snapshot()
    if not encounter.take_action("staffStrike"):
        return false
    accepted_actions += 1
    var after: Dictionary = encounter.snapshot()
    var receipt: Dictionary = visual_gate.consume(
        "ender", "full_length_staff", "staffStrike", true,
        before, after, reduced_motion
    )
    if receipt.is_empty():
        push_error("NEUTRAL_BATTLE_VISUAL_RECEIPT_INVALID: gameplay remains resolved; visuals fail closed")
        return false
    var pose: Dictionary = receipt["visualPose"]
    if not staff_view.set_facing("east") or not staff_view.apply_battle_pose(pose):
        push_error("NEUTRAL_BATTLE_WEAPON_VIEW_REJECTED")
        return false
    staff_view.visible = true
    # Enemy state observes *actual* resolved retaliation and HP change, even
    # though this visual playback may show them in chronological phases.
    enemy_view.set_encounter_state(
        bool(receipt["analyzed"]),
        bool(receipt["cleared"]),
        int(receipt["enemyTurnsAfter"])
    )
    if int(receipt["damageObserved"]) > 0:
        enemy_view.register_resolved_damage(
            int(receipt["beforeHp"]), int(receipt["afterHp"])
        )
    last_visual_receipt = receipt.duplicate(true)
    finished_visual_receipts += 1
    queue_redraw()
    return true

func close_lab() -> bool:
    if encounter == null or not encounter.active:
        return false
    var closed: bool = encounter.close()
    if closed:
        enemy_view.visible = false
        staff_view.visible = false
        queue_redraw()
    return closed

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 640), Color("#071421"))
    draw_rect(Rect2(42, 89, 876, 469), Color("#122839"))
    draw_rect(Rect2(58, 106, 844, 430), Color("#162e3d"), false, 2.0)
    draw_rect(Rect2(558, 149, 307, 327), Color("#0f2836"))
    draw_circle(Vector2(692, 309), 104, Color(0.22, 0.57, 0.66, 0.08))
    draw_line(Vector2(605, 449), Vector2(783, 449), Color(0.44, 0.72, 0.67, 0.45), 1.0)
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(76, 67), DEMO_ONLY,
        HORIZONTAL_ALIGNMENT_LEFT, 770, 20, Color("#f0d8a7"))
    draw_string(font, Vector2(78, 155), "ENDER  /  FULL-LENGTH STAFF",
        HORIZONTAL_ALIGNMENT_LEFT, 460, 18, Color("#eadabf"))
    draw_string(font, Vector2(572, 165), "WIND SHEAR  /  ART STUDY",
        HORIZONTAL_ALIGNMENT_LEFT, 300, 17, Color("#9dcdd1"))
    var status: String = "NOT STARTED"
    var hp: String = "—"
    if encounter != null:
        status = "TURN %d  |  VISUAL RECEIPTS %d" % [encounter.turns, finished_visual_receipts]
        hp = "ENEMY HP %d/%d  |  ENEMY TURNS %d" % [
            int(encounter.target.get("hp", 0)),
            int(encounter.target.get("maxHp", 1)),
            encounter.enemy_turns
        ]
    draw_string(font, Vector2(80, 506), status,
        HORIZONTAL_ALIGNMENT_LEFT, 750, 16, Color("#cad8db"))
    draw_string(font, Vector2(80, 530), hp,
        HORIZONTAL_ALIGNMENT_LEFT, 750, 16, Color("#e6b77b"))
    draw_string(font, Vector2(80, 570), "ENTER — LOAD   |   1 — ONE STAFF STRIKE   |   R — RESET LAB",
        HORIZONTAL_ALIGNMENT_LEFT, 810, 15, Color("#d6c59d"))
    draw_string(font, Vector2(80, 592), "No quest, save, hitbox, new enemy or story placement.",
        HORIZONTAL_ALIGNMENT_LEFT, 810, 15, Color("#a5afac"))
