extends SceneTree
const State = preload("res://scripts/planetary/worldmap_state.gd")
var failed: Array[String] = []

func check(ok: bool, label: String) -> void:
    if not ok:
        failed.append(label)

func _initialize() -> void:
    var initial := State.defaults()
    var encoded := State.encode(initial)
    var restored := State.decode(encoded)
    check(not restored.is_empty(),"valid state decodes")
    check(restored["flight"] == initial["flight"],"flight round trip")
    var with_data := initial.duplicate(true)
    with_data["mode"] = "local"
    with_data["discovered"] = ["survey_a","survey_b"]
    with_data["waypoint"] = {"latDeg":-41.2,"lonDeg":179.4}
    var repaired := State.decode(State.encode(with_data))
    check(repaired["mode"] == "local","view state preserved")
    check(repaired["discovered"].size() == 2,"discovery preserved")
    check(absf(float(repaired["waypoint"]["lonDeg"])-179.4)<0.001,"waypoint preserved")
    check(State.decode("not json").is_empty(),"corruption fails closed")
    check(State.decode(JSON.stringify({"version":99,"state":initial})).is_empty(),"version mismatch")
    var tampered := with_data.duplicate(true)
    tampered["flight"]["latDeg"] = 140.0
    check(State.encode(tampered).is_empty(),"latitude tamper rejected")
    tampered = with_data.duplicate(true)
    tampered["flight"]["speedKmh"] = INF
    check(State.encode(tampered).is_empty(),"nonfinite speed rejected")
    tampered = with_data.duplicate(true)
    tampered["discovered"] = ["survey_a","secret_route"]
    check(State.encode(tampered).is_empty(),"unknown discovery rejected")
    tampered = with_data.duplicate(true)
    tampered["discovered"] = ["survey_a","survey_a"]
    check(State.encode(tampered).is_empty(),"duplicated discovery rejected")
    tampered = with_data.duplicate(true)
    tampered["waypoint"] = {"latDeg":0.0,"lonDeg":180.0}
    check(State.encode(tampered).is_empty(),"out-of-range waypoint rejected")
    check(State.decode("x".repeat(State.LIMIT_BYTES+1)).is_empty(),"payload limit")
    if failed.is_empty():
        print("GODOT_WORLDMAP_STATE_PASS: persistence parity and fail-closed validation")
        quit(0)
    else:
        push_error("GODOT_WORLDMAP_STATE_FAIL: " + ", ".join(failed))
        quit(1)
