extends SceneTree
## Native Godot 4.7.2 test against the ACTUAL Chapter I review scene,
## not the isolated flight-lab project. Source pixels are original Git blobs.
const Chapter = preload("res://scenes/first_wake_chapter1_review.tscn")
var errors: Array[String] = []
var checks: int = 0

func check(value: bool, message: String) -> void:
    checks += 1
    if not value:
        errors.append(message)

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var chapter_scene = Chapter.instantiate()
    root.add_child(chapter_scene)
    await process_frame
    chapter_scene.set_process(false)
    var layer: Node2D = chapter_scene.environment_asset_intake
    check(layer != null, "real Chapter I scene contains opt-in asset intake layer")
    if layer != null:
        check(layer.name == "ChapterOneEnvironmentAssetIntakeReviewOnly",
            "noncanonical identity explicitly retained")
        check(not layer.visible, "review visuals fail closed by default")
        check(layer.z_index == -1, "decorative layer appears behind interactive actors")
        var resources: Dictionary = layer.source_resources()
        check(resources.size() == 4, "all four source PNG files native-imported")
        for key in ["terrain","foliage","water","biome"]:
            var tex: Texture2D = resources.get(key)
            check(tex != null, "native import of "+key)
            if tex != null:
                check(tex.get_size() == Vector2(128,128), "128px source texture "+key)
                var img: Image = tex.get_image()
                check(img != null, "imported image has native pixels "+key)
                if img != null:
                    check(img.get_pixel(13,19) != img.get_pixel(79,83),
                        "source art is not an empty placeholder "+key)
    var stage: Dictionary = chapter_scene.chapter.snapshot().duplicate(true)
    var old_pos: Vector2 = chapter_scene.ender.global_position
    var old_bounds: Rect2 = chapter_scene.ender.walking_bounds
    var old_collision_layer: int = chapter_scene.ender.collision_layer
    var old_collision_mask: int = chapter_scene.ender.collision_mask
    var root_children: int = chapter_scene.get_child_count()
    for enabled in [true,false,true,false]:
        chapter_scene.set_environment_asset_intake_review_enabled(enabled)
        check(chapter_scene.is_environment_asset_intake_review_enabled()==enabled,
            "review toggle is reversible")
        check(chapter_scene.chapter.snapshot()==stage,
            "visual assets cannot change story/save snapshot")
        check(chapter_scene.ender.global_position==old_pos,
            "preview layer cannot move Ender")
        check(chapter_scene.ender.walking_bounds==old_bounds,
            "no altered playable region")
        check(chapter_scene.ender.collision_layer==old_collision_layer
            and chapter_scene.ender.collision_mask==old_collision_mask,
            "no collision participation changed")
        check(chapter_scene.get_child_count()==root_children,
            "toggle creates no extra gameplay nodes")
    check(not chapter_scene.is_environment_asset_intake_review_enabled(),
        "the scene returns to its original hidden-material state")
    chapter_scene.queue_free()
    await process_frame
    if errors.is_empty():
        print("GODOT_CH1_ENVIRONMENT_INTAKE_PASS checks=",checks)
        quit(0)
    else:
        for problem in errors:
            push_error("GODOT_CH1_ENVIRONMENT_INTAKE_FAIL: "+problem)
        quit(1)
