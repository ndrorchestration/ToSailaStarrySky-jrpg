extends Node2D
## Original, unapproved Godot-authored layered combat pose study.
## Does NOT transform/mirror the existing walking sprite or approved portrait.
## Draws four directions with separately authored 6-key motion channels.
## Read-only: no collision, damage, combat command, saved equipment, or progression.
const FACINGS: Array[String] = ["east", "west", "south", "north"]
const ART_AUTHORITY := "ORIGINAL_PROCEDURAL_COMBAT_CANDIDATE_NOT_ACCEPTED_ART"
const KEYS: Array[float] = [0.0, 0.20, 0.40, 0.62, 0.77, 1.0]
const STAFF_HALF := 84.0
const FERRULE := 12.0
const WRAP_HALF := 23.0
const FLOOR_Y := 112.0
const COAT := Color("#607655")
const COAT_SHADOW := Color("#354b41")
const CREAM := Color("#e5d3ad")
const BRASS := Color("#d6a75c")
const WOOD := Color("#825c3b")
const WOOD_LIGHT := Color("#b08a5f")
const HAIR := Color("#a8653a")
const SKIN := Color("#dfad8a")
const OUTLINE := Color("#1e2a33")
const BOOT := Color("#3b3334")
const GLASS := Color("#7cc3a0")
const LEATHER := Color("#4d3c35")

# Five physical beats plus recovery keyed by the existing 6-cut timeline.
# Values are independently authored per direction; no flip_h on source images.
const TRACKS := {
    "east": {
        "angle":[18.0,-22.0,-49.0,77.0,49.0,18.0],
        "step":[0.0,-6.0,-10.0,18.0,11.0,0.0],
        "crouch":[0.0,8.0,13.0,2.0,3.0,0.0],
        "lean":[0.0,-7.0,-13.0,19.0,9.0,0.0],
        "spread":[0.0,5.0,11.0,23.0,12.0,0.0],
        "grip_x":[29.0,20.0,15.0,44.0,34.0,29.0],
        "grip_y":[0.0,-11.0,-23.0,-13.0,-5.0,0.0]
    },
    "west": {
        "angle":[-20.0,27.0,51.0,-76.0,-46.0,-20.0],
        "step":[0.0,5.0,10.0,-18.0,-11.0,0.0],
        "crouch":[0.0,9.0,13.0,2.0,3.0,0.0],
        "lean":[0.0,7.0,13.0,-19.0,-9.0,0.0],
        "spread":[0.0,5.0,11.0,23.0,12.0,0.0],
        "grip_x":[-29.0,-20.0,-15.0,-44.0,-34.0,-29.0],
        "grip_y":[0.0,-12.0,-24.0,-12.0,-4.0,0.0]
    },
    "south": {
        "angle":[-10.0,-28.0,-42.0,59.0,28.0,-10.0],
        "step":[0.0,-2.0,-4.0,10.0,5.0,0.0],
        "crouch":[0.0,7.0,12.0,1.0,3.0,0.0],
        "lean":[0.0,-4.0,-8.0,11.0,5.0,0.0],
        "spread":[0.0,4.0,12.0,22.0,13.0,0.0],
        "grip_x":[25.0,19.0,12.0,40.0,29.0,25.0],
        "grip_y":[-1.0,-14.0,-25.0,-12.0,-6.0,-1.0]
    },
    "north": {
        "angle":[15.0,35.0,48.0,-53.0,-25.0,15.0],
        "step":[0.0,3.0,5.0,-11.0,-6.0,0.0],
        "crouch":[0.0,8.0,12.0,2.0,4.0,0.0],
        "lean":[0.0,5.0,9.0,-12.0,-5.0,0.0],
        "spread":[0.0,4.0,11.0,22.0,13.0,0.0],
        "grip_x":[-24.0,-17.0,-12.0,-40.0,-28.0,-24.0],
        "grip_y":[-2.0,-14.0,-24.0,-11.0,-6.0,-2.0]
    }
}

var facing: String = "east"
var action_pose: Dictionary = {}
var current_frame: Dictionary = {}

func set_facing(next_facing: String) -> bool:
    if next_facing not in FACINGS:
        return false
    facing = next_facing
    _refresh()
    return true

func apply_battle_pose(value: Dictionary) -> bool:
    if str(value.get("actorId","")) != "ender" \
        or str(value.get("weaponId","")) != "full_length_staff" \
        or str(value.get("formulaActionId","")) != "staffStrike" \
        or str(value.get("mode","")) != "AUTHORIZED_ACTION_VISUAL_ONLY" \
        or str(value.get("action","")) != "attack" \
        or bool(value.get("canExecute",true)) \
        or bool(value.get("combatCommandIssued",true)):
        return false
    var progress: float = float(value.get("progress",-1.0))
    if is_nan(progress) or is_inf(progress) or progress < 0.0 or progress > 1.0:
        return false
    action_pose = value.duplicate(true)
    _refresh()
    return true

