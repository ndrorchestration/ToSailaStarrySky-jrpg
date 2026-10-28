extends Node2D
## REVIEW ONLY: two distinct walkable provisional salvage areas with immediate
## in-memory custody receipts. Not approved fuel chemistry, coast geography,
## a real persistent inventory or a materials acquisition simulation.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Core = preload("res://scripts/first_wake_core_alignment_review.gd")
const Actor = preload("res://scripts/pilot_actor.gd")
const Inputs = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const WorkshopScene = preload("res://scenes/first_wake_core_alignment_review.tscn")
const Checkpoint = preload("res://scripts/first_wake_salvage_checkpoint_v3.gd")
const SaveStore = preload("res://scripts/first_wake_chapter1_save_store.gd")

const QUAY := "quay_review"
const DEPOT := "depot_review"
const BOUNDS := Rect2(Vector2(113, 411), Vector2(750, 110))
const RANGE := 64.0
const QUAY_SUPPLY := Vector2(288, 471)
const DEPOT_PART := Vector2(695, 471)
const QUAY_TO_DEPOT := Vector2(846, 471)
const DEPOT_TO_QUAY := Vector2(143, 471)
const RETURN_TO_WAKE := Vector2(695, 471)

var story
var core = Core.new()
var configured: bool = false
var imported_from_checkpoint: bool = false
var _restored_position: Vector2 = Vector2(160, 471)
var region: String = QUAY
var custody: Array[Dictionary] = []
var workshop: Node2D
var ender: CharacterBody2D
var ui_layer: CanvasLayer
var headline: Label
var objective: Label
var custody_label: Label
var hint: Label
var last_message: String = "Find both physical review objects, then return aboard for installation."

func configure_after_theory(story_state: Variant) -> bool:
    if is_inside_tree() or configured:
        return false
    if not (story_state is RefCounted) or story_state.get_script() != Opening:
        return false
    var report: Dictionary = story_state.snapshot()
    if report.get("step", "") != "working_theory" or report.get("active_party_ids", []) != ["ender", "ionia", "lyra"]:
        return false
    if not bool(report.get("safe_reunion_confirmed", false)) or int(report.get("evidence_count", 0)) < 2:
        return false
    if not core.begin(story_state):
        return false
    story = story_state
    configured = true
    return true

func configure_from_restored_checkpoint(rebuilt: Dictionary) -> bool:
    # Called before adding to SceneTree. The codec alone constructs the
    # valid story, candidate two-source receipts and bounded player position.
    if is_inside_tree() or configured or not bool(rebuilt.get("ok", false)):
        return false
    var restored_story: Variant = rebuilt.get("opening")
    var restored_core: Variant = rebuilt.get("core")
    if not (restored_story is RefCounted) or restored_story.get_script() != Opening:
        return false
    if not (restored_core is RefCounted) or restored_core.get_script() != Core:
        return false
    if restored_core.authorized_story != restored_story:
        return false
    if not Checkpoint.validate(Checkpoint.encode(restored_story, restored_core,
            str(rebuilt.get("region", "")), rebuilt.get("custody", []),
            rebuilt.get("player_position", Vector2(-1, -1)))).get("ok", false):
        return false
    story = restored_story
    core = restored_core
    region = str(rebuilt["region"])
    custody.clear()
    for receipt in rebuilt["custody"]:
        custody.append(Dictionary(receipt).duplicate(true))
    configured = true
    _restored_position = rebuilt["player_position"]
    imported_from_checkpoint = true
    return true

