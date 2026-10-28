extends RefCounted
## P-03 DATA CONTRACT ONLY. Never used by First Wake's active SaveStore.
## Only developer-review item instances are eligible. Old v1 story saves
## migrate into a QUARANTINED, NON-GRANTING state until item bootstrap is
## specifically authorized. This is not a real loot, trade, or save system.

const ChapterCodec = preload("res://scripts/first_wake_chapter1_save_codec.gd")
const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const Session = preload("res://scripts/battle_equipment_session_review.gd")

const SCHEMA := "tstss.equipment.study.v0"
const FIXTURE_STATE := "review-fixture-only"
const PENDING_STATE := "legacy-pending-authorization"
const FIXTURE_IDS: Array[String] = [
    "ender-starter-staff",
    "ender-staff-inlay-review",
    "ender-armor-overlay-review",
    "ender-charm-review",
    "lyra-starter-chakram",
    "ionia-starter-mace",
    "reson-starter-sword",
    "reson-starter-rifle",
    "aepex-martial-arts",
]
const REQUIRED_KEYS: Array[String] = ["schema", "state", "chapterV1", "roster", "instances"]

static func preview_legacy_migration(chapter_v1: Dictionary) -> Dictionary:
    if not bool(ChapterCodec.validate(chapter_v1).get("ok", false)):
        return {}
    if chapter_v1.has("inventory") or chapter_v1.has("equipment"):
        return {}
    # No item instance is invented during a backward-compatible migration.
    return {
        "schema": SCHEMA,
        "state": PENDING_STATE,
        "chapterV1": chapter_v1.duplicate(true),
        "roster": {},
        "instances": [],
    }

static func encode_test_fixture(session, chapter_v1: Dictionary) -> Dictionary:
    if session == null or not session.validate():
        return {}
    if not bool(ChapterCodec.validate(chapter_v1).get("ok", false)):
        return {}
    if chapter_v1.has("inventory") or chapter_v1.has("equipment"):
        return {}

    var roster: Dictionary = {}
    for actor_id in Session.ACTOR_IDS:
        var loadout = session.loadouts[actor_id]
        var equipment: Dictionary = {}
        for slot_id in Loadout.SLOTS:
            var definition_id: String = loadout.item_id_for(slot_id)
            equipment[slot_id] = _instance_id(definition_id) if not definition_id.is_empty() else ""
        roster[actor_id] = {
            "slots": equipment,
            "heldSlot": str(loadout.held_slot),
        }

    var instances: Array = []
    for definition_id in FIXTURE_IDS:
        var definition: Dictionary = Loadout.ITEMS[definition_id]
        var actor_id: String = str(definition["owner"])
        var slot_id: String = str(definition["slot"])
        var equipped: bool = str(roster[actor_id]["slots"][slot_id]) == _instance_id(definition_id)
        instances.append({
            "instanceId": _instance_id(definition_id),
            "definitionId": definition_id,
            "location": "equipped" if equipped else "bag",
            "actorId": actor_id if equipped else "",
            "slot": slot_id if equipped else "",
            "provenance": "developer-fixture-not-loot",
        })
    var result := {
        "schema": SCHEMA,
        "state": FIXTURE_STATE,
        "chapterV1": chapter_v1.duplicate(true),
        "roster": roster,
        "instances": instances,
    }
    return result if bool(validate(result).get("ok", false)) else {}

