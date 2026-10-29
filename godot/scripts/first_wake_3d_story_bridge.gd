extends Node
## Read-only-to-save 3D adapter to the ACTUAL existing First Wake opening scene.
##
## A single original JobScene.opening is bound to the same Session class used
## by the native F5 game. We delegate dialogue to original JobScene.interact()
## rather than copying its words, actors, interview, or story transitions.
##
## This bridge does not expose ship boarding or engineering in 3D until a
## physical 3D room and equivalent controls exist. This prevents fake progress.
const JobScene = preload("res://scenes/first_wake_job_preview.tscn")
const Session = preload("res://scripts/first_wake_game_session.gd")

const PROBE_FLYER := "NoticeBoard_ReviewOnly"
const PROBE_IONIA := "IoniaArrival_ReviewOnly"
const PROBE_GANGWAY := "AureateWakeGangway_ReviewOnly"
const ENGINEERING_STATIONS := {
    "EngineeringReference_ReviewOnly": "reference",
    "EngineeringContainment_ReviewOnly": "containment",
    "EngineeringFuel_ReviewOnly": "fuel",
    "EngineeringSafety_ReviewOnly": "checklist",
}

var authoritative_job: Node2D
var authoritative_session = Session.new()
var bridge_ready := false
var bridge_status := ""
var completed_dialogues: Array[String] = []
var physically_confirmed_interactions := 0

func _ready() -> void:
    authoritative_job = JobScene.instantiate()
    authoritative_job.name = "AuthoritativeOriginalFirstWakeJobSceneHidden"
    # Do not render a second playable dock or intercept 3D movement.
    authoritative_job.visible = false
    add_child(authoritative_job)
    if authoritative_job.ui_layer != null:
        authoritative_job.ui_layer.visible = false
    if authoritative_job.portrait_preview != null:
        authoritative_job.portrait_preview.visible = false
    # The original job exists solely as story-state authority here.
    # Direct deliberate interact() calls still execute on disabled-process nodes.
    authoritative_job.process_mode = Node.PROCESS_MODE_DISABLED
    bridge_ready = authoritative_session.bind_job_scene(authoritative_job.opening)
    bridge_status = "Approach the job notice. First Wake canon uses its original dialogue and party contract." if bridge_ready else "Original First Wake story binding unavailable."

func _dialogue_line() -> String:
    if not bridge_ready or authoritative_job == null:
        return ""
    if not authoritative_job.dialogue_open:
        return ""
    var index: int = int(authoritative_job.dialogue_cursor)
    if index < 0 or index >= authoritative_job.dialogue_lines.size():
        return ""
    return str(authoritative_job.dialogue_lines[index])

func advance_authoritative_dialogue() -> bool:
    if not bridge_ready or not authoritative_job.dialogue_open:
        return false
    var prior_event: String = authoritative_job.dialogue_event
    if not authoritative_job.interact():
        return false
    if authoritative_job.dialogue_open:
        bridge_status = _dialogue_line()
    else:
        bridge_status = str(authoritative_job.last_message)
        if not prior_event.is_empty():
            completed_dialogues.append(prior_event)
    return true

func interact_at_verified_probe(probe_name: String) -> bool:
    # Caller MUST confirm a real Area3D/CharacterBody3D overlap first.
    # Do not allow entering a new scene or accepting job while dialogue open:
    # E already advances the active AUTHORED dialogue through the same method.
    if not bridge_ready or authoritative_job == null:
        return false
    if authoritative_job.dialogue_open:
        return advance_authoritative_dialogue()
    match probe_name:
        PROBE_FLYER:
            if authoritative_job.flyer_read:
                bridge_status = "The original First Wake job notice has already been read."
                return false
            authoritative_job.ender.position = authoritative_job.FLYER_POSITION
        PROBE_IONIA:
            if not authoritative_job.flyer_read:
                bridge_status = "First inspect the job notice. Ionia cannot be recruited early."
                return false
            if "ionia" in authoritative_job.opening.active_party_ids:
                bridge_status = "Ionia is already in the authoritative story party."
                return false
            authoritative_job.ender.position = authoritative_job.IONIA_DOCK_POSITION
        PROBE_GANGWAY:
            if authoritative_job.opening.step_key() != "engineering" or (
                    authoritative_job.opening.active_party_ids != ["ender", "ionia"]):
                bridge_status = "Complete Ionia's original hiring dialogue before boarding."
                return false
            if authoritative_job.room != "dock":
                bridge_status = "The original engineering room is already active."
                return false
            # The caller has already verified REAL gangway Area3D overlap.
            # The same original JobScene.interact performs the actual room transition.
            authoritative_job.ender.position = authoritative_job.GANGWAY_POSITION
            if not authoritative_job.interact() or authoritative_job.room != "engineering":
                bridge_status = "The existing First Wake boarding rules rejected this entry."
                return false
            physically_confirmed_interactions += 1
            bridge_status = "Original First Wake engineering room entered. Inspect all three stations and the safety checklist."
            return true
        _:
            if not ENGINEERING_STATIONS.has(probe_name):
                bridge_status = "Unknown 3D story interaction blocked."
                return false
            if authoritative_job.room != "engineering":
                bridge_status = "Engineering is inaccessible before verified gangway boarding."
                return false
            var item: String = ENGINEERING_STATIONS[probe_name]
            if authoritative_job.opening.step_key() != "engineering":
                bridge_status = "Engineering checks are already completed; 3D flight remains gated."
                return false
            if item == "checklist" and authoritative_job.inspected_items.size() != (
                    authoritative_job.ENGINEERING_ITEMS.size()):
                bridge_status = "First complete reference, containment and fuel inspections."
                return false
            if item != "checklist" and item in authoritative_job.inspected_items:
                bridge_status = "That original engineering inspection is already recorded."
                return false
            # Original job checks player distance to its original station positions;
            # this maps a REAL 3D physics overlap to that SAME existing contract.
            authoritative_job.ender.position = authoritative_job.ROOM_POSITIONS[item]
    if not authoritative_job.interact():
        bridge_status = "Original First Wake scene refused the attempted interaction."
        return false
    physically_confirmed_interactions += 1
    bridge_status = _dialogue_line() if authoritative_job.dialogue_open else str(authoritative_job.last_message)
    return true

func story_snapshot() -> Dictionary:
    var progress: Dictionary = authoritative_session.progress_snapshot()
    progress["bridge_ready"] = bridge_ready
    progress["original_job_scene_reused"] = true
    progress["same_original_opening_instance"] = authoritative_job != null and (
        authoritative_session.opening == authoritative_job.opening)
    progress["flyer_read"] = authoritative_job != null and authoritative_job.flyer_read
    progress["dialogue_open"] = authoritative_job != null and authoritative_job.dialogue_open
    progress["dialogue_line"] = _dialogue_line()
    progress["dialogue_completions"] = completed_dialogues.duplicate()
    progress["verified_probe_interactions"] = physically_confirmed_interactions
    progress["3d_engineering_room_ready"] = (
        authoritative_job != null and authoritative_job.room == "engineering"
    )
    progress["engineering_checks"] = (
        authoritative_job.inspected_items.duplicate() if authoritative_job != null else []
    )
    progress["3d_flight_launch_allowed"] = false
    progress["physical_3d_water_contact_verified"] = false
    progress["3d_authoritative_checkpoint_available"] = false
    return progress
