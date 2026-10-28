extends SceneTree
## Isolated shader visual test; no world-state/physics/recruitment authority.
const Dock = preload("res://scripts/dock_depth_review.gd")
var faults: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        faults.append(label)

func _run() -> void:
    check(ProjectSettings.get_setting("application/run/main_scene") ==
        "res://scenes/first_wake_game.tscn", "canonical first wake player entry preserved")
    var dock = Dock.new()
    dock.name = "CoastShaderBackgroundReview"
    root.add_child(dock)
    await process_frame
    check(dock.painted_sky_enabled, "painted sky on by default in review")
    check(dock.painted_sky != null, "native sky object not created")
    if dock.painted_sky != null:
        check(dock.painted_sky.size == Vector2(960, 402), "native visual bounds")
        check(dock.painted_sky.mouse_filter == Control.MOUSE_FILTER_IGNORE,
            "painted sky must not intercept mouse")
        check(dock.painted_sky.show_behind_parent, "sky must not cover dock/actors")
        var mat: ShaderMaterial = dock.painted_sky.material as ShaderMaterial
        check(mat != null and mat.shader != null, "reuses real cinematic shader")
    check(dock.get_tree().get_nodes_in_group("character_party").is_empty(),
        "sky should never create party participants")
    var plain = Dock.new()
    plain.painted_sky_enabled = false
    root.add_child(plain)
    await process_frame
    check(plain.painted_sky == null, "disable restores old sky")
    var foreground = Dock.new()
    foreground.foreground = true
    root.add_child(foreground)
    await process_frame
    check(foreground.painted_sky == null, "foreground does not duplicate sky")
    check(dock.get_node_or_null("CollisionShape2D") == null and
        plain.get_node_or_null("CollisionShape2D") == null,
        "visual only, no physics collision authority")
    foreground.queue_free()
    plain.queue_free()
    dock.queue_free()
    await process_frame
    if faults.is_empty():
        print("TSTSS_FIRST_WAKE_PAINTED_COAST_PASS checks=", checks,
            " native_shader=true visual_only=true fallback=true main_unchanged=true")
        quit(0)
    else:
        for fault in faults:
            push_error("TSTSS_FIRST_WAKE_PAINTED_COAST_FAIL: " + fault)
        quit(1)
