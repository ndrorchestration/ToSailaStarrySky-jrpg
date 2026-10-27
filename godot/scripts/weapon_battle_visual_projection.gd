extends RefCounted
## Read-only bridge for the EXISTING authorized First Wake staffStrike.
## This file has no FormulaEncounter, save, inventory or resource mutation API.
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")
const Timeline = preload("res://scripts/weapon_action_timeline.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")

const VERSION := "0.1.0"
const RENDER_AUTHORITY := "VISUAL_PROJECTION_ONLY"
const ENDER_STAFF_ID := "full_length_staff"
const STRIKE_ACTION_ID := "staffStrike"

var catalog = Catalog.new()
var timeline = Timeline.new()
var authority = Authority.new()

func initial(actor_id: String, weapon_id: String, reduced_motion: bool = false) -> Dictionary:
    if not _permitted_weapon(actor_id, weapon_id):
        return {}
    return _frame(actor_id, weapon_id, "idle", "", 0.0, reduced_motion)

func accepted_action(actor_id: String, weapon_id: String, action_id: String,
        elapsed: float, reduced_motion: bool = false) -> Dictionary:
    if not _permitted_weapon(actor_id, weapon_id):
        return {}
    if not authority.can_use_formula_action(actor_id, action_id):
        return {}
    # The other authorized actions deliberately have NO invented animations.
    # Their neutral idle state is not a new formula or skill grant.
    var visual_action := "attack" if action_id == STRIKE_ACTION_ID else "idle"
    return _frame(actor_id, weapon_id, visual_action, action_id, elapsed, reduced_motion)

func _frame(actor_id: String, weapon_id: String, visual_action: String,
        action_id: String, elapsed: float, reduced_motion: bool) -> Dictionary:
    var sample: Dictionary = timeline.sample(weapon_id, visual_action, elapsed, reduced_motion)
    if sample.is_empty():
        return {}
    sample["actorId"] = actor_id
    sample["formulaActionId"] = action_id
    sample["renderAuthority"] = RENDER_AUTHORITY
    sample["canAuthorizeActions"] = false
    sample["approvedCharacterArt"] = false
    return sample

func _permitted_weapon(actor_id: String, weapon_id: String) -> bool:
    return actor_id == "ender" and weapon_id == ENDER_STAFF_ID \
        and str(catalog.weapon(weapon_id).get("family","")) == "staff"

func validate() -> bool:
    if not catalog.validate() or not timeline.validate() or not authority.validate():
        return false
    if not initial("ender", ENDER_STAFF_ID).has("weaponId"):
        return false
    if not initial("lyra", ENDER_STAFF_ID).is_empty():
        return false
    if not initial("ender", "practice_sword").is_empty():
        return false
    for unapproved in ["staff.measured_footwork", "sharedDream", "windWard", "aetherSeal"]:
        if not accepted_action("ender", ENDER_STAFF_ID, unapproved, 0.2).is_empty():
            return false
    var strike := accepted_action("ender", ENDER_STAFF_ID, STRIKE_ACTION_ID, 0.4)
    return not strike.is_empty() and str(strike["action"]) == "attack" \
        and not bool(strike["canAuthorizeActions"]) and int(strike["damage"]) == 0
