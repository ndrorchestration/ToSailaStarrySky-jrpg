extends Control
## Standalone read-only combat loadout visualization. Its buttons NEVER dispatch
## turn actions, edit Chapter I saves, or equip canonical party members.
const Adapter = preload("res://scripts/weapon_battle_visual_adapter.gd")
const Pose = preload("res://scripts/weapon_combat_pose_review.gd")
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")
const FormulaEncounter = preload("res://scripts/first_wake_formula_encounter.gd")

const WEAPONS: Array[String] = [
    "full_length_staff", "practice_sword", "field_pike", "service_rifle"
]
const ACTIONS: Array[String] = ["idle","attack","guard","victory"]
const PAPER := Color("#f1e5cb")
const MUTED := Color("#a6c3c9")

var adapter = Adapter.new()
var catalog = Catalog.new()
var frozen_encounter = FormulaEncounter.new()
var authorized_intent_mode: bool = true
var weapon_index: int = 0
var action_index: int = 1
var elapsed: float = 0.0
var reduced_motion: bool = false
var playing: bool = false
var pose_node: Node2D
var mode_button: Button
var equip_button: Button
var action_button: Button
var play_button: Button
var motion_toggle: CheckButton
var timeline_slider: HSlider
var authority_label: Label
var cue_label: Label
var phase_label: Label
var target_label: Label

func _ready() -> void:
    size = Vector2(960,640)
    _build()
    _refresh()

func current_weapon_id() -> String:
    return "full_length_staff" if authorized_intent_mode else WEAPONS[weapon_index]

func current_animation() -> String:
    return "attack" if authorized_intent_mode else ACTIONS[action_index]

func review_pose() -> Dictionary:
    if authorized_intent_mode:
        return adapter.actor_action_pose(
            "ender",current_weapon_id(),"staffStrike",elapsed,reduced_motion)
    return adapter.equipment_sandbox_pose(
        current_weapon_id(),current_animation(),elapsed,reduced_motion)

func review_contract() -> Dictionary:
    if pose_node == null:
        return {}
    var entry := review_pose()
    var node_contract: Dictionary = pose_node.visual_contract()
    return {
        "mode":entry.get("mode",""),
        "actorId":entry.get("actorId",""),
        "weaponId":entry.get("weaponId",""),
        "animation":entry.get("action",""),
        "combatCommandIssued":entry.get("combatCommandIssued",true),
        "canExecute":entry.get("canExecute",true),
        "rigWeaponId":node_contract.get("weaponId",""),
        "rigFamily":node_contract.get("family",""),
        "motionReduced":node_contract.get("motionReduced",false)
    }

func _label(value: String, at: Vector2, dimensions: Vector2, font_size: int = 16) -> Label:
    var entry := Label.new()
    entry.text = value
    entry.position = at
    entry.size = dimensions
    entry.add_theme_font_size_override("font_size",font_size)
    entry.add_theme_color_override("font_color",PAPER)
    add_child(entry)
    return entry

func _button(value: String, at: Vector2, dimensions: Vector2) -> Button:
    var entry := Button.new()
    entry.text = value
    entry.position = at
    entry.size = dimensions
    entry.add_theme_font_size_override("font_size",15)
    add_child(entry)
    return entry

