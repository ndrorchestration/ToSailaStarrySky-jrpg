# First Wake native multi-scene visual pass — 2026-10-28

Status: review-only production code; not cinematic art accepted, merged or released.

## Changes in local Godot source
- `first_wake_flight_water_review.gd`: layered coastal background and lit quay skyline (previous local commit).
- `first_wake_postflight_family_review.gd`: layered harbor water, mast silhouettes, plank seams and warm quay lighting.
- `first_wake_salvage_review.gd`: shared weathered walkway treatment; waterborne pier posts, reflections and stores-annex structural trusses and practical lights.

These are genuine draw calls in the playable Godot scenes, not reference illustrations. They preserve all interaction coordinates, party chronology, story/custody semantics, water/berth physics, controls and saves. Character stand-ins and some interactive marker blocks remain temporary; these additions do not imply completed final assets or geographic canon.

## Verified on connected Windows desktop / Godot 4.7.2
- `first_wake_postflight_family_review_test.gd`: PASS.
- `first_wake_salvage_review_test.gd`: PASS.
- `first_wake_main_entry_to_water_review_test.gd`: PASS.
- Earlier full 960x640 OpenGL flight/recovery capture: PASS (prior local state).

## Outstanding acceptance
Render and visually inspect authentic new family/quay/depot images, ensure readable interaction labels and character visibility, replace stand-in markers with creator-approved sprites, and repeat full screenshot and export QA. This is not a Windows installer release and does not clear Defender custody.