func _ready() -> void:
    Inputs.ensure_defaults()
    if not configured:
        push_error("TSTSS_SALVAGE_REVIEW_REQUIRES_SHARED_THEORY")
        return
    ender = Actor.new()
    ender.name = "EnderSalvageReviewPlayer"
    ender.character_name = "Ender"
    ender.player_controlled = true
    ender.walking_bounds = BOUNDS
    ender.position = _restored_position if imported_from_checkpoint else Vector2(160, 471)
    add_child(ender)
    ender.set_walk_review_enabled(true)
    ui_layer = CanvasLayer.new()
    ui_layer.name = "SalvageReviewReadableUI"
    add_child(ui_layer)
    headline = _label(ui_layer, Vector2(24, 20), 23)
    objective = _label(ui_layer, Vector2(25, 65), 18)
    custody_label = _label(ui_layer, Vector2(25, 102), 16)
    hint = _label(ui_layer, Vector2(24, 556), 16)
    _refresh()

func _label(parent: Node, at: Vector2, font_size: int) -> Label:
    var node := Label.new()
    node.position = at
    node.custom_minimum_size = Vector2(917, 44)
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", Color("#f9e9ce"))
    node.add_theme_color_override("font_shadow_color", Color("#10263c"))
    parent.add_child(node)
    return node

func _draw() -> void:
    # Two distinguishable temporary environments, not named canon places.
    var water_side: bool = region == QUAY
    draw_rect(Rect2(0, 0, 960, 640), Color("#173649") if water_side else Color("#293e45"))
    if water_side:
        draw_rect(Rect2(0, 270, 960, 125), Color("#326979"))
        # Matched distant shore haze with the flight and family compositions.
        for mist in range(10):
            var mist_y := 287.0 + float(mist) * 9.0
            draw_line(Vector2(0, mist_y), Vector2(960, mist_y - 3.0), Color(0.90, 0.84, 0.71, 0.015 + float(mist) * 0.004), 2.0)
        for x in [45.0, 205.0, 365.0, 525.0, 685.0, 845.0]:
            draw_arc(Vector2(x, 368), 54, 0, PI, 20, Color("#92c9ca"), 2.0)
        draw_line(Vector2(0, 396), Vector2(960, 396), Color("#b8dad2"), 3.0)
    else:
        draw_rect(Rect2(78, 235, 804, 160), Color("#445761"))
        for x in [135.0, 320.0, 505.0, 690.0]:
            draw_rect(Rect2(x, 268, 140, 113), Color("#5a6663"))
            draw_line(Vector2(x + 9, 318), Vector2(x + 131, 318), Color("#c1a47c"), 2.0)
    # Shared authored surface kit across the quay and stores annex;
    # strictly below the navigable actor and existing custody stations.
    draw_rect(Rect2(0, 396, 960, 147), Color("#665443") if water_side else Color("#514e46"))
    for y in [417.0, 443.0, 469.0, 495.0, 521.0]:
        draw_line(Vector2(0, y), Vector2(960, y - 4), Color("#a58b69") if water_side else Color("#89908b"), 1.5)
        draw_line(Vector2(0, y + 4), Vector2(960, y), Color("#312e2c", 0.65), 1.0)
    for row_idx in range(5):
        for section in range(9):
            var px := 31.0 + float(section) * 118.0 + float(row_idx % 2) * 50.0
            var py := 415.0 + float(row_idx) * 26.0
            draw_line(Vector2(px, py), Vector2(px - 5.0, py + 21.0), Color("#282e30", 0.46), 1.0)
    if water_side:
        for post in range(7):
            var hx := 58.0 + float(post) * 146.0
            draw_line(Vector2(hx, 376), Vector2(hx, 406), Color("#263f48"), 4.0)
            draw_line(Vector2(hx - 19, 379), Vector2(hx + 19, 379), Color("#ba9c73"), 2.0)
        for spark in range(22):
            var sx := float(spark) * 45.0
            var sy := 302.0 + float(spark % 4) * 19.0
            draw_line(Vector2(sx, sy), Vector2(sx + 14, sy), Color(0.77, 0.92, 0.89, 0.22), 1.0)
    else:
        for truss in range(7):
            var tx := 93.0 + float(truss) * 128.0
            draw_line(Vector2(tx, 246), Vector2(tx + 34, 380), Color("#293e47"), 3.0)
            draw_line(Vector2(tx + 34, 380), Vector2(tx + 75, 251), Color("#77817c", 0.65), 1.5)
        for glow_x in [178.0, 462.0, 752.0]:
            draw_circle(Vector2(glow_x, 285), 19, Color(1.0, 0.76, 0.48, 0.055))
            draw_circle(Vector2(glow_x, 285), 4, Color("#eec18c"))
    draw_rect(Rect2(0, 0, 960, 159), Color("#0c1b2c"))
    draw_rect(Rect2(0, 547, 960, 93), Color("#0c1b2c"))
    if water_side:
        _station(QUAY_SUPPLY, "STOCK CACHE", "recovered_supply", Color("#bf9664"))
        _station(RETURN_TO_WAKE, "RETURN TO WAKE", "", Color("#7daab1"))
        _station(QUAY_TO_DEPOT, "DEPOT PATH", "", Color("#d2ae79"))
    else:
        _station(DEPOT_TO_QUAY, "QUAY PATH", "", Color("#d2ae79"))
        _station(DEPOT_PART, "REPLACEMENT PART", "recovered_part", Color("#a8a9a6"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 222), "AREA: %s — NOT APPROVED WORLD GEOGRAPHY" % ("SHORE CACHE" if water_side else "STORES ANNEX"), HORIZONTAL_ALIGNMENT_LEFT, 870, 17, Color("#f0d8ae"))
    if workshop != null:
        draw_rect(Rect2(0, 0, 960, 640), Color("#081420"))

