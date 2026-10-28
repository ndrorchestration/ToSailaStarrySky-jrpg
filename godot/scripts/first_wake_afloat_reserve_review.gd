extends Node2D
## Review-only shipboard reserve inspection after verified local flotation.
## This is a navigable onboard station, not salvage, a shoreline, a new save
## schema, a validated fuel inventory, or permission to recruit Lyra/Talen.

const Actor = preload("res://scripts/pilot_actor.gd")

const RESERVE_POSITION := Vector2(729, 456)
const INTERACT_RADIUS := 68.0
const DECK_BOUNDS := Rect2(Vector2(154, 402), Vector2(680, 113))
# Keep the deck's actor collisions local: nested dock/flight review bodies
# otherwise remain physically present even when their visuals are hidden.
const ABOARD_ACTOR_LAYER := 1 << 18

var opening
var ender: CharacterBody2D
var ionia: CharacterBody2D
var inspection_observed: bool = false
var hint_label: Label

func configure_afloat(contract) -> bool:
    # Only the physical flight controller may admit this scene after contact.
    if is_inside_tree() or not (contract is RefCounted) or opening != null:
        return false
    if not contract.has_method("step_key") or contract.step_key() != "waterborne":
        return false
    if contract.active_party_ids != ["ender", "ionia"]:
        return false
    opening = contract
    return true

func _ready() -> void:
    if opening == null:
        # Opening this review scene directly never grants a story transition.
        queue_redraw()
        return
    var actors := Node2D.new()
    actors.name = "AfloatReviewActors"
    actors.y_sort_enabled = true
    add_child(actors)

    ender = Actor.new()
    ender.name = "Ender"
    ender.character_name = "Ender"
    ender.player_controlled = true
    ender.collision_layer = ABOARD_ACTOR_LAYER
    ender.collision_mask = ABOARD_ACTOR_LAYER
    ender.walking_bounds = DECK_BOUNDS
    ender.position = Vector2(210, 460)
    actors.add_child(ender)
    ender.set_walk_review_enabled(true)

    ionia = Actor.new()
    ionia.name = "Ionia"
    ionia.character_name = "Ionia"
    ionia.player_controlled = false
    ionia.collision_layer = ABOARD_ACTOR_LAYER
    ionia.collision_mask = ABOARD_ACTOR_LAYER
    ionia.walking_bounds = DECK_BOUNDS
    ionia.position = Vector2(319, 415)
    actors.add_child(ionia)
    ionia.set_ionia_stage_art_enabled(true, "east")

    var hud := CanvasLayer.new()
    hud.name = "AfloatReserveInspectionHUD"
    hud.layer = 2
    add_child(hud)
    var title_label := _label(hud, Vector2(25, 19), 20)
    title_label.text = "AUREATE WAKE / AFTER SPLASHDOWN — REVIEW ONLY"
    hint_label = _label(hud, Vector2(26, 561), 17)
    _refresh_hint()

func _label(parent: Node, at: Vector2, size: int) -> Label:
    var label := Label.new()
    label.position = at
    label.custom_minimum_size = Vector2(901, 64)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", Color("#f5e8c7"))
    label.add_theme_color_override("font_shadow_color", Color("#142535"))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 2)
    parent.add_child(label)
    return label

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 640), Color("#0f2e42"))
    draw_rect(Rect2(84, 260, 792, 289), Color("#284c58"))
    draw_rect(Rect2(135, 387, 720, 155), Color("#765945"))
    for x in range(160, 860, 42):
        draw_line(Vector2(x, 398), Vector2(x, 525), Color("#a37d58", 0.45), 2.0)
    draw_line(Vector2(120, 380), Vector2(866, 380), Color("#d9b877"), 5.0)
    draw_line(Vector2(120, 545), Vector2(866, 545), Color("#d9b877"), 5.0)
    draw_rect(Rect2(678, 369, 117, 102), Color("#162f3c"))
    draw_rect(Rect2(688, 381, 96, 75), Color("#345260"))
    draw_circle(RESERVE_POSITION + Vector2(0, -45), 14.0, Color("#d4aa73"))
    draw_arc(RESERVE_POSITION + Vector2(0, -45), 22, 0.0, TAU, 32, Color("#d9d2b1"), 3.0)
    draw_string(ThemeDB.fallback_font, Vector2(657, 350), "RESERVE STATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f5e1b9"))
    draw_rect(Rect2(0, 0, 960, 101), Color(0.04, 0.08, 0.16, 0.94))
    draw_rect(Rect2(0, 549, 960, 91), Color(0.04, 0.08, 0.16, 0.94))
    draw_string(ThemeDB.fallback_font, Vector2(28, 95), "Crew: Ender + Ionia / no shore contact / no salvage granted", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b9d5d9"))

func interact() -> bool:
    # Must move Ender to the reserve station before using the existing story
    # contract. Proximity is actual scene-space distance, not a dialogue flag.
    if opening == null or ender == null or inspection_observed:
        return false
    if opening.step_key() != "waterborne" or opening.active_party_ids != ["ender", "ionia"]:
        return false
    if ender.position.distance_to(RESERVE_POSITION) > INTERACT_RADIUS:
        _refresh_hint()
        return false
    if not opening.inspect_postflight_reserve(true):
        return false
    inspection_observed = true
    _refresh_hint()
    queue_redraw()
    return true

func _refresh_hint() -> void:
    if hint_label == null:
        return
    if inspection_observed:
        hint_label.text = "Reserve inspected: empty. No fuel formula, salvage items or shoreline encounter verified. F8: return to original v1."
    else:
        hint_label.text = "Move Ender with movement controls to RESERVE STATION; E: inspect only when nearby."

func review_snapshot() -> Dictionary:
    return {
        "station_entered": opening != null,
        "inspection_observed": inspection_observed,
        "distance_to_station": ender.position.distance_to(RESERVE_POSITION) if ender != null else -1.0,
        "physical_station_in_scene": ender != null,
        "real_inventory_scan_verified": false,
        "salvage_verified": false,
        "shoreline_scene_verified": false,
    }
