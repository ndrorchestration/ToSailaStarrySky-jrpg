extends RefCounted
## Read-only, review-only Chapter I choice receipt.
## Derives the player's authored storm outcome from already-persisted identity.
## Never mutates the legacy epilogue resolver, save schema, or canon.

const Content = preload("res://scripts/first_wake_chapter1_content.gd")

static func build(choice_path: String, outcome_variant: String, epilogue_id: String = "") -> Dictionary:
    if not Content.CHOICES.has(choice_path):
        return {"ok": false, "error": "UNKNOWN_CHOICE"}
    if outcome_variant not in ["10+", "7-9"]:
        return {"ok": false, "error": "UNKNOWN_VARIANT"}
    if not epilogue_id.is_empty() and not Content.EPILOGUES.has(epilogue_id):
        return {"ok": false, "error": "UNKNOWN_LEGACY_EPILOGUE"}

    var outcome_text: String = Content.choice_outcome(choice_path, outcome_variant)
    if outcome_text.strip_edges().is_empty():
        return {"ok": false, "error": "EMPTY_AUTHORED_OUTCOME"}

    var legacy_epilogue_name := ""
    if not epilogue_id.is_empty():
        legacy_epilogue_name = str(Content.epilogue(epilogue_id).get("name", ""))

    return {
        "ok": true,
        "error": "",
        "choice_path": choice_path,
        "outcome_variant": outcome_variant,
        "choice_label": Content.choice_label(choice_path),
        "authored_outcome": outcome_text,
        "legacy_epilogue_id": epilogue_id,
        "legacy_epilogue_name": legacy_epilogue_name,
        # Narrow, observable contradiction only. Other path/ending pairs may
        # require narrative review and are not automatically certified coherent.
        "legacy_departure_conflict": epilogue_id == "epiline_1" and choice_path != "path_a",
    }
