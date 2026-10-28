extends SceneTree
## Renderer screenshot proof of REAL 3D physics interaction, not a final-art shot.
const Slice = preload("res://scenes/first_wake_3d_visual_slice.tscn")
var target_directory := ""
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _capture(name: String) -> void:
    for i in range(3):
        await process_frame
        await RenderingServer.frame_post_draw
    var image: Image = root.get_viewport().get_texture().get_image()
    if image == null or image.get_size() != Vector2i(960, 640):
        errors.append("native framebuffer unavailable: " + name)
        return
    var dest: String = target_directory.path_join("first_wake_3d_navigation_" + name + ".png")
    if image.save_png(dest) != OK:
        errors.append("could not save native framebuffer: " + name)
        return
    print("TSTSS_NAVIGATION_3D_FRAME:", name,
        ":SHA256:", FileAccess.get_sha256(dest), ":FILE:", dest)

func _run() -> void:
    target_directory = ProjectSettings.globalize_path("user://first_wake_3d_navigation_evidence")
    if DirAccess.make_dir_recursive_absolute(target_directory) != OK:
        push_error("TSTSS_NAVIGATION_3D_RENDER_FAIL:cannot create evidence folder")
        quit(1)
        return
    var scene = Slice.instantiate()
    root.add_child(scene)
    for i in range(15):
        await physics_frame
    if scene.navigation_body == null or not scene.navigation_body.is_on_floor():
        errors.append("physics body does not contact real pier")
    scene.camera_follow_navigation = true
    scene._update_camera()
    await _capture("physically_grounded_spawn_960x640")
    Input.action_press("tstss_3d_forward")
    for i in range(174):
        await physics_frame
    Input.action_release("tstss_3d_forward")
    for i in range(4):
        await physics_frame
    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_E
    scene._unhandled_input(key)
    if scene.interaction_receipts.is_empty() or scene.interaction_receipts.back() != "NoticeBoard_ReviewOnly":
        errors.append("physical notice interaction did not occur before native frame")
    scene._update_camera()
    await _capture("notice_real_area3d_960x640")
    Input.action_press("tstss_3d_forward")
    for i in range(93):
        await physics_frame
    Input.action_release("tstss_3d_forward")
    for i in range(3):
        await physics_frame
    scene._unhandled_input(key)
    if scene.interaction_receipts.size() != 2 or scene.interaction_receipts.back() != "IoniaArrival_ReviewOnly":
        errors.append("physical Ionia reference interaction failed")
    scene._update_camera()
    await _capture("ionia_spatial_probe_960x640")
    scene.queue_free()
    await process_frame
    for message in errors:
        push_error("TSTSS_NAVIGATION_3D_RENDER_FAIL:" + message)
    if errors.is_empty():
        print("TSTSS_NAVIGATION_3D_RENDER_PASS:real_physics=true actual_area3d=true native_960x640=true frames=3 story_migration=false rigged_hero_missing=true")
        print("TSTSS_NAVIGATION_3D_RENDER_DIR:", target_directory)
    quit(0 if errors.is_empty() else 1)