func _station(pos: Vector2, label: String, item_id: String, color: Color) -> void:
    var already_taken: bool = item_id != "" and item_id in core.recovered
    # Recognizable silhouettes replace the earlier single flat placeholder
    # rectangles; positions and physical pickup permissions are unchanged.
    var left := pos.x - 35.0
    var top := pos.y - 90.0
    draw_rect(Rect2(left - 3, top + 54, 76, 5), Color("#27383e", 0.65))
    if item_id == "recovered_supply":
        draw_rect(Rect2(left, top + 9, 70, 46), Color("#614c3a") if not already_taken else Color("#355a55"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(left - 3, top + 10), Vector2(left + 14, top),
            Vector2(left + 60, top), Vector2(left + 73, top + 10)
        ]), Color("#c8a171"))
        for strap in [12.0, 53.0]:
            draw_line(Vector2(left + strap, top + 9), Vector2(left + strap, top + 51), Color("#c3a66a"), 3.0)
        draw_rect(Rect2(left + 28, top + 24, 15, 11), Color("#d1bc8a"))
    elif item_id == "recovered_part":
        draw_circle(pos + Vector2(0, -63), 26, Color("#334953"))
        draw_arc(pos + Vector2(0, -63), 24, 0, TAU, 24, Color("#c6b899"), 5.0)
        draw_circle(pos + Vector2(0, -63), 12, Color("#8ac4c7"))
        for tooth in range(8):
            var angle := TAU * float(tooth) / 8.0
            draw_line(pos + Vector2(cos(angle), sin(angle)) * 22 + Vector2(0, -63), pos + Vector2(cos(angle), sin(angle)) * 33 + Vector2(0, -63), Color("#d7c099"), 5.0)
    else:
        draw_colored_polygon(PackedVector2Array([
            Vector2(left, top + 54), Vector2(left, top + 19),
            Vector2(left + 35, top), Vector2(left + 70, top + 19),
            Vector2(left + 70, top + 54)
        ]), Color("#446773") if not already_taken else Color("#3b675f"))
        draw_line(Vector2(left + 12, top + 27), Vector2(left + 58, top + 27), Color("#d6bd8c"), 3.0)
        draw_circle(Vector2(left + 35, top + 39), 7, Color("#aad4cf"))
    draw_string(ThemeDB.fallback_font, pos + Vector2(-80, -99), label, HORIZONTAL_ALIGNMENT_LEFT, 162, 14, Color("#f9e8c8"))
    if already_taken:
        draw_line(pos + Vector2(-20, -63), pos + Vector2(20, -39), Color("#e7f0d7"), 3.0)
        draw_line(pos + Vector2(20, -63), pos + Vector2(-20, -39), Color("#e7f0d7"), 3.0)

