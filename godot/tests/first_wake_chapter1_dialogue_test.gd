extends SceneTree
## Contract for migrated First Wake multi-line contact dialogue sequencing.

const Content = preload("res://scripts/first_wake_chapter1_content.gd")
const DialogueState = preload("res://scripts/first_wake_chapter1_dialogue_state.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var expected := {
        "elder_farmer": "Ionia",
        "engine_spirit": "Wakeheart",
        "child_prophet": "Lyra",
        "corporate_salvager": "Verrick",
    }

    for contact_id in expected.keys():
        var source_lines := Content.contact_intro(contact_id)
        if source_lines.size() != 5:
            _fail(contact_id + " intro must contain exactly five packaged lines")
            return

        var dialogue = DialogueState.new()
        if not dialogue.begin_contact(contact_id):
            _fail("could not begin dialogue for " + contact_id)
            return
        if dialogue.speaker_name() != expected[contact_id]:
            _fail("speaker mismatch for " + contact_id)
            return
        if dialogue.current_line() != source_lines[0]:
            _fail("first line mismatch for " + contact_id)
            return

        for index in range(1, source_lines.size()):
            if not dialogue.advance_or_close():
                _fail("advance rejected for " + contact_id)
                return
            if not dialogue.open or dialogue.line_index != index:
                _fail("cursor mismatch for " + contact_id)
                return
            if dialogue.current_line() != source_lines[index]:
                _fail("line mismatch for " + contact_id + " at " + str(index))
                return

        if not dialogue.advance_or_close():
            _fail("final close rejected for " + contact_id)
            return
        if dialogue.open or not dialogue.current_line().is_empty():
            _fail("dialogue did not close cleanly for " + contact_id)
            return

    var invalid = DialogueState.new()
    if invalid.begin_contact("not_a_contact"):
        _fail("unknown contact dialogue opened")
        return
    if invalid.advance_or_close():
        _fail("closed dialogue advanced")
        return

    print("AETHERWAKE_GODOT_CHAPTER1_DIALOGUE_PASS: four authored five-line contact intros advance and close deterministically")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_DIALOGUE_FAIL: " + reason)
    quit(1)
