extends RefCounted
## P-02 review-only session authority. This is NOT a durable player inventory,
## loot acquisition, job permission service, save codec, or canonical roster.
## One authority owns all five starter-family identities and Ender's pre-seeded
## practice bag while separate disposable Godot scenes are instantiated.
##
## The permanent Chapter I save remains aetherwake.first-wake.chapter1.v1.
## This object exists only in memory until intentionally discarded.

const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const TrialInventory = preload("res://scripts/battle_equipment_trial_inventory.gd")

const VERSION := "0.1.0-session-review"
const STATUS := "volatile-noncanonical-equipment-session"
const ACTOR_IDS: Array[String] = ["ender", "lyra", "ionia", "reson", "aepex"]
const STUDY_SCRIPT := "res://scripts/first_wake_chapter1_review.gd"

var loadouts: Dictionary = {}
var trial_inventory = TrialInventory.new()
var transition_count: int = 0

func _init() -> void:
    for actor_id in ACTOR_IDS:
        loadouts[actor_id] = Loadout.new(actor_id)

func validate() -> bool:
    if loadouts.size() != ACTOR_IDS.size() or loadouts.keys().size() != ACTOR_IDS.size():
        return false
    for actor_id in ACTOR_IDS:
        if not loadouts.has(actor_id) or not (loadouts[actor_id] is RefCounted):
            return false
        var loadout = loadouts[actor_id]
        if loadout.actor_id != actor_id or not loadout.validate():
            return false
        # Non-Ender actors have family presentation studies only. The study
        # does NOT seed their inventory, grant equippable gear or combat turns.
        if actor_id != "ender" and loadout.slots != Loadout.STARTER_SLOTS[actor_id]:
            return false
        if actor_id != "ender" and loadout.held_slot == "secondaryWeapon" and actor_id != "reson":
            return false
    return trial_inventory.validate(loadouts["ender"])

func loadout_for(actor_id: String):
    if actor_id not in ACTOR_IDS or not validate():
        return null
    return loadouts[actor_id]

func snapshot() -> Dictionary:
    if not validate():
        return {}
    var rows: Dictionary = {}
    for actor_id in ACTOR_IDS:
        var loadout = loadouts[actor_id]
        rows[actor_id] = {
            "slots": loadout.slots.duplicate(true),
            "heldSlot": str(loadout.held_slot),
            "appearance": loadout.appearance().duplicate(true),
        }
    return {
        "status": STATUS,
        "version": VERSION,
        "roster": rows.duplicate(true),
        "trialBag": trial_inventory.bag.duplicate(true),
        "transitions": transition_count,
    }

func bind_study_scene(scene: Node2D) -> bool:
    # Every boundary is checked BEFORE changing either scene or session.
    if not validate() or not is_instance_valid(scene) or not scene.is_inside_tree():
        return false
    var script: Script = scene.get_script()
    if script == null or script.resource_path != STUDY_SCRIPT:
        return false
    if not scene.equipment_station_review_enabled or scene.field_gear_display == null:
        return false
    if scene.formula_encounter.active or scene.gear_inspector_open or scene.dialogue.open:
        return false
    if not scene.active_hazard_encounter_id.is_empty():
        return false
    if scene.battle_loadout.actor_id != "ender" or not scene.trial_inventory.validate(scene.battle_loadout):
        return false
    if scene.field_gear_display == null or scene.battle_equipment_view == null:
        return false

    # Rebind references, do not copy the owned bag or duplicate a loadout.
    # The same loadout object now feeds the station, field study rig, native
    # Formula Review and the next new study scene after the previous is freed.
    scene.battle_loadout = loadouts["ender"]
    scene.trial_inventory = trial_inventory
    var appearance: Dictionary = loadouts["ender"].appearance()
    scene.battle_equipment_view.set_appearance(appearance)
    scene.field_gear_display.set_appearance(appearance)
    transition_count += 1
    return true
