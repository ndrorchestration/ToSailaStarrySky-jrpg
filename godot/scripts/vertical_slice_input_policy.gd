extends RefCounted
## Review-only named input actions. Keeps interaction prompts binding-aware and
## prepares controller/remapping work without changing production input authority.

const INTERACT := "aetherwake_interact"
const CHOICE_PRIMARY := "aetherwake_choice_primary"
const CHOICE_SECONDARY := "aetherwake_choice_secondary"

static func ensure_defaults() -> void:
    _ensure_key_and_pad(INTERACT, KEY_E, JOY_BUTTON_A)
    _ensure_key_and_pad(CHOICE_PRIMARY, KEY_1, JOY_BUTTON_X)
    _ensure_key_and_pad(CHOICE_SECONDARY, KEY_2, JOY_BUTTON_Y)

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
