extends SceneTree
## Native contract for independent skills, correct equip visual and no combat grant.
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")
const Silhouette = preload("res://scripts/weapon_silhouette_review.gd")

func _initialize() -> void:
    var model = Catalog.new()
    if not model.validate():
        _fail("catalog did not validate")
        return
    if not model.weapon("missing").is_empty() or not model.skills_for("missing").is_empty():
        _fail("unknown weapons must fail closed")
        return

    var learned: Array[String] = []
    if model.unlock_status("full_length_staff","staff.measured_footwork",learned,1,2) != "ready":
        _fail("tier-one technique unavailable")
        return
    var first := model.learn("full_length_staff","staff.measured_footwork",learned,1,2)
    if not bool(first["ok"]) or int(first["points"]) != 1:
        _fail("first technique point accounting")
        return
    learned = first["known"]
    if model.unlock_status("practice_sword","staff.deflecting_arc",learned,3,3) != "wrong_family_or_skill":
        _fail("cross-family unlock permitted")
        return
    if model.unlock_status("full_length_staff","staff.deflecting_arc",learned,1,2) != "rank_required":
        _fail("rank gate not enforced")
        return
    var second := model.learn("full_length_staff","staff.deflecting_arc",learned,2,1)
    if not bool(second["ok"]):
        _fail("eligible second technique rejected")
        return
    learned = second["known"]
    if bool(model.learn("full_length_staff","staff.deflecting_arc",learned,3,2)["ok"]):
        _fail("duplicate technique charged")
        return
    if bool(model.learn("full_length_staff","staff.centerline_drive",learned,3,0)["ok"]):
        _fail("zero-point unlock permitted")
        return
    if model.battle_preview("full_length_staff",learned).size() != 2:
        _fail("equipped family did not restore learned technique surface")
        return
    if not model.battle_preview("practice_sword",learned).is_empty():
        _fail("unequipped staff techniques leaked into sword menu")
        return
    for action in model.battle_preview("full_length_staff",learned):
        if bool(action["executionAuthorized"]):
            _fail("review skill falsely gained native formula authority")
            return

    var display = Silhouette.new()
    if not display.select_weapon("service_rifle") or str(display.visual_contract()["family"]) != "rifle":
        _fail("rifle silhouette selection failed")
        return
    if display.select_weapon("missing") or str(display.visual_contract()["family"]) != "rifle":
        _fail("invalid equip changed rendered family")
        return
    var packed = load("res://scenes/weapon_tree_review.tscn")
    if packed == null:
        _fail("native review scene missing")
        return
    var review = packed.instantiate()
    get_root().add_child(review)
    if not review.has_node("WeaponSilhouette"):
        _fail("native UI lacks actual weapon silhouette node")
        return
    if review.current_weapon_id() != "full_length_staff":
        _fail("scene default weapon drifted")
        return
    review._cycle_weapon(1)
    if review.current_weapon_id() != "practice_sword":
        _fail("equipment selector failed")
        return
    if str(review.get_node("WeaponSilhouette").visual_contract()["family"]) != "sword":
        _fail("weapon equip did not change drawing profile")
        return
    review.queue_free()
    display.free()
    print("STARRY_SKY_WEAPON_TREE_REVIEW_PASS: 4 families, 12 nodes, switching silhouettes, fail-closed combat")
    quit(0)

func _fail(message: String) -> void:
    push_error("STARRY_SKY_WEAPON_TREE_REVIEW_FAIL: "+message)
    quit(1)
