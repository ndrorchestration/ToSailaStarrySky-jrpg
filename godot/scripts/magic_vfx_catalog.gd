extends RefCounted
## Review-only affinity visuals. Never grants skills, spells, mastery, or combat authority.
## Creator-approved fundamental affinities: Ender Spirit; Lyra Water;
## Ionia Earth; Reson Fire; Aepex Air. Secondary pink light remains Lyra's motif.

const CHARACTER_ORDER = ["ender", "lyra", "ionia", "reson", "aepex"]
const PROFILES = {
    "ender": {"character": "Ender", "affinity": "Spirit", "signature": "convergent constellations", "color": "#c6bbff", "accent": "#ffefcf", "glyph": "spirit"},
    "lyra": {"character": "Lyra", "affinity": "Water", "signature": "tidal ribbon and pink spirit-light", "color": "#69d9f6", "accent": "#f9a0de", "glyph": "water"},
    "ionia": {"character": "Ionia", "affinity": "Earth", "signature": "rising mineral facets and dust", "color": "#cdb57c", "accent": "#93e2b0", "glyph": "earth"},
    "reson": {"character": "Reson", "affinity": "Fire", "signature": "ascending embers and thermal crown", "color": "#ff9a49", "accent": "#ffe2a0", "glyph": "fire"},
    "aepex": {"character": "Aepex", "affinity": "Air", "signature": "aerodynamic spirals and pressure wakes", "color": "#b4e9ee", "accent": "#a5caff", "glyph": "air"}
}
const PHASES = ["anticipation", "formation", "release", "impact", "aftermath"]
const DURATION_SECONDS = 2.4

static func has_character(character_id: String) -> bool:
    return PROFILES.has(character_id)

static func profile(character_id: String) -> Dictionary:
    if not has_character(character_id):
        return {}
    return PROFILES[character_id].duplicate(true)

static func phase_at(progress: float) -> String:
    var p := clampf(progress, 0.0, 1.0)
    if p < 0.18:
        return "anticipation"
    if p < 0.40:
        return "formation"
    if p < 0.58:
        return "release"
    if p < 0.77:
        return "impact"
    return "aftermath"
