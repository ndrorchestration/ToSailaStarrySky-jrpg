extends Node2D
## Opt-in live preview listener. The actual Chapter I controller owns all turns,
## formulas, resources and save writes. No input, collisions, hitboxes or dispatch.
const Observer = preload("res://scripts/first_wake_staff_visual_pipeline_observer.gd")
const Staff = preload("res://scripts/ender_staff_combat_keyframe_review.gd")
const Target = preload("res://scripts/ender_staff_target_alignment_review.gd")
const Camera = preload("res://scripts/weapon_cinematic_contact_review.gd")
const PresentationQueue = preload("res://scripts/first_wake_staff_presentation_queue.gd")

const SOURCE := "FIRST_WAKE_EVENT_DRIVEN_STAFF_VISUAL_PILOT"
const EQUIPPED_STAFF := "full_length_staff"
const MAX_HOLD_SECONDS := 0.22
const STAGE_POS := Vector2(663,352)
const STAGE_SCALE := 0.64

var world: Node2D
var observer = Observer.new()
var camera = Camera.new()
var presentation_queue = PresentationQueue.new()
var staff: Node2D
var practice: Node2D
var enabled: bool = true
var reduced_motion: bool = false
var facing: String = "east"
var playing: bool = false
var elapsed: float = 0.0
var hold_elapsed: float = 0.0
var last_sequence: int = 0
var accepted_visual_count: int = 0
var rejected_event_count: int = 0
var ignored_nonstaff_count: int = 0
var last_receipt: Dictionary = {}
var latest_frame: Dictionary = {}
var latest_contact: Dictionary = {}

func _ready() -> void:
    position = STAGE_POS
    scale = Vector2.ONE*STAGE_SCALE
    z_index = 12
    staff = Staff.new()
    staff.name = "EventDrivenStaffRig"
    add_child(staff)
    practice = Target.new()
    practice.name = "EventDrivenTargetFixture"
    add_child(practice)
    visible = false
    set_process(true)

func attach_to_scene(scene: Node2D) -> bool:
    if scene == null or world != null \
        or not scene.has_signal("formula_action_resolved") \
        or not scene.has_method("take_formula_review_action") \
        or not observer.validate():
        return false
    world = scene
    scene.formula_action_resolved.connect(_on_action_resolved)
    return true

func detach() -> void:
    if is_instance_valid(world) and world.formula_action_resolved.is_connected(_on_action_resolved):
        world.formula_action_resolved.disconnect(_on_action_resolved)
    world = null
    playing = false
    visible = false
    last_receipt = {}
    latest_frame = {}
    latest_contact = {}
    presentation_queue.clear()

func _exit_tree() -> void:
    detach()

func set_pilot_enabled(value: bool) -> void:
    enabled = value
    if not enabled:
        playing = false
        visible = false
        presentation_queue.clear()

func set_reduced_motion(value: bool) -> void:
    reduced_motion = value
    presentation_queue.set_reduced_motion(value)
    if not last_receipt.is_empty() and visible:
        _render_elapsed()

func set_facing(value: String) -> bool:
    if value not in Staff.FACINGS:
        return false
    facing = value
    if not last_receipt.is_empty() and visible:
        _align_fixture()
        _render_elapsed()
    return true

func _on_action_resolved(event: Dictionary) -> void:
    # Only the genuine attached scene's signal is subscribed; nonetheless
    # reject stale/duplicate payloads and compare immutable-deep-copy intent
    # with the scene's current formula and chapter state.
    if not enabled or not is_instance_valid(world) \
        or str(event.get("source","")) != str(world.VISUAL_EVENT_SOURCE) \
        or not bool(event.get("accepted",false)) \
        or not bool(event.get("visualOnly",false)) \
        or bool(event.get("combatCommandIssuedByEvent",true)) \
        or bool(event.get("saveWrittenByEvent",true)):
        rejected_event_count += 1
        return
    var serial: int = int(event.get("sequence",0))
    if serial <= last_sequence or serial != int(world.formula_visual_event_serial) \
        or Dictionary(event.get("combatAfter",{})) != world.formula_encounter.snapshot() \
        or Dictionary(event.get("chapterAfter",{})) != world.chapter.snapshot():
        rejected_event_count += 1
        return
    last_sequence = serial
    playing = false
    visible = false
    presentation_queue.clear()
    if str(event.get("actionId","")) != "staffStrike":
        ignored_nonstaff_count += 1
        return
    var observed: Dictionary = observer.observe_accepted_transition(
        str(event.get("actorId","")),EQUIPPED_STAFF,
        str(event.get("actionId","")),true,
        Dictionary(event.get("combatBefore",{})),
        Dictionary(event.get("combatAfter",{})),
        Dictionary(event.get("chapterBefore",{})),
        Dictionary(event.get("chapterAfter",{})),
        facing,reduced_motion)
    if observed.is_empty() or not bool(observed.get("visualPlaybackReady",false)):
        rejected_event_count += 1
        return
    last_receipt = observed.duplicate(true)
    elapsed = 0.0
    hold_elapsed = 0.0
    if not _align_fixture():
        rejected_event_count += 1
        last_receipt = {}
        return
    var duration: float = observer.bridge.timeline.duration(EQUIPPED_STAFF,"attack")
    if not presentation_queue.accept_result(
        serial,observed,
        Dictionary(event.get("combatBefore",{})),
        Dictionary(event.get("combatAfter",{})),
        duration,reduced_motion):
        rejected_event_count += 1
        last_receipt = {}
        return
    playing = true
    visible = true
    accepted_visual_count += 1
    _render_elapsed()

