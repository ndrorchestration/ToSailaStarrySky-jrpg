extends SceneTree
## Real engine 3D spatial/camera/material proof, isolated from First Wake 2D entry.
const Slice = preload("res://scenes/first_wake_3d_visual_slice.tscn")
var errors: Array[String] = []
var checks := 0

func _initialize() -> void:
    call_deferred("_verify")

func check(ok: bool, description: String) -> void:
    checks += 1
    if not ok:
        errors.append(description)
        push_error("TSTSS_3D_SLICE_FAIL:" + description)

func _verify() -> void:
    check(ProjectSettings.get_setting("application/run/main_scene") ==
        "res://scenes/first_wake_game.tscn", "original First Wake F5 entry mutated")
    var preview = Slice.instantiate()
    root.add_child(preview)
    await process_frame
    var snap: Dictionary = preview.quality_snapshot()
    check(snap.get("mode") == "separate_true_3d_visual_slice", "3D scene not isolated")
    check(int(snap.get("true_3d_geometry_count", 0)) >= 110,
        "3D scene lacks real constructed pier, coast, sea and ship geometry")
    check(snap.get("real_spatial_water") == true, "sea not spatial shader geometry")
    check(snap.get("real_3d_camera") == true, "real 3D camera missing")
    check(int(snap.get("physical_3d_lights", 0)) == 5, "five native 3D lanterns missing")
    check(preview.sunlight is DirectionalLight3D and preview.sunlight.shadow_enabled,
        "3D keylight not a shadow-casting directional sun")
    check(preview.camera is Camera3D and preview.camera.far >= 200.0,
        "3D camera or meaningful coastline view distance absent")
    check(preview.water.mesh is PlaneMesh and preview.water.material_override.shader != null,
        "3D sea is actually a 3D shader mesh")
    var wet_mesh := preview.water.mesh as PlaneMesh
    check(wet_mesh.subdivide_depth >= 100 and wet_mesh.subdivide_width >= 100,
        "wave displacement has insufficient actual vertices")
    var arrivals := 0
    var empty_private_slots := 0
    for child in preview.visual_root.get_children():
        if child.name.ends_with("_True3DImportSlot"):
            arrivals += 1
            var audit: Dictionary = child.audit_snapshot()
            if not audit.get("real_model_loaded"):
                empty_private_slots += 1
            check(audit.get("visual_approval") == false,
                "GLB source slot claims artist approval without inspection")
        if child is CollisionObject3D:
            check(false, "review scene has unauthorized physics collision object")
    check(arrivals == 2, "Ionia/Ender GLB placement slots absent")
    check(snap.get("playable_chapter_one_3d_migrated") == false,
        "3D art study falsely claimed chapter migration")
    check(snap.get("cinematic_art_approved") == false,
        "3D blockout falsely accepted as cinematic final")
    check(int(snap.get("rigged_creator_models_ready", -1)) == (arrivals - empty_private_slots),
        "source GLB availability misreported")
    check(preview.active_hour == "golden_hour", "review golden-hour default lost")
    var event := InputEventKey.new()
    event.pressed = true
    event.keycode = KEY_T
    preview._unhandled_input(event)
    check(preview.active_hour == "blue_hour" and preview.sunlight.light_energy < 0.5,
        "native T key did not switch to nighttime lighting")
    preview._unhandled_input(event)
    check(preview.active_hour == "golden_hour" and preview.sunlight.light_energy > 0.65,
        "T key could not restore cinematic sunset")
    var original_distance: float = preview.camera_distance
    Input.action_press("ui_up")
    preview._process(0.45)
    Input.action_release("ui_up")
    check(preview.camera_distance < original_distance,
        "actual review camera orbit/zoom code is inert")
    event.keycode = KEY_R
    preview._unhandled_input(event)
    check(absf(preview.camera_distance - 34.0) < 0.01,
        "camera R reset failed")
    check(not ResourceLoader.exists("res://art-review/private-3d/characters/ender.glb") or
        preview.visual_root.get_node("Ender_True3DImportSlot").audit_snapshot().get("real_model_loaded") == true,
        "source model available but gate failed; inspect import")
    preview.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_3D_SLICE_PASS checks=", checks,
            " spatial=true actual_water_shader=true 3d_camera=true original_game_untouched=true")
    quit(0 if errors.is_empty() else 1)
