extends RefCounted
## Deterministic native dialogue cursor for migrated First Wake contact intros.
## Dialogue sequencing is intentionally separate from quest/progression mutation.

const Content = preload("res://scripts/first_wake_chapter1_content.gd")

var contact_id: String = ""
var lines: Array[String] = []
var line_index: int = 0
var open: bool = false

func begin_contact(next_contact_id: String) -> bool:
    var next_lines := Content.contact_intro(next_contact_id)
    if next_lines.is_empty():
        return false
    contact_id = next_contact_id
    lines = next_lines
    line_index = 0
    open = true
    return true

func current_line() -> String:
    if not open or lines.is_empty():
        return ""
    return lines[line_index]

func speaker_name() -> String:
    return Content.contact_name(contact_id) if open else ""

func advance_or_close() -> bool:
    if not open:
        return false
    if line_index < lines.size() - 1:
        line_index += 1
        return true
    close()
    return true

func close() -> void:
    open = false
    contact_id = ""
    lines = []
    line_index = 0

func snapshot() -> Dictionary:
    return {
        "open": open,
        "contact_id": contact_id,
        "speaker": speaker_name(),
        "line_index": line_index,
        "line_count": lines.size(),
        "line": current_line(),
    }
