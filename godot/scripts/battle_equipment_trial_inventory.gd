extends RefCounted
## Ephemeral equipment transaction boundary for the optional battle review.
## This ledger is a fixed, noncanonical practice fixture, NOT world inventory.
## Never acquires loot, changes story economy, grants a combat turn, or saves.
##
## One unit each: Ender's starting staff (equipped), silver-inlay staff,
## brass-guard chest study, travel-charm study. Every transaction conserves
## ownership across the worn slots and trial bag or it is rejected entirely.

const Loadout = preload("res://scripts/battle_equipment_loadout.gd")

const VERSION := "0.1.0-review"
const ACTOR_ID := "ender"
const OWNED_TOTALS := {
    "ender-starter-staff": 1,
    "ender-staff-inlay-review": 1,
    "ender-armor-overlay-review": 1,
    "ender-charm-review": 1,
}
const INITIAL_BAG := {
    "ender-starter-staff": 0,
    "ender-staff-inlay-review": 1,
    "ender-armor-overlay-review": 1,
    "ender-charm-review": 1,
}

var bag: Dictionary = {}
var revision: int = 0

func _init() -> void:
    reset()

func reset() -> void:
    bag = INITIAL_BAG.duplicate(true)
    revision += 1

func count_in_bag(item_id: String) -> int:
    if not OWNED_TOTALS.has(item_id):
        return 0
    return int(bag.get(item_id, 0))

func snapshot() -> Dictionary:
    return {
        "status": "temporary-practice-inventory",
        "version": VERSION,
        "bag": bag.duplicate(true),
        "revision": revision,
    }

func validate(loadout) -> bool:
    if loadout == null or loadout.actor_id != ACTOR_ID or not loadout.validate():
        return false
    if bag.size() != OWNED_TOTALS.size():
        return false
    var counts: Dictionary = {}
    for item_id in OWNED_TOTALS.keys():
        var amount = bag.get(item_id, null)
        if not (amount is int) or int(amount) < 0 or int(amount) > int(OWNED_TOTALS[item_id]):
            return false
        counts[item_id] = int(amount)
    for slot_id in Loadout.SLOTS:
        var worn_id: String = loadout.item_id_for(slot_id)
        if worn_id.is_empty():
            continue
        if not counts.has(worn_id):
            return false
        var item: Dictionary = loadout.item_for(slot_id)
        if item.is_empty() or str(item.get("slot", "")) != slot_id or str(item.get("owner", "")) != ACTOR_ID:
            return false
        counts[worn_id] = int(counts[worn_id]) + 1
    for item_id in OWNED_TOTALS.keys():
        if int(counts[item_id]) != int(OWNED_TOTALS[item_id]):
            return false
    return true

func transfer(loadout, slot_id: String, next_item_id: String) -> bool:
    if not validate(loadout) or slot_id not in Loadout.SLOTS:
        return false
    var previous_id: String = loadout.item_id_for(slot_id)
    if previous_id == next_item_id:
        return true
    if next_item_id.is_empty() and slot_id == "mainWeapon":
        return false
    if not next_item_id.is_empty():
        if not OWNED_TOTALS.has(next_item_id) or count_in_bag(next_item_id) < 1:
            return false
        var next_item: Dictionary = Loadout.ITEMS.get(next_item_id, {})
        if str(next_item.get("slot", "")) != slot_id or str(next_item.get("owner", "")) != ACTOR_ID:
            return false

    var previous_bag: Dictionary = bag.duplicate(true)
    var previous_slots: Dictionary = loadout.slots.duplicate(true)
    var previous_held: String = loadout.held_slot
    var previous_revision: int = int(loadout.visual_revision)
    var new_bag: Dictionary = bag.duplicate(true)
    if not previous_id.is_empty():
        new_bag[previous_id] = int(new_bag[previous_id]) + 1
    if not next_item_id.is_empty():
        new_bag[next_item_id] = int(new_bag[next_item_id]) - 1
    if int(new_bag.get(next_item_id, 0)) < 0:
        return false

    if not loadout.equip(slot_id, next_item_id):
        return false
    bag = new_bag
    if not validate(loadout):
        # A rejected transaction restores both authorities, including the
        # visual revision and held weapon selection, without side effects.
        bag = previous_bag
        loadout.slots = previous_slots
        loadout.held_slot = previous_held
        loadout.visual_revision = previous_revision
        return false
    revision += 1
    return true

func cycle_ender_review(loadout, slot_id: String) -> bool:
    if not validate(loadout) or not Loadout.ENDER_REVIEW_CYCLE.has(slot_id):
        return false
    var choices: Array = Loadout.ENDER_REVIEW_CYCLE[slot_id]
    var at: int = choices.find(loadout.item_id_for(slot_id))
    if at < 0:
        return false
    return transfer(loadout, slot_id, str(choices[(at + 1) % choices.size()]))
