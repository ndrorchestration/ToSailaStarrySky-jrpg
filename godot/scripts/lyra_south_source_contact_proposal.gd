extends RefCounted
## Original artist-side CONTACT PROPOSAL: hand-picked inside drawn Lyra south shoe
## polygons. Review candidate ONLY: no approved anatomical stance or canon.
## The existing six-pose 480x128 SVG source is never modified.
const SOURCE_ATLAS := "res://art-review/lyra-south-sixphase-v1-unapproved.svg"
const SOURCE_VIEW := "south"
const ANNOTATION_VERSION := "lyra-south-boot-source-v1-unapproved"
const SOURCE_TRANSFORM_SCALE := 0.8
const SOURCE_TRANSFORM_OFFSET := Vector2(8.0, 24.6)
const FRAME_WIDTH := 80
const FRAME_HEIGHT := 128
const BOOT_HEX := Color("#493f3d")
const FOOT_RIGHT := "proposed_anatomical_right"
const FOOT_LEFT := "proposed_anatomical_left"
const SWING := "unmarked"
# Original editable SVG x/y within each pose's inner <g> transform.
# Screen-left original boot is provisionally Lyra's anatomical right.
const RIGHT_SHOE_SVG := [
    Vector2(28, 121), Vector2(32, 121), Vector2(37, 121),
    Vector2(34, 121), Vector2(27, 121), Vector2(31, 121)
]
const LEFT_SHOE_SVG := [
    Vector2(53, 121), Vector2(50, 121), Vector2(44, 121),
    Vector2(45, 121), Vector2(52, 121), Vector2(49, 121)
]
const REVIEW_STANCE := [
    FOOT_RIGHT, FOOT_RIGHT, SWING, FOOT_LEFT, FOOT_LEFT, SWING
]

static func point(phase: int, foot: String) -> Dictionary:
    if phase < 0 or phase >= 6:
        return {"valid": false, "reason": "out_of_range"}
    if foot != FOOT_RIGHT and foot != FOOT_LEFT:
        return {"valid": false, "reason": "unknown_anatomical_candidate"}
    var shape: Vector2 = RIGHT_SHOE_SVG[phase] if foot == FOOT_RIGHT else LEFT_SHOE_SVG[phase]
    var native: Vector2 = SOURCE_TRANSFORM_OFFSET + shape * SOURCE_TRANSFORM_SCALE
    var pixel := Vector2i(roundi(native.x), roundi(native.y))
    return {
        "valid": true,
        "character": "Lyra",
        "direction": SOURCE_VIEW,
        "source_path": SOURCE_ATLAS,
        "source_svg": shape,
        "source_pixel": pixel,
        "foot_candidate": foot,
        "stance_candidate": REVIEW_STANCE[phase] == foot,
        "approval": "UNAPPROVED_SOURCE_GEOMETRY_PROPOSAL",
        "anatomy_certified": false,
        "phase_index": phase,
        "version": ANNOTATION_VERSION
    }

static func sample_source_pixel(texture: Texture2D, phase: int, foot: String) -> Dictionary:
    var spec := point(phase, foot)
    if not spec.get("valid", false) or texture == null:
        return {"valid": false, "reason": "missing_annotation_or_atlas"}
    if texture.resource_path != SOURCE_ATLAS:
        return {"valid": false, "reason": "wrong_source_atlas"}
    var image: Image = texture.get_image()
    if image.is_empty() or image.get_size() != Vector2i(480, FRAME_HEIGHT):
        return {"valid": false, "reason": "wrong_imported_atlas_dimensions"}
    var local: Vector2i = spec["source_pixel"]
    var rgb: Color = image.get_pixel(local.x + phase * FRAME_WIDTH, local.y)
    var boot_color_error: float = Vector3(rgb.r - BOOT_HEX.r, rgb.g - BOOT_HEX.g, rgb.b - BOOT_HEX.b).length()
    return {
        "valid": rgb.a >= 0.55 and boot_color_error <= 0.35,
        "alpha": rgb.a,
        "boot_color_error": boot_color_error,
        "source_pixel": local,
        "approval": "UNAPPROVED_SOURCE_GEOMETRY_PROPOSAL"
    }

static func world_point(actor: CharacterBody2D, phase: int, foot: String) -> Dictionary:
    if actor == null or String(actor.get("character_id")) != "Lyra":
        return {"valid": false, "reason": "wrong_actor"}
    var spec := point(phase, foot)
    if not spec.get("valid", false):
        return spec
    var sources: Dictionary = actor.get("source_sprites")
    var sprite: Sprite2D = sources.get(SOURCE_VIEW) as Sprite2D
    if sprite == null or sprite.texture == null or sprite.texture.resource_path != SOURCE_ATLAS:
        return {"valid": false, "reason": "source_sprite_absent"}
    var source_pixel: Vector2i = spec["source_pixel"]
    var local_in_cell := Vector2(float(source_pixel.x) - 40.0, float(source_pixel.y) - 64.0)
    var native_offset: Vector2 = sprite.position + local_in_cell * sprite.scale
    return {
        "valid": true,
        "world_pixel": actor.global_position + native_offset,
        "stance_candidate": spec["stance_candidate"],
        "approval": "UNAPPROVED_SOURCE_GEOMETRY_PROPOSAL",
        "anatomy_certified": false
    }
