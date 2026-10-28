extends Node2D
## Standalone authored training prop, spatially aligned with the *visual*
## staff-tip at the keyed contact frame. This is NOT a hit, a hitbox, an enemy,
## or a replacement for authorized combat resolution.
const STAFF = preload("res://scripts/ender_staff_combat_keyframe_review.gd")
const SOURCE := "READ_ONLY_TARGET_ALIGNMENT_STUDY"
const DISTANCE_LIMIT := 18.0
const CONTACT_KEY := 0.695
const TARGET_RADIUS := 20.0
const RIM := Color("#d8b775")
const BARK := Color("#695d4c")
const SHADE := Color("#243f4a")
const OPTIC := Color("#a9d3bf")

var facing: String = ""
var center: Vector2 = Vector2.ZERO
var active_tip: String = ""
var aligned: bool = false
var visual_state: Dictionary = {}

func _tip_name(_next_facing: String) -> String:
    # Positive (upper) ferrule points outward at contact in each of the
    # independently-authored east/west/south/north strike tracks.
    return "shaftTipA"

func bind_contact_anchor(next_facing: String, contact_frame: Dictionary) -> bool:
    if next_facing not in STAFF.FACINGS \
        or str(contact_frame.get("source","")) != STAFF.ART_AUTHORITY \
        or str(contact_frame.get("actorId","")) != "ender" \
        or str(contact_frame.get("facing","")) != next_facing \
        or bool(contact_frame.get("combatCommandIssued",true)) \
        or bool(contact_frame.get("canExecute",true)) \
        or absf(float(contact_frame.get("progress",-1.0))-CONTACT_KEY) > 0.0001:
        return false
    var tip_id: String = _tip_name(next_facing)
    center = Vector2(contact_frame[tip_id])
    facing = next_facing
    active_tip = tip_id
    aligned = true
    visual_state = {}
    queue_redraw()
    return true

func apply_visual_contact(frame: Dictionary, cue: Dictionary) -> bool:
    if not aligned or str(frame.get("source","")) != STAFF.ART_AUTHORITY \
        or str(frame.get("facing","")) != facing \
        or str(frame.get("actorId","")) != "ender" \
        or bool(frame.get("combatCommandIssued",true)) \
        or bool(frame.get("canExecute",true)) \
        or str(cue.get("source","")) != "REVIEW_ONLY_DIRECTIONAL_CINEMATIC" \
        or bool(cue.get("hitAuthorized",true)) \
        or bool(cue.get("combatCommandIssued",true)) \
        or int(cue.get("damage",-1)) != 0:
        return false
    var progress: float = float(frame.get("progress",-1.0))
    if is_nan(progress) or is_inf(progress) or progress < 0.0 or progress > 1.0:
        return false
    var tip: Vector2 = Vector2(frame[active_tip])
    var distance: float = tip.distance_to(center)
    if is_nan(distance) or is_inf(distance):
        return false
    var reduced: bool = bool(frame.get("motionReduced",false)) or bool(cue.get("motionReduced",false))
    var in_interval: bool = progress >= 0.62 and progress < 0.77
    var intensity: float = 0.0
    if in_interval and not reduced and distance <= DISTANCE_LIMIT:
        intensity = clampf(float(cue.get("contactStrength",0.0))/0.55,0.0,1.0)
    visual_state = {
        "source":SOURCE,"facing":facing,"actorId":"ender",
        "targetAnchor":center,"tip":tip,"tipId":active_tip,
        "proximity":distance,"aligned":distance<=DISTANCE_LIMIT,
        "reaction":intensity,"reactionIsOptical":true,
        "pivotDegrees":intensity*(4.0 if facing in ["east","south"] else -4.0),
        "compression":intensity*3.5,
        "sfxFired":false,"collisionDetected":false,
        "hitAuthorized":false,"damage":0,"combatCommandIssued":false,
        "motionReduced":reduced
    }
    queue_redraw()
    return true

func visual_contract() -> Dictionary:
    return visual_state.duplicate(true)

func _draw() -> void:
    if not aligned:
        return
    var intensity: float = clampf(float(visual_state.get("reaction",0.0)),0.0,1.0)
    var tilt: float = deg_to_rad(float(visual_state.get("pivotDegrees",0.0)))
    var rim_shift := Vector2(sin(tilt)*TARGET_RADIUS,cos(tilt)*intensity*2.0)
    var disk: Vector2 = center+rim_shift
    var foot: Vector2 = Vector2(center.x,112.0)
    # Physical training stand has its own shadow, grounded stem and brace.
    draw_colored_polygon(PackedVector2Array([
        foot+Vector2(-22.0,1.0),foot+Vector2(22.0,1.0),
        foot+Vector2(31.0,5.0),foot+Vector2(-31.0,5.0)
    ]),Color("#081b27",0.34))
    draw_line(foot+Vector2(-24.0,0.0),foot+Vector2(21.0,0.0),BARK,5.0)
    draw_line(foot+Vector2(0.0,-2.0),center+Vector2(0.0,18.0),SHADE,7.0)
    draw_line(foot+Vector2(-16.0,-2.0),center+Vector2(-2.0,29.0),BARK,3.0)
    draw_line(foot+Vector2(15.0,-2.0),center+Vector2(2.0,29.0),BARK,3.0)
    # Draw a readable wood/brass training disk, independent of enemies.
    draw_circle(disk,TARGET_RADIUS+3.0,SHADE)
    draw_circle(disk,TARGET_RADIUS,RIM)
    draw_circle(disk,TARGET_RADIUS-4.0,BARK)
    draw_arc(disk,TARGET_RADIUS-7.0,0.0,TAU,36,OPTIC.darkened(0.25),2.2)
    draw_line(disk+Vector2(-11.0,0.0),disk+Vector2(11.0,0.0),RIM,2.5)
    draw_line(disk+Vector2(0.0,-11.0),disk+Vector2(0.0,11.0),RIM,2.5)
    draw_circle(disk,3.0,OPTIC)
    # Only visually registered, bounded compression. This does not mark a hit.
    if intensity > 0.01:
        draw_arc(disk,TARGET_RADIUS+6.0,-1.5,1.3,26,
            Color("#e6d9b6",intensity*0.40),2.0)
        draw_arc(disk,TARGET_RADIUS+10.0,0.9,2.1,16,
            Color("#b8d1c5",intensity*0.25),1.3)
