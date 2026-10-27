# Airship identity contract — public-safe

**Authority:** CREATOR CANON, 2026-10-27. This document supersedes older naming-relationship questions where the identity of these two ships was left open. It does not approve ship art or any production behavior.

| Stable content key | Name | Established facts | Unapproved/open |
|---|---|---|---|
| `aureate_wake` | Aureate Wake | Dragonfly-inspired airship; Ionia's ship; mobile home of the protagonists | Exact final dimensions, fitted mechanics and cinematic representation |
| `dragonfly_frigate` | The Dragonfly | **Separate Frigate-class airship**, **substantially larger** than the Aureate Wake | Allegiance, crew, armament, exact size, flight physics, appearance, story role |

## Non-alias invariant

`aureate_wake != dragonfly_frigate`. Do not use the word "Dragonfly" in prototype or trailer files to automatically identify the Aureate Wake, nor interpret historical flight-study references to "Dragonfly" as evidence that the Frigate-class ship was controllable or in Chapter I.

**Migration safety:** Historical filenames, Godot placeholders, tests and archived QA may retain their original terms for provenance. A future gameplay migration must bind an explicit content key to each authored scene/asset; do not silently rename scenes, ship nodes, saves or serialized identifiers. Numerical frigate specifications are OPEN, not inferred from its class.

**Canon boundary:** This document is public safe and must not disclose Moon Bridge activation or restricted late-game mechanics. See [canon policy](CANON_AND_REVEAL_POLICY.md), [art authority](CHARACTER_AND_ART_AUTHORITY.md), and [concept teaser](CINEMATIC_CONCEPT_TEASER_2026-10-26.md).

## Production acceptance

- [ ] Creator approves final look and scale comparison in the Visual Bible
- [ ] Godot native scene ship identity is bound explicitly
- [ ] Ship-specific movement/collision/crew bindings are tested independently
- [ ] Teaser imagery is not represented as measured or captured Godot behavior
