extends RefCounted
## READ-ONLY bridge from current actor combat authority to a rehearsal pose.
## This class neither calls FormulaEncounter.take_action nor resolves damage.
## A timeline 'attack' is not a newly authorized command.
const PartyAuthority = preload("res://scripts/first_wake_party_combat_authority.gd")
const Formula = preload("res://scripts/first_wake_combat_formula.gd")
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")
const Timeline = preload("res://scripts/weapon_action_timeline.gd")

const VERSION := "0.1.0"
const ACTOR_VISUALS := {
    "ender": {
        "staffStrike": {"weaponId":"full_length_staff", "animation":"attack"}
    }
}
const MODE_AUTHORIZED_INTENT := "AUTHORIZED_ACTION_VISUAL_ONLY"
const MODE_SANDBOX := "ANONYMOUS_EQUIPMENT_SANDBOX"

var authority = PartyAuthority.new()
var formula = Formula.new()
var catalog = Catalog.new()
var timeline = Timeline.new()

func actor_action_pose(actor_id: String, equipped_weapon_id: String,
        formula_action_id: String, elapsed: float, reduced_motion: bool = false) -> Dictionary:
    # Reject unknown actors, unresolved equipment, unsupported mappings,
    # missing formula permissions, and spoofed technique IDs *before* drawing.
    if not authority.can_use_formula_action(actor_id, formula_action_id):
        return {}
    if formula.get_formula(formula_action_id).is_empty():
        return {}
    var mapped: Dictionary = ACTOR_VISUALS.get(actor_id, {})
    if not mapped.has(formula_action_id):
        return {}
    var cue: Dictionary = mapped[formula_action_id]
    if str(cue["weaponId"]) != equipped_weapon_id:
        return {}
    var pose := timeline.sample(equipped_weapon_id, str(cue["animation"]), elapsed, reduced_motion)
    if pose.is_empty():
        return {}
    pose["mode"] = MODE_AUTHORIZED_INTENT
    pose["actorId"] = actor_id
    pose["formulaActionId"] = formula_action_id
    pose["actorPermissionObserved"] = true
    pose["visualOnly"] = true
    pose["combatCommandIssued"] = false
    pose["damage"] = 0
    pose["canExecute"] = false
    return pose

func equipment_sandbox_pose(weapon_id: String, animation: String,
        elapsed: float, reduced_motion: bool = false) -> Dictionary:
    # Family changes belong to anonymous art/rig study, NEVER to actor equipment.
    var pose := timeline.sample(weapon_id, animation, elapsed, reduced_motion)
    if pose.is_empty():
        return {}
    pose["mode"] = MODE_SANDBOX
    pose["actorId"] = ""
    pose["formulaActionId"] = ""
    pose["actorPermissionObserved"] = false
    pose["visualOnly"] = true
    pose["combatCommandIssued"] = false
    pose["damage"] = 0
    pose["canExecute"] = false
    return pose

func learned_tree_preview(weapon_id: String, known: Array[String]) -> Array[Dictionary]:
    # The existing weapon tree does not acquire authorization by being displayed.
    var rows := catalog.battle_preview(weapon_id, known)
    for row in rows:
        row["combatCommandIssued"] = false
        row["actorPermissionObserved"] = false
    return rows

func validate() -> bool:
    if not authority.validate() or not formula.validate() or not timeline.validate():
        return false
    if ACTOR_VISUALS.size() != 1:
        return false
    for actor in ACTOR_VISUALS:
        for action in ACTOR_VISUALS[actor]:
            var cue: Dictionary = ACTOR_VISUALS[actor][action]
            if not authority.can_use_formula_action(str(actor), str(action)):
                return false
            if catalog.weapon(str(cue["weaponId"])).is_empty():
                return false
            if timeline.duration(str(cue["weaponId"]),str(cue["animation"])) <= 0.0:
                return false
    return actor_action_pose("ender","practice_sword","staffStrike",0.2).is_empty()
