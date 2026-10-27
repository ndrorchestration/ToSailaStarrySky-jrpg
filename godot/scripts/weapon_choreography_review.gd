extends Control
## Standalone Godot 4.7.2 weapon choreography study, not a Chapter I battle.
const Timeline = preload("res://scripts/weapon_action_timeline.gd")
const Pose = preload("res://scripts/weapon_combat_pose_review.gd")
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")

const WEAPONS: Array[String] = [
    "full_length_staff", "practice_sword", "field_pike", "service_rifle"
]
const ACTIONS: Array[String] = ["idle","attack","guard","victory"]
const PAPER := Color("#eee1c8")
const MUTED := Color("#adc9c6")

var timeline = Timeline.new()
var catalog = Catalog.new()
var weapon_index: int = 0
var action_index: int = 0
var elapsed: float = 0.0
var playing: bool = false
var reduced_motion: bool = false
var pose_node: Node2D
var weapon_button: Button
var action_button: Button
var play_button: Button
var motion_button: CheckButton
var scrubber: HSlider
var phase_label: Label
var status_label: Label
var cue_label: Label

func _ready() -> void:
    size = Vector2(960,640)
    _build()
    _refresh()

func weapon_id() -> String:
    return WEAPONS[weapon_index]

func action_id() -> String:
    return ACTIONS[action_index]

func current_contract() -> Dictionary:
    return pose_node.visual_contract() if pose_node != null else {}

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
    entry.add_theme_font_size_override("font_size",16)
    add_child(entry)
    return entry

func _build() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color("#0c1829")
    backdrop.size = Vector2(960,640)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(backdrop)

    _label("WEAPON CHOREOGRAPHY  /  ACTION LAB",Vector2(34,17),Vector2(890,40),26)
    _label("Deterministic, physical motion studies • neutral rehearsal figure • no executable battle skills",
        Vector2(35,59),Vector2(895,28),15)
    _label("LOADOUT / PHYSICAL TECHNIQUE",Vector2(36,120),Vector2(434,26),16)
    weapon_button = _button("Weapon",Vector2(35,155),Vector2(408,45))
    weapon_button.pressed.connect(_cycle_weapon)
    action_button = _button("Action",Vector2(35,216),Vector2(408,45))
    action_button.pressed.connect(_cycle_action)
    play_button = _button("Play / Replay",Vector2(35,279),Vector2(195,43))
    play_button.pressed.connect(_play)
    var step_button := _button("Step + 0.1s",Vector2(243,279),Vector2(200,43))
    step_button.pressed.connect(_step)

    motion_button = CheckButton.new()
    motion_button.text = "Reduced-motion preview"
    motion_button.position = Vector2(36,351)
    motion_button.size = Vector2(367,42)
    motion_button.add_theme_font_size_override("font_size",17)
    motion_button.toggled.connect(_set_motion)
    add_child(motion_button)

    _label("CHOREOGRAPHY TIMELINE",Vector2(35,422),Vector2(390,28),15)
    scrubber = HSlider.new()
    scrubber.position = Vector2(38,459)
    scrubber.size = Vector2(406,28)
    scrubber.min_value = 0.0
    scrubber.max_value = 100.0
    scrubber.step = 0.1
    scrubber.value_changed.connect(_scrub)
    add_child(scrubber)
    phase_label = _label("",Vector2(35,503),Vector2(446,48),17)
    cue_label = _label("",Vector2(35,553),Vector2(880,33),14)

    pose_node = Pose.new()
    pose_node.name = "BattlePose"
    pose_node.position = Vector2(710,325)
    add_child(pose_node)
    _label("TRAINING STAGE — NON-CANONICAL",Vector2(520,120),Vector2(420,28),15)
    status_label = _label("",Vector2(517,522),Vector2(423,46),14)
    var footer := _label(
        "REVIEW ONLY · No HP changes, actor permissions, quest, inventory, or save mutations.",
        Vector2(35,605),Vector2(900,28),14)
    footer.add_theme_color_override("font_color",MUTED)

func _cycle_weapon() -> void:
    weapon_index = posmod(weapon_index+1,WEAPONS.size())
    _reset()

func _cycle_action() -> void:
    action_index = posmod(action_index+1,ACTIONS.size())
    _reset()

func _reset() -> void:
    playing = false
    elapsed = 0.0
    _refresh()

func _play() -> void:
    if elapsed >= timeline.duration(weapon_id(),action_id()):
        elapsed = 0.0
    playing = true
    _refresh()

func _step() -> void:
    playing = false
    elapsed = minf(
        timeline.duration(weapon_id(),action_id()), elapsed+0.1
    )
    _refresh()

func _scrub(percent: float) -> void:
    playing = false
    elapsed = timeline.duration(weapon_id(),action_id())*clampf(percent/100.0,0.0,1.0)
    _refresh()

func _set_motion(enabled: bool) -> void:
    reduced_motion = enabled
    if motion_button != null:
        motion_button.set_pressed_no_signal(enabled)
    _refresh()

func _process(delta: float) -> void:
    if not playing:
        return
    var length := timeline.duration(weapon_id(),action_id())
    if action_id() == "idle":
        elapsed = fposmod(elapsed+delta,length)
    else:
        elapsed = minf(length,elapsed+delta)
        if elapsed >= length:
            playing = false
    _refresh()

func _refresh() -> void:
    if pose_node == null:
        return
    var data := timeline.sample(weapon_id(),action_id(),elapsed,reduced_motion)
    pose_node.apply_pose(data)
    weapon_button.text = "Equipped: "+str(catalog.weapon(weapon_id())["label"])+"   [Change]"
    action_button.text = "Animation: "+action_id().capitalize()+"   [Change]"
    play_button.text = "Replay" if playing else "Play / Replay"
    phase_label.text = "Phase: %s     %0.2f / %0.2fs" % [
        str(data["phase"]).capitalize(),float(data["elapsed"]),float(data["duration"])
    ]
    cue_label.text = "Physical cue: "+str(data["cue"])
    status_label.text = "Stage rig: %s   |   Reduced motion: %s" % [
        str(data["family"]).to_upper(), "ON" if reduced_motion else "OFF"
    ]
    scrubber.set_value_no_signal(100.0*float(data["progress"]))
