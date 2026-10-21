extends SceneTree
## Review-only numeric gait-custody test; pixel bottom != planted-foot physics.
## Uses actual Godot-imported 6x512x768 atlases, not a prose asset claim.
const MAX_INTRA_FACING_FOOT_BOTTOM_DRIFT := 4
const MAX_INTER_FACING_FOOT_BOTTOM_RANGE := 8
const FOOT_SEARCH_BOTTOM := 767
const FOOT_SEARCH_TOP := 680
const SOURCE_WIDTH := 512
const SOURCE_HEIGHT := 768

func _initialize() -> void:
    call_deferred("_verify")

func _lowest_opaque_pixel(img: Image, phase: int) -> int:
    var left := phase * SOURCE_WIDTH
    for y in range(FOOT_SEARCH_BOTTOM, FOOT_SEARCH_TOP - 1, -1):
        for x in range(left, left + SOURCE_WIDTH):
            if img.get_pixel(x, y).a > 0.2:
                return y
    return -1

func _verify() -> void:
    var sources := {
        "east": "res://art-review/ionia-east-sidebody-v4-candidate.svg",
        "west": "res://art-review/ionia-west-sidebody-v4-candidate.svg",
        "south": "res://art-review/ionia-front-sixframe-candidate.svg",
        "north": "res://art-review/ionia-north-sixframe-candidate.svg"
    }
    var all_bottoms: Array[int] = []
    for facing in ["east", "west", "south", "north"]:
        var texture: Texture2D = load(sources[facing])
        if texture == null:
            push_error("IONIA_CONTACT_FAIL: missing native imported atlas " + facing)
            quit(1)
            return
        var img: Image = texture.get_image()
        if img.is_empty() or img.get_width() != 6 * SOURCE_WIDTH or img.get_height() != SOURCE_HEIGHT:
            push_error("IONIA_CONTACT_FAIL: wrong source dimensions " + facing)
            quit(2)
            return
        var bottoms: Array[int] = []
        for frame in range(6):
            var bottom := _lowest_opaque_pixel(img, frame)
            if bottom < 700 or bottom > 745:
                push_error("IONIA_CONTACT_FAIL: blank or displaced visible lower pixel " + facing + " phase " + str(frame))
                quit(3)
                return
            bottoms.append(bottom)
            all_bottoms.append(bottom)
        var drift: int = bottoms.max() - bottoms.min()
        print("IONIA_CONTACT_OBSERVATION:%s:LOWEST_ROWS=%s:INTRA_DRIFT=%d" % [facing, str(bottoms), drift])
        if drift > MAX_INTRA_FACING_FOOT_BOTTOM_DRIFT:
            push_error("IONIA_CONTACT_FAIL: apparent foot baseline jitters within " + facing)
            quit(4)
            return
    var cross_drift: int = all_bottoms.max() - all_bottoms.min()
    print("IONIA_CONTACT_CROSS_DIRECTION_SOURCE_ROW_RANGE=" + str(cross_drift))
    if cross_drift > MAX_INTER_FACING_FOOT_BOTTOM_RANGE:
        push_error("IONIA_CONTACT_FAIL: cross-facing foot baseline mismatch")
        quit(5)
        return
    # True v4 vs v3 footwear preservation is also checked in the 4-direction test.
    print("IONIA_CONTACT_PIXEL_ENVELOPE_PASS: 24 phases, 4 independently imported views")
    print("IONIA_CONTACT_FOOT_PLANT_AND_SLIDE=NOT_ESTABLISHED")
    print("IONIA_CONTACT_HUMAN_VISUAL_ACCEPTANCE=PENDING")
    quit(0)
