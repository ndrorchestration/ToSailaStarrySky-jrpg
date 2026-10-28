extends Node2D
## Public-safe scene-admission schematic for the real Ionia-first engineering preview.
## Strictly read-only: NO 3D asset import, navigation, mode switch, story grant,
## playable bridge doorway, party powers, save change or hidden ship specs.
const SHIP_ART_SOURCE_HEAD := "8f7112d0f8ed3afcad8faa76b5d0b224d25cdce9"
const SHIP_ART_SOURCE_PR: int = 482
const SOURCE_ENGINE := "Godot 4.7.2 / separate flight-slice branch"
const ADMISSION_STATUS := "BLOCKED_ON_HULL_SCALE_AND_EGRESS"
const DOME_DIAMETER_STUDY_M: float = 3.80
const CABIN_WIDTH_STUDY_M: float = 2.35
const DOME_PEAK_ABOVE_DECK_STUDY_M: float = 1.825
const MIN_STANDING_REVIEW_M: float = 2.05
const WATER_SEAL_VERIFIED: bool = false
const TRAVERSABLE_BRIDGE_VERIFIED: bool = false

func source_contract() -> Dictionary:
    return {
        "source_pr": SHIP_ART_SOURCE_PR,
        "source_head": SHIP_ART_SOURCE_HEAD,
        "source_engine": SOURCE_ENGINE,
        "review_only": true,
        "ship_part_ids": ["open_foredeck", "geodesic_helm", "crew_entry", "engineering"],
        "dome_diameter_study_m": DOME_DIAMETER_STUDY_M,
        "cabin_width_study_m": CABIN_WIDTH_STUDY_M,
        "roof_shortfall_study_m": MIN_STANDING_REVIEW_M - DOME_PEAK_ABOVE_DECK_STUDY_M,
        "can_traverse": TRAVERSABLE_BRIDGE_VERIFIED,
        "water_seal_verified": WATER_SEAL_VERIFIED,
        "admission": ADMISSION_STATUS
    }

func request_review(enabled: bool, room: String,
        story_stage: String, party_ids: Array[String]) -> bool:
    # Callers cannot stage-review the ship during Ender's job search, or imply
    # Lyra is already aboard in the opening. No latent opt-in is stored.
    var eligible: bool = room == "engineering" and (
        story_stage == "engineering" or story_stage == "preflight") and (
        party_ids == ["ender", "ionia"])
    visible = enabled and eligible
    queue_redraw()
    return visible

func _ready() -> void:
    name = "ShipSpacesHandoffReviewOnly"
    visible = false
    z_index = 2

func _draw() -> void:
    if not visible:
        return
    # Diagrammatic 2D "ship-space intake" plate, not a rendered 3D asset.
    # Intentionally above the machine props / walk bounds; no collision.
    var frame := Rect2(592.0, 37.0, 343.0, 158.0)
    draw_rect(frame, Color(0.075, 0.13, 0.18, 0.94))
    draw_rect(frame, Color(0.72, 0.55, 0.35, 0.70), false, 2.0)
    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(604.0, 56.0),
        "SHIP SPACE STUDY / NONPLAYABLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
        Color(0.95, 0.84, 0.65))

    # Left-to-right: exposed prow, enclosed helm, modest aft work area.
    var bow: PackedVector2Array = PackedVector2Array([
        Vector2(616, 122), Vector2(645, 110), Vector2(670, 112),
        Vector2(670, 148), Vector2(645, 151)])
    draw_colored_polygon(bow, Color(0.29, 0.40, 0.37))
    for side_y in [111.0, 147.0]:
        draw_line(Vector2(645, side_y), Vector2(671, side_y),
            Color(0.75, 0.55, 0.32), 2.0)
    # Glass-helm cap: flattened circle, with original triangle language.
    var center := Vector2(730.0, 126.0)
    draw_circle(center, 34.0, Color(0.15, 0.38, 0.44, 0.69))
    draw_arc(center, 34.0, 0.0, TAU, 18,
        Color(0.79, 0.62, 0.40), 2.0, true)
    for point in [Vector2(730, 92), Vector2(697, 119),
            Vector2(714, 153), Vector2(748, 151), Vector2(763, 118)]:
        draw_line(point, center, Color(0.69, 0.75, 0.70, 0.61), 1.1)
    draw_line(Vector2(670, 110), Vector2(670, 147),
        Color(0.92, 0.71, 0.41), 2.0)
    draw_rect(Rect2(765, 104, 137, 46), Color(0.34, 0.28, 0.24))
    draw_rect(Rect2(765, 104, 137, 46), Color(0.67, 0.55, 0.40), false, 1.5)
    draw_string(font, Vector2(610.0, 80.0),
        "FOREDECK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
        Color(0.85, 0.89, 0.84))
    draw_string(font, Vector2(694.0, 173.0),
        "GLASS HELM", HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
        Color(0.76, 0.90, 0.94))
    draw_string(font, Vector2(785.0, 132.0),
        "CREW / ENGINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
        Color(0.93, 0.84, 0.73))
    draw_string(font, Vector2(604.0, 189.0),
        "ACCESS: SCALE REVIEW BLOCKED", HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
        Color(0.98, 0.70, 0.52))
