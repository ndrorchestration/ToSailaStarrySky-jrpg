extends SceneTree
## Read authentic prior 960x640 Godot render PNGs from this runner, crop native pixels,
## and encode lossless PNG crops into private Actions logs with SHA-256 per crop.
## Also logs exact original full-frame PNG bytes; commits to private Git objects are separate.
## Does NOT imply creator acceptance or public publication.

const OUTPUT := "res://review-evidence/"
const MAX_CROP_BYTES := 95000
const MAX_FULL_BYTES := 350000
const SAMPLES := [
    {"label": "ender-east", "source": "ender-east-original-source-native-960x640.png", "roi": [285, 319, 225, 228]},
    {"label": "ender-west", "source": "ender-west-centered-staff-native-960x640.png", "roi": [285, 319, 225, 228]},
    {"label": "ender-front", "source": "ender-south-actual-native-960x640.png", "roi": [285, 319, 225, 228]},
    {"label": "ender-back", "source": "ender-north-actual-native-960x640.png", "roi": [285, 319, 225, 228]},
    {"label": "ionia-front", "source": "ionia-south-route-native-960x640.png", "roi": [490, 310, 180, 235]},
    {"label": "ionia-back", "source": "ionia-north-route-native-960x640.png", "roi": [385, 310, 180, 235]},
]

const JOINT_SCENE_SAMPLES := [
    {"label": "joint-fixed-baseline", "source": "joint-fixed-baseline-native-960x640.png"},
    {"label": "joint-fixed-east", "source": "joint-fixed-east-native-960x640.png"},
    {"label": "joint-fixed-west", "source": "joint-fixed-west-native-960x640.png"},
    {"label": "joint-fixed-south", "source": "joint-fixed-south-native-960x640.png"},
    {"label": "joint-fixed-north", "source": "joint-fixed-north-native-960x640.png"},
]

func _initialize() -> void:
    call_deferred("_emit")

func _emit() -> void:
    for sample in SAMPLES:
        if not _emit_one(sample):
            quit(1)
            return
        if not _emit_full_sample(sample):
            quit(2)
            return
    for sample in JOINT_SCENE_SAMPLES:
        if not _emit_full_sample(sample):
            quit(3)
            return
    # These eight files are genuine animated-route renders, not fixed-anchor poses.
    # Transfer exact PNG bytes privately; source must be reviewed/archived separately.
    for direction in ["south", "west", "north", "east"]:
        for phase in [1, 4]:
            var moving_sample := {"label": "ionia-moving-" + direction + "-phase-" + str(phase),
                "source": "ionia-moving-" + direction + "-phase-" + str(phase) + "-native-960x640.png"}
            if not _emit_full_sample(moving_sample):
                quit(4)
                return
    print("MOVING_GAIT_NATIVE_BYTES_EMITTED=EIGHT_FULL_960x640_PENDING_PRIVATE_CUSTODY")
    print("JOINT_FOURWAY_NATIVE_BYTES_EMITTED=FIVE_FULL_960x640_PENDING_PRIVATE_CUSTODY")
    print("AW_NATIVE_CROP_EMIT_PASS: six lossless 1x crops AND six original byte-identical 960x640 renderer PNGs")
    print("AW_NATIVE_FULL_SCREEN_CUSTODY=LOG_TRANSPORT_ONLY_UNTIL_PRIVATE_GIT_RECEIPT")
    print("AW_NATIVE_VISUAL_ACCEPTANCE=PENDING")
    quit(0)

