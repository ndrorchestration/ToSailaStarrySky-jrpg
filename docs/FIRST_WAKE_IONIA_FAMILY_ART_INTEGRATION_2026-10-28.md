# First Wake Ionia family-scene art integration — 2026-10-28

Status: playable Godot source, review only; not approved final sprite or cinematic acceptance.

- Reuses the existing Ionia v5 front-facing candidate from `pilot_actor.gd`, inside the actual postflight family scene.
- Ionia is stationary, has disabled collision layers/masks and cannot be controlled; existing story Ionia party state is the sole authority.
- Ender's existing walk-direction artwork is unchanged. Lyra and Talen remain provisional visual representations; no canon changes.
- Godot 4.7.2 native `first_wake_postflight_family_review_test.gd`: PASS.
- Godot 4.7.2 native `first_wake_main_entry_to_water_review_test.gd`: PASS.
- New Ionia image has not undergone native screenshot acceptance or matching-against-reference evaluation.
- Windows installer/security gate remains independent and blocked; do not merge or release without review.
