extends SceneTree
## Quota-independent, public-safe Wind Shear review images from actual prior
## Godot 960x640 framebuffer PNGs. Logs *bounded* small JPEG previews and
## lossless stage PNGs, tagged with the exact source PNG SHA-256.
##
## No game state, story state, screenshots or art assets are modified. Review
## bytes are readable in this repository's Actions job log: do not expand this
## to confidential or unrevealed scenes without a new disclosure review.

const SOURCE_DIR := "res://review-evidence/wind-shear/"
const SCENES := [
    {"name": "idle", "file": "wind-shear-idle-native-960x640.png"},
    {"name": "analyzed", "file": "wind-shear-analyzed-native-960x640.png"},
    {"name": "hit", "file": "wind-shear-hit-native-960x640.png"},
    {"name": "gale", "file": "wind-shear-gale-native-960x640.png"},
]
const CAPTURE_SIZE := Vector2i(960, 640)
const STAGE_RECT := Rect2i(588, 185, 196, 192)
const PREVIEW_SIZE := Vector2i(480, 320)
const MAX_JPEG_BYTES := 90000
const MAX_STAGE_PNG_BYTES := 60000
const CHUNK_SIZE := 3200

func _initialize() -> void:
    call_deferred("_emit")

func _emit_bytes(name: String, codec: String, frame_size: Vector2i,
        original_sha: String, payload: PackedByteArray, byte_limit: int) -> bool:
    if payload.is_empty() or payload.size() > byte_limit:
        push_error("WIND_SHEAR_REVIEW_EMIT_FAIL: encoded preview invalid/oversized: " + name)
        return false
    var encoder := HashingContext.new()
    if encoder.start(HashingContext.HASH_SHA256) != OK:
        push_error("WIND_SHEAR_REVIEW_EMIT_FAIL: cannot hash encoded preview")
        return false
    encoder.update(payload)
    var preview_sha := encoder.finish().hex_encode()
    var encoded := Marshalls.raw_to_base64(payload)
    print("WIND_SHEAR_REVIEW_BEGIN:" + name + ":" + codec + ":" +
        str(frame_size.x) + "x" + str(frame_size.y) + ":" +
        original_sha + ":" + preview_sha + ":" + str(payload.size()))
    var ordinal := 0
    for offset in range(0, encoded.length(), CHUNK_SIZE):
        print("WIND_SHEAR_REVIEW_DATA:" + name + ":" + str(ordinal) + ":" +
            encoded.substr(offset, CHUNK_SIZE))
        ordinal += 1
    print("WIND_SHEAR_REVIEW_END:" + name)
    return true

func _emit() -> void:
    for item in SCENES:
        var label: String = item["name"]
        var path: String = SOURCE_DIR + item["file"]
        if not FileAccess.file_exists(path):
            push_error("WIND_SHEAR_REVIEW_EMIT_FAIL: authentic capture missing " + label)
            quit(1)
            return
        var frame := Image.new()
        if frame.load(path) != OK or frame.get_size() != CAPTURE_SIZE:
            push_error("WIND_SHEAR_REVIEW_EMIT_FAIL: invalid native capture " + label)
            quit(2)
            return
        var source_sha := FileAccess.get_sha256(path)
        if source_sha.length() != 64:
            push_error("WIND_SHEAR_REVIEW_EMIT_FAIL: invalid source hash " + label)
            quit(3)
            return
        # Whole 960x640 scene, downsampled for assessing layout/legibility.
        var inspection := frame.duplicate()
        inspection.resize(PREVIEW_SIZE.x, PREVIEW_SIZE.y, Image.INTERPOLATE_LANCZOS)
        if not _emit_bytes(label + "-scene", "jpg", PREVIEW_SIZE, source_sha,
                inspection.save_jpg_to_buffer(0.79), MAX_JPEG_BYTES):
            quit(4)
            return
        # A genuine native-pixel stage crop, not resized or reconstructed art.
        var crop: Image = frame.get_region(STAGE_RECT)
        if not _emit_bytes(label + "-stage", "png", STAGE_RECT.size, source_sha,
                crop.save_png_to_buffer(), MAX_STAGE_PNG_BYTES):
            quit(5)
            return
    print("WIND_SHEAR_REVIEW_EMIT_PASS: four authentic scene JPEGs and four native-pixel stage PNGs; creator art acceptance pending")
    print("WIND_SHEAR_REVIEW_PUBLIC_SAFE_ONLY=true")
    quit(0)
