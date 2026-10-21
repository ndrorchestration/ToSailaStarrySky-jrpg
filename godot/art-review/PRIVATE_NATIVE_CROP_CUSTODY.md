# Private Godot visual evidence: exact full PNGs and 1x actor crops

Status: **PRIVATE DRAFT SOURCE-BYTES CUSTODY ESTABLISHED FOR THIS SPECIFIC EVIDENCE SET.** Human visual acceptance and release remain pending.

The original 960×640 real Godot scene renders were produced in [workflow #39642661420](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39642661420) from candidate `a9c40c2ed5a076eaba04b38691bd188d4bd030bf`, inside the existing private Aetherwake native renderer pipeline (Godot 4.7.2, Xvfb/OpenGL3). The modified review transport emitted **two formats** with exact SHA-256: six original full 960×640 PNG files byte-for-byte (labels `*-full`), and six unscaled lossless 1× actor crops (Ender east/west/front/back and Ionia front/back). PNG dimensions and byte lengths were verified after decoding.

The verified PNGs were then written as Git blobs and committed only to the private draft PR #316 branch, at [the evidence directory](https://github.com/ndrorchestration/aetherwake-jrpg/tree/46b393d0157cbc3e5ba24fe5290b0fbb853dee77/docs/reviews/native-evidence/2026-10-21-pr316). See `manifest.json` there for all 12 source PNG SHA-256 values, unscaled crop SHA-256 values, Git blob IDs, exact renderer commit/run/job identifiers and original first-failure provenance. A GitHub read-back confirmed all 12 immutable blobs match their recorded Git blob SHAs, dimensions and sizes.

## Recovery workflow and boundaries

An authenticated reviewer with access to the private repo can inspect/download the persisted image files directly. If reviewing another runner attempt before manual Git custody, fetch its job logs with `gh api repos/ndrorchestration/aetherwake-jrpg/actions/jobs/JOB_ID/logs > native-job.log`; reconstruct all logged PNGs using `python3 godot/tests/recover_private_native_crops.py native-job.log --out recovered`. The decoder rejects incomplete, out-of-order, non-PNG, incorrectly dimensioned or SHA-mismatched data. `test_private_crop_decoder.py` exercises valid and five invalid cases. Each new run needs its **own** independent recovery and storage; these are not automatically archived in Git.

The first native evidence attempt `5107201` succeeded at checksums but mistakenly cropped background for Ionia's northward route. That failed crop is preserved in PR #316 history and a separate review comment. Corrected Ionia north ROI tracks x470 and was visually inspected with Ionia present before the above final evidence was admitted to *custody*.

### Strict exclusions

- Private Git custody **solves retrieval of exactly these six original native frames plus six 1× crops**, but does **not** fix the GitHub Actions artifact-storage quota, guarantee arbitrary future capture retention, publish assets, authorize character art, or replace independent user/artist review.
- Existing front/back six-frame SVGs from #310 and independently authored west sprite from #313 remain unapproved drafts. The separate ChatGPT-created 64×96 neutral studies were **not** used as Godot assets.
- The original Ender east raster still visibly differs in style/density from the simplified directional SVGs. Staff carry/centered wrap across views and Ionia's final appearance remain pending review.
- No production runtime switch, protected branch merge, canonical map, engine migration, game release or Windows installer authorization was performed.

`EVIDENCE_PRIVATE_SOURCE_CUSTODY=VERIFIED_FOR_12_PNGS`; `HUMAN_RECIPIENT_REVIEW=NOT_ESTABLISHED`; `VISUAL_ACCEPTANCE=PENDING`; `STAFF_CONTINUITY=NOT_ACCEPTED`; `FIELD_PACK_READINESS=NOT_READY`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`.
