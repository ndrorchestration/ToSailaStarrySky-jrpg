extends RefCounted
## Review-only Chapter I migration inputs.
## Creates defaults only when actions do not already exist, preserving remaps.

const INTERACT := "aetherwake_ch1_interact"
const CHOICE_A := "aetherwake_ch1_choice_a"
const CHOICE_B := "aetherwake_ch1_choice_b"
const CHOICE_C := "aetherwake_ch1_choice_c"
const FORMULA_REVIEW := "aetherwake_ch1_formula_review"
const COMBAT_STRIKE := "aetherwake_ch1_combat_strike"
const COMBAT_ANALYZE := "aetherwake_ch1_combat_analyze"
const COMBAT_HOLD := "aetherwake_ch1_combat_hold"
const COMBAT_REST := "aetherwake_ch1_combat_rest"
const EQUIP_WEAPON_PREVIEW := "aetherwake_ch1_equip_weapon_preview"
const EQUIP_ARMOR_PREVIEW := "aetherwake_ch1_equip_armor_preview"
const EQUIP_ACCESSORY_PREVIEW := "aetherwake_ch1_equip_accessory_preview"
const SAVE_PROGRESS := "aetherwake_ch1_save_progress"
const LOAD_PROGRESS := "aetherwake_ch1_load_progress"

static func ensure_defaults() -> void:
    _ensure_key_and_pad(INTERACT, KEY_E, JOY_BUTTON_A)
    _ensure_key_and_pad(CHOICE_A, KEY_1, JOY_BUTTON_X)
    _ensure_key_and_pad(CHOICE_B, KEY_2, JOY_BUTTON_Y)
    _ensure_key_and_pad(CHOICE_C, KEY_3, JOY_BUTTON_B)
    _ensure_key_and_pad(FORMULA_REVIEW, KEY_C, JOY_BUTTON_RIGHT_SHOULDER)
    _ensure_key_and_pad(COMBAT_STRIKE, KEY_1, JOY_BUTTON_X)
    _ensure_key_and_pad(COMBAT_ANALYZE, KEY_2, JOY_BUTTON_Y)
    _ensure_key_and_pad(COMBAT_HOLD, KEY_3, JOY_BUTTON_B)
    _ensure_key_and_pad(COMBAT_REST, KEY_4, JOY_BUTTON_A)
    _ensure_key(EQUIP_WEAPON_PREVIEW, KEY_5)
    _ensure_key(EQUIP_ARMOR_PREVIEW, KEY_6)
    _ensure_key(EQUIP_ACCESSORY_PREVIEW, KEY_7)
    _ensure_key(SAVE_PROGRESS, KEY_F5)
    _ensure_key(LOAD_PROGRESS, KEY_F9)

static func primary_label(action: String) -> String:
    if not InputMap.has_action(action):
        return "Unbound"
    var events := InputMap.action_get_events(action)
    if events.is_empty():
        return "Unbound"
    for event in events:
        if event is InputEventKey:
            return event.as_text_keycode()
    return events[0].as_text()

static func _ensure_key_and_pad(action: String, keycode: Key, button: JoyButton) -> void:
    if InputMap.has_action(action):
        return
    InputMap.add_action(action)
    var key := InputEventKey.new()
    key.keycode = keycode
    InputMap.action_add_event(action, key)
    var pad := InputEventJoypadButton.new()
    pad.button_index = button
    InputMap.action_add_event(action, pad)

static func _ensure_key(action: String, keycode: Key) -> void:
    if InputMap.has_action(action):
        return
    InputMap.add_action(action)
    var key := InputEventKey.new()
    key.keycode = keycode
    InputMap.action_add_event(action, key)