func _align_fixture() -> bool:
    var elapsed_hit: float = observer.bridge.timeline.duration(
        EQUIPPED_STAFF,"attack")*observer.VISUAL_CUE_PROGRESS
    # A NORMAL phase is used to place the prop even when motion is reduced;
    # reduced-motion still freezes pose & removes all optical reaction.
    var key_pose: Dictionary = observer.bridge.actor_action_pose(
        "ender",EQUIPPED_STAFF,"staffStrike",elapsed_hit,false)
    var key_frame: Dictionary = observer.staff.sample_frame(facing,key_pose)
    return practice.bind_contact_anchor(facing,key_frame)

func seek_review_seconds(seconds: float) -> bool:
    # Test/review-only playback cursor. No combat command can originate here.
    if last_receipt.is_empty() or not visible or is_nan(seconds) or is_inf(seconds):
        return false
    var duration: float = observer.bridge.timeline.duration(EQUIPPED_STAFF,"attack")
    elapsed = clampf(seconds,0.0,duration)
    presentation_queue.seek(elapsed)
    hold_elapsed = 0.0
    _render_elapsed()
    return true

func _process(delta: float) -> void:
    if not playing:
        return
    if not is_instance_valid(world) or not world.formula_encounter.active:
        playing = false
        visible = false
        presentation_queue.clear()
        return
    var duration: float = observer.bridge.timeline.duration(EQUIPPED_STAFF,"attack")
    if elapsed < duration:
        elapsed = minf(duration,elapsed+delta)
        presentation_queue.seek(elapsed)
        _render_elapsed()
    else:
        hold_elapsed += delta
        if hold_elapsed >= MAX_HOLD_SECONDS:
            playing = false
            visible = false
            presentation_queue.clear()

func _render_elapsed() -> void:
    var pose: Dictionary = observer.bridge.actor_action_pose(
        "ender",EQUIPPED_STAFF,"staffStrike",elapsed,reduced_motion)
    var frame: Dictionary = observer.staff.sample_frame(facing,pose)
    var cue: Dictionary = camera.sample(pose,facing)
    if pose.is_empty() or frame.is_empty() or cue.is_empty() \
        or not staff.set_facing(facing) \
        or not staff.apply_battle_pose(pose) \
        or not practice.apply_visual_contact(frame,cue):
        visible = false
        playing = false
        latest_frame = {}
        latest_contact = {}
        return
    latest_frame = frame.duplicate(true)
    latest_contact = practice.visual_contract()
    queue_redraw()

func presentation_projection() -> Dictionary:
    if not enabled or not is_instance_valid(world)         or not world.formula_encounter.active or not visible:
        return {}
    return presentation_queue.projection()

func visual_contract() -> Dictionary:
    return {
        "source":SOURCE,"attached":is_instance_valid(world),
        "enabled":enabled,"visible":visible,
        "playing":playing,"sequence":last_sequence,
        "visualCount":accepted_visual_count,
        "ignoredNonstaffCount":ignored_nonstaff_count,
        "rejectedEventCount":rejected_event_count,
        "facing":facing,"motionReduced":reduced_motion,
        "chapterActionObserved":not last_receipt.is_empty(),
        "formulaDamageObserved":int(last_receipt.get("formulaDamageObserved",0)),
        "visualContactStrength":float(latest_contact.get("reaction",0.0)),
        "cameraOnly":true,"realHitVerified":false,
        "combatCommandIssued":false,"saveWritten":false,
        "artApproved":false,
        "presentationPhase":str(presentation_projection().get("phase","inactive")),
        "presentationSequence":presentation_queue.sequence,
    }

