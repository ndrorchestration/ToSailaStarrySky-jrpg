extends SceneTree
## Original full-size Godot capture plus size-bounded review thumbnail.
## The JPEG in the job log is a low-resolution inspection aid, NOT native art evidence.

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    world.set_character_lineup_review_enabled(true)
    await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image.is_empty() or image.get_width() != 960 or image.get_height() != 640:
        push_error("CHARACTER_LINEUP_CAPTURE_FAIL: Godot native image missing or incorrect resolution")
        quit(1)
        return
    var output_dir := "res://review-evidence/"
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir)) != OK:
        push_error("CHARACTER_LINEUP_CAPTURE_FAIL: unable to create review directory")
        quit(2)
        return
    var path := output_dir + "five-lights-lineup-native-960x640.png"
    if image.save_png(path) != OK:
        push_error("CHARACTER_LINEUP_CAPTURE_FAIL: unable to store full native screenshot")
        quit(3)
        return
    print("CHARACTER_LINEUP_NATIVE_PNG:sha256=" + FileAccess.get_sha256(path))
    var thumbnail: Image = image.duplicate()
    thumbnail.resize(480, 320, Image.INTERPOLATE_LANCZOS)
    var jpeg: PackedByteArray = thumbnail.save_jpg_to_buffer(0.59)
    if jpeg.is_empty() or jpeg.size() > 85000:
        push_error("CHARACTER_LINEUP_CAPTURE_FAIL: thumbnail empty or over disclosure bound")
        quit(4)
        return
    # This output is only a log-delivered thumbnail to inspect composition.
    print("CHARACTER_LINEUP_PREVIEW_480x320_JPEG_BASE64:" + Marshalls.raw_to_base64(jpeg))
    # Second genuine native frame at 1x authored source scale, so artists can
    # judge readability without mistaking the magnified board for gameplay size.
    world.character_lineup_review.call("set_magnified", false)
    await process_frame
    await RenderingServer.frame_post_draw
    var true_size: Image = root.get_texture().get_image()
    if true_size.is_empty() or true_size.get_width() != 960 or true_size.get_height() != 640:
        push_error("CHARACTER_LINEUP_CAPTURE_FAIL: native-scale second frame missing")
        quit(5)
        return
    var native_size_path := output_dir + "five-lights-source-size-native-960x640.png"
    if true_size.save_png(native_size_path) != OK:
        push_error("CHARACTER_LINEUP_CAPTURE_FAIL: cannot save source-scale native frame")
        quit(6)
        return
    print("CHARACTER_LINEUP_SOURCE_SIZE_NATIVE_PNG:sha256=" + FileAccess.get_sha256(native_size_path))
    var source_thumb: Image = true_size.duplicate()
    source_thumb.resize(480, 320, Image.INTERPOLATE_LANCZOS)
    var source_jpeg: PackedByteArray = source_thumb.save_jpg_to_buffer(0.59)
    if source_jpeg.is_empty() or source_jpeg.size() > 85000:
        push_error("CHARACTER_LINEUP_CAPTURE_FAIL: native-size JPEG exceeds inspection bounds")
        quit(7)
        return
    print("CHARACTER_LINEUP_SOURCE_SIZE_480x320_JPEG_BASE64:" + Marshalls.raw_to_base64(source_jpeg))
    print("CHARACTER_LINEUP_NATIVE_CAPTURE_PASS: two actual Godot screenshots runner-local; both review thumbnails in logs; no art admission")
    quit(0)
