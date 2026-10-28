extends SceneTree
## Actual Chapter I native material test; no fake renderer or gameplay changes.
const Chapter = preload("res://scenes/first_wake_chapter1_review.tscn")
const ShaderAsset = preload("res://shaders/environment_material_adapter.gdshader")
var errors: Array[String] = []
var checks: int = 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        errors.append(label)

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var scene = Chapter.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var adapter = scene.environment_asset_intake
    check(not adapter.visible, "new material always hidden by default")
    check(adapter.preview_variant() == "blended", "new masked material is review preference")
    check(adapter.material_patches().size() == 4,
        "exactly four reused material patches, no extra meshes")
    var before: Dictionary = scene.chapter.snapshot().duplicate(true)
    var origin: Vector2 = scene.ender.global_position
    var bounds: Rect2 = scene.ender.walking_bounds
    var layer: int = scene.ender.collision_layer
    var mask: int = scene.ender.collision_mask
    var child_count: int = scene.get_child_count()
    var textures: Dictionary = adapter.source_resources()
    var patches: Array[TextureRect] = adapter.material_patches()
    for i in range(patches.size()):
        var patch: TextureRect = patches[i]
        check(patch.mouse_filter == Control.MOUSE_FILTER_IGNORE,
            "art layer never captures interactive mouse")
        check(patch.focus_mode == Control.FOCUS_NONE,
            "art layer does not change keyboard focus")
        check(patch.get_child_count() == 0, "no particles or hidden collision nodes")
        check(patch.material is ShaderMaterial, "actual native shader owns material")
        var m: ShaderMaterial = patch.material
        check(m.shader == ShaderAsset, "one reusable material-shader source")
        check(m.get_shader_parameter("region_detail") == textures["biome"],
            "original regional texture used by every patch")
        check(m.get_shader_parameter("micro_detail") ==
            (textures["water"] if i < 2 else textures["foliage"]),
            "original visual source selected by existing dock region")
        check(int(m.get_shader_parameter("surface_family")) == (0 if i < 2 else 1),
            "material domain matches water or planter")
        check(patch.visible, "blended version active within hidden review parent")
    for variant in ["legacy", "blended", "legacy", "blended"]:
        adapter.set_preview_variant(variant)
        check(adapter.preview_variant() == variant,
            "reference blend variant is reversible")
        for patch in adapter.material_patches():
            check(patch.visible == (variant == "blended"),
                "reference mode is mutually exclusive with blended children")
    adapter.set_preview_variant("unknown")
    check(adapter.preview_variant() == "blended",
        "unsupported material family fails closed")
    scene.set_environment_asset_intake_review_enabled(true)
    adapter.set_low_detail(true)
    check(adapter.is_low_detail(), "explicit low detail enabled")
    for patch in adapter.material_patches():
        check(not patch.visible, "low quality disables extra material draw")
    adapter.set_low_detail(false)
    for patch in adapter.material_patches():
        check(patch.visible, "high quality restores original material instances")
    scene.set_environment_asset_intake_review_enabled(false)
    check(not adapter.visible, "whole review hidden after quality tests")
    check(scene.chapter.snapshot() == before,
        "art review cannot change authored chapter state")
    check(scene.ender.global_position == origin and scene.ender.walking_bounds == bounds,
        "art review cannot change player position or boundaries")
    check(scene.ender.collision_layer == layer and scene.ender.collision_mask == mask,
        "art review cannot change collision identity")
    check(scene.get_child_count() == child_count,
        "no dynamic gameplay node leaks from material switches")
    scene.queue_free()
    await process_frame
    if errors.is_empty():
        print("GODOT_ENV_MATERIAL_ADAPTER_PASS checks=",checks)
        quit(0)
    else:
        for message in errors:
            push_error("GODOT_ENV_MATERIAL_ADAPTER_FAIL: "+message)
        quit(1)