func _unhandled_input(event: InputEvent) -> void:
    if workshop != null:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_K:
            var saved: Dictionary = save_review_checkpoint()
            last_message = "V3 salvage saved." if bool(saved.get("ok", false)) else "V3 save denied: " + str(saved.get("error", saved.get("reason", "unknown")))
            _refresh()
            get_viewport().set_input_as_handled()
            return
        if event.keycode == KEY_L:
            var loaded: Dictionary = load_review_checkpoint()
            last_message = "V3 salvage restored." if bool(loaded.get("ok", false)) else "V3 load denied: " + str(loaded.get("error", loaded.get("reason", "unknown")))
            _refresh()
            get_viewport().set_input_as_handled()
            return
    if event.is_action_pressed(Inputs.INTERACT) and not event.is_echo():
        interact()
        get_viewport().set_input_as_handled()

func interact() -> bool:
    if workshop != null or ender == null or not configured:
        return false
    if region == QUAY:
        if _near(QUAY_SUPPLY) and "recovered_supply" not in core.recovered:
            return recover_item("recovered_supply", QUAY)
        if _near(QUAY_TO_DEPOT):
            region = DEPOT
            ender.position = Vector2(170, 471)
            last_message = "Entered stores review annex. Look for the checked replacement part."
            _refresh()
            return true
        if _near(RETURN_TO_WAKE) and core.snapshot()["phase"] == "install":
            return handoff_to_workshop()
    elif region == DEPOT:
        if _near(DEPOT_PART) and "recovered_part" not in core.recovered:
            return recover_item("recovered_part", DEPOT)
        if _near(DEPOT_TO_QUAY):
            region = QUAY
            ender.position = Vector2(830, 471)
            last_message = "Back on the review quay. Return both objects to the Wake."
            _refresh()
            return true
    last_message = "Physical proximity and both distinct acquisitions are required."
    _refresh()
    return false

func recover_item(item_id: String, source_region: String) -> bool:
    # Source region, grounded player distance and matching station are checked
    # against the actual scene rather than accepted from a caller's receipt.
    if not configured or ender == null or workshop != null:
        return false
    if item_id == "recovered_supply":
        if source_region != QUAY or region != QUAY or not _near(QUAY_SUPPLY):
            return false
    elif item_id == "recovered_part":
        if source_region != DEPOT or region != DEPOT or not _near(DEPOT_PART):
            return false
    else:
        return false
    if not core.take_world_item(item_id, "world_pickup"):
        return false
    custody.append({
        "item_id": item_id,
        "area_id": source_region,
        "custodian": "ender",
        "source": "walkable_scene_interaction",
    })
    last_message = "Collected %s on foot from %s; custody logged." % [item_id, source_region]
    _refresh()
    return true

func export_review_checkpoint() -> Dictionary:
    if not configured or ender == null or workshop != null:
        return {}
    return Checkpoint.encode(story, core, region, custody, ender.position)

func save_review_checkpoint(path: String = Checkpoint.SLOT_PATH) -> Dictionary:
    var data: Dictionary = export_review_checkpoint()
    if data.is_empty():
        return {"ok": false, "reason": "not_safe_salvage_checkpoint_stage"}
    return SaveStore.new().save_snapshot(data, path, Checkpoint)

func load_review_checkpoint(path: String = Checkpoint.SLOT_PATH) -> Dictionary:
    if not configured or workshop != null or ender == null:
        return {"ok": false, "reason": "not_in_salvage"}
    var loaded: Dictionary = SaveStore.new().load_snapshot(path, Checkpoint)
    if not bool(loaded.get("ok", false)):
        return loaded
    if not restore_review_checkpoint(loaded["snapshot"]):
        return {"ok": false, "reason": "checkpoint_does_not_match_active_story"}
    return {"ok": true, "source": loaded.get("source", ""), "recovered": loaded.get("recovered", false)}