func _build() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color("#0e1e30")
    backdrop.size = Vector2(960,640)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(backdrop)
    _label("BATTLE EQUIPMENT / VISUAL AUTHORITY LAB",Vector2(30,15),Vector2(915,35),25)
    _label("First Wake read-only intent   |   Anonymous alternate-equipment rehearsal",
        Vector2(30,53),Vector2(904,27),16)

    mode_button = _button("",Vector2(31,113),Vector2(435,48))
    mode_button.pressed.connect(_toggle_mode)
    equip_button = _button("",Vector2(31,176),Vector2(435,48))
    equip_button.pressed.connect(_cycle_weapon)
    action_button = _button("",Vector2(31,239),Vector2(435,48))
    action_button.pressed.connect(_cycle_action)

    play_button = _button("Play",Vector2(31,305),Vector2(209,44))
    play_button.pressed.connect(_play)
    var step := _button("Step +0.1s",Vector2(251,305),Vector2(215,44))
    step.pressed.connect(_step)

    motion_toggle = CheckButton.new()
    motion_toggle.position = Vector2(31,365)
    motion_toggle.size = Vector2(426,40)
    motion_toggle.text = "Reduced motion"
    motion_toggle.add_theme_font_size_override("font_size",16)
    motion_toggle.toggled.connect(_set_reduced_motion)
    add_child(motion_toggle)

    timeline_slider = HSlider.new()
    timeline_slider.position = Vector2(31,429)
    timeline_slider.size = Vector2(435,30)
    timeline_slider.min_value = 0.0
    timeline_slider.max_value = 100.0
    timeline_slider.step = 0.1
    timeline_slider.value_changed.connect(_scrub)
    add_child(timeline_slider)

    phase_label = _label("",Vector2(30,472),Vector2(449,30),16)
    authority_label = _label("",Vector2(30,505),Vector2(913,27),14)
    cue_label = _label("",Vector2(30,541),Vector2(913,27),14)

    pose_node = Pose.new()
    pose_node.name = "ReadOnlyEquippedBattleRig"
    pose_node.position = Vector2(708,331)
    add_child(pose_node)
    _label("GEOMETRIC TRAINING PROXY — NOT ENDER ART",Vector2(489,105),Vector2(460,26),14)
    target_label = _label("",Vector2(494,542),Vector2(450,26),13)
    var footer := _label(
        "NO DAMAGE OR TURN DISPATCH • NO CANON EQUIP ASSIGNMENT • NO SAVE WRITES",
        Vector2(31,608),Vector2(899,28),14)
    footer.add_theme_color_override("font_color",MUTED)

func _toggle_mode() -> void:
    authorized_intent_mode = not authorized_intent_mode
    _reset()

func _cycle_weapon() -> void:
    if authorized_intent_mode:
        return
    weapon_index = posmod(weapon_index + 1,WEAPONS.size())
    _reset()

func _cycle_action() -> void:
    if authorized_intent_mode:
        return
    action_index = posmod(action_index + 1,ACTIONS.size())
    _reset()

func _set_reduced_motion(enabled: bool) -> void:
    reduced_motion = enabled
    motion_toggle.set_pressed_no_signal(enabled)
    _refresh()

func _reset() -> void:
    elapsed = 0.0
    playing = false
    _refresh()

func _duration() -> float:
    return adapter.timeline.duration(current_weapon_id(),current_animation())

func _play() -> void:
    if elapsed >= _duration():
        elapsed = 0.0
    playing = true
    _refresh()

func _step() -> void:
    playing = false
    elapsed = minf(_duration(),elapsed+0.1)
    _refresh()

func _scrub(percentage: float) -> void:
    playing = false
    elapsed = clampf(percentage/100.0,0.0,1.0)*_duration()
    _refresh()

func _process(delta: float) -> void:
    if not playing:
        return
    elapsed = minf(_duration(),elapsed+delta)
    if elapsed >= _duration():
        playing = false
    _refresh()

func _refresh() -> void:
    if pose_node == null:
        return
    var entry := review_pose()
    if entry.is_empty():
        authority_label.text = "VISUAL ROUTE REJECTED: UNAUTHORIZED OR UNKNOWN"
        return
    pose_node.apply_pose(entry)
    mode_button.text = "MODE: Ender authorized intent" if authorized_intent_mode \
        else "MODE: Anonymous sandbox equipment"
    equip_button.text = "Equipped: "+str(catalog.weapon(current_weapon_id())["label"])
    equip_button.disabled = authorized_intent_mode
    action_button.text = "Action pose: "+current_animation().capitalize()
    action_button.disabled = authorized_intent_mode
    play_button.text = "Playing…" if playing else "Play / Replay"
    phase_label.text = "%s  —  %0.2f / %0.2fs" % [
        str(entry["phase"]).capitalize(),float(entry["elapsed"]),float(entry["duration"])
    ]
    authority_label.text = (
        "Ender staffStrike: ALLOWED IN FORMULA CONTRACT, ANIMATION ONLY — NOT EXECUTED"
        if authorized_intent_mode else
        "ANONYMOUS SANDBOX: NEVER AN ACTOR LOADOUT OR COMBAT PERMISSION"
    )
    cue_label.text = "Physical direction: "+str(entry["cue"])
    target_label.text = "Read-only fixture target: %d / %d HP" % [
        int(frozen_encounter.target["hp"]),int(frozen_encounter.target["maxHp"])
    ]
    timeline_slider.set_value_no_signal(100.0*float(entry["progress"]))
