extends SceneTree
## No shipped navigation changes: native verification of deck study hypotheses.
const Layout = preload("res://ship_interior_layout.gd")
const Study = preload("res://ship_interior_study.gd")
var count: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label_text: String) -> void:
    count += 1
    if not ok:
        failures.append(label_text)

func _run() -> void:
    check(Layout.LENGTH_M > 0.0 and Layout.BEAM_M > 0.0, "positive envelope")
    check(Layout.gross_envelope_m3() > 100.0 and
        Layout.gross_envelope_m3() < 115.0, "gross envelope inside study target")
    check(Layout.AISLE_HALF_WIDTH_M >= 0.60, "central passage width target")
    check(Layout.zones().size() == 3, "bridge commons and engineering provisional")
    var ids := {}
    var items: Array[Dictionary] = Layout.fixtures()
    check(items.size() == 8, "eight compact authored station footprints")
    for station in items:
        var id: String = str(station["id"])
        check(not ids.has(id), "fixture identity is unique: " + id)
        ids[id] = true
        check(Layout.fixture_inside_envelope(station), "fixture fits envelope: " + id)
        check(Layout.aisle_is_clear(station), "fixture leaves continuous aisle: " + id)
        check(Layout.zones_cover_station((station["center"] as Vector2).y),
            "fixture belongs to a deck station: " + id)
    for z in [-3.8, -2.1, -1.3, 0.0, 1.64, 3.8]:
        check(Layout.zones_cover_station(z), "continuous station geography: " + str(z))
    # Opposing furniture cannot collide if migrated to proper physics geometry.
    for first in range(items.size()):
        for second in range(first + 1, items.size()):
            var a: Vector2 = items[first]["center"]
            var b: Vector2 = items[second]["center"]
            var ha: Vector2 = items[first]["half_footprint"]
            var hb: Vector2 = items[second]["half_footprint"]
            var overlaps: bool = absf(a.x - b.x) < ha.x + hb.x \
                and absf(a.y - b.y) < ha.y + hb.y
            check(not overlaps, "station rectangles do not overlap")
    var study := Study.new()
    root.add_child(study)
    await process_frame
    check(study.get_node_or_null("DeckFoundation") is MeshInstance3D,
        "real deck floor generated in Godot")
    check(study.get_node_or_null("InteriorReviewCamera") is Camera3D,
        "native camera is installed")
    check(study.get_node_or_null("PhaseDriveObservation/HarmonicRing") is MeshInstance3D,
        "engineering has inspectable noncanonical harmonic apparatus")
    for station in items:
        var base: Node3D = study.get_node_or_null("Fixture_" + str(station["id"]))
        check(base != null, "physical prop node exists: " + str(station["id"]))
        if base != null:
            check(base.get_node_or_null("Case") is MeshInstance3D,
                "prop has rendered case: " + str(station["id"]))
    for side in ["Port", "Starboard"]:
        check(study.get_node_or_null("AisleInlay_" + side) is MeshInstance3D,
            "aisle guide remains readable")
    study.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_SHIP_INTERIOR_STUDY_PASS checks=", count)
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_SHIP_INTERIOR_STUDY_FAIL: " + failure)
        quit(1)
