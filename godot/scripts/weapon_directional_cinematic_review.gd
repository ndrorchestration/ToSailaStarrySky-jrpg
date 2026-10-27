extends Control
## Independent comparison stage: candidate Ender walking silhouettes with a
## purely visual existing authorized staffStrike intent and cinematic contact.
## No battle formulas are evaluated, and no new actor artwork is accepted.
const Adapter = preload("res://scripts/weapon_battle_visual_adapter.gd")
const Pose = preload("res://scripts/weapon_combat_pose_review.gd")
const Layer = preload("res://scripts/weapon_directional_character_review.gd")
const CameraStudy = preload("res://scripts/weapon_cinematic_contact_review.gd")
const Marker = preload("res://scripts/weapon_training_contact_marker.gd")
const FACINGS: Array[String] = ["east","west","south","north"]
const PAPER := Color("#eadfc6")
const GOLD := Color("#d5b780")

var adapter = Adapter.new()
var framing = CameraStudy.new()
var facing_index: int = 0
var show_candidate: bool = true
var reduced_motion: bool = false
var elapsed: float = 0.0
var playing: bool = false
var stage: Node2D
var directional: Node2D
var marker: Node2D
var facing_button: Button
var candidate_button: Button
var play_button: Button
var motion_button: CheckButton
var scrubber: HSlider
var phase_label: Label
var status_label: Label
var evidence_label: Label

func _ready() -> void:
    size = Vector2(960,640)
    _build()
    _refresh()

func current_facing() -> String:
    return FACINGS[facing_index]

func actor_pose() -> Dictionary:
    return adapter.actor_action_pose(
        "ender","full_length_staff","staffStrike",elapsed,reduced_motion)

func active_contract() -> Dictionary:
    var pose: Dictionary = actor_pose()
    var camera: Dictionary = framing.sample(pose,current_facing())
    var visual: Dictionary = directional.visual_contract() if directional != null else {}
    return {
        "actorId":str(pose.get("actorId","")),
        "weaponId":str(pose.get("weaponId","")),
        "formulaActionId":str(pose.get("formulaActionId","")),
        "candidateShown":show_candidate,
        "face":current_facing(),
        "texturePath":str(visual.get("texturePath","")),
        "spriteFrame":int(visual.get("spriteFrame",-1)),
        "duplicateStaffOverlay":stage.weapon.visible if stage != null else true,
        "candidateArtAuthority":str(visual.get("candidateStatus","")),
        "cinematicZoom":float(camera.get("zoom",0.0)),
        "contactStrength":float(camera.get("contactStrength",-1.0)),
        "motionReduced":reduced_motion,
        "combatCommandIssued":bool(pose.get("combatCommandIssued",true)),
        "canExecute":bool(pose.get("canExecute",true)),
        "cameraOnly":bool(camera.get("cameraStateOnly",false)),
        "damage":int(camera.get("damage",-1))
    }

func _label(value: String, at: Vector2, dimensions: Vector2, font_size: int=16) -> Label:
    var result := Label.new()
    result.text = value
    result.position = at
    result.size = dimensions
    result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result.add_theme_font_size_override("font_size",font_size)
    result.add_theme_color_override("font_color",PAPER)
    add_child(result)
    return result

