# Planetary Surface Native Admission — NONCANON

This is an **isolated Godot 4.7.2 contract consumer**, not a spherical renderer, local playable planet, ship flight level, or production data importer. No scene, mesh, shader, planet radius, collision, flight state, save, route, Moon Bridge clue or hidden discovery is created.

## Execute the real Node → JSON → Godot boundary

From repository root:

```sh
node scripts/build-planetary-surface-fixture.js --out /tmp/planetary-surface-manifest.json
godot --headless --editor --path godot/planetary_handoff --quit
godot --headless --path godot/planetary_handoff --script res://tests/test_manifest.gd -- /tmp/planetary-surface-manifest.json
```

Replace `godot` with the exact Godot 4.7.2 executable as appropriate. On Windows, supply an accessible path for the generated manifest. Hosted CI installs `Godot_v4.7.2-stable_linux.x86_64` and saves an ephemeral fixture plus native logs in its short-lived artifact.

**Expected result:** `PLANETARY_SURFACE_GODOT_ADMISSION_PASS checks=7 cases=4 NONCANON` after validating the generated tile bundle and rejecting forged gameplay/height/radius/material/center fields. **Never** interpret a PASS as an approved spherical mesh, physical map, collision surface or released build.

Manifest source-of-truth: `modules/planetary-surface-handoff.js`; each tile is a cube-sphere address, independently checked against latitude/longitude using **mathematical Z as the pole axis**. Godot scene rendering uses Y-up, so any future real geometry adapter **must** specify the transform and unit conversion; this validator does not perform or approve it.

Full acceptance thresholds, links to upstream studies and outstanding gates are in [Planetary Surface Production Admission](../../docs/PLANETARY_SURFACE_PRODUCTION_ADMISSION.md).
