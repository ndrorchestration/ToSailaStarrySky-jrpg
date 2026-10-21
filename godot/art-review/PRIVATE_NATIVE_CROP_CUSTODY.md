# Private native lossless-crop recovery (draft-only / PR #315 extension)

No new game art was admitted. The native scene is rendered by the **existing** Godot 4.7.2 capture pipeline. This follow-up adds a bounded, read-only lossless inspection channel for the existing Ender east/west/front/back and Ionia south/north review variants.

After native 960×640 PNGs have been successfully created in the Actions runner by pre-existing capture scripts, `res://tests/emit_lossless_native_crops.gd` extracts an Ender 225×228 or Ionia 180×235 **pixel-exact crop with no scaling or JPEG conversion**. It checks each original frame exists, is precisely 960×640, verifies ROI limits, caps encoded PNG size (95k bytes), computes the entire source-frame SHA-256 and crop SHA-256, and writes numbered base64 chunks plus hashes to **private repository job logs**.

Use `godot/tests/recover_private_native_crops.py` on the downloaded full job log to reconstruct all six crop PNGs; it fails on missing chunks, SHA-256 mismatch, unexpected dimensions or truncated logs. Retrieve private logs using a permitted GitHub account, for example `gh api repos/ndrorchestration/aetherwake-jrpg/actions/jobs/JOB_ID/logs > native-job.log`, then `python3 godot/tests/recover_private_native_crops.py native-job.log --out native-crops`. The user must have permission to read this private repository's Actions logs.

This is an explicitly **bounded evidence custody improvement**: the 1× character ROIs become retrievable while the private job log remains retained and hashes match upon download. It does **not** preserve any source 960×640 full-scene PNG, prove long-term archival durability, grant another recipient access, or constitute any human art approval. It must never be called full-frame evidence custody. GitHub Actions artifact quota remains unresolved; no public publishing, token write access or external service is used.

This change intentionally does not import the separate unapproved 64×96 PNG front/back neutral studies from the creator review ZIP. Existing #310/#313 independently authored six-frame SVGs remain separate, visual acceptance pending.

Hard holds remain: `VISUAL_ACCEPTANCE=PENDING`; `STAFF_CONTINUITY=NOT_ACCEPTED`; `FIELD_PACK_READINESS=NOT_READY`; `FULL_NATIVE_FRAME_CUSTODY=NOT_ESTABLISHED`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`. Draft-only, no merge.