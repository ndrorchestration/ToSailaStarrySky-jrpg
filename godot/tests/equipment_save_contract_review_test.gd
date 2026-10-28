extends SceneTree
## P-03 review-only durable-data candidate and file-custody proof. NEVER
## writes or imports this format through the active First Wake v1 SaveStore.

const Chapter = preload("res://scripts/first_wake_chapter1_state.gd")
const ChapterCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")
const Session = preload("res://scripts/battle_equipment_session_review.gd")
const Codec = preload("res://scripts/equipment_save_contract_review.gd")
const Store = preload("res://scripts/equipment_save_store_review.gd")

func _initialize() -> void:
    call_deferred("_test")

func _fail(why: String) -> void:
    push_error("TSTSS_EQUIPMENT_P03_FAIL: " + why)
    quit(1)

func _reject(envelope: Dictionary, why: String) -> bool:
    if bool(Codec.validate(envelope).get("ok", false)):
        _fail("accepted invalid snapshot: " + why)
        return false
    return true

func _test() -> void:
    var chapter = Chapter.new()
    var original_v1: Dictionary = ChapterCodec.encode(chapter, {"hull_integrity": 96, "morale": 42, "engine_integration": 2}, Vector2(444, 476))
    if not bool(ChapterCodec.validate(original_v1).get("ok", false)):
        _fail("starting actual v1 chapter snapshot invalid")
        return
    var migration: Dictionary = Codec.preview_legacy_migration(original_v1)
    var migration_verdict: Dictionary = Codec.validate(migration)
    if not bool(migration_verdict.get("ok", false)) or bool(migration_verdict.get("ready", true)):
        _fail("legacy migration should be valid but NOT inventory-ready")
        return
    if not Dictionary(migration["roster"]).is_empty() or not Array(migration["instances"]).is_empty() or migration["chapterV1"] != original_v1:
        _fail("legacy migration invented owned items or altered story state")
        return
    var legacy_mutation: Dictionary = original_v1.duplicate(true)
    legacy_mutation["resolver_stats"]["morale"] = 99
    if Codec.preview_legacy_migration(legacy_mutation) == migration:
        _fail("old v1 snapshot did not retain its own independent resolver state")
        return
    var pending_tamper: Dictionary = migration.duplicate(true)
    pending_tamper["instances"] = [{"instanceId": "unexpected"}]
    if not _reject(pending_tamper, "unauthorized bootstrap during legacy migration"):
        return

    var live = Session.new()
    if not live.validate():
        _fail("verified P-02 in-memory session failed initial preflight")
        return
    var fixture: Dictionary = Codec.encode_test_fixture(live, original_v1)
    var valid_fixture: Dictionary = Codec.validate(fixture)
    if not bool(valid_fixture.get("ok", false)) or not bool(valid_fixture.get("ready", false)):
        _fail("fixture coding rejected all nine provenance-labelled test instances")
        return
    if fixture["instances"].size() != 9 or fixture["roster"].size() != 5:
        _fail("fixture was not exact roster and item cardinality")
        return
    var original_chapter_copy: Dictionary = fixture["chapterV1"].duplicate(true)
    if not live.trial_inventory.transfer(live.loadouts["ender"], "mainWeapon", "ender-staff-inlay-review"):
        _fail("existing P-02 source cannot perform legal owned staff transaction")
        return
    if not live.trial_inventory.transfer(live.loadouts["ender"], "bodyArmor", "ender-armor-overlay-review"):
        _fail("existing P-02 source cannot perform legal owned armor transaction")
        return
    if not live.trial_inventory.transfer(live.loadouts["ender"], "accessory", "ender-charm-review"):
        _fail("existing P-02 source cannot perform legal owned charm transaction")
        return
    var changed: Dictionary = Codec.encode_test_fixture(live, original_v1)
    if not bool(Codec.validate(changed).get("ready", false)):
        _fail("owned training transfers did not produce valid proposal snapshot")
        return
    if fixture == changed or changed["chapterV1"] != original_chapter_copy:
        _fail("owned gear swaps were lost or secretly changed chapter progression")
        return
    if changed["roster"]["ender"]["slots"]["mainWeapon"] != "fixture:ender-staff-inlay-review":
        _fail("swapped real owned loadout not represented by correct unique item instance")
        return
    if Codec.inspect(changed)["roster"]["ender"]["slots"]["bodyArmor"] != "fixture:ender-armor-overlay-review":
        _fail("decode inspection failed to retain owned armor")
        return
    var decoded: Dictionary = Codec.inspect(changed)
    decoded["instances"][0]["location"] = "forgery"
    if not bool(Codec.validate(changed).get("ok", false)):
        _fail("mutating detached inspection corrupted submitted candidate")
        return

    var roundtrip = JSON.parse_string(JSON.stringify(changed))
    if not bool(Codec.validate(roundtrip).get("ready", false)) or roundtrip != changed:
        _fail("JSON byte-safe round-trip of full review ownership was rejected")
        return
    var mutations: Array = []
    var dupe = changed.duplicate(true)
    dupe["instances"][1] = dupe["instances"][0].duplicate(true)
    mutations.append({"case": "duplicate-item-instance", "value": dupe})
    var extra = changed.duplicate(true)
    extra["newCanonFlag"] = true
    mutations.append({"case": "unapproved-envelope-key", "value": extra})
    var unknown = changed.duplicate(true)
    unknown["instances"][0]["definitionId"] = "new-unapproved-loot"
    mutations.append({"case": "invented-item-definition", "value": unknown})
    var count = changed.duplicate(true)
    count["instances"].pop_back()
    mutations.append({"case": "dropped-instance", "value": count})
    var same_slot = changed.duplicate(true)
    same_slot["roster"]["ender"]["slots"]["bodyArmor"] = same_slot["roster"]["ender"]["slots"]["mainWeapon"]
    mutations.append({"case": "equipped-twice", "value": same_slot})
    var wrong_actor = changed.duplicate(true)
    wrong_actor["roster"]["lyra"]["slots"]["mainWeapon"] = "fixture:ender-starter-staff"
    mutations.append({"case": "stolen-item", "value": wrong_actor})
    var wrong_owner = changed.duplicate(true)
    wrong_owner["instances"][0]["actorId"] = "lyra"
    mutations.append({"case": "owner-record-conflict", "value": wrong_owner})
    var unknown_provenance = changed.duplicate(true)
    unknown_provenance["instances"][0]["provenance"] = "claimed-loot-drop"
    mutations.append({"case": "unsupported-acquisition", "value": unknown_provenance})
    var unsafe_location = changed.duplicate(true)
    unsafe_location["instances"][0]["location"] = "ground"
    mutations.append({"case": "unauthorized-location", "value": unsafe_location})
    var malformed_story = changed.duplicate(true)
    malformed_story["chapterV1"]["stage"] = "done"
    mutations.append({"case": "contradictory-story", "value": malformed_story})
    var foreign_status = changed.duplicate(true)
    foreign_status["state"] = "production-approved"
    mutations.append({"case": "forged-approval", "value": foreign_status})
    var foreign_schema = changed.duplicate(true)
    foreign_schema["schema"] = "future.v9"
    mutations.append({"case": "unknown-version", "value": foreign_schema})
    for item in mutations:
        if not _reject(item["value"], str(item["case"])):
            return

    var file_store = Store.new()
    file_store.delete_review()
    var first: Dictionary = file_store.save_review(migration)
    if not bool(first.get("ok", false)) or not str(first.get("primary_sha256", "")).length() == 64:
        _fail("migration-pending candidate could not write verified test-slot generation")
        return
    var first_bytes_sha: String = FileAccess.get_sha256(Store.PATH)
    if first_bytes_sha != first["primary_sha256"]:
        _fail("first test-slot primary bytes not hash-bound")
        return
    var loaded_migration: Dictionary = file_store.load_review()
    if not bool(loaded_migration.get("ok", false)) or bool(Codec.validate(loaded_migration["snapshot"]).get("ready", true)):
        _fail("disk load illegitimately converted non-granting legacy migration into inventory")
        return

    var second: Dictionary = file_store.save_review(changed)
    if not bool(second.get("ok", false)) or not FileAccess.file_exists(Store.PATH + ".bak"):
        _fail("full fixture test save omitted verified backup")
        return
    if second["backup_sha256"] != first_bytes_sha or FileAccess.get_sha256(Store.PATH + ".bak") != first_bytes_sha:
        _fail("replaced original migration generation without hash-safe backup")
        return
    var actual: Dictionary = file_store.load_review()
    if not bool(actual.get("ok", false)) or actual["snapshot"] != changed or bool(actual.get("recovered", true)):
        _fail("valid P-03 fixture did not round-trip primary")
        return

    var pre_reject_sha: String = FileAccess.get_sha256(Store.PATH)
    if bool(file_store.save_review(dupe).get("ok", false)) or FileAccess.get_sha256(Store.PATH) != pre_reject_sha:
        _fail("rejected duplicate wrote into valid primary")
        return
    var corrupt := FileAccess.open(Store.PATH, FileAccess.WRITE)
    if corrupt == null:
        _fail("could not make controlled primary corruption fixture")
        return
    corrupt.store_string("{ broken-review-record")
    corrupt.close()
    var recovered: Dictionary = file_store.load_review()
    if not bool(recovered.get("ok", false)) or not bool(recovered.get("recovered", false)):
        _fail("corrupt primary did not recover known-good backup")
        return
    if bool(Codec.validate(recovered["snapshot"]).get("ready", true)):
        _fail("backup recovery was not exact previous-generation pending migration")
        return
    if not bool(file_store.save_review(changed).get("ok", false)):
        _fail("repair from corrupted primary rejected valid candidate")
        return
    corrupt = FileAccess.open(Store.PATH, FileAccess.WRITE)
    corrupt.store_string("{ damaged-again")
    corrupt.close()
    if FileAccess.get_sha256(Store.PATH + ".bak") != first_bytes_sha:
        _fail("repair overwrote known-good backup with corrupt primary")
        return
    var recovered_again: Dictionary = file_store.load_review()
    if not bool(recovered_again.get("recovered", false)):
        _fail("known-good backup not retained after repair")
        return
    var bad_backup := FileAccess.open(Store.PATH + ".bak", FileAccess.WRITE)
    bad_backup.store_string("{ both-invalid")
    bad_backup.close()
    if bool(file_store.load_review().get("ok", true)):
        _fail("two corrupt versions incorrectly passed load validation")
        return
    file_store.delete_review()
    if FileAccess.file_exists(Store.PATH) or FileAccess.file_exists(Store.PATH + ".bak"):
        _fail("test slot cleanup left an owned item record on disk")
        return
    if not bool(ChapterCodec.validate(original_v1).get("ok", false)) or original_v1 != original_chapter_copy:
        _fail("active Chapter I v1 snapshot was changed by offline equipment contract")
        return
    print("TSTSS_EQUIPMENT_P03_PASS: legacy migration yields ZERO grants; nine developer-only instances; five actor records; corrupt/duplicate/forged items denied; atomic test-slot backup and v1 source preserved")
    quit(0)