func _channel(values: Array, progress: float) -> float:
    var slot: int = 4
    for i in range(5):
        if progress < KEYS[i+1]:
            slot = i
            break
    var blend: float = clampf((progress-KEYS[slot])/(KEYS[slot+1]-KEYS[slot]),0.0,1.0)
    var eased: float = blend*blend*(3.0-2.0*blend)
    return lerpf(float(values[slot]),float(values[slot+1]),eased)

func sample_frame(next_facing: String, pose: Dictionary) -> Dictionary:
    if next_facing not in FACINGS \
        or str(pose.get("actorId","")) != "ender" \
        or str(pose.get("weaponId","")) != "full_length_staff" \
        or str(pose.get("formulaActionId","")) != "staffStrike" \
        or bool(pose.get("combatCommandIssued",true)) \
        or bool(pose.get("canExecute",true)):
        return {}
    var progress: float = float(pose.get("progress",-1.0))
    if is_nan(progress) or is_inf(progress) or progress < 0.0 or progress > 1.0:
        return {}
    var reduced: bool = bool(pose.get("motionReduced",false))
    # Preserve phase labels and a fully grounded readable silhouette; freeze
    # moving geometry for reduced motion (no jitter or sudden pose jumps).
    var geometry_time: float = 0.0 if reduced else progress
    var data: Dictionary = TRACKS[next_facing]
    var step: float = _channel(data["step"],geometry_time)
    var crouch: float = _channel(data["crouch"],geometry_time)
    var lean: float = _channel(data["lean"],geometry_time)
    var spread: float = _channel(data["spread"],geometry_time)
    var angle: float = _channel(data["angle"],geometry_time)
    var root_x: float = -45.0+step
    var hip: Vector2 = Vector2(root_x,16.0+crouch)
    var chest: Vector2 = Vector2(root_x+lean*0.48,-38.0+crouch)
    var head: Vector2 = chest+Vector2(lean*0.10,-42.0)
    var left_shoulder: Vector2 = chest+Vector2(-16.0,-8.0)
    var right_shoulder: Vector2 = chest+Vector2(16.0,-8.0)
    var foot_a: Vector2 = Vector2(root_x-14.0-spread*0.46,FLOOR_Y)
    var foot_b: Vector2 = Vector2(root_x+14.0+spread*0.46,FLOOR_Y)
    var knee_a: Vector2 = Vector2((hip.x+foot_a.x)*0.5-4.0,60.0+crouch*0.3)
    var knee_b: Vector2 = Vector2((hip.x+foot_b.x)*0.5+4.0,60.0+crouch*0.3)
    var shaft_mid: Vector2 = Vector2(
        root_x+_channel(data["grip_x"],geometry_time),
        -30.0+crouch+_channel(data["grip_y"],geometry_time))
    var shaft_axis: Vector2 = Vector2(0.0,-1.0).rotated(deg_to_rad(angle))
    var hand_a: Vector2 = shaft_mid+shaft_axis*11.0
    var hand_b: Vector2 = shaft_mid-shaft_axis*11.0
    # Optical study only: the motion contour follows the actual ferrule tip,
    # not a claimed collision or magic projectile. Reduced motion removes it.
    var trail_strength: float = 0.0
    if not reduced and progress >= 0.40 and progress < 0.77:
        var rising: float = clampf((progress-0.40)/0.22,0.0,1.0)
        var fading: float = clampf((0.77-progress)/0.15,0.0,1.0)
        trail_strength = rising*fading
    var left_contact: Vector2 = hand_a
    var right_contact: Vector2 = hand_b
    # Distinct depth/arm ordering is authored for each facing, not texture flips.
    if next_facing == "west" or next_facing == "north":
        left_contact = hand_b
        right_contact = hand_a
    return {
        "actorId":"ender","facing":next_facing,
        "source":ART_AUTHORITY,"progress":progress,
        "phase":str(pose.get("phase","")),
        "poseIndex":mini(4,int(progress*5.0)),
        "angle":angle,"hip":hip,"chest":chest,"head":head,
        "leftShoulder":left_shoulder,"rightShoulder":right_shoulder,
        "footA":foot_a,"footB":foot_b,"kneeA":knee_a,"kneeB":knee_b,
        "shaftMidpoint":shaft_mid,"shaftAxis":shaft_axis,
        "shaftTipA":shaft_mid+shaft_axis*STAFF_HALF,
        "shaftTipB":shaft_mid-shaft_axis*STAFF_HALF,
        "leftHand":left_contact,"rightHand":right_contact,
        "leftGripPoint":left_contact,"rightGripPoint":right_contact,
        "weaponLength":STAFF_HALF*2.0,
        "gripError":0.0,"floorY":FLOOR_Y,
        "trailStrength":trail_strength,"dustStrength":trail_strength*0.40,
        "trailFollowsFerrule":true,"visualContactOnly":true,
        "staffEmbeddedInCandidate":false,"oneStaffOnly":true,
        "handContact":true,"footGrounding":true,
        "animationAuthoredForCombatReview":true,
        "spriteAssetApproved":false,"combatCommandIssued":false,
        "damage":0,"canExecute":false,"motionReduced":reduced
    }

