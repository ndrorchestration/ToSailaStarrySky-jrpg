extends SceneTree
## NONCANON Godot GL proof: compare same-camera frames across canopy LOD.
## Separates mesh-switch pixel discontinuity from camera-motion differences.
const StudyScene = preload("res://main.tscn")
const CAMERA_X: Array[float] = [-30.0, -26.0, -22.0, -18.0, -14.0,
    -10.0, -6.0, -2.0, 2.0, 6.0, 10.0, 6.0, 2.0, -2.0, -6.0,
    -10.0, -14.0, -18.0, -22.0, -26.0, -30.0]
const EYE_Y: float = 18.0
const EYE_Z: float = 0.0
const PIXEL_THRESHOLD: float = 0.045

func _initialize() -> void:
    call_deferred("_run")

func _frame() -> Image:
    for i in range(4):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _changed_pixels(a: Image, b: Image) -> int:
    if a == null or b == null or a.get_size() != Vector2i(960,640) or (
            b.get_size() != Vector2i(960,640)):
        return -1
    var changed: int = 0
    for y in range(0,640,4):
        for x in range(0,960,4):
            var ca: Color = a.get_pixel(x,y)
            var cb: Color = b.get_pixel(x,y)
            if absf(ca.r-cb.r) + absf(ca.g-cb.g) + absf(ca.b-cb.b) > PIXEL_THRESHOLD:
                changed += 1
    return changed

func _run() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene._clock = 23.0
    scene._update_scene(10.0)
    scene.set_manual_mode(false)
    scene.visuals.set_low_quality(false)
    scene.visuals.set_canopy_review_override(2)
    var folder: String = ProjectSettings.globalize_path(
        "res://evidence/forest-lod-threshold")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("FOREST_THRESHOLD_DIR_FAILED")
        quit(1)
        return
    # Explicitly settle at the distant first waypoint BEFORE the measured run.
    # Otherwise the initial return to the far view counts as real travel LOD
    # switches, contaminating approach/retreat transition measurements.
    scene.visuals.update_forest_detail(Vector3(CAMERA_X[0],EYE_Y,EYE_Z))
    scene.visuals.set_canopy_review_override(0)
    if scene.visuals._near_patch_count != 0:
        push_error("FOREST_THRESHOLD_UNSETTLED_START")
        quit(1)
        return
    scene.overlay.visible = false
    scene.ship.visible = false
    var total_switches: int = 0
    var enter_switches: int = 0
    var exit_switches: int = 0
    var max_pixels: int = 0
    var saved_pairs: int = 0
    var samples: Array[Dictionary] = []
    var max_switches_per_frame: int = 0
    var max_settle_frames: int = 0
    for x in CAMERA_X:
        var eye := Vector3(x,EYE_Y,EYE_Z)
        scene.camera.position = eye
        scene.camera.look_at(Vector3(40.0,8.0,0.0),Vector3.UP)
        scene.terrain.update_detail(eye,0.0)
        scene.visuals.refresh_coverage()
        # Stage each waypoint at a fixed eye. Each native before/after image
        # pair contains exactly ONE simulated rendering-update mesh decision.
        # Reevaluate until no pending switches remain; this is a scripted
        # path, not a claim of real 60FPS camera playback.
        var settled: bool = false
        for settle_tick in range(scene.visuals._forest_batches.size() + 2):
            var before: Image = await _frame()
            scene.visuals.update_forest_detail(eye)
            var receipt: Dictionary = scene.visuals.forest_lod_receipt()
            var transitions: Array = scene.visuals.lod_last_switches.duplicate(true)
            var after: Image = await _frame()
            var pixels: int = _changed_pixels(before,after)
            if pixels < 0:
                push_error("FOREST_THRESHOLD_BAD_CAPTURE_SIZE")
                quit(1)
                return
            if transitions.size() > scene.visuals.CANOPY_SWAPS_PER_UPDATE:
                push_error("FOREST_THRESHOLD_EXCEEDED_ONE_SWAP_BUDGET")
                quit(1)
                return
            max_switches_per_frame = maxi(max_switches_per_frame, transitions.size())
            total_switches += transitions.size()
            for transition in transitions:
                if transition["now_near"]:
                    enter_switches += 1
                else:
                    exit_switches += 1
            max_pixels = maxi(max_pixels,pixels)
            # Preserve one actual same-eye image pair from each direction.
            var store_pair: bool = transitions.size() > 0 and (
                (saved_pairs == 0 and transitions[0]["now_near"]) or
                (saved_pairs == 1 and not transitions[0]["now_near"]))
            if store_pair:
                var label_text: String = "approach" if saved_pairs == 0 else "retreat"
                if before.save_png(folder.path_join(label_text+"-before.png")) != OK or (
                        after.save_png(folder.path_join(label_text+"-after.png")) != OK):
                    push_error("FOREST_THRESHOLD_IMAGE_WRITE_FAILED")
                    quit(1)
                    return
                saved_pairs += 1
            samples.append({
                "camera":[eye.x,eye.y,eye.z],
                "settle_tick":settle_tick,
                "changed_subsampled_pixels":pixels,
                "switches":transitions,
                "receipt":receipt
            })
            if receipt["pending_species_cell_swaps"] == 0:
                settled = true
                max_settle_frames = maxi(max_settle_frames, settle_tick+1)
                break
        if not settled:
            push_error("FOREST_THRESHOLD_DID_NOT_CONVERGE_AT_WAYPOINT")
            quit(1)
            return
    var file := FileAccess.open(folder.path_join("transition-receipt.json"),FileAccess.WRITE)
    if file == null:
        push_error("FOREST_THRESHOLD_RECEIPT_WRITE_FAILED")
        quit(1)
        return
    file.store_string(JSON.stringify({
        "engine":Engine.get_version_info().string,
        "renderer":RenderingServer.get_current_rendering_method(),
        "adapter":RenderingServer.get_video_adapter_name(),
        "scene":"NONCANON local flight art study",
        "resolution":[960,640], "stride":4,
        "pixel_rgb_abs_sum_threshold":PIXEL_THRESHOLD,
        "interpretation":"Fixed-pose before/after mesh-switch pixel differences; not moving-camera stability, GPU timings or proof of visual acceptance",
        "switches_total":total_switches,
        "enter_switches":enter_switches,
        "exit_switches":exit_switches,
        "peak_changed_subsampled_pixels":max_pixels,
        "samples":samples,
        "camera_waypoints":CAMERA_X.size(),
        "max_changes_per_frame":max_switches_per_frame,
        "max_settle_frames_at_waypoint":max_settle_frames,
        "budget":scene.visuals.CANOPY_SWAPS_PER_UPDATE
    },"  "))
    file.close()
    if total_switches == 0 or enter_switches == 0 or exit_switches == 0 or (
            saved_pairs < 2) or max_switches_per_frame > scene.visuals.CANOPY_SWAPS_PER_UPDATE or (
            max_settle_frames < 2) or samples.size() < CAMERA_X.size():
        push_error("FOREST_THRESHOLD_INCOMPLETE_APPROACH_RETREAT")
        quit(1)
        return
    print("NATIVE_FOREST_THRESHOLD_PASS switches=",total_switches,
        " enters=",enter_switches," exits=",exit_switches,
        " frames=",samples.size()," pairs=",saved_pairs,
        " max_per_frame=",max_switches_per_frame,
        " max_settle_frames=",max_settle_frames,
        " peak_pixels=",max_pixels)
    scene.queue_free()
    await process_frame
    quit(0)
