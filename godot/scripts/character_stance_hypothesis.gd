extends RefCounted
## REVIEW HYPOTHESES, NOT ANATOMICALLY ANNOTATED STANCE TRUTH.
## "screen_left/right" are the sprite image halves, never left/right anatomical feet.
## Each of the 72 phase labels is an explicit revisable annotation proposal.
const FACINGS: Array[String] = ["south", "west", "north", "east"]
const CHARACTERS: Array[String] = ["Lyra", "Aepex", "Reson"]
const UNKNOWN := "unmarked"
const SCREEN_LEFT := "screen_left"
const SCREEN_RIGHT := "screen_right"
const SCHEMA_VERSION := "source-stances-hypothesis-v1"
const PROPOSALS := {
    "Lyra": {
        "south": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"],
        "west": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"],
        "north": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"],
        "east": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"]
    },
    "Aepex": {
        "south": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"],
        "west": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"],
        "north": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"],
        "east": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"]
    },
    "Reson": {
        "south": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"],
        "west": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"],
        "north": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"],
        "east": ["screen_left", "screen_left", "unmarked", "screen_right", "screen_right", "unmarked"]
    }
}

static func annotation(character_id: String, facing: String, phase: int) -> Dictionary:
    if not PROPOSALS.has(character_id) or not FACINGS.has(facing) or phase < 0 or phase >= 6:
        return {"valid": false, "reason": "invalid_identity_facing_or_phase"}
    var rows: Array = PROPOSALS[character_id][facing]
    if rows.size() != 6:
        return {"valid": false, "reason": "wrong_schema_frame_count"}
    var side: String = rows[phase]
    if not [UNKNOWN, SCREEN_LEFT, SCREEN_RIGHT].has(side):
        return {"valid": false, "reason": "invalid_screen_side"}
    return {
        "valid": true,
        "candidate_screen_side": side,
        "review_status": "UNAPPROVED_HYPOTHESIS",
        "anatomical_foot_identified": false,
        "stance_certified": false,
        "schema": SCHEMA_VERSION
    }

static func world_support(actor: CharacterBody2D, facing: String, phase: int, side: String) -> Dictionary:
    if actor == null or not FACINGS.has(facing) or phase < 0 or phase >= 6:
        return {"valid": false, "reason": "invalid_actor_or_facing"}
    var key: String = "left" if side == SCREEN_LEFT else "right" if side == SCREEN_RIGHT else ""
    if key.is_empty():
        return {"valid": false, "reason": "unmarked_or_invalid_side"}
    var sample: Dictionary = actor.call("get_source_boot_sample", facing, phase)
    if not sample.get("valid", false):
        return {"valid": false, "reason": "no_source_alpha_sample"}
    var support: Dictionary = sample[key]
    if not support.get("present", false):
        return {"valid": false, "reason": "candidate_pixel_missing"}
    var sprite: Sprite2D = actor.get("source_sprites").get(facing) as Sprite2D
    if sprite == null:
        return {"valid": false, "reason": "source_sprite_missing"}
    var pixel_pos: Vector2 = actor.global_position + sprite.position + Vector2(
        float(support["x"]) - 40.0, float(support["y"]) - 64.0)
    return {"valid": true, "world_pixel": pixel_pos,
        "review_status": "SCREEN_HALF_ALPHA_PIXEL_NOT_FOOT_PLANT"}
