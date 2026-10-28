extends Node2D
## REVIEW ONLY: two distinct walkable provisional salvage areas with immediate
## in-memory custody receipts. Not approved fuel chemistry, coast geography,
## a real persistent inventory or a materials acquisition simulation.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Core = preload("res://scripts/first_wake_core_alignment_review.gd")
const Actor = preload("res://scripts/pilot_actor.gd")
const Inputs = preload("res://scripts/first_wake_chapter1_input_policy.gd")
const WorkshopScene = preload("res://scenes/first_wake_core_alignment_review.tscn")

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
    ender.position = Vector2(160, 471)
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
        for x in [45.0, 205.0, 365.0, 525.0, 685.0, 845.0]:
            draw_arc(Vector2(x, 368), 54, 0, PI, 20, Color("#92c9ca"), 2.0)
        draw_line(Vector2(0, 396), Vector2(960, 396), Color("#b8dad2"), 3.0)
    else:
        draw_rect(Rect2(78, 235, 804, 160), Color("#445761"))
        for x in [135.0, 320.0, 505.0, 690.0]:
            draw_rect(Rect2(x, 268, 140, 113), Color("#5a6663"))
            draw_line(Vector2(x + 9, 318), Vector2(x + 131, 318), Color("#c1a47c"), 2.0)
    draw_rect(Rect2(0, 396, 960, 147), Color("#6e5b4a") if water_side else Color("#635749"))
    for y in [417.0, 443.0, 469.0, 495.0, 521.0]:
        draw_line(Vector2(63, y), Vector2(900, y), Color("#907d68"), 1.0)
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
    draw_rect(Rect2(pos + Vector2(-35, -90), Vector2(70, 58)), Color("#3b675f") if already_taken else color)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-80, -99), label, HORIZONTAL_ALIGNMENT_LEFT, 162, 14, Color("#f9e8c8"))
    if already_taken:
        draw_line(pos + Vector2(-20, -63), pos + Vector2(20, -39), Color("#e7f0d7"), 3.0)
        draw_line(pos + Vector2(20, -63), pos + Vector2(-20, -39), Color("#e7f0d7"), 3.0)

func _unhandled_input(event: InputEvent) -> void:
    if workshop != null:
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
    hint.text = last_message + "  [Arrows: move; E: inspect, collect, change area or return]"
    queue_redraw()
