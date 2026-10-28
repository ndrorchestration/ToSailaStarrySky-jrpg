extends SceneTree
## FAIL-CLOSED pilot: candidate screen-side stance labels are NOT artist-approved feet.
## Measure source-alpha candidate world displacement over explicit two-phase windows.
const Stance = preload("res://scripts/character_stance_hypothesis.gd")
const NAMES: Array[String] = ["Lyra", "Aepex", "Reson"]
const FACINGS: Array[String] = ["south", "west", "north", "east"]
const SIDES: Array[String] = ["screen_left", "screen_right"]

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String, code: int) -> void:
    push_error("STANCE_CANDIDATE_FAIL: " + message)
    quit(code)

func _verify() -> void:
    if Stance.annotation("Bogus", "south", 0).get("valid", true):
        _fail("unknown character accepted", 1)
        return
    if Stance.annotation("Lyra", "diagonal", 0).get("valid", true):
        _fail("unknown view accepted", 2)
        return
    if Stance.annotation("Lyra", "south", -1).get("valid", true) or Stance.annotation("Lyra", "south", 6).get("valid", true):
        _fail("outside phase range accepted", 3)
        return

    var rows := 0
    var candidate_left := 0
    var candidate_right := 0
    var unmarked := 0
    for character_id in NAMES:
        for facing in FACINGS:
            for phase in range(6):
                var spec: Dictionary = Stance.annotation(character_id, facing, phase)
                if not spec.get("valid", false) or spec.get("stance_certified", true) or spec.get("anatomical_foot_identified", true):
                    _fail("spec pretends phase is approved foot plant", 4)
                    return
                var side: String = spec["candidate_screen_side"]
                if side == Stance.SCREEN_LEFT:
                    candidate_left += 1
                elif side == Stance.SCREEN_RIGHT:
                    candidate_right += 1
                elif side == Stance.UNKNOWN:
                    unmarked += 1
                else:
                    _fail("invalid screen-side enum", 5)
                    return
                rows += 1
    if rows != 72 or candidate_left != 24 or candidate_right != 24 or unmarked != 24:
        _fail("not all 72 unapproved candidate labels are explicit", 6)
        return

    var stage = load("res://scenes/three_character_physics_walk_review.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    if stage.stance_guides_enabled or stage.source_guides_enabled:
        _fail("diagnostic layers visible without opt-in", 7)
        return
    var origins := {}
    for character_id in NAMES:
        var actor = stage.get_actor(character_id)
        if actor == null or actor.review_enabled:
            _fail("review actor missing or moving without consent", 8)
            return
        origins[character_id] = actor.global_position
        if Stance.world_support(actor, "south", 0, Stance.UNKNOWN).get("valid", true):
            _fail("unknown phase was treated as stance foot", 9)
            return
        if Stance.world_support(actor, "south", 0, "anatomical_left").get("valid", true):
            _fail("unsupported anatomical label accepted", 10)
            return

    stage.set_stance_guides_enabled(true)
    if not stage.stance_guides_enabled or stage.source_guides_enabled:
        _fail("stance overlay toggle interferes with source-alpha guide", 11)
        return
    for character_id in NAMES:
        if not stage.stance_guides[character_id].visible or stage.get_actor(character_id).global_position != origins[character_id]:
            _fail("overlay changed actor world transform", 12)
            return

    var last_key := {}
    var started := {}
    var counts := {}
    var peaks := {}
    for character_id in NAMES:
        last_key[character_id] = ""
        started[character_id] = Vector2.ZERO
        counts[character_id] = {}
        peaks[character_id] = {}
        for facing in FACINGS:
            counts[character_id][facing] = {"screen_left": 0, "screen_right": 0}
            peaks[character_id][facing] = {"screen_left": 0.0, "screen_right": 0.0}

    stage.start_all()
    var physical_ticks := 0
    for tick in range(320):
        await physics_frame
        var any_running := false
        for character_id in NAMES:
            var actor = stage.get_actor(character_id)
            if actor.completed:
                continue
            any_running = true
            physical_ticks += 1
            var facing: String = actor.facing
            var phase: int = actor.current_phase
            var spec: Dictionary = Stance.annotation(character_id, facing, phase)
            if not spec.get("valid", false):
                _fail("moving actor generated invalid source phase", 13)
                return
            var side: String = spec["candidate_screen_side"]
            if side == Stance.UNKNOWN:
                last_key[character_id] = ""
                continue
            var sample: Dictionary = Stance.world_support(actor, facing, phase, side)
            if not sample.get("valid", false):
                _fail("proposed marker absent in imported atlas " + character_id + " " + facing, 14)
                return
            var candidate: Vector2 = sample["world_pixel"]
            var key: String = facing + ":" + side
            if key != last_key[character_id]:
                last_key[character_id] = key
                started[character_id] = candidate
                counts[character_id][facing][side] += 1
            else:
                var slip: float = candidate.distance_to(started[character_id])
                peaks[character_id][facing][side] = maxf(float(peaks[character_id][facing][side]), slip)
        if not any_running:
            break
    if physical_ticks < 700:
        _fail("not enough real movement ticks collected", 15)
        return
    for character_id in NAMES:
        var actor = stage.get_actor(character_id)
        if not actor.completed or actor.global_position.distance_to(origins[character_id]) > 0.1:
            _fail("closed physics route changed by candidate overlay", 16)
            return
        for facing in FACINGS:
            for side in SIDES:
                var windows: int = counts[character_id][facing][side]
                var slip: float = peaks[character_id][facing][side]
                if windows < 1 or slip <= 1.0 or slip >= 100.0:
                    _fail("missing/implausible candidate window " + character_id + "/" + facing + "/" + side, 17)
                    return
                print("STANCE_CANDIDATE_WORLD_DRIFT:%s:%s:%s:windows=%d:max_drift=%.2f:NOT_ARTIST_MARKED" % [
                    character_id, facing, side, windows, slip])
    stage.set_stance_guides_enabled(false)
    if stage.stance_guides_enabled or stage.source_guides_enabled:
        _fail("overlay opt-out failed", 18)
        return
    for character_id in NAMES:
        if stage.stance_guides[character_id].visible:
            _fail("candidate overlay still visible", 19)
            return
    print("STANCE_CANDIDATE_AUDIT_PASS: 72 explicitly provisional labels, 24 directional side windows, actual physics-world drift and reversible opt-in")
    print("STANCE_CANDIDATE_REAL_PLANTED_FOOT_CERTIFICATION=UNAVAILABLE")
    quit(0)
