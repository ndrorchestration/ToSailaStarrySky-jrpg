extends RefCounted
## A FAIL-CLOSED admission gate for locally authored, private First Wake motion assets.
##
## Source is 4 named directions x 6 transparent PNG frames *per character*.
## A manifest and individually-hashed images are required. This gate only proves
## structural authenticity and image variety, NOT artistic quality or approval.
## No missing direction is synthesized, mirrored or inferred from a still portrait.
const DIRECTIONS: Array[String] = ["south", "north", "east", "west"]
const FRAME_COUNT := 6
const FRAME_SIZE := Vector2i(96, 144)
const FRAME_SCALE := 0.78
const MIN_CHANGED_SAMPLES := 20
const SAMPLE_STRIDE := 3

var loaded: bool = false
var error_message: String = ""
var character_id: String = ""
var source_reference: String = ""
var textures: Dictionary = {}
var source_root: String = ""

func _reject(reason: String) -> bool:
    loaded = false
    error_message = reason
    textures.clear()
    return false

func _asset_path(root: String, direction: String, index: int) -> String:
    return root.path_join(direction).path_join("%02d.png" % index)

func _color_distance(a: Color, b: Color) -> float:
    return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)

func _difference_count(first: Image, second: Image) -> int:
    var changed := 0
    for y in range(1, FRAME_SIZE.y - 1, SAMPLE_STRIDE):
        for x in range(1, FRAME_SIZE.x - 1, SAMPLE_STRIDE):
            if _color_distance(first.get_pixel(x, y), second.get_pixel(x, y)) > 0.12:
                changed += 1
    return changed

func _validate_image(img: Image, label: String) -> bool:
    if img.get_size() != FRAME_SIZE:
        return _reject(label + " must have native RGBA 96x144 dimensions")
    if img.get_format() != Image.FORMAT_RGBA8:
        return _reject(label + " must be RGBA8 with actual transparency")
    var opaque := 0
    var transparent := 0
    var foot_pixels := 0
    for y in range(FRAME_SIZE.y):
        for x in range(FRAME_SIZE.x):
            var alpha: float = img.get_pixel(x, y).a
            if alpha > 0.5:
                opaque += 1
            if alpha < 0.02:
                transparent += 1
            if y >= FRAME_SIZE.y - 8 and alpha > 0.8 and x >= 18 and x <= 78:
                foot_pixels += 1
    var total: int = FRAME_SIZE.x * FRAME_SIZE.y
    if opaque < int(float(total) * 0.08) or opaque > int(float(total) * 0.74):
        return _reject(label + " alpha occupancy is not a plausible isolated full-body frame")
    if transparent < int(float(total) * 0.20):
        return _reject(label + " has no meaningful transparent background")
    if foot_pixels < 4:
        return _reject(label + " fails authored boot-contact guide")
    return true

func load_from_directory(root: String, expected_character: String) -> bool:
    loaded = false
    error_message = ""
    character_id = ""
    source_reference = ""
    source_root = ""
    textures.clear()
    if expected_character not in ["ender", "ionia"]:
        return _reject("only the two source-reviewed opening protagonists are admitted")
    if root.is_empty() or not (root.begins_with("res://") or root.begins_with("user://")):
        return _reject("source root must be local res:// or user://")
    var manifest_path := root.path_join("manifest.json")
    if not FileAccess.file_exists(manifest_path):
        return _reject("missing original creator motion manifest")
    var content := FileAccess.get_file_as_string(manifest_path)
    var json := JSON.new()
    if json.parse(content) != OK or not (json.data is Dictionary):
        return _reject("invalid motion manifest JSON")
    var manifest: Dictionary = json.data
    if manifest.get("schema_version") != 1:
        return _reject("unsupported motion contract schema")
    if manifest.get("character") != expected_character:
        return _reject("motion manifest belongs to the wrong protagonist")
    if manifest.get("intent") != "review_only":
        return _reject("motion art must remain a private review-only candidate")
    var original: String = str(manifest.get("source_reference", ""))
    if original.length() < 12:
        return _reject("source character-art reference must be recorded")
    if not (manifest.get("directions") is Dictionary):
        return _reject("missing independent four-direction hash manifest")
    var maps: Dictionary = manifest["directions"]
    if maps.size() != 4:
        return _reject("motion manifest must contain four directions exactly")
    var all_hashes: Dictionary = {}
    var prepared: Dictionary = {}
    var last_first_frames: Dictionary = {}
    for facing in DIRECTIONS:
        if not maps.has(facing):
            return _reject("missing authored " + facing + " direction")
        var hashes = maps[facing]
        if not (hashes is Array) or hashes.size() != FRAME_COUNT:
            return _reject(facing + " needs six distinct authored frame hashes")
        var frames: Array[Texture2D] = []
        var previous: Image = null
        for index in range(FRAME_COUNT):
            var digest: String = str(hashes[index]).to_lower()
            if digest.length() != 64 or not digest.is_valid_hex_number():
                return _reject(facing + " frame has an invalid SHA-256 digest")
            if all_hashes.has(digest):
                return _reject("identical image reused across different frames or directions")
            var file_path := _asset_path(root, facing, index)
            if not FileAccess.file_exists(file_path):
                return _reject("authoring asset missing " + file_path)
            if FileAccess.get_sha256(file_path).to_lower() != digest:
                return _reject("source image hash mismatch " + file_path)
            var img := Image.new()
            if img.load(file_path) != OK or not _validate_image(img, facing + "/" + str(index)):
                return _reject(error_message if not error_message.is_empty() else "image import failed")
            if previous != null and _difference_count(previous, img) < MIN_CHANGED_SAMPLES:
                return _reject(facing + " successive poses are near-identical; not an authored gait")
            if index == 0:
                for prev_face in last_first_frames:
                    if _difference_count(last_first_frames[prev_face], img) < MIN_CHANGED_SAMPLES:
                        return _reject(facing + " is not visually distinct from " + str(prev_face))
                last_first_frames[facing] = img.duplicate()
            all_hashes[digest] = true
            frames.append(ImageTexture.create_from_image(img))
            previous = img
        prepared[facing] = frames
    if all_hashes.size() != DIRECTIONS.size() * FRAME_COUNT:
        return _reject("incomplete 24-frame source set")
    textures = prepared
    loaded = true
    character_id = expected_character
    source_reference = original
    source_root = root
    return true

func get_frame(direction: String, index: int) -> Texture2D:
    if not loaded or direction not in DIRECTIONS or index < 0 or index >= FRAME_COUNT:
        return null
    var candidates: Array = textures[direction]
    return candidates[index]

func frame_count() -> int:
    return DIRECTIONS.size() * FRAME_COUNT if loaded else 0

func snapshot() -> Dictionary:
    return {
        "ready": loaded,
        "character": character_id,
        "frames_loaded": frame_count(),
        "directions": DIRECTIONS.size() if loaded else 0,
        "review_only": true,
        "approved_for_production": false,
        "source_ref": source_reference,
        "last_error": error_message
    }
