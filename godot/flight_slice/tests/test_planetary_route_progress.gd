extends SceneTree
## Contract checks only: synthetic receipts test state guards, not physics proof.
const Route = preload("res://planetary_route_progress.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    var route = Route.new()
    check(route.phase == Route.Phase.DOCKED, "starts docked")
    check(not route.start_departure(Route.FRIGATE_ID), "frigate cannot substitute home ship")
    check(route.start_departure(Route.HOME_SHIP_ID), "home ship can depart")
    check(not route.disembark(true), "cannot disembark before landing")
    check(not route.mark_coast(false, true), "out of bounds coast is rejected")
    check(not route.mark_coast(true, false), "unverified coast is rejected")
    check(route.mark_coast(true, true), "coast reach")
    check(not route.mark_touchdown({}, "LANDED"), "no physics receipt")
    check(not route.mark_touchdown({"valid": true}, "LANDED"), "missing native receipt fields")
    var receipt := {"valid": true, "position": Vector3.ZERO, "normal": Vector3.UP}
    check(not route.mark_touchdown(receipt, "DESCENDING"), "descent is not landing")
    check(route.mark_touchdown(receipt, "LANDED"), "supported landing")
    check(not route.disembark(false), "requires real ground scene")
    check(route.disembark(true), "ground scene")
    check(not route.return_to_ship(Route.FRIGATE_ID, true), "wrong ship denied")
    check(not route.return_to_ship(Route.HOME_SHIP_ID, false), "requires boarding")
    check(route.return_to_ship(Route.HOME_SHIP_ID, true), "route completes")
    check(route.snapshot()["phase"] == Route.Phase.RETURNED, "snapshot reports return")
    route.reset()
    check(route.phase == Route.Phase.DOCKED and not route.visited_coast, "reset clears route")
    if failures.is_empty():
        print("GODOT_PLANETARY_ROUTE_CONTRACT_PASS checks=", checks)
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_PLANETARY_ROUTE_CONTRACT_FAIL: " + failure)
        quit(1)

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
