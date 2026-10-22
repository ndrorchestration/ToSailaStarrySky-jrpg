extends SceneTree
## Contract for the fail-closed current-story enemy adapter.

const Adapter = preload("res://scripts/first_wake_current_enemy_adapter.gd")
const Content = preload("res://scripts/first_wake_chapter1_content.gd")
const StatModel = preload("res://scripts/jrpg_stat_model.gd")

func _initialize() -> void:
    var adapter = Adapter.new()
    var stat_model = StatModel.new()

    if Adapter.VERSION != "0.1.0":
        _fail("adapter version drifted")
        return
    if Content.hazard_label("wind_shear") != "Wind Shear":
        _fail("current Chapter I Wind Shear label drifted")
        return
    if not adapter.supports_hazard("wind_shear"):
        _fail("current Wind Shear hazard was not admitted")
        return
    if adapter.supports_hazard("sky_predator"):
        _fail("renamed Loose Cargo Sweep was incorrectly mapped to combat")
        return
    if adapter.supports_hazard("corporate_intercept"):
        _fail("Dock Authority Hold was incorrectly mapped to combat")
        return
    if not adapter.target_for_hazard("sky_predator").is_empty():
        _fail("unsupported Loose Cargo Sweep produced a combat target")
        return
    if not adapter.target_for_hazard("corporate_intercept").is_empty():
        _fail("unsupported authority hold produced a combat target")
        return

    var target := adapter.target_for_hazard("wind_shear")
    if target.is_empty() or not adapter.validate_target(target):
        _fail("Wind Shear target failed adapter validation")
        return
    if str(target.get("id", "")) != "windShear":
        _fail("live enemy id drifted")
        return
    if str(target.get("name", "")) != "Harmonic Shear Elemental":
        _fail("current story-facing enemy name drifted")
        return
    if int(target.get("hp", 0)) != 14 or int(target.get("maxHp", 0)) != 14:
        _fail("live Wind Shear HP was not preserved")
        return
    if str(target.get("weakness", "")).find("Uncover Truth") < 0 or str(target.get("weakness", "")).find("EMP") < 0:
        _fail("current Wind Shear weakness copy drifted")
        return
    if str(target.get("encounterKind", "")) != "authored_hazard":
        _fail("adapter did not mark authored hazard mode")
        return
    if str(target.get("hazardId", "")) != "wind_shear":
        _fail("hazard identity was not retained")
        return

    var legacy: Dictionary = target.get("legacyPrimaryStats", {})
    if int(legacy.get("might", -1)) != 2 or int(legacy.get("grace", -1)) != 0 or int(legacy.get("wits", -1)) != 1:
        _fail("live legacy Wind Shear primaries drifted")
        return

    var migrated: Dictionary = target.get("productionPrimaryStats", {})
    var expected_primary := {
        "might": 2,
        "grace": 1,
        "wits": 1,
        "spirit": 1,
        "presence": 1,
    }
    if migrated != expected_primary:
        _fail("production primary migration drifted: " + str(migrated))
        return

    var expected_derived := stat_model.derive(expected_primary, 1)
    var actual_derived: Dictionary = target.get("productionDerivedStats", {})
    if int(actual_derived.get("aetherDefense", -1)) != int(expected_derived.get("aetherDefense", -2)):
        _fail("aether defense was not derived by the production stat model")
        return
    if int(actual_derived.get("evasion", -1)) != int(expected_derived.get("evasion", -2)):
        _fail("evasion was not derived by the production stat model")
        return

    var tampered := target.duplicate(true)
    tampered["adapterSource"] = "invented"
    if adapter.validate_target(tampered):
        _fail("tampered adapter provenance was accepted")
        return

    print("AETHERWAKE_GODOT_CURRENT_ENEMY_ADAPTER_PASS: only current Wind Shear maps to combat; live metadata preserved and production defense/evasion derived")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CURRENT_ENEMY_ADAPTER_FAIL: " + reason)
    quit(1)
