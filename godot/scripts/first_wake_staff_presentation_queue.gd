extends RefCounted
## Transient HUD projection of a formula result already resolved by Chapter I.
## The source combat snapshots are never modified or re-dispatched.
const SOURCE := "FIRST_WAKE_POST_RESOLUTION_PRESENTATION_QUEUE_REVIEW"
const CONTACT_PROGRESS := 0.695
const REQUIRED_ACTION := "staffStrike"

var active: bool = false
var sequence: int = 0
var before: Dictionary = {}
var after: Dictionary = {}
var elapsed: float = 0.0
var duration: float = 1.10
var reduced_motion: bool = false
var phase: String = "inactive"
var revealed_count: int = 0
var cleared_count: int = 0

func accept_result(serial: int, receipt: Dictionary, before_snapshot: Dictionary,
        after_snapshot: Dictionary, playback_duration: float,
        motion_reduced: bool = false) -> bool:
    if serial <= sequence or serial < 1 or playback_duration <= 0.0 \
        or is_nan(playback_duration) or is_inf(playback_duration) \
        or str(receipt.get("source","")) != "FIRST_WAKE_OBSERVED_STAFF_VISUAL_PIPELINE_REVIEW" \
        or str(receipt.get("formulaActionId","")) != REQUIRED_ACTION \
        or str(receipt.get("actorId","")) != "ender" \
        or str(receipt.get("weaponId","")) != "full_length_staff" \
        or not bool(receipt.get("visualPlaybackReady",false)) \
        or bool(receipt.get("combatCommandIssuedByObserver",true)) \
        or bool(receipt.get("savedStateWritten",true)) \
        or before_snapshot.is_empty() or after_snapshot.is_empty() \
        or int(receipt.get("turnDeltaObserved",0)) != 1:
        return false
    var old_p: Dictionary = before_snapshot.get("player",{})
    var new_p: Dictionary = after_snapshot.get("player",{})
    var old_t: Dictionary = before_snapshot.get("target",{})
    var new_t: Dictionary = after_snapshot.get("target",{})
    if old_p.is_empty() or new_p.is_empty() or old_t.is_empty() or new_t.is_empty() \
        or str(old_p.get("id","")) != "ender" \
        or str(new_p.get("id","")) != "ender" \
        or str(old_t.get("id","")) != str(new_t.get("id","")) \
        or int(old_t.get("hp",-1)) != int(receipt.get("targetHpBefore",-2)) \
        or int(new_t.get("hp",-1)) != int(receipt.get("targetHpAfter",-2)) \
        or int(old_p.get("staffCharges",-1)) != int(receipt.get("staffChargesBefore",-2)) \
        or int(new_p.get("staffCharges",-1)) != int(receipt.get("staffChargesAfter",-2)) \
        or int(old_t.get("hp",0))-int(new_t.get("hp",0)) != int(receipt.get("formulaDamageObserved",-1)):
        return false
    # Permit a newer genuine resolved action to supersede a still-playing view.
    # A stale/duplicate cannot start or rewind a presentation.
    sequence=serial
    before=before_snapshot.duplicate(true)
    after=after_snapshot.duplicate(true)
    elapsed=0.0
    duration=playback_duration
    reduced_motion=motion_reduced
    active=true
    phase="pending"
    if reduced_motion:
        phase="revealed"
        revealed_count+=1
    return true

func seek(seconds: float) -> bool:
    if not active or is_nan(seconds) or is_inf(seconds):
        return false
    elapsed=clampf(seconds,0.0,duration)
    var next_phase: String = "revealed" if reduced_motion \
        or elapsed >= duration*CONTACT_PROGRESS else "pending"
    # A committed result is never visually rolled back within one event.
    if phase == "revealed":
        next_phase = "revealed"
    if phase != "revealed" and next_phase == "revealed":
        revealed_count+=1
    phase=next_phase
    return true

func set_reduced_motion(value: bool) -> void:
    reduced_motion=value
    if active:
        seek(elapsed)

func clear() -> void:
    if active:
        cleared_count+=1
    active=false
    phase="inactive"
    before={}
    after={}
    elapsed=0.0

func projection() -> Dictionary:
    if not active:
        return {}
    var showing_pre: bool = phase == "pending"
    var display: Dictionary = before if showing_pre else after
    var old_t: Dictionary = before.get("target",{})
    var new_t: Dictionary = after.get("target",{})
    var target: Dictionary = display.get("target",{})
    var player: Dictionary = display.get("player",{})
    var heat: Dictionary = player.get("heat",{})
    var damage: int = int(old_t.get("hp",0))-int(new_t.get("hp",0))
    var log: Array = after.get("log",[])
    var resolution_text: String = str(log.back()) if log.size() > 0 else "Staff Strike resolved."
    return {
        "source":SOURCE,"phase":phase,"sequence":sequence,
        "targetId":str(target.get("id","")),
        "targetName":str(target.get("name","")),
        "targetHp":int(target.get("hp",-1)),
        "targetMaxHp":int(target.get("maxHp",-1)),
        "playerVit":int(player.get("vit",-1)),
        "playerMaxVit":int(player.get("maxVit",-1)),
        "staffCharges":int(player.get("staffCharges",-1)),
        "maxStaffCharges":int(player.get("maxStaffCharges",-1)),
        "heat":int(heat.get("current",0)),"maxHeat":int(heat.get("max",3)),
        "formulaDamage":damage,"damageNumberVisible":not showing_pre,
        "statusText":"Staff Strike — anticipating contact…" if showing_pre else resolution_text,
        "motionReduced":reduced_motion,
        "combatCommandIssued":false,"saveWritten":false,
        "hitboxCreated":false,"actualResultAlreadyCommitted":true
    }
