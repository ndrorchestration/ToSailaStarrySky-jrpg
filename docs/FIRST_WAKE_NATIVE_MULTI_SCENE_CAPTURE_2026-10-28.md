# First Wake — latest native scene capture manifest (2026-10-28)

**Status:** genuine local Godot 4.7.2 renderer output, *not* artistic sign-off, public media or installer approval.

Source branch: `visual/first-wake-layered-coast-review-20261028`; source parent before this documentation: `84344db`.

## Completed captures
- `capture_first_wake_salvage_review.gd`: PASS; five 960x640 PNG files (quay before/after, depot, returned quay, workshop). Existing pixel difference guards passed for collection, area, HUD and workshop.
- `capture_first_wake_recovery_review.gd`: PASS; six 960x640 PNG files (afloat, recovery, berth contact, secured, family arrival, Lyra join). Existing pixel difference guards passed for berth-state and party-state distinctions.
- Files saved to `godot/review-evidence/` locally only; not distributed publicly, not in the Git tree.
- Ionia's reviewed directional sprite candidate is present in the family scene and its visibility/collision guard passed on previous exact-local native test.

## Important limitations
Lyra, Talen and other party members still lack admitted final sprite packs; the repo contains Ender and Ionia candidates only. The native captures prove rendering and state differences, **not visual fidelity or human acceptance**. The screenshot manifests should not be promoted to the public README until artist review, provenance, consent and stable approved image custody. Collision, story timing, fuel mystery, save and party contracts are unchanged. No merge, public release, or Defender clearance.

## Production priorities
(1) Review these genuine screenshots at original 1x resolution; (2) match creator visual bible and approve/correct Ionia/Ender candidates; (3) create/admit remaining character sprites and authored environmental source assets; (4) rerun native scene + screenshot + Windows custody QA before a Windows build is advertised.