func _button(value: String, at: Vector2, dimensions: Vector2) -> Button:
    var result := Button.new()
    result.text = value
    result.position = at
    result.size = dimensions
    result.add_theme_font_size_override("font_size",16)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#29465b")
    style.border_color = Color("#729997")
    style.set_border_width_all(1)
    style.set_corner_radius_all(5)
    result.add_theme_stylebox_override("normal",style)
    add_child(result)
    return result

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color("#0b1929")
    background.size = Vector2(960,640)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    _label("ENDER / DIRECTIONAL WEAPON & CONTACT STUDY",
        Vector2(28,17),Vector2(912,40),24)
    _label("Existing walking candidates, not accepted combat sprite art",
        Vector2(30,60),Vector2(890,30),16)
    _label("LOOK DIRECTION",Vector2(32,108),Vector2(438,25),14)
    facing_button = _button("",Vector2(31,143),Vector2(438,45))
    facing_button.pressed.connect(_cycle_facing)
    candidate_button = _button("",Vector2(31,208),Vector2(438,45))
    candidate_button.pressed.connect(_toggle_candidate)
    play_button = _button("Play / Replay",Vector2(31,275),Vector2(211,44))
    play_button.pressed.connect(_play)
    var step := _button("Step +0.1s",Vector2(254,275),Vector2(215,44))
    step.pressed.connect(_step)

    motion_button = CheckButton.new()
    motion_button.text = "Reduced motion / no contact flash"
    motion_button.position = Vector2(30,337)
    motion_button.size = Vector2(440,40)
    motion_button.add_theme_font_size_override("font_size",16)
    motion_button.toggled.connect(_set_motion)
    add_child(motion_button)

    scrubber = HSlider.new()
    scrubber.position = Vector2(34,407)
    scrubber.size = Vector2(435,31)
    scrubber.min_value = 0.0
    scrubber.max_value = 100.0
    scrubber.step = 0.1
    scrubber.value_changed.connect(_scrub)
    add_child(scrubber)

    phase_label = _label("",Vector2(31,463),Vector2(437,35),16)
    status_label = _label("",Vector2(31,509),Vector2(438,66),14)
    evidence_label = _label("",Vector2(488,528),Vector2(456,60),14)

    stage = Pose.new()
    stage.name = "CinematicReviewStage"
    stage.position = Vector2(718,324)
    stage.show_mannequin = false
    add_child(stage)
    stage.weapon.visible = false

    directional = Layer.new()
    directional.name = "DirectionalCandidateLayer"
    stage.add_child(directional)
    marker = Marker.new()
    marker.name = "VisualOnlyContactMarker"
    stage.add_child(marker)
    var bottom := _label(
        "VISUAL REVIEW / NO EXECUTION • NO STORY OR EQUIPMENT STATE WRITES",
        Vector2(30,604),Vector2(900,27),14)
    bottom.add_theme_color_override("font_color",GOLD)

func _cycle_facing() -> void:
    facing_index = posmod(facing_index+1,FACINGS.size())
    _refresh()

func _toggle_candidate() -> void:
    show_candidate = not show_candidate
    _refresh()

func _set_motion(active: bool) -> void:
    reduced_motion = active
    motion_button.set_pressed_no_signal(active)
    _refresh()

func _duration() -> float:
    return adapter.timeline.duration("full_length_staff","attack")

func _play() -> void:
    if elapsed >= _duration():
        elapsed = 0.0
    playing = true
    _refresh()

func _step() -> void:
    playing = false
    elapsed = minf(_duration(),elapsed+0.1)
    _refresh()

func _scrub(value: float) -> void:
    playing = false
    elapsed = clampf(value/100.0,0.0,1.0)*_duration()
    _refresh()

func _process(delta: float) -> void:
    if not playing:
        return
    elapsed = minf(_duration(),elapsed+delta)
    if elapsed >= _duration():
        playing = false
    _refresh()

func _refresh() -> void:
    if stage == null or directional == null:
        return
    var pose := actor_pose()
    var camera := framing.sample(pose,current_facing())
    if pose.is_empty() or camera.is_empty():
        status_label.text = "FAIL-CLOSED: VISUAL AUTHORITY REJECTED"
        return
    stage.apply_pose(pose)
    directional.set_facing(current_facing())
    directional.apply_battle_pose(pose)
    stage.show_mannequin = not show_candidate
    stage.weapon.visible = not show_candidate
    directional.visible = show_candidate
    stage.queue_redraw()
    marker.apply_cue(camera)
    stage.position = Vector2(718,324) + Vector2(camera["stageShift"])
    stage.scale = Vector2.ONE*float(camera["zoom"])
    facing_button.text = "Facing: "+current_facing().capitalize()+"  [Change]"
    candidate_button.text = "Actor layer: "+(
        "UNAPPROVED DIRECTIONAL ART" if show_candidate else "NEUTRAL TRAINING FIGURE")
    play_button.text = "Playing…" if playing else "Play / Replay"
    phase_label.text = "%s   %0.2f / %0.2fs" % [
        str(pose["phase"]).capitalize(),float(pose["elapsed"]),float(pose["duration"])
    ]
    status_label.text = (
        "Existing Ender candidate sheet, frame 0 only. Staff already drawn "
        + "in sprite; no second weapon layer." if show_candidate else
        "Abstract mannequin comparison; no accepted character art."
    )
    evidence_label.text = (
        "Ender staffStrike: authorized formula intent, visual ONLY.\n"
        + "Framing <=2.2% zoom; practice target only; zero damage."
    )
    scrubber.set_value_no_signal(float(pose["progress"])*100.0)