func _emit_one(sample: Dictionary) -> bool:
    var source: String = OUTPUT + sample["source"]
    var label: String = sample["label"]
    if not FileAccess.file_exists(source):
        push_error("CROP_EMIT_FAIL: source native PNG missing: " + label)
        return false
    var original := Image.new()
    if original.load(source) != OK:
        push_error("CROP_EMIT_FAIL: cannot load authentic source: " + label)
        return false
    if original.get_width() != 960 or original.get_height() != 640:
        push_error("CROP_EMIT_FAIL: source is not the expected native 960x640: " + label)
        return false
    var r: Array = sample["roi"]
    var region := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
    if region.position.x < 0 or region.position.y < 0 or region.end.x > 960 or region.end.y > 640:
        push_error("CROP_EMIT_FAIL: ROI is outside native frame: " + label)
        return false
    var crop: Image = original.get_region(region)
    # An SHA-valid screenshot crop may still miss the moving subject.
    # In this fixed pilot, Ionia walks north along x470, not her x570 start.
    # The reference depth-mode baseline has no moving Ionia at x470.
    if label == "ionia-back":
        var baseline := Image.new()
        if baseline.load(OUTPUT + "dock-depth-review-native-960x640.png") != OK:
            push_error("CROP_EMIT_FAIL: no native background/control capture for rear-view presence")
            return false
        if baseline.get_width() != 960 or baseline.get_height() != 640:
            push_error("CROP_EMIT_FAIL: invalid background/control capture dimensions")
            return false
        if crop.get_data() == baseline.get_region(region).get_data():
            push_error("CROP_EMIT_FAIL: Ionia rear ROI is background only")
            return false
    var png: PackedByteArray = crop.save_png_to_buffer()
    if png.is_empty() or png.size() > MAX_CROP_BYTES:
        push_error("CROP_EMIT_FAIL: crop missing/too large: " + label)
        return false
    var ctx := HashingContext.new()
    if ctx.start(HashingContext.HASH_SHA256) != OK:
        push_error("CROP_EMIT_FAIL: SHA256 initialization error")
        return false
    ctx.update(png)
    var crop_sha: String = ctx.finish().hex_encode()
    var full_sha: String = FileAccess.get_sha256(source)
    if full_sha.length() != 64:
        push_error("CROP_EMIT_FAIL: cannot hash source full native PNG: " + label)
        return false
    var encoded: String = Marshalls.raw_to_base64(png)
    print("AW_NATIVE_CROP_BEGIN:" + label + ":" + str(crop.get_width()) + "x" + str(crop.get_height()) + ":" + crop_sha + ":" + full_sha + ":" + str(png.size()))
    var offset := 0
    var ordinal := 0
    while offset < encoded.length():
        print("AW_NATIVE_CROP_DATA:" + label + ":" + str(ordinal) + ":" + encoded.substr(offset, 3000))
        offset += 3000
        ordinal += 1
    print("AW_NATIVE_CROP_END:" + label)
    return true

func _emit_full_sample(sample: Dictionary) -> bool:
    # Preserve exact original PNG BYTES, not a resized/re-encoded pixel copy.
    var source: String = OUTPUT + sample["source"]
    var label: String = str(sample["label"]) + "-full"
    if not FileAccess.file_exists(source):
        push_error("FULL_NATIVE_EMIT_FAIL: missing source " + label)
        return false
    var original := Image.new()
    if original.load(source) != OK or original.get_width() != 960 or original.get_height() != 640:
        push_error("FULL_NATIVE_EMIT_FAIL: not original native 960x640: " + label)
        return false
    var png: PackedByteArray = FileAccess.get_file_as_bytes(source)
    if png.is_empty() or png.size() > MAX_FULL_BYTES:
        push_error("FULL_NATIVE_EMIT_FAIL: source bytes missing or above bounded size: " + label)
        return false
    var ctx := HashingContext.new()
    if ctx.start(HashingContext.HASH_SHA256) != OK:
        push_error("FULL_NATIVE_EMIT_FAIL: SHA256 initialization")
        return false
    ctx.update(png)
    var exact_sha: String = ctx.finish().hex_encode()
    var source_sha: String = FileAccess.get_sha256(source)
    if source_sha.length() != 64 or exact_sha != source_sha:
        push_error("FULL_NATIVE_EMIT_FAIL: original source-byte hash mismatch: " + label)
        return false
    var encoded: String = Marshalls.raw_to_base64(png)
    print("AW_NATIVE_CROP_BEGIN:" + label + ":960x640:" + exact_sha + ":" + source_sha + ":" + str(png.size()))
    var offset := 0
    var ordinal := 0
    while offset < encoded.length():
        print("AW_NATIVE_CROP_DATA:" + label + ":" + str(ordinal) + ":" + encoded.substr(offset, 3000))
        offset += 3000
        ordinal += 1
    print("AW_NATIVE_CROP_END:" + label)
    return true