func _refresh() -> void:
    if action_pose.is_empty():
        return
    current_frame = sample_frame(facing,action_pose)
    queue_redraw()

func visual_contract() -> Dictionary:
    if current_frame.is_empty():
        return {}
    return current_frame.duplicate(true)

func _stroke(a: Vector2,b: Vector2,color: Color,width: float) -> void:
    draw_line(a,b,OUTLINE,width+2.5,false)
    draw_line(a,b,color,width,false)

func _draw() -> void:
    if current_frame.is_empty():
        return
    var d: Dictionary = current_frame
    var head: Vector2 = d["head"]
    var chest: Vector2 = d["chest"]
    var hip: Vector2 = d["hip"]
    var foot_a: Vector2 = d["footA"]
    var foot_b: Vector2 = d["footB"]
    var mid: Vector2 = d["shaftMidpoint"]
    var axis: Vector2 = d["shaftAxis"]
    # Ground shadow and planted lower body. Feet stay on the same deck.
    draw_colored_polygon(PackedVector2Array([
        Vector2(hip.x-42.0,FLOOR_Y+3.0),Vector2(hip.x+42.0,FLOOR_Y+3.0),
        Vector2(hip.x+49.0,FLOOR_Y+6.0),Vector2(hip.x-48.0,FLOOR_Y+6.0)
    ]),Color("#0d1c25",0.37))
    _stroke(hip+Vector2(-9.0,-2.0),d["kneeA"],COAT_SHADOW,13.0)
    _stroke(d["kneeA"],foot_a+Vector2(0.0,-7.0),COAT_SHADOW,12.0)
    _stroke(hip+Vector2(9.0,-2.0),d["kneeB"],COAT,13.0)
    _stroke(d["kneeB"],foot_b+Vector2(0.0,-7.0),COAT,12.0)
    _stroke(foot_a+Vector2(-5.0,-4.0),foot_a+Vector2(8.0,-4.0),BOOT,11.0)
    _stroke(foot_b+Vector2(-7.0,-4.0),foot_b+Vector2(6.0,-4.0),BOOT,11.0)
    # Original layered coat and field scholar silhouette.
    var width: float = 18.0 if facing in ["south","north"] else 13.0
    draw_colored_polygon(PackedVector2Array([
        chest+Vector2(-width,-12.0), chest+Vector2(width,-12.0),
        hip+Vector2(width+7.0,11.0),hip+Vector2(-width-6.0,11.0)
    ]),OUTLINE)
    draw_colored_polygon(PackedVector2Array([
        chest+Vector2(-width+2.0,-10.0), chest+Vector2(width-2.0,-10.0),
        hip+Vector2(width+3.0,8.0),hip+Vector2(-width-3.0,8.0)
    ]),COAT)
    draw_line(chest+Vector2(-width+4.0,-5.0),hip+Vector2(11.0,4.0),
        CREAM,5.0)
    draw_line(chest+Vector2(width-4.0,-5.0),hip+Vector2(-5.0,6.0),
        COAT_SHADOW,3.0)
    draw_line(chest+Vector2(-9.0,15.0),chest+Vector2(10.0,15.0),
        BRASS,3.0)
    # Off-torso satchel, leather straps and simple material separation.
    var satchel_side: float = -1.0 if facing in ["east","south"] else 1.0
    var bag: Vector2 = hip+Vector2(satchel_side*(width+8.0),-8.0)
    draw_rect(Rect2(bag-Vector2(8.0,10.0),Vector2(16.0,19.0)),LEATHER)
    draw_line(bag+Vector2(-7.0,-5.0),bag+Vector2(7.0,-5.0),BRASS,2.0)
    # Head faces independently per direction; rear excludes front lenses.
    draw_circle(head,20.0,OUTLINE)
    draw_circle(head,17.0,SKIN)
    draw_arc(head+Vector2(0.0,-4.0),17.0,PI,TAU,15,HAIR,8.0)
    if facing == "east":
        draw_rect(Rect2(head+Vector2(4.0,-7.0),Vector2(14.0,8.0)),BRASS)
        draw_rect(Rect2(head+Vector2(6.0,-6.0),Vector2(10.0,6.0)),GLASS)
        draw_line(head+Vector2(-15.0,-6.0),head+Vector2(3.0,-5.0),LEATHER,3.0)
    elif facing == "west":
        draw_rect(Rect2(head+Vector2(-18.0,-7.0),Vector2(14.0,8.0)),BRASS)
        draw_rect(Rect2(head+Vector2(-16.0,-6.0),Vector2(10.0,6.0)),GLASS)
        draw_line(head+Vector2(-3.0,-6.0),head+Vector2(15.0,-5.0),LEATHER,3.0)
    elif facing == "south":
        for x in [-10.0,5.0]:
            draw_rect(Rect2(head+Vector2(x,-7.0),Vector2(10.0,9.0)),BRASS)
            draw_rect(Rect2(head+Vector2(x+2.0,-5.0),Vector2(6.0,5.0)),GLASS)
        draw_line(head+Vector2(-14.0,3.0),head+Vector2(14.0,3.0),LEATHER,2.0)
    else:
        # North: reddish back of head and goggle strap. No rear eye lenses.
        draw_arc(head,16.0,PI*0.04,PI*1.96,25,HAIR,10.0)
        draw_line(head+Vector2(-14.0,-4.0),head+Vector2(14.0,-4.0),LEATHER,4.0)
    # A small physical swipe ribbon around the ferrule's actual path. Never
    # reference a target hitbox, HP, combat formula, or magical affinity.
    var trail: float = clampf(float(d.get("trailStrength",0.0)),0.0,1.0)
    if trail > 0.01:
        var trail_axis: Vector2 = d["shaftAxis"]
        var motion_angle: float = trail_axis.angle()
        var start_angle: float = motion_angle - 0.38
        var end_angle: float = motion_angle + 0.10
        draw_arc(mid,STAFF_HALF+6.0,start_angle,end_angle,22,
            Color("#d7d5c5",trail*0.38),3.4)
        draw_arc(mid,STAFF_HALF-2.0,start_angle,end_angle,22,
            Color("#f1cb8d",trail*0.33),1.8)
        var tip: Vector2 = d["shaftTipA"]
        draw_circle(tip,2.4+trail*2.1,Color("#f1d9aa",trail*0.48))
        var near_boot: Vector2 = d["footB"]
        for i in range(3):
            var dust_x: float = float(i*11-12)
            draw_line(near_boot+Vector2(dust_x,-2.0),
                near_boot+Vector2(dust_x+5.0,-4.0-float(i)*1.6),
                Color("#b7b1a0",trail*0.24),1.6)
    # Both arm segments are generated from the SAME grip anchors as the staff.
    _stroke(d["leftShoulder"],d["leftHand"],COAT_SHADOW,9.0)
    _stroke(d["rightShoulder"],d["rightHand"],COAT,9.0)
    var tip_a: Vector2 = d["shaftTipA"]
    var tip_b: Vector2 = d["shaftTipB"]
    _stroke(tip_a,tip_b,WOOD,8.0)
    draw_line(tip_a,tip_b,WOOD_LIGHT,1.5)
    for end_sign in [-1.0,1.0]:
        var cap_start: Vector2 = mid+axis*end_sign*(STAFF_HALF-FERRULE)
        var cap_end: Vector2 = mid+axis*end_sign*STAFF_HALF
        _stroke(cap_start,cap_end,BRASS,9.0)
    # CENTER leather wrap and cross-stitched grip. Both hands within it.
    _stroke(mid-axis*WRAP_HALF,mid+axis*WRAP_HALF,LEATHER,10.0)
    var perpendicular: Vector2 = Vector2(-axis.y,axis.x)
    for tick in range(-4,5):
        var point: Vector2 = mid+axis*float(tick)*4.7
        draw_line(point-perpendicular*4.0,point+perpendicular*4.0,
            WOOD_LIGHT,1.2)
    draw_circle(d["leftHand"],5.8,OUTLINE)
    draw_circle(d["leftHand"],4.8,SKIN)
    draw_circle(d["rightHand"],5.8,OUTLINE)
    draw_circle(d["rightHand"],4.8,SKIN)
