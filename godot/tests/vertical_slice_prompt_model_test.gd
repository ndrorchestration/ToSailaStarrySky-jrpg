extends SceneTree
## Asset-independent context-prompt regression.

const PromptModel = preload("res://scripts/vertical_slice_prompt_model.gd")

func _initialize() -> void:
    var valid: bool = true
    valid = valid and PromptModel.prompt("search", 200.0, 0.0, 0.0) == "Find the labeled SIGNAL"
    valid = valid and PromptModel.prompt("search", 10.0, 0.0, 0.0, "Pad A") == "Pad A: Inspect the signal"
    valid = valid and PromptModel.prompt("meet", 0.0, 200.0, 0.0) == "Bring the clue to Ionia"
    valid = valid and PromptModel.prompt("meet", 0.0, 10.0, 0.0) == "E: Talk to Ionia"
    valid = valid and PromptModel.prompt("approach", 0.0, 0.0, 200.0) == "Cross the dock to CHALLENGE"
    valid = valid and PromptModel.prompt("approach", 0.0, 0.0, 10.0) == "E: Begin the signal challenge"
    valid = valid and PromptModel.prompt("return", 200.0, 0.0, 0.0) == "Return to the SIGNAL"
    valid = valid and PromptModel.prompt("return", 10.0, 0.0, 0.0) == "E: See what changed"
    valid = valid and PromptModel.prompt("complete", 0.0, 0.0, 0.0) == ""
    if not valid:
        push_error("AETHERWAKE_PROMPT_MODEL_FAIL: stage/distance prompt mismatch")
        quit(1)
        return
    print("AETHERWAKE_PROMPT_MODEL_PASS: stage objectives and nearby actions are explicit")
    quit(0)
