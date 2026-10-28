extends RefCounted
## Public-safe numeric admission check for a bridge access *proposal*.
## Contradictions are reported, not waved away with art-only meshes.
const Bridge = preload("res://ship_geodesic_bridge.gd")
const Bow = preload("res://ship_foredeck.gd")
const Boarding = preload("res://ship_boarding_interface.gd")
const BRIDGE_SHIP_Z: float = -0.50
const CANDIDATE_CABIN_WIDTH_M: float = 2.35
const REVIEW_HEADROOM_M: float = 2.05
const MAX_DECK_SEAM_GAP_M: float = 0.20

static func assess() -> Dictionary:
    var scale_factor: float = Boarding.ART_TO_METRES
    var dome_diameter_m: float = 2.0 * Bridge.RADIUS * scale_factor
    var cabin_width_m: float = CANDIDATE_CABIN_WIDTH_M
    # Only at the dome *summit*, not proof of usable standing room throughout.
    var peak_height_above_deck_m: float = (
        Bridge.CENTER_Y + Bridge.RADIUS - Bow.PLATFORM_Y) * scale_factor
    var bow_meeting_gap_m: float = absf(
        (BRIDGE_SHIP_Z - Bridge.RADIUS) - Bow.PLATFORM_BACK_Z) * scale_factor
    var width_fits: bool = dome_diameter_m <= cabin_width_m
    var standing_compatible: bool = peak_height_above_deck_m >= REVIEW_HEADROOM_M
    var seam_near: bool = bow_meeting_gap_m <= MAX_DECK_SEAM_GAP_M
    return {
        "dome_diameter_m": dome_diameter_m,
        "candidate_cabin_width_m": cabin_width_m,
        "cabin_overhang_m": maxf(dome_diameter_m - cabin_width_m, 0.0),
        "summit_height_over_deck_m": peak_height_above_deck_m,
        "minimum_review_height_m": REVIEW_HEADROOM_M,
        "roof_shortfall_m": maxf(REVIEW_HEADROOM_M - peak_height_above_deck_m, 0.0),
        "bow_meeting_gap_m": bow_meeting_gap_m,
        "near_bow": seam_near,
        "fits_width": width_fits,
        "supports_standing": standing_compatible,
        "ready_for_physical_integration": (
            seam_near and width_fits and standing_compatible),
        "status": "PROPOSAL_BLOCKED_ON_HULL_SCALE_AND_EGRESS"
    }
