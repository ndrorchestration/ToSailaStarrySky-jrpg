extends RefCounted
## Isolated review model. No combat formula or save schema is changed.
const VERSION := "0.1.0"
const AUTHORITY := "PROPOSAL_REVIEW_ONLY"
const WEAPONS := {
    "full_length_staff": {"label":"Full-Length Staff","family":"staff","silhouette":"straight_two_ferrules_mid_wrap","note":"Ender staff anchor; skill names proposed"},
    "practice_sword": {"label":"Practice Sword","family":"sword","silhouette":"single_edge_brass_guard","note":"Reson sword vocabulary established; item proposed"},
    "field_pike": {"label":"Field Pike","family":"pike","silhouette":"long_shaft_spear_tip","note":"Reson pike vocabulary established; item proposed"},
    "service_rifle": {"label":"Rifle Silhouette Study","family":"rifle","silhouette":"long_barrel_shoulder_stock","note":"Reson firearm family established; exact model open"}
}
const TREES := {
    "staff": [
        {"id":"staff.measured_footwork","name":"Measured Footwork","rank":1,"requires":"","intent":"Positioning and stance","cue":"Grounded step"},
        {"id":"staff.deflecting_arc","name":"Deflecting Arc","rank":2,"requires":"staff.measured_footwork","intent":"Guard and counter","cue":"Compact brass contact glint"},
        {"id":"staff.centerline_drive","name":"Centerline Drive","rank":3,"requires":"staff.deflecting_arc","intent":"Committed physical strike","cue":"Full-length thrust"}
    ],
    "sword": [
        {"id":"sword.edge_discipline","name":"Edge Discipline","rank":1,"requires":"","intent":"Controlled attack","cue":"Clean steel sweep"},
        {"id":"sword.turning_parry","name":"Turning Parry","rank":2,"requires":"sword.edge_discipline","intent":"Defense and riposte","cue":"Short contact sparks"},
        {"id":"sword.crosswind_cut","name":"Crosswind Cut","rank":3,"requires":"sword.turning_parry","intent":"Mobile physical combo","cue":"Paired blade arcs"}
    ],
    "pike": [
        {"id":"pike.distance_read","name":"Distance Read","rank":1,"requires":"","intent":"Reach and spacing","cue":"Extended ground shadow"},
        {"id":"pike.braced_line","name":"Braced Line","rank":2,"requires":"pike.distance_read","intent":"Intercept and defense","cue":"Shaft braces into ground"},
        {"id":"pike.breakthrough_thrust","name":"Breakthrough Thrust","rank":3,"requires":"pike.braced_line","intent":"Precise penetrating attack","cue":"Narrow strike trail"}
    ],
    "rifle": [
        {"id":"rifle.sight_picture","name":"Sight Picture","rank":1,"requires":"","intent":"Precision and preparation","cue":"Small focus reticle"},
        {"id":"rifle.controlled_pair","name":"Controlled Pair","rank":2,"requires":"rifle.sight_picture","intent":"Bounded ranged attack","cue":"Two muzzle pulses"},
        {"id":"rifle.covering_line","name":"Covering Line","rank":3,"requires":"rifle.controlled_pair","intent":"Suppression and positioning","cue":"Restrained directional warnings"}
    ]
}
func weapon(weapon_id: String) -> Dictionary:
    if not WEAPONS.has(weapon_id):
        return {}
    return Dictionary(WEAPONS[weapon_id]).duplicate(true)

func skills_for(weapon_id: String) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    var item := weapon(weapon_id)
    if item.is_empty():
        return results
    for skill in TREES.get(str(item["family"]), []):
        results.append(Dictionary(skill).duplicate(true))
    return results

func skill_by_id(skill_id: String) -> Dictionary:
    for family in TREES:
        for skill in TREES[family]:
            if str(skill["id"]) == skill_id:
                return Dictionary(skill).duplicate(true)
    return {}

func unlock_status(weapon_id: String, skill_id: String, known: Array[String], training_rank: int, points: int) -> String:
    var item := weapon(weapon_id)
    if item.is_empty():
        return "unknown_weapon"
    var skill := skill_by_id(skill_id)
    if skill.is_empty() or not skill_id.begins_with(str(item["family"]) + "."):
        return "wrong_family_or_skill"
    if skill_id in known:
        return "learned"
    if training_rank < int(skill["rank"]):
        return "rank_required"
    if not str(skill["requires"]).is_empty() and str(skill["requires"]) not in known:
        return "prerequisite_required"
    if points < 1:
        return "points_required"
    return "ready"

func learn(weapon_id: String, skill_id: String, known: Array[String], training_rank: int, points: int) -> Dictionary:
    var status := unlock_status(weapon_id, skill_id, known, training_rank, points)
    if status != "ready":
        return {"ok":false,"reason":status,"known":known.duplicate(),"points":points}
    var next_known: Array[String] = known.duplicate()
    next_known.append(skill_id)
    return {"ok":true,"reason":"learned","known":next_known,"points":points - 1}

func battle_preview(weapon_id: String, known: Array[String]) -> Array[Dictionary]:
    ## Recomputed after equip; learned skills on unequipped families persist.
    ## Preview actions are never executable in the current Chapter I resolver.
    var result: Array[Dictionary] = []
    for skill in skills_for(weapon_id):
        if str(skill["id"]) in known:
            result.append({"id":skill["id"],"name":skill["name"],"weaponId":weapon_id,
                "executionAuthorized":false,"authority":"PREVIEW_ONLY_NOT_FORMULA_AUTHORIZED"})
    return result

func validate() -> bool:
    if WEAPONS.size() != 4 or TREES.size() != 4:
        return false
    if str(WEAPONS["full_length_staff"]["silhouette"]) != "straight_two_ferrules_mid_wrap":
        return false
    var seen := {}
    for family in TREES:
        var prior := ""
        var skills: Array = TREES[family]
        if skills.size() != 3:
            return false
        for i in range(skills.size()):
            var s: Dictionary = skills[i]
            var id: String = str(s["id"])
            if seen.has(id) or not id.begins_with(str(family) + "."):
                return false
            if int(s["rank"]) != i + 1 or str(s["requires"]) != prior:
                return false
            seen[id] = true
            prior = id
    for id in WEAPONS:
        if not TREES.has(str(WEAPONS[id]["family"])):
            return false
    return true
