extends RefCounted
## Chapter I migration VISUAL OBSERVER only. The actual
## FirstWakeChapterOneReview.take_formula_review_action() remains the sole
## gameplay entry point. This class only sees read-only before/after snapshots.
## It cannot submit a turn, play audio, register a hitbox, or write a save.
const Bridge = preload("res://scripts/weapon_battle_visual_adapter.gd")
const Staff = preload("res://scripts/ender_staff_combat_keyframe_review.gd")
const Camera = preload("res://scripts/weapon_cinematic_contact_review.gd")
const Target = preload("res://scripts/ender_staff_target_alignment_review.gd")

const VERSION := "0.1.0"
const SOURCE := "FIRST_WAKE_OBSERVED_STAFF_VISUAL_PIPELINE_REVIEW"
const VISUAL_CUE_PROGRESS := 0.695
const ACCEPTED_KINDS: Array[String] = ["formula_review", "authored_hazard"]

var bridge = Bridge.new()
var camera = Camera.new()
var staff = Staff.new()

func observe_accepted_transition(actor_id: String, equipped_weapon_id: String,
        action_id: String, accepted: bool, before: Dictionary, after: Dictionary,
        chapter_before: Dictionary, chapter_after: Dictionary,
        facing: String = "east", reduced_motion: bool = false) -> Dictionary:
    # Reject fabricated execution metadata; only the call site in the real
    # First Wake test actually invokes the formula scene's action entry point.
    # A snapshot-only observer is NOT cryptographic proof of action provenance.
    if not accepted or actor_id != "ender" or action_id != "staffStrike" \
        or equipped_weapon_id != "full_length_staff" or facing not in Staff.FACINGS \
        or not bridge.authority.can_use_formula_action(actor_id, action_id) \
        or not bridge.validate() or not camera.validate():
        return {}
    if chapter_before.is_empty() or chapter_before != chapter_after \
        or before.is_empty() or after.is_empty():
        return {}
    if not bool(before.get("active",false)) or not bool(after.get("active",false)) \
        or bool(before.get("completed",true)) or bool(before.get("playerDefeated",true)):
        return {}
    if str(before.get("encounterKind","")) not in ACCEPTED_KINDS \
        or str(before.get("encounterKind","")) != str(after.get("encounterKind","")):
        return {}
    var previous_player: Dictionary = before.get("player",{})
    var updated_player: Dictionary = after.get("player",{})
    var previous_target: Dictionary = before.get("target",{})
    var updated_target: Dictionary = after.get("target",{})
    if str(previous_player.get("id","")) != actor_id \
        or str(updated_player.get("id","")) != actor_id \
        or str(previous_target.get("id","")).is_empty() \
        or str(previous_target.get("id","")) != str(updated_target.get("id","")) \
        or int(previous_target.get("maxHp",0)) != int(updated_target.get("maxHp",-1)):
        return {}
    var before_hp: int = int(previous_target.get("hp",-1))
    var after_hp: int = int(updated_target.get("hp",-1))
    var before_charges: int = int(previous_player.get("staffCharges",-1))
    var after_charges: int = int(updated_player.get("staffCharges",-1))
    var turn_delta: int = int(after.get("turns",-1))-int(before.get("turns",-1))
    var enemy_delta: int = int(after.get("enemyTurns",-1))-int(before.get("enemyTurns",-1))
    if before_hp <= 0 or after_hp < 0 or after_hp > before_hp \
        or before_charges < 1 or after_charges != before_charges-1 \
        or turn_delta != 1 or enemy_delta < 0 or enemy_delta > 1:
        return {}
    if str(before["encounterKind"]) == "formula_review":
        if str(previous_target["id"]) != "formula_review_target" or enemy_delta != 0:
            return {}
    else:
        if str(previous_target.get("hazardId","")) != "wind_shear" \
            or str(previous_target["id"]) != "windShear":
            return {}
        if bool(after.get("completed",false)) and enemy_delta != 0:
            return {}
    var earlier_log: Array = before.get("log",[])
    var later_log: Array = after.get("log",[])
    if later_log.size() <= earlier_log.size() or not str(later_log[earlier_log.size()]).begins_with("Staff Strike:"):
        return {}
    var playback_seconds: float = bridge.timeline.duration(
        equipped_weapon_id,"attack")*VISUAL_CUE_PROGRESS
    var pose: Dictionary = bridge.actor_action_pose(
        actor_id,equipped_weapon_id,action_id,playback_seconds,reduced_motion)
    var frame: Dictionary = staff.sample_frame(facing,pose)
    var cue: Dictionary = camera.sample(pose,facing)
    if pose.is_empty() or frame.is_empty() or cue.is_empty():
        return {}
    var practice: Node2D = Target.new()
    if not practice.bind_contact_anchor(facing,frame) \
        or not practice.apply_visual_contact(frame,cue):
        return {}
    var contact: Dictionary = practice.visual_contract()
    if bool(contact.get("hitAuthorized",true)) \
        or bool(contact.get("collisionDetected",true)) \
        or bool(contact.get("combatCommandIssued",true)) \
        or int(contact.get("damage",-1)) != 0:
        return {}
    return {
        "version":VERSION, "source":SOURCE,
        "actorId":actor_id, "weaponId":equipped_weapon_id,
        "formulaActionId":action_id, "facing":facing,
        "encounterKind":str(before["encounterKind"]),
        "targetId":str(previous_target["id"]),
        "actorActionObserved":true,
        "staffChargesBefore":before_charges,
        "staffChargesAfter":after_charges,
        "turnDeltaObserved":turn_delta,"enemyTurnDeltaObserved":enemy_delta,
        "targetHpBefore":before_hp,"targetHpAfter":after_hp,
        "formulaDamageObserved":before_hp-after_hp,
        "chapterSnapshotUnchanged":chapter_before == chapter_after,
        "visualPose":pose.duplicate(true),
        "authoredFrame":frame.duplicate(true),
        "contactStudy":contact.duplicate(true),
        "cameraStudy":cue.duplicate(true),
        "visualPlaybackReady":true, "realHitVerified":false,
        "combatCommandIssuedByObserver":false, "savedStateWritten":false,
        "spriteAssetApproved":false, "canonicalSceneModified":false,
        "motionReduced":reduced_motion
    }

func validate() -> bool:
    return bridge.validate() and camera.validate() \
        and observe_accepted_transition(
            "lyra","full_length_staff","staffStrike",
            false,{},{},{},{}
        ).is_empty()
