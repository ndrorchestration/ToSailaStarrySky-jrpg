extends SceneTree
## Actual native framebuffer evidence; frozen matched poses, no visual acceptance claim.
const StudyScene = preload("res://main.tscn")
const CUTS: Array = [["coast", 9.0], ["forest", 23.0], ["highland", 34.0]]
var failed: bool = false
func _initialize() -> void:
    call_deferred("_capture")
func _frame() -> Image:
    for warmup in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()
func _save(frame: Image, path: String) -> void:
    if frame == null or frame.get_size() != Vector2i(960,640) or frame.save_png(path) != OK:
        push_error("CAPTURE_FAILED: " + path)
        failed = true
    else:
        print("NATIVE_ART_CAPTURE:", path, " 960x640")
func _different(a: Image, b: Image) -> int:
    var count: int = 0
    for y in range(110,640,2):
        for x in range(0,960,2):
            if a.get_pixel(x,y) != b.get_pixel(x,y): count += 1
    return count
func _capture() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var baseline: bool = OS.get_cmdline_user_args().has("--baseline")
    var folder: String = ProjectSettings.globalize_path("res://evidence/" + ("baseline" if baseline else "materials"))
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("CAPTURE_FOLDER_FAILED")
        quit(1)
        return
    for cut in CUTS:
        scene._clock = float(cut[1])
        scene._update_scene(10.0)
        scene.overlay.text = "TO SAIL THE STARRY SKY  /  VISUAL LAB\n" + str(cut[0]).to_upper() + "  •  NATIVE GODOT 4.7.2\nCOAST-TO-HIGHLAND ART STUDY  •  NON-CANON"
        var screenshot: Image = await _frame()
        _save(screenshot,folder.path_join(str(cut[0])+".png"))
    if not baseline:
        scene._clock = 9.0
        scene._update_scene(10.0)
        scene.overlay.text = "TO SAIL THE STARRY SKY  /  VISUAL LAB\nCOAST  •  NATIVE GODOT 4.7.2\nCOAST-TO-HIGHLAND ART STUDY  •  NON-CANON"
        var first: Image = await _frame()
        var still: Image = await _frame()
        scene.visuals.set_clock(10.0,false)
        var moving: Image = await _frame()
        var motion_pixels: int = _different(first,moving)
        var paused_pixels: int = _different(first,still)
        scene.visuals.set_clock(9.0,false)
        scene.visuals.set_low_quality(true)
        var low: Image = await _frame()
        _save(low,folder.path_join("coast-low.png"))
        var quality_pixels: int = _different(first,low)
        scene.visuals.set_clock(18.0,true)
        var reduced_a: Image = await _frame()
        scene.visuals.set_clock(23.0,true)
        var reduced_b: Image = await _frame()
        var reduced_pixels: int = _different(reduced_a,reduced_b)
        scene.terrain.update_detail(Vector3(500,10,500),0.5)
        scene.visuals.refresh_coverage()
        await _frame()
        var mask_readback: PackedByteArray = scene.visuals.coverage.get_image().get_data()
        if mask_readback != scene.visuals._coverage_bytes:
            push_error("NATIVE_COVERAGE_READBACK_FAILED")
            failed = true
        else:
            print("NATIVE_COVERAGE_READBACK_PASS hidden tiles have zero coverage")
        # One real native manual-pilot frame; no implied controller hardware FPS.
        scene.visuals.set_low_quality(false)
        scene._clock = 23.0
        scene._update_scene(10.0)
        scene.set_manual_mode(true)
        for pilot_frame in range(25):
            scene.advance_manual(Vector3(0.24, 1.0, 0.0), 0.05)
        scene._update_scene(6.0) # position cinematic camera at the resulting ship course
        scene.overlay.text = "TO SAIL THE STARRY SKY  /  PILOT STUDY\nMANUAL DRAGONFLY TEST  •  NATIVE GODOT 4.7.2\nLOCAL TERRAIN CLEARANCE  •  NON-CANON"
        var manual_frame: Image = await _frame()
        _save(manual_frame,folder.path_join("manual-pilot.png"))
        print("NATIVE_PILOT_FRAME_PASS clearance=", scene.ship.position.y -
            maxf(scene.terrain.SEA_LEVEL,scene.terrain.sample_height(scene.ship.position.x, scene.ship.position.z)))
        # Authored demo field: a sampled-contact review, not a physics-body landing.
        scene._manual_position = Vector3(8.0, scene.terrain.sample_height(8.0, -12.0) + 7.0, -12.0)
        scene._update_scene(8.0)
        if not scene.request_touchdown():
            push_error("NATIVE_TOUCHDOWN_QUEUE_DENIED")
            failed = true
        await physics_frame
        if scene.landing.state != "DESCENDING" or not scene.last_touchdown_contact.get("valid", false):
            push_error("NATIVE_TOUCHDOWN_PHYSICS_ADMISSION_FAILED")
            failed = true
        else:
            print("NATIVE_TOUCHDOWN_PHYSICS_FRAME_PASS triangles=", scene.landing_ground.triangle_count,
                " rayHeightError=", scene.last_touchdown_contact.get("height_error", 99.0))
        for settle_step in range(85):
            scene.advance_manual(Vector3.ZERO, 0.05)
        scene._update_scene(8.0)
        if scene.landing.state != "LANDED":
            push_error("NATIVE_TOUCHDOWN_NOT_LANDED")
            failed = true
        scene.overlay.text = "TO SAIL THE STARRY SKY  /  TOUCHDOWN STUDY\nNATIVE RAYCAST-CONFIRMED TEST FIELD  •  GODOT 4.7.2\nSTATIC TERRAIN SHAPE  •  NOT RIGIDBODY FLIGHT"
        var touchdown_frame: Image = await _frame()
        _save(touchdown_frame, folder.path_join("touchdown.png"))
        print("NATIVE_TOUCHDOWN_FRAME_PASS state=", scene.landing.state,
            " clearance=", scene.ship.position.y -
            scene.terrain.sample_height(scene.ship.position.x, scene.ship.position.z))

        print("NATIVE_EFFECT_PIXEL_CHECK motion=",motion_pixels," paused=",paused_pixels," low_quality=",quality_pixels," reduced_motion=",reduced_pixels)
        if motion_pixels < 100 or quality_pixels < 100 or paused_pixels != 0 or reduced_pixels != 0:
            push_error("NATIVE_EFFECT_PIXEL_CHECK_FAILED")
            failed = true
    scene.queue_free()
    await process_frame
    quit(1 if failed else 0)
