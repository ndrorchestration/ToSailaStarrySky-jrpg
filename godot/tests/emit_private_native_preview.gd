extends SceneTree
## Private CI fallback: 480x320 lossy inspection images in GitHub job logs.
## Native 960x640 lossless capture/sha checks run separately and remain authoritative.
## No public upload, no third-party endpoint, no claim of artistic acceptance.

func _initialize() -> void:
    call_deferred("_emit")

func _encode_frame(label: String) -> bool:
    await RenderingServer.frame_post_draw
    var native: Image = root.get_texture().get_image()
    if native.is_empty() or native.get_width() != 960 or native.get_height() != 640:
        push_error("PRIVATE_REVIEW_FAIL: native renderer dimensions invalid")
        return false
    var preview: Image = native.duplicate()
    preview.resize(480, 320, Image.INTERPOLATE_LANCZOS)
    var encoded_bytes: PackedByteArray = preview.save_jpg_to_buffer(0.72)
    if encoded_bytes.is_empty() or encoded_bytes.size() > 180000:
        push_error("PRIVATE_REVIEW_FAIL: preview encoding empty or too large")
        return false
    var encoded: String = Marshalls.raw_to_base64(encoded_bytes)
    print("AW_PRIVATE_REVIEW_JPEG_BEGIN:" + label + ":480x320")
    for i in range(0, encoded.length(), 3500):
        print("AW_PRIVATE_REVIEW_JPEG_DATA:" + encoded.substr(i, 3500))
    print("AW_PRIVATE_REVIEW_JPEG_END:" + label)
    return true

func _emit() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    world.set_dock_depth_review_enabled(true)
    world.ionia.set_aligned_review_enabled(true)
    var ender = world.ender
    ender.set_walk_review_enabled(true)
    # Input-driven traversal places both samples near the same dock x-coordinate.
    ender.position = Vector2(350, 462)
    Input.action_press("ui_right")
    for i in range(24):
        await physics_frame
    Input.action_release("ui_right")
    if ender.walk_facing != "east" or not ender.walk_review_sprite.visible:
        push_error("PRIVATE_REVIEW_FAIL: east source missing")
        quit(2)
        return
    if not await _encode_frame("east-original"):
        quit(3)
        return
    ender.position = Vector2(470, 462)
    Input.action_press("ui_left")
    for i in range(24):
        await physics_frame
    Input.action_release("ui_left")
    if ender.walk_facing != "west" or not ender.walk_west_sprite.visible or ender.walk_west_sprite.flip_h:
        push_error("PRIVATE_REVIEW_FAIL: west source absent or mirrored")
        quit(4)
        return
    if not await _encode_frame("west-new-unmirrored"):
        quit(5)
        return
    print("AW_PRIVATE_REVIEW_PASS: two true native Godot frames summarized privately as 480x320 JPEG job-log receipts")
    print("AW_PRIVATE_REVIEW_VISUAL_ACCEPTANCE=PENDING")
    quit(0)
