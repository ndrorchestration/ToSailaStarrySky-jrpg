extends RefCounted
## Immutable-snapshot visual gate for an isolated neutral Godot battle lab.
## The actual FormulaEncounter.take_action() is called ONLY by the host scene,
## never by this class. This receipt is not a signed production event.
const WeaponVisual = preload("res://scripts/weapon_battle_visual_adapter.gd")
const VERSION := "neutral_visual_cue_v0"
const ACCEPTED_ENEMY := "windShear"
const ACCEPTED_HAZARD := "wind_shear"

var weapon = WeaponVisual.new()
var consumed_ids: Dictionary = {}

func reset() -> void:
    consumed_ids.clear()

func consume(actor_id: String, weapon_id: String, action_id: String,
        accepted: bool, before: Dictionary, after: Dictionary,
        reduced_motion: bool = false) -> Dictionary:
    if not accepted or actor_id != "ender" or weapon_id != "full_length_staff"         or action_id != "staffStrike" or before.is_empty() or after.is_empty():
        return {}
    if not bool(before.get("active", false)) or bool(before.get("completed", true))         or bool(before.get("playerDefeated", true)) or not bool(after.get("active", false)):
        return {}
    if str(before.get("encounterKind", "")) != "authored_hazard"         or str(after.get("encounterKind", "")) != "authored_hazard":
        return {}
    var previous_target: Dictionary = before.get("target", {})
    var next_target: Dictionary = after.get("target", {})
    var prev_player: Dictionary = before.get("player", {})
    var next_player: Dictionary = after.get("player", {})
    if str(previous_target.get("id", "")) != ACCEPTED_ENEMY         or str(next_target.get("id", "")) != ACCEPTED_ENEMY         or str(previous_target.get("hazardId", "")) != ACCEPTED_HAZARD         or str(next_target.get("hazardId", "")) != ACCEPTED_HAZARD         or str(prev_player.get("id", "")) != actor_id         or str(next_player.get("id", "")) != actor_id:
        return {}
    var max_hp: int = int(previous_target.get("maxHp", -1))
    var hp_before: int = int(previous_target.get("hp", -1))
    var hp_after: int = int(next_target.get("hp", -1))
    if max_hp <= 0 or max_hp != int(next_target.get("maxHp", -2))         or hp_before <= 0 or hp_before > max_hp or hp_after < 0 or hp_after > hp_before:
        return {}
    var prior_turn: int = int(before.get("turns", -1))
    var new_turn: int = int(after.get("turns", -1))
    var prior_enemy_turn: int = int(before.get("enemyTurns", -1))
    var next_enemy_turn: int = int(after.get("enemyTurns", -1))
    var enemy_turn_delta: int = next_enemy_turn - prior_enemy_turn
    if prior_turn < 0 or new_turn != prior_turn + 1         or prior_enemy_turn < 0 or enemy_turn_delta < 0 or enemy_turn_delta > 1         or (not bool(after.get("completed", false)) and enemy_turn_delta != 1):
        return {}
    if int(prev_player.get("staffCharges", -1)) < 1         or int(next_player.get("staffCharges", -2)) != int(prev_player.get("staffCharges", -1)) - 1:
        return {}
    var earlier_log: Array = before.get("log", [])
    var latest_log: Array = after.get("log", [])
    if latest_log.size() <= earlier_log.size()         or not str(latest_log[earlier_log.size()]).begins_with("Staff Strike:"):
        return {}
    var receipt_id := "%s:%d" % [ACCEPTED_ENEMY, new_turn]
    if consumed_ids.has(receipt_id):
        return {}
    var pose: Dictionary = weapon.actor_action_pose(
        actor_id, weapon_id, action_id,
        weapon.timeline.duration(weapon_id, "attack") * 0.695,
        reduced_motion
    )
    if pose.is_empty() or bool(pose.get("canExecute", true))         or bool(pose.get("combatCommandIssued", true))         or not bool(pose.get("visualOnly", false)):
        return {}
    consumed_ids[receipt_id] = true
    return {
        "version": VERSION, "receiptId": receipt_id,
        "actorId": actor_id, "enemyId": ACCEPTED_ENEMY,
        "actionId": action_id, "beforeHp": hp_before, "afterHp": hp_after,
        "damageObserved": hp_before - hp_after,
        "enemyTurnsBefore": prior_enemy_turn, "enemyTurnsAfter": next_enemy_turn,
        "analyzed": not Dictionary(next_target.get("analysis", {})).is_empty(),
        "cleared": bool(after.get("completed", false)),
        "visualPose": pose.duplicate(true),
        "turnDelta": 1, "visualOnly": true, "canExecute": false,
        "combatActionIssued": false, "saveWritten": false,
        "storyPlacementApproved": false, "spriteApproved": false
    }
