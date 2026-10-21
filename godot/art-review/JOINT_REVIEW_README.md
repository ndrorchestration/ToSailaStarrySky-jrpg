# Ender–Ionia joint native capture and pose-authoring boundary

Approved Ender source is copied as an identical Git blob from draft PR #261. It is an appearance reference only, NOT runtime field art. The existing Ender side strip and Ionia derivative are unapproved.

The native reviewer (res://tests/capture_ender_ionia_joint_review.gd) produces four true Godot 960×640 PNG captures: both placeholders, Ender only, Ionia only, and both review sprites together. The approved full-resolution Ender reference is deliberately NOT rendered as a playable 64×96 sprite.

Front/back pose bytes remain missing. Before authoring 64×96 directionals, inspect ENDER_PROVENANCE_RECEIPT.md and the original approved image. Avoid reflecting the side strip into fake front/back poses; preserve hair, eyes, goggles, centered staff grip, ferrules and foot baseline. New candidate files require source provenance, hash and creator scale review. No candidate is admitted by a green smoke or capture test.

Reproduction in Godot 4.7.2 after native editor import:
- python3 godot/tests/verify_ender_provenance.py
- godot --headless --path godot --editor --quit
- godot --headless --path godot --script res://tests/smoke_test.gd
- godot --headless --path godot --script res://tests/ender_walk_test.gd
- godot --path godot --rendering-driver opengl3 --resolution 960x640 --script res://tests/capture_ender_ionia_joint_review.gd
- sha256sum godot/review-evidence/joint-ender-ionia/*.png

Custody: hosted workflow only logs renderer hashes; GitHub Actions artifact storage quota previously failed. Runner-only images are ephemeral. Private recipient must receive original PNG bytes, hash manifest, exact commit, engine identity, capture procedure and successfully verify downloaded bytes before evidence delivery is recorded. Do not claim capture custody, visual acceptance or creator signoff from CI.

No protected branch merge, production art manifest, default art toggle, release or canon changes. VISUAL_ACCEPTANCE=PENDING; FIELD_PACK_READINESS=NOT_READY; PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED; RELEASE=NOT_AUTHORIZED.
