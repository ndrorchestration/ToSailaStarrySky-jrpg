extends RefCounted
## Native equipment presentation contract, review-only until inventory/save/job
## permissions are admitted. Never grants combat actions or stat modifiers.
## Starter weapon families follow the creator-directed equipment draft, while
## the alternate looks and all armor/accessory items below are visual studies.

const VERSION := "0.1.0"
const SLOTS := ["mainWeapon", "secondaryWeapon", "bodyArmor", "accessory"]
const ITEMS := {
    "ender-starter-staff": {"slot": "mainWeapon", "owner": "ender", "family": "staff", "visual": "staff-brass", "name": "Fighting Staff", "status": "locked-family"},
    "ender-staff-inlay-review": {"slot": "mainWeapon", "owner": "ender", "family": "staff", "visual": "staff-silver-inlay", "name": "Inlaid Staff (study)", "status": "visual-proposal"},
    "lyra-starter-chakram": {"slot": "mainWeapon", "owner": "lyra", "family": "chakram", "visual": "chakram", "name": "Chakram", "status": "locked-family"},
    "ionia-starter-mace": {"slot": "mainWeapon", "owner": "ionia", "family": "mace", "visual": "mace", "name": "Mace", "status": "locked-family"},
    "reson-starter-sword": {"slot": "mainWeapon", "owner": "reson", "family": "sword", "visual": "sword", "name": "Sword", "status": "locked-family"},
    "reson-starter-rifle": {"slot": "secondaryWeapon", "owner": "reson", "family": "rifle", "visual": "rifle", "name": "Rifle", "status": "locked-family"},
    "aepex-martial-arts": {"slot": "mainWeapon", "owner": "aepex", "family": "unarmed", "visual": "unarmed", "name": "Martial Arts", "status": "locked-family"},
    "ender-armor-overlay-review": {"slot": "bodyArmor", "owner": "ender", "family": "armor-overlay", "visual": "brass-plate", "name": "Brass Guard (study)", "status": "visual-proposal"},
    "ender-charm-review": {"slot": "accessory", "owner": "ender", "family": "trinket", "visual": "small-charm", "name": "Travel Charm (study)", "status": "visual-proposal"},
}
const STARTER_SLOTS := {
    "ender": {"mainWeapon": "ender-starter-staff", "secondaryWeapon": "", "bodyArmor": "", "accessory": ""},
    "lyra": {"mainWeapon": "lyra-starter-chakram", "secondaryWeapon": "", "bodyArmor": "", "accessory": ""},
    "ionia": {"mainWeapon": "ionia-starter-mace", "secondaryWeapon": "", "bodyArmor": "", "accessory": ""},
    "reson": {"mainWeapon": "reson-starter-sword", "secondaryWeapon": "reson-starter-rifle", "bodyArmor": "", "accessory": ""},
    "aepex": {"mainWeapon": "aepex-martial-arts", "secondaryWeapon": "", "bodyArmor": "", "accessory": ""},
}
const ENDER_REVIEW_CYCLE := {
    "mainWeapon": ["ender-starter-staff", "ender-staff-inlay-review"],
    "bodyArmor": ["", "ender-armor-overlay-review"],
    "accessory": ["", "ender-charm-review"],
}

var actor_id: String = ""
var slots: Dictionary = {}
var held_slot: String = "mainWeapon"
var visual_revision: int = 0

func _init(character_id: String = "ender") -> void:
    actor_id = character_id
    reset_to_starter()

func reset_to_starter() -> bool:
    if not STARTER_SLOTS.has(actor_id):
        slots = {}
        return false
    slots = Dictionary(STARTER_SLOTS[actor_id]).duplicate(true)
    held_slot = "mainWeapon"
    visual_revision += 1
    return true

func item_for(slot_id: String) -> Dictionary:
    if slot_id not in SLOTS:
        return {}
    var item_id := str(slots.get(slot_id, ""))
    if not ITEMS.has(item_id):
        return {}
    return Dictionary(ITEMS[item_id]).duplicate(true)

func item_id_for(slot_id: String) -> String:
    return str(slots.get(slot_id, ""))

func equip(slot_id: String, item_id: String) -> bool:
    if not STARTER_SLOTS.has(actor_id) or slot_id not in SLOTS:
        return false
    if item_id.is_empty():
        # A character cannot remove their current basic fighting identity.
        if slot_id == "mainWeapon":
            return false
    else:
        if not ITEMS.has(item_id):
            return false
        var item: Dictionary = ITEMS[item_id]
        if str(item.get("owner", "")) != actor_id or str(item.get("slot", "")) != slot_id:
            return false
    if item_id_for(slot_id) == item_id:
        return true
    slots[slot_id] = item_id
    if held_slot == "secondaryWeapon" and item_id_for("secondaryWeapon").is_empty():
        held_slot = "mainWeapon"
    visual_revision += 1
    return true

func hold_weapon_slot(slot_id: String) -> bool:
    if slot_id not in ["mainWeapon", "secondaryWeapon"] or item_for(slot_id).is_empty():
        return false
    if held_slot != slot_id:
        held_slot = slot_id
        visual_revision += 1
    return true

func cycle_ender_review(slot_id: String) -> bool:
    if actor_id != "ender" or not ENDER_REVIEW_CYCLE.has(slot_id):
        return false
    var choices: Array = ENDER_REVIEW_CYCLE[slot_id]
    var next := (choices.find(item_id_for(slot_id)) + 1) % choices.size()
    return equip(slot_id, str(choices[next]))

func appearance() -> Dictionary:
    if slots.is_empty():
        return {}
    var held: Dictionary = item_for(held_slot)
    return {
        "actorId": actor_id,
        "heldSlot": held_slot,
        "weaponId": item_id_for(held_slot),
        "weaponName": str(held.get("name", "")),
        "weaponFamily": str(held.get("family", "")),
        "weaponVisual": str(held.get("visual", "")),
        "armorVisual": str(item_for("bodyArmor").get("visual", "")),
        "accessoryVisual": str(item_for("accessory").get("visual", "")),
        "visualRevision": visual_revision,
        "status": str(held.get("status", "")),
    }

func validate() -> bool:
    if slots.is_empty():
        return false
    for slot_id in SLOTS:
        var item_id := item_id_for(slot_id)
        if slot_id == "mainWeapon" and item_id.is_empty():
            return false
        if item_id.is_empty():
            continue
        if not ITEMS.has(item_id):
            return false
        var item: Dictionary = ITEMS[item_id]
        if str(item.get("slot", "")) != slot_id or str(item.get("owner", "")) != actor_id:
            return false
    return not item_for(held_slot).is_empty()