static func validate(raw: Variant) -> Dictionary:
    if not (raw is Dictionary):
        return _reject("envelope_not_dictionary")
    var envelope: Dictionary = raw
    if envelope.size() != REQUIRED_KEYS.size():
        return _reject("unexpected_or_missing_envelope_keys")
    for key in REQUIRED_KEYS:
        if not envelope.has(key):
            return _reject("missing_" + key)
    if typeof(envelope["schema"]) != TYPE_STRING or envelope["schema"] != SCHEMA:
        return _reject("unsupported_schema")
    if typeof(envelope["state"]) != TYPE_STRING:
        return _reject("state_type")
    if not (envelope["chapterV1"] is Dictionary):
        return _reject("chapter_v1_type")
    var chapter: Dictionary = envelope["chapterV1"]
    if not bool(ChapterCodec.validate(chapter).get("ok", false)):
        return _reject("chapter_v1_invalid")
    if chapter.has("inventory") or chapter.has("equipment") or chapter.has("trialBag"):
        return _reject("legacy_payload_leak")
    if not (envelope["roster"] is Dictionary) or not (envelope["instances"] is Array):
        return _reject("roster_or_instances_type")
    var roster: Dictionary = envelope["roster"]
    var records: Array = envelope["instances"]

    if envelope["state"] == PENDING_STATE:
        if not roster.is_empty() or not records.is_empty():
            return _reject("legacy_migration_granted_unauthorized_items")
        return {"ok": true, "ready": false, "error": ""}
    if envelope["state"] != FIXTURE_STATE:
        return _reject("unknown_item_authority")
    if roster.size() != Session.ACTOR_IDS.size() or records.size() != FIXTURE_IDS.size():
        return _reject("fixture_roster_or_instance_cardinality")

    var references: Dictionary = {}
    for actor_id in Session.ACTOR_IDS:
        if not roster.has(actor_id) or not (roster[actor_id] is Dictionary):
            return _reject("missing_actor_" + actor_id)
        var actor: Dictionary = roster[actor_id]
        if actor.size() != 2 or not actor.has("slots") or not actor.has("heldSlot"):
            return _reject("actor_shape_" + actor_id)
        if not (actor["slots"] is Dictionary) or typeof(actor["heldSlot"]) != TYPE_STRING:
            return _reject("actor_field_types_" + actor_id)
        var slots: Dictionary = actor["slots"]
        if slots.size() != Loadout.SLOTS.size():
            return _reject("actor_slot_cardinality_" + actor_id)
        for slot_id in Loadout.SLOTS:
            if not slots.has(slot_id) or typeof(slots[slot_id]) != TYPE_STRING:
                return _reject("actor_slot_shape_" + actor_id)
            var instance_id: String = slots[slot_id]
            if slot_id == "mainWeapon" and instance_id.is_empty():
                return _reject("actor_missing_primary_" + actor_id)
            if instance_id.is_empty():
                continue
            if references.has(instance_id):
                return _reject("item_equipped_more_than_once")
            references[instance_id] = {"actorId": actor_id, "slot": slot_id}
        var held: String = str(actor["heldSlot"])
        if held not in ["mainWeapon", "secondaryWeapon"] or str(slots.get(held, "")).is_empty():
            return _reject("invalid_held_weapon_" + actor_id)
        if actor_id != "ender":
            var expected: Dictionary = Loadout.STARTER_SLOTS[actor_id]
            for slot_id in Loadout.SLOTS:
                var starter: String = str(expected[slot_id])
                var expected_instance: String = _instance_id(starter) if not starter.is_empty() else ""
                if str(slots[slot_id]) != expected_instance:
                    return _reject("foreign_actor_fixture_gear_" + actor_id)
            if held != "mainWeapon" and actor_id != "reson":
                return _reject("foreign_actor_held_slot")
        elif held != "mainWeapon":
            return _reject("ender_unauthorized_secondary")

    var seen_instances: Dictionary = {}
    var seen_definitions: Dictionary = {}
    for raw_item in records:
        if not (raw_item is Dictionary):
            return _reject("instance_type")
        var item: Dictionary = raw_item
        if item.size() != 6:
            return _reject("instance_field_cardinality")
        for field in ["instanceId", "definitionId", "location", "actorId", "slot", "provenance"]:
            if not item.has(field) or typeof(item[field]) != TYPE_STRING:
                return _reject("instance_field_" + field)
        var iid: String = item["instanceId"]
        var definition_id: String = item["definitionId"]
        if definition_id not in FIXTURE_IDS or iid != _instance_id(definition_id):
            return _reject("unapproved_or_forged_instance_identity")
        if seen_instances.has(iid) or seen_definitions.has(definition_id):
            return _reject("duplicate_instance_or_definition")
        seen_instances[iid] = true
        seen_definitions[definition_id] = true
        if item["provenance"] != "developer-fixture-not-loot":
            return _reject("unapproved_acquisition_provenance")
        var definition: Dictionary = Loadout.ITEMS[definition_id]
        if item["location"] == "equipped":
            if not references.has(iid):
                return _reject("orphan_equipped_instance")
            var ref: Dictionary = references[iid]
            if item["actorId"] != ref["actorId"] or item["slot"] != ref["slot"]:
                return _reject("instance_owner_slot_mismatch")
            if item["actorId"] != definition["owner"] or item["slot"] != definition["slot"]:
                return _reject("definition_owner_slot_mismatch")
        elif item["location"] == "bag":
            if references.has(iid) or item["actorId"] != "" or item["slot"] != "":
                return _reject("bag_instance_equipped_or_has_owner")
        else:
            return _reject("unrecognized_location")
    if seen_instances.size() != FIXTURE_IDS.size():
        return _reject("missing_item_instances")
    # Every worn slot must resolve to a real instance. Otherwise a fake ID
    # in Ender's slot could masquerade as gear while the true item remains
    # in the bag: the duplication/ghost-item case must fail closed.
    for equipped_id in references.keys():
        if not seen_instances.has(equipped_id):
            return _reject("equipped_reference_without_owned_instance")
    return {"ok": true, "ready": true, "error": ""}

static func inspect(raw: Variant) -> Dictionary:
    var verdict: Dictionary = validate(raw)
    if not bool(verdict.get("ok", false)):
        return {"ok": false, "error": str(verdict.get("error", "invalid")), "ready": false}
    var envelope: Dictionary = raw
    return {
        "ok": true,
        "ready": bool(verdict["ready"]),
        "state": str(envelope["state"]),
        "chapterV1": Dictionary(envelope["chapterV1"]).duplicate(true),
        "roster": Dictionary(envelope["roster"]).duplicate(true),
        "instances": Array(envelope["instances"]).duplicate(true),
    }

static func _instance_id(definition_id: String) -> String:
    return "fixture:" + definition_id

static func _reject(code: String) -> Dictionary:
    return {"ok": false, "ready": false, "error": code}
