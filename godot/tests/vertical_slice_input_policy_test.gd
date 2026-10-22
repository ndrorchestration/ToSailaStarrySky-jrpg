extends SceneTree
## Asset-independent named-input contract for the review slice.

const InputPolicy = preload("res://scripts/vertical_slice_input_policy.gd")

func _initialize() -> void:
    for action in [InputPolicy.INTERACT, InputPolicy.CHOICE_PRIMARY, InputPolicy.CHOICE_SECONDARY, InputPolicy.HISTORY]:
        if InputMap.has_action(action):
            InputMap.erase_action(action)
    InputPolicy.ensure_defaults()
    for action in [InputPolicy.INTERACT, InputPolicy.CHOICE_PRIMARY, InputPolicy.CHOICE_SECONDARY, InputPolicy.HISTORY]:
        if not InputMap.has_action(action) or InputMap.action_get_events(action).size() < 2:
            push_error("AETHERWAKE_INPUT_POLICY_FAIL: missing keyboard/controller defaults for " + action)
            quit(1)
            return
    if InputPolicy.primary_label(InputPolicy.INTERACT) != "E":
        push_error("AETHERWAKE_INPUT_POLICY_FAIL: prompt label does not follow interact key")
        quit(1)
        return
    if InputPolicy.primary_label(InputPolicy.HISTORY) != "H":
        push_error("AETHERWAKE_INPUT_POLICY_FAIL: dialogue-history binding missing")
        quit(1)
        return
    # Existing remaps must be preserved rather than overwritten.
    InputMap.erase_action(InputPolicy.INTERACT)
    InputMap.add_action(InputPolicy.INTERACT)
    var custom := InputEventKey.new()
    custom.keycode = KEY_F
    InputMap.action_add_event(InputPolicy.INTERACT, custom)
    InputPolicy.ensure_defaults()
    if InputPolicy.primary_label(InputPolicy.INTERACT) != "F" or InputMap.action_get_events(InputPolicy.INTERACT).size() != 1:
        push_error("AETHERWAKE_INPUT_POLICY_FAIL: ensure_defaults overwrote a custom remap")
        quit(1)
        return
    print("AETHERWAKE_INPUT_POLICY_PASS: keyboard/controller defaults exist and custom remap is preserved")
    quit(0)
