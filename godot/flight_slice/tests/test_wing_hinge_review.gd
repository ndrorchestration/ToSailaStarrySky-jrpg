extends SceneTree
## Native contract for four original, still-direct-child procedural wing rigs.
## Generic art-only hinge preview: no gameplay, navigation or save behavior.
const Study = preload("res://main.tscn")
const WINGS = ["PortFore", "PortAft", "StarboardFore", "StarboardAft"]
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, note: String) -> void:
    checks += 1
    if not ok:
        failures.append(note)

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var ship: Node3D = scene.ship
    # Snapshot the neutral reference without procedural flex.
    ship.set_motion(0.0, true)
    var original_ship: Transform3D = ship.global_transform
    var original_hull: Mesh = (ship.get_node("LongHull") as MeshInstance3D).mesh
    var baseline: Dictionary = {}
    for name in WINGS:
        var rig: Node3D = ship.get_node("WingRig_" + name)
        var side: float = -1.0 if name.begins_with("Port") else 1.0
        var fore: bool = name.ends_with("Fore")
        var expected_root := Vector3(
            side * (0.38 if fore else 0.40),
            0.18 if fore else 0.17,
            -1.18 if fore else 0.08)
        check(rig.position.is_equal_approx(expected_root),
            "wing pivot at original root " + name)
        check(rig.get_child_count() == 4,
            "original membrane and three rib bundles retained " + name)
        check(rig.get_node("Membrane_" + name) is MeshInstance3D,
            "direct-child membrane retained " + name)
        for child in rig.get_children():
            var part: Node3D = child as Node3D
            check(part.global_transform.is_equal_approx(original_ship),
                "neutral original ship-local geometry preserved " + name + "/" + str(child.name))
        baseline[name] = (rig.get_node("Membrane_" + name) as MeshInstance3D).global_transform
    check(ship.set_wing_review_sweep(0.5), "half sweep accepted")
    for name in WINGS:
        var rig: Node3D = ship.get_node("WingRig_" + name)
        var direction: float = 1.0 if name.begins_with("Port") else -1.0
        check(is_equal_approx(rig.rotation.y, direction * deg_to_rad(7.5)),
            "symmetric half-angle " + name)
    check(ship.set_wing_review_sweep(1.0), "full sweep accepted")
    check(not ship.set_wing_review_sweep(NAN), "non-finite sweep rejected")
    for name in WINGS:
        var rig: Node3D = ship.get_node("WingRig_" + name)
        var direction: float = 1.0 if name.begins_with("Port") else -1.0
        check(is_equal_approx(rig.rotation.y, direction * deg_to_rad(15.0)),
            "invalid input leaves prior wing pose intact " + name)
    ship.set_motion(12.0, true)
    for name in WINGS:
        var rig: Node3D = ship.get_node("WingRig_" + name)
        check(is_zero_approx(rig.rotation.z),
            "M reduced-motion suppresses procedural flex " + name)
    check(ship.set_wing_review_sweep(0.0), "baseline restored")
    for name in WINGS:
        var membrane: MeshInstance3D = ship.get_node(
            "WingRig_" + name + "/Membrane_" + name)
        check(membrane.global_transform.is_equal_approx(baseline[name]),
            "baseline transforms restored " + name)
    check(ship.global_transform == original_ship, "flight transform never mutated")
    check((ship.get_node("LongHull") as MeshInstance3D).mesh == original_hull,
        "hull mesh identity unchanged")
    check(scene.terrain.chunk_count() == 64, "original terrain budget unchanged")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_NEUTRAL_WING_HINGE_PASS checks=", checks)
        quit(0)
    else:
        for item in failures:
            push_error("GODOT_NEUTRAL_WING_HINGE_FAIL: " + item)
        quit(1)
