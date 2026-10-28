extends RefCounted
## Scene-local 2D ridge profile source shared by the dock-depth rendering
## and opt-in vegetation. It is NOT collision, navigation or planet terrain.
const SURFACE_ID := "pilot_dock_back_ridge_canvas_2d"
const TOP := [
    Vector2(0,319), Vector2(92,277), Vector2(143,293),
    Vector2(196,254), Vector2(240,304), Vector2(330,268),
    Vector2(392,310), Vector2(460,293), Vector2(535,322),
    Vector2(620,273), Vector2(697,306), Vector2(790,269),
    Vector2(850,296), Vector2(960,263)
]
const FILL_BOTTOM := 408.0

static func ridge_polygon() -> Array[Vector2]:
    # Exactly the original dock_depth_review rear ridge vertices and closure.
    var result: Array[Vector2] = []
    for point in TOP:
        result.append(point)
    result.append(Vector2(960, FILL_BOTTOM))
    result.append(Vector2(0, FILL_BOTTOM))
    return result

static func sample_root(screen_x: float, surface_id: String = SURFACE_ID) -> Dictionary:
    if surface_id != SURFACE_ID:
        return {"ok": false, "reason": "unrecognized_local_surface"}
    if is_nan(screen_x) or is_inf(screen_x) or (
            screen_x < TOP[0].x or screen_x > TOP[TOP.size()-1].x):
        return {"ok": false, "reason": "outside_authored_ridge"}
    for i in range(TOP.size() - 1):
        var a: Vector2 = TOP[i]
        var b: Vector2 = TOP[i + 1]
        if screen_x >= a.x and screen_x <= b.x:
            var alpha: float = (screen_x - a.x) / (b.x - a.x)
            return {"ok": true, "point": a.lerp(b, alpha),
                "surface_id": SURFACE_ID, "segment": i}
    return {"ok": false, "reason": "no_authored_segment"}
