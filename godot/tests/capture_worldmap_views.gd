extends SceneTree
## Actual OpenGL/GL Compatibility worldmap render gate, never synthetic or
## headless illustration. Frames stay runner-local; checksums logged by CI.
const Scene = preload("res://scenes/planetary_worldmap.tscn")
const OUT := "res://review-evidence/"
var _frame_names := ["globe","chart","local-survey","low-sky-3d","sea-facing","cube-tiles"]

func _initialize() -> void:
    call_deferred("_run")

func _capture() -> Image:
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _valid(img: Image, view_name: String) -> bool:
    if img.is_empty() or img.get_width() != 960 or img.get_height() != 640:
        return false
    var unique: Dictionary = {}
    for y in range(95,540,21):
        for x in range(30,930,27):
            unique[img.get_pixel(x,y).to_rgba32()] = true
    print("GODOT_WORLDMAP_FRAME_VARIATION: %s colors=%d" % [view_name,unique.size()])
    # Earlier low-sky view had only four sampled colors. Keep the test
    # sensitive to accidental flat-sky/blank-material regressions.
    return unique.size() >= (55 if view_name == "low-sky-3d" else 18)

func _run() -> void:
    root.size = Vector2i(960,640)
    var world := Scene.instantiate()
    root.add_child(world)
    await process_frame
    await process_frame
    var base: Image
    for i in range(_frame_names.size()):
        if i == 5:
            # Same actual ship position in an entirely global sphere frame,
            # not a screenshot of the prior local tangent terrain.
            var cubes: Dictionary = world.call("snapshot")
            cubes["mode"] = "tiles"
            cubes["flight"]["headingDeg"] = 90.0
            world.call("_apply_state",cubes)
            world.call("_refresh_chart")
            world.call("_update_view")
        elif i == 4:
            # Rotate toward the neighboring open-water side without changing
            # geography, so shader-water pixels have a dedicated review gate.
            var sea_state: Dictionary = world.call("snapshot")
            sea_state["mode"] = "flight"
            sea_state["flight"]["headingDeg"] = 270.0
            world.call("_apply_state",sea_state)
            world.call("_refresh_chart")
            world.call("_update_view")
        elif i != 0:
            var key := InputEventKey.new()
            key.pressed = true
            key.keycode = KEY_1+i
            world.call("_unhandled_input",key)
        # A fresh Godot GL process may upload 26 separate 3D meshes and
        # compile sea/land variants asynchronously. Do not compare an
        # unpopulated frame with a hidden renderer and infer invisible art.
        var warmup_frames := 18 if i == 5 else 2
        for warmup in range(warmup_frames):
            await process_frame
        var image: Image = await _capture()
        if not _valid(image,_frame_names[i]):
            push_error("GODOT_WORLDMAP_CAPTURE_FAIL: nonrendered or unvaried "+_frame_names[i])
            quit(i+2)
            return
        if i == 3:
            var ground := world.get_node_or_null("LowSkyTerrainDevelopmentPatch")
            if ground == null or not ground.visible:
                push_error("GODOT_WORLDMAP_CAPTURE_FAIL: 3D terrain node not visible")
                quit(12)
                return
            ground.visible = false
            await process_frame
            await process_frame
            var without_ground: Image = await _capture()
            ground.visible = true
            # Identical pixels would mean a camera pointed at blank sky, a
            # culled mesh, a broken material or an otherwise invisible patch.
            var area := Rect2i(15,120,930,415)
            if image.get_region(area).get_data() == without_ground.get_region(area).get_data():
                push_error("GODOT_WORLDMAP_CAPTURE_FAIL: 3D terrain has no visible rendered pixels")
                quit(13)
                return
            print("GODOT_WORLDMAP_GROUND_PIXEL_DELTA_PASS")
        if i == 4:
            var ocean := world.get_node_or_null("LowSkyTerrainDevelopmentPatch/OceanSurface") as MeshInstance3D
            if ocean == null or ocean.mesh == null or not ocean.visible:
                push_error("GODOT_WORLDMAP_CAPTURE_FAIL: sea mesh missing")
                quit(14)
                return
            ocean.visible = false
            await process_frame
            await process_frame
            var without_water: Image = await _capture()
            ocean.visible = true
            var sample_area := Rect2i(20,110,920,435)
            if image.get_region(sample_area).get_data() == without_water.get_region(sample_area).get_data():
                push_error("GODOT_WORLDMAP_CAPTURE_FAIL: ocean material does not contribute visible pixels")
                quit(15)
                return
            print("GODOT_WORLDMAP_OCEAN_PIXEL_DELTA_PASS")
        if i == 5:
            var tile_root := world.get_node_or_null("NativeCubedSphereTerrain")
            if tile_root == null or not tile_root.visible:
                push_error("GODOT_WORLDMAP_CAPTURE_FAIL: native cube tile scene invisible")
                quit(16)
                return
            var tile_stats: Dictionary = tile_root.call("stats")
            if int(tile_stats["visible"]) == 0 or int(tile_stats["visible"]) > 32:
                push_error("GODOT_WORLDMAP_CAPTURE_FAIL: cube stream outside mesh budget")
                quit(17)
                return
            tile_root.visible = false
            await process_frame
            await process_frame
            var without_tiles: Image = await _capture()
            tile_root.visible = true
            var tile_area := Rect2i(20,110,920,435)
            if image.get_region(tile_area).get_data() == without_tiles.get_region(tile_area).get_data():
                # Renderer/debug evidence: determine whether actual pixels land
                # below the capture ROI, fail culling, or miss the camera frame.
                for band in range(6):
                    var vertical := Rect2i(0,band*100,960,100)
                    var changed := image.get_region(vertical).get_data() != without_tiles.get_region(vertical).get_data()
                    print("CUBE_CAPTURE_DIAG_BAND_%d_DIFF=%s" % [band,str(changed)])
                var inspect_camera := world.get_node_or_null("WorldMapOrbitCamera") as Camera3D
                if inspect_camera != null:
                    print("CUBE_CAPTURE_DIAG_CAMERA: "+str(inspect_camera.global_position))
                    var in_front := 0
                    var visible_sample := 0
                    for tile_node in tile_root.get_children():
                        var terrain_mesh := tile_node.get_node_or_null("SphericalLand") as MeshInstance3D
                        if terrain_mesh == null or terrain_mesh.mesh == null:
                            continue
                        var arr: Array = terrain_mesh.mesh.surface_get_arrays(0)
                        var vertices: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
                        if vertices.is_empty():
                            continue
                        var sample: Vector3 = vertices[int(vertices.size()/2)]
                        if not inspect_camera.is_position_behind(sample):
                            in_front += 1
                            var projected := inspect_camera.unproject_position(sample)
                            if projected.x >= 0.0 and projected.x <= 960.0 and projected.y >= 0.0 and projected.y <= 640.0:
                                visible_sample += 1
                    print("CUBE_CAPTURE_DIAG_MESH_IN_FRONT=%d_PROJECTED_ONSCREEN=%d" % [in_front,visible_sample])
                push_error("GODOT_WORLDMAP_CAPTURE_FAIL: streamed spherical mesh has no visible pixels")
                quit(18)
                return
            print("GODOT_WORLDMAP_CUBE_TERRAIN_PIXEL_DELTA_PASS: visible=%d" % int(tile_stats["visible"]))
        if i == 0:
            base = image
        elif image.get_data() == base.get_data():
            push_error("GODOT_WORLDMAP_CAPTURE_FAIL: mode visually unchanged "+_frame_names[i])
            quit(i+6)
            return
        if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
            push_error("GODOT_WORLDMAP_CAPTURE_FAIL: cannot create destination")
            quit(10)
            return
        var target: String = OUT+"worldmap-"+str(_frame_names[i])+"-native-960x640.png"
        if image.save_png(target) != OK:
            push_error("GODOT_WORLDMAP_CAPTURE_FAIL: PNG write")
            quit(11)
            return
        print("GODOT_WORLDMAP_NATIVE_FRAME_PASS: "+target)
    print("GODOT_WORLDMAP_RENDER_CAPTURE_PASS: globe/chart/survey/low-sky/sea-facing/true-cube-tiles actually rendered")
    print("GODOT_WORLDMAP_CREATOR_VISUAL_ACCEPTANCE=PENDING")
    quit(0)
