# Ionia east/west side-body V4: native Windows A/B review

These are original Godot Windows GPU captures, not image-model mockups. The candidate is **draft PR #324** at exact source commit `7ac77a4c71705f4da46e33b7095a2ca468d73e3b`, stacked on draft PR #321 at `3288cf1e501dc53a32c2b7b53c07519f694718b3`.

The ZIP contains all **24 original native 960x640 PNG files**: v3 and v4, east and west, six contact phases each, identical review actor anchors. `manifest.json` lists SHA-256 of each PNG and of the ZIP. The four individual phase-zero full-native PNGs support direct preview, and the two six-phase side-by-side contact sheets display enlarged crops derived from the originals. These contacts are comparisons, NOT additional engine renders. Every extracted member can be independently SHA-256 matched to the manifest.

Engine: official Godot 4.7.2 Windows binary; ZIP verified against the release SHA-256. Renderer: Intel Iris Xe OpenGL 3.3, not headless dummy output. Code for captured scenes remains local-only review source `godot/review-evidence/windows_phase_review_v4.gd`; no release or runtime behavior added by the evidence packaging.

**Measured result:** upper torso width east/west 16.8 -> 20.5 screen px (about +21.8%) across six phases, source waist y460 width 110 -> 138px. Head/facial features, leg/foot positions and original V3 source are preserved, and the V4 opt-in source is never selected by default gameplay. Hosted exact-art-commit native movement, render and smoke workflows all passed, as did the local Windows 6-test suite.

**Limitations:** Geometry and native visual fidelity improve but do not establish authoritative creator approval, perfect ground-contact animation, parity with north/south shading or Ender costume detail, complete engine migration, or production readiness. The opt-in V4 remains unapproved. The repository is private; do not publish this visual packet externally or claim full-game release acceptance.

`VISUAL_ACCEPTANCE=PENDING`; `IONIA_V4_ART=UNAPPROVED`; `FIELD_PACK_READINESS=NOT_READY`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`.
