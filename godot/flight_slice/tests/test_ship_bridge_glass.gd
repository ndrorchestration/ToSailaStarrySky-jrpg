extends SceneTree
## Godot 4.7.2: real ShaderMaterial contract and candid scale admission.
## Never implies a safe, sealed or playable geodesic-bridge doorway.
const Ship = preload("res://ship.gd")
const Bridge = preload("res://ship_geodesic_bridge.gd")
const Contract = preload("res://ship_bridge_access_contract.gd")
var failures: Array[String] = []
var count: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, label_text: String) -> void:
    count += 1
    if not value:
        failures.append(label_text)

func _run() -> void:
    var ship := Ship.new()
    root.add_child(ship)
    await process_frame
    var dome = ship.get_node("GeodesicBridge") as Bridge
    check(dome != null, "actual hero ship includes the refined faceted bridge")
    var glass: MeshInstance3D = dome.get_node("GeodesicGlass")
    var material := glass.material_override as ShaderMaterial
    check(material != null and material.shader != null,
        "real geodesic pane mesh is backed by an imported spatial shader")
    if material != null:
        check(material.shader == Bridge.PANORAMA_GLASS,
            "dome uses the exact authored glass resource")
        check(material.shader.code.find("depth_draw_never") >= 0
            and material.shader.code.find("normalize(VIEW)") >= 0,
            "shader uses bounded view-based rim and does not occlude the deck depth")
        check(dome.glass_review_profile == "clear", "default profile is clear")
        check(is_equal_approx(
            float(material.get_shader_parameter("face_alpha")), 0.13),
            "day-review pane opacity remains appropriately restrained")
        var initial_edges: int = dome.unique_frame_edges
        var initial_triangles: int = dome.panel_count
        dome.set_glass_review_profile("low_glare")
        check(dome.glass_review_profile == "low_glare",
            "low-glare option is explicit and non-gameplay")
        check(is_equal_approx(
            float(material.get_shader_parameter("highlight_gain")), 0.10),
            "glare highlights reduce in the controlled review option")
        check(is_equal_approx(
            float(material.get_shader_parameter("edge_alpha")), 0.045),
            "grazing-angle opacity reduces while preserving navigation visibility")
        dome.set_glass_review_profile("extreme_pressure")
        check(dome.glass_review_profile == "low_glare",
            "undocumented modes are rejected rather than implied by art controls")
        dome.set_glass_review_profile("clear")
        check(dome.glass_review_profile == "clear"
            and is_equal_approx(
                float(material.get_shader_parameter("highlight_gain")), 0.30),
            "original glass response restores without stale shader state")
        check(dome.unique_frame_edges == initial_edges
            and dome.panel_count == initial_triangles,
            "review lighting changes never modify hull/frame topology")

    var result: Dictionary = Contract.assess()
    check(is_equal_approx(
        ship.get_node("GeodesicBridge").position.z, Contract.BRIDGE_SHIP_Z),
        "boarding contract tracks exact existing hero-ship dome station")
    check(float(result["dome_diameter_m"]) > 3.7
        and float(result["dome_diameter_m"]) < 3.9,
        "current geometric roof is about 3.8 m wide at 2.5 metre mapping")
    check(float(result["candidate_cabin_width_m"]) == 2.35
        and float(result["cabin_overhang_m"]) > 1.40,
        "dome overhang against tiny threshold cabin is quantified")
    check(float(result["summit_height_over_deck_m"]) < 1.90
        and float(result["roof_shortfall_m"]) > 0.20,
        "roof does not meet provisional 2.05 m clearance even at summit")
    check(bool(result["near_bow"])
        and float(result["bow_meeting_gap_m"]) < 0.10,
        "bow-to-bridge plan position is promising but not access proof")
    check(not bool(result["fits_width"])
        and not bool(result["supports_standing"])
        and not bool(result["ready_for_physical_integration"]),
        "unsafe bridge join is explicitly not certified")
    check(str(result["status"]) == "PROPOSAL_BLOCKED_ON_HULL_SCALE_AND_EGRESS",
        "readiness gate stays blocked until real hull/door and headroom integration")

    ship.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_BRIDGE_GLASS_ACCESS_PASS checks=", count,
            " access=BLOCKED_ON_SCALE_RECONCILIATION")
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_BRIDGE_GLASS_ACCESS_FAIL: " + failure)
        quit(1)