func restore_review_checkpoint(raw: Variant) -> bool:
    # Fully validate the saved bytes BEFORE any scene mutation, and refuse
    # unrelated story memories: do not silently rewrite parent flight/family
    # contracts during an active game session.
    if not configured or ender == null or workshop != null:
        return false
    if not bool(Checkpoint.validate(raw).get("ok", false)):
        return false
    if story.step_key() != "working_theory" or story.clues != raw["clues"]:
        return false
    if story.active_party_ids != ["ender", "ionia", "lyra"] or not story.safe_reunion_confirmed:
        return false
    var rebuilt_core = Core.new()
    if not rebuilt_core.begin(story):
        return false
    for receipt in raw["custody"]:
        if not rebuilt_core.take_world_item(str(receipt["item_id"]), "world_pickup"):
            return false
    # All validation and replay complete. Commit one synchronized scene swap.
    var point: Dictionary = raw["player_position"]
    core = rebuilt_core
    custody.clear()
    for receipt in raw["custody"]:
        custody.append(Dictionary(receipt).duplicate(true))
    region = str(raw["region"])
    ender.position = Vector2(float(point["x"]), float(point["y"]))
    last_message = "V3 review resumed; original real flight is NOT re-verified by saved evidence."
    _refresh()
    return true

func handoff_to_workshop() -> bool:
    if workshop != null or region != QUAY or ender == null or not _near(RETURN_TO_WAKE):
        return false
    if core.snapshot()["phase"] != "install" or custody.size() != 2:
        return false
    for id in Core.ITEM_IDS:
        var count := 0
        for receipt in custody:
            if str(receipt.get("item_id", "")) == id and str(receipt.get("source", "")) == "walkable_scene_interaction":
                count += 1
        if count != 1:
            return false
    var scene := WorkshopScene.instantiate()
    if not bool(scene.call("configure_with_salvage_core", story, core)):
        scene.free()
        return false
    workshop = scene
    ender.player_controlled = false
    ender.visible = false
    ui_layer.visible = false
    add_child(workshop)
    queue_redraw()
    return true

func snapshot() -> Dictionary:
    return {
        "region": region,
        "collected_ids": core.recovered.duplicate(),
        "custody": custody.duplicate(true),
        "required_regions_visited": _all_regions_have_receipts(),
        "material_installation_ready": core.snapshot()["phase"] == "install",
        "workshop_handoff": workshop != null,
        "story_identity_preserved": core.authorized_story == story,
        "genuine_world_inventory": false,
        "persistent_item_custody": false,
        "approved_material_identity": false,
        "approved_geography": false,
        "review_only": true,
        "v3_checkpoint_available": configured and workshop == null,
        "checkpoint_restores_prior_physics": false,
    }

func _all_regions_have_receipts() -> bool:
    var regions: Array[String] = []
    for entry in custody:
        var region_name: String = str(entry.get("area_id", ""))
        if region_name not in regions:
            regions.append(region_name)
    return QUAY in regions and DEPOT in regions

func _near(target: Vector2) -> bool:
    return ender.position.distance_to(target) <= RANGE

func _refresh() -> void:
    if headline == null:
        return
    headline.text = "FIRST WAKE / WALKABLE SALVAGE — REVIEW ONLY"
    objective.text = "Two source areas: %s  |  %d/2 collected" % [region.to_upper(), core.recovered.size()]
    custody_label.text = "HELD BY ENDER: " + (" / ".join(core.recovered) if not core.recovered.is_empty() else "(none)") + "  |  FLIGHT: LOCKED"
    hint.text = last_message + "  [Arrows: move; E: interact; K: v3 save; L: v3 load]"
    queue_redraw()
