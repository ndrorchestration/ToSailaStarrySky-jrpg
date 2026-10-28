# Aureate Wake panoramic glass — exact-source native art intake (2026-10-28)

**G1 GLASS-SHADER STAGING PROTOTYPE / NOT PRODUCTION MATERIAL OR PRESSURE RATING**

This reversible study is stacked on the real anonymous-crew walk/camera review, [draft PR #531](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/531), which itself is stacked on the unified metre-scale bridge [draft PR #512](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/512). Both branches remain draft and unmerged. No change to the playable First Wake's party, story, save, combat or hidden ship abilities.

## Exact verified asset provenance

- Original source: `godot/flight_slice/shaders/bridge_panorama_glass.gdshader` from [draft PR #482](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/482), fixed source commit `8f7112d0f8ed3afcad8faa76b5d0b224d25cdce9`; standalone native [review run 40608998147](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40608998147).
- Git blob SHA-1: `b6c7e8d4144acc14074581b08b61c61b7f5a047a`. Raw shader bytes SHA-256: `fa5a1d235d28c51aa93640e30ef25ddffecce16ab7d1083330da122a2480b7be`. The *staged* Godot path `res://art-staging/ship-glass-study/bridge_panorama_glass.gdshader` has **the same Git blob SHA**. CI explicitly runs `sha256sum` and `git hash-object` on the imported bytes, not mere JSON metadata agreement.
- Source manifest: `godot/art-staging/ship-glass-study/source-manifest.v1.json`; declares scope, original source commit, exact byte identities, preview presets, and mandatory `production_ready=false`, `physical_glass_approved=false`, `collision_glazing=false`.

## Integration touchpoint

The existing isolated metre-scale 3D ship allows one of exactly three *appearance-only* modes, with **metric_proxy** remaining the default: `metric_proxy`, `source_clear`, `source_low_glare`. Both imported modes use a genuine Godot `ShaderMaterial` referencing the **same unchanged** PR #482 spatial shader; explicit setting changes create a new visual material without mutating hull, hatch, floor, actor collision, save state, camera policy, narrative, or release rights. `source_clear` uses original authored tone/edge alpha, while `source_low_glare` softens the same values.

## Native acceptance

- `godot/tests/aureate_wake_source_glass_intake_test.gd`: reads exact source manifest and actual shader bytes, checks original source head and material identity, default-off state, source clear and low-glare parameters, rejects imaginary glass/capability modes, verifies unchanged glass mesh/frame geometry, open/closed/open capsule physics and unchanged Ionia-first real scene.
- `godot/tests/capture_aureate_wake_source_glass.gd`: two authentic 960×640 Godot Compatibility scenes from identical framing, `source-glass-clear.png` and `source-glass-low-glare.png`, requiring a positive pixel-difference count. No concept/render substitutions. Exact GDScript import and runtime GL proof are separate.
- [Dedicated native workflow](../.github/workflows/godot-aureate-wake-source-glass.yml): verified official Godot 4.7.2 binary, explicit SHA256 and Git SHA1 checks, headless native import/physics, real software-GL frames, original source-state custody. Also retain full inherited crew-physics and native Chapter I regression workflows.

## What this does *not* admit

- This transfer is **only original shader bytes**. The metric scene still uses **original proxy dome topology**, NOT the isolated flight-lab dome mesh or its native structural design. The glass has no collision, cracking/shielding model or environmental pressure/sealing behavior.
- Clear/low-glare source settings are **art-review hypotheses**; no daytime/nighttime glare acceptance, real physical reflection/refraction, human-inhabited vessel certification, final art approval, or creator-selected dimensions.
- The test's passing result can advance **G1 source shader intake** to native review; G2 physically integrated hull and G3 gameplay scene remain unapproved; Windows safety and G5 release remain blocked. A valid source hash and shader import are *not* user approval of the optical aesthetic.

**Review status:** exact-head CI and screenshots must be inspected before calling this work verified. Do not merge automatically, migrate source art to playable Chapter I, or make hidden lore public.
