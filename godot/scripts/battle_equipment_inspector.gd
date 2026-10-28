extends RefCounted
## Review-only, read-before-commit gear inspector. It is not a real shop,
## inventory menu, skill tree, rarity system, or creator-approved item lore.
## All comparisons use immutable copies and the exact practice formula fixture.

const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const TrialInventory = preload("res://scripts/battle_equipment_trial_inventory.gd")
const Equipment = preload("res://scripts/battle_equipment_training_profile.gd")

const VERSION := "0.1.0-review"
const SLOTS := ["mainWeapon", "bodyArmor", "accessory"]
const LABELS := {
    "mainWeapon": "MAIN WEAPON",
    "bodyArmor": "BODY ARMOR",
    "accessory": "ACCESSORY",
}
const DESCRIPTIONS := {
    "ender-starter-staff": "Full-length fighting staff. Ender's basic martial gear; no spell required.",
    "ender-staff-inlay-review": "Silver-inlay staff LOOK STUDY. Trial power is not approved progression.",
    "ender-armor-overlay-review": "Brass chest-guard STUDY. Practice physical protection only.",
    "ender-charm-review": "Travel charm STUDY. Practice aether protection only; not plot Spirit magic.",
    "": "Empty optional slot. Keeps this piece of gear in the practice bag.",
}

var slot_index: int = 0
var choice_index: int = 0
var training = Equipment.new()

func current_slot() -> String:
    return str(SLOTS[slot_index])

func reset(loadout, inventory) -> bool:
    slot_index = 0
    choice_index = 0
    return _align(loadout, inventory)

func _available(loadout, inventory, slot_id: String) -> Array[String]:
    var result: Array[String] = []
    if not inventory.validate(loadout) or not Loadout.ENDER_REVIEW_CYCLE.has(slot_id):
        return result
    for id in Loadout.ENDER_REVIEW_CYCLE[slot_id]:
        var item_id: String = str(id)
        if item_id == loadout.item_id_for(slot_id) or item_id.is_empty() or inventory.count_in_bag(item_id) > 0:
            result.append(item_id)
    return result

func _align(loadout, inventory) -> bool:
    var options := _available(loadout, inventory, current_slot())
    if options.is_empty():
        return false
    choice_index = maxi(0, options.find(loadout.item_id_for(current_slot())))
    return true

func move_slot(delta: int, loadout, inventory) -> bool:
    if not inventory.validate(loadout):
        return false
    slot_index = posmod(slot_index + delta, SLOTS.size())
    return _align(loadout, inventory)

func move_choice(delta: int, loadout, inventory) -> bool:
    var options := _available(loadout, inventory, current_slot())
    if options.is_empty():
        return false
    choice_index = posmod(choice_index + delta, options.size())
    return true

func selected_item(loadout, inventory) -> String:
    var options := _available(loadout, inventory, current_slot())
    if options.is_empty() or choice_index < 0 or choice_index >= options.size():
        return ""
    return str(options[choice_index])

func selection_is_valid(loadout, inventory) -> bool:
    var options := _available(loadout, inventory, current_slot())
    return not options.is_empty() and choice_index >= 0 and choice_index < options.size()

func commit(loadout, inventory) -> bool:
    if not selection_is_valid(loadout, inventory):
        return false
    var item_id := selected_item(loadout, inventory)
    if not inventory.transfer(loadout, current_slot(), item_id):
        return false
    return _align(loadout, inventory)

func _simulation(loadout, inventory, slot_id: String, item_id: String) -> Dictionary:
    if not inventory.validate(loadout):
        return {}
    var candidate = Loadout.new(loadout.actor_id)
    candidate.slots = loadout.slots.duplicate(true)
    candidate.held_slot = loadout.held_slot
    candidate.visual_revision = loadout.visual_revision
    var bag_copy = TrialInventory.new()
    bag_copy.bag = inventory.bag.duplicate(true)
    if not bag_copy.transfer(candidate, slot_id, item_id):
        return {}
    return {"loadout": candidate, "bag": bag_copy}

func describe(loadout, inventory, primary_stats: Dictionary, level: int = 1) -> Dictionary:
    if not inventory.validate(loadout) or not selection_is_valid(loadout, inventory):
        return {}
    var slot_id := current_slot()
    var current_id: String = loadout.item_id_for(slot_id)
    var item_id := selected_item(loadout, inventory)
    var simulated := _simulation(loadout, inventory, slot_id, item_id)
    if simulated.is_empty():
        return {}
    var trial_loadout = simulated["loadout"]
    var before: Dictionary = training.project(loadout, primary_stats, level)
    var after: Dictionary = training.project(trial_loadout, primary_stats, level)
    if before.is_empty() or after.is_empty():
        return {}
    var before_bonuses: Dictionary = before["bonuses"]
    var after_bonuses: Dictionary = after["bonuses"]
    var physical_before := training.resolve_practice_hit(primary_stats, level, before_bonuses, "physical")
    var physical_after := training.resolve_practice_hit(primary_stats, level, after_bonuses, "physical")
    var aether_before := training.resolve_practice_hit(primary_stats, level, before_bonuses, "aether")
    var aether_after := training.resolve_practice_hit(primary_stats, level, after_bonuses, "aether")
    if physical_before.is_empty() or physical_after.is_empty() or aether_before.is_empty() or aether_after.is_empty():
        return {}
    var options := _available(loadout, inventory, slot_id)
    var item_name := "Unequipped" if item_id.is_empty() else str(Loadout.ITEMS[item_id].get("name", item_id))
    var current_name := "Unequipped" if current_id.is_empty() else str(Loadout.ITEMS[current_id].get("name", current_id))
    return {
        "status": "practice-inspect-no-canon",
        "slot": slot_id,
        "slotLabel": str(LABELS[slot_id]),
        "slotIndex": slot_index,
        "slots": SLOTS.duplicate(),
        "options": options.duplicate(),
        "optionIndex": choice_index,
        "itemId": item_id,
        "itemName": item_name,
        "currentId": current_id,
        "currentName": current_name,
        "description": str(DESCRIPTIONS.get(item_id, "Undocumented practice gear")),
        "ownedInBag": 0 if item_id.is_empty() else inventory.count_in_bag(item_id),
        "alreadyEquipped": item_id == current_id,
        "beforeStrike": int(before["equippedDamage"]),
        "afterStrike": int(after["equippedDamage"]),
        "beforePhysicalDefense": int(before["physicalDefense"]),
        "afterPhysicalDefense": int(after["physicalDefense"]),
        "beforeAetherDefense": int(before["aetherDefense"]),
        "afterAetherDefense": int(after["aetherDefense"]),
        "beforePhysicalHit": int(physical_before["damage"]),
        "afterPhysicalHit": int(physical_after["damage"]),
        "beforeAetherHit": int(aether_before["damage"]),
        "afterAetherHit": int(aether_after["damage"]),
    }
