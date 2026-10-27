extends SceneTree
## Chapter I choice receipt is a derivation, never an ending rewrite.

const Receipt = preload("res://scripts/first_wake_choice_receipt.gd")
const Content = preload("res://scripts/first_wake_chapter1_content.gd")

func _initialize() -> void:
    for path_id in ["path_a", "path_b", "path_c"]:
        for variant in ["10+", "7-9"]:
            var receipt: Dictionary = Receipt.build(path_id, variant)
            if not bool(receipt.get("ok", false)):
                _fail("authored outcome missing: %s/%s" % [path_id, variant])
                return
            if str(receipt.get("choice_label", "")) != Content.choice_label(path_id):
                _fail("choice label drift: %s" % path_id)
                return
            if str(receipt.get("authored_outcome", "")) != Content.choice_outcome(path_id, variant):
                _fail("outcome text drift: %s/%s" % [path_id, variant])
                return
            if bool(receipt.get("legacy_departure_conflict", true)):
                _fail("an unresolved legacy epilogue was incorrectly marked in conflict")
                return

    var default_a := Receipt.build("path_a", "10+", "epiline_1")
    var default_b := Receipt.build("path_b", "10+", "epiline_1")
    var default_c := Receipt.build("path_c", "10+", "epiline_1")
    if not bool(default_a.get("ok", false)) or bool(default_a.get("legacy_departure_conflict", true)):
        _fail("correct departure path was misidentified")
        return
    if not bool(default_b.get("legacy_departure_conflict", false)):
        _fail("hold-dock/default legacy departure contradiction was hidden")
        return
    if not bool(default_c.get("legacy_departure_conflict", false)):
        _fail("project-shield/default legacy departure contradiction was hidden")
        return
    if str(default_c.get("authored_outcome", "")).find("bright wing") < 0:
        _fail("path C authored consequence was replaced")
        return

    for invalid in [
        Receipt.build("path_z", "10+", "epiline_1"),
        Receipt.build("path_a", "6-", "epiline_1"),
        Receipt.build("path_a", "10+", "epiline_unknown"),
    ]:
        if bool(invalid.get("ok", true)):
            _fail("invalid receipt input was accepted")
            return

    print("AETHERWAKE_GODOT_CHAPTER1_CHOICE_RECEIPT_PASS: six authored outcomes preserved; default departure conflicts surfaced without legacy migration rewrite")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_CHOICE_RECEIPT_FAIL: " + reason)
    quit(1)
