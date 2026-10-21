# Actual native Godot fixed-position Ender/Ionia comparisons

**Source:** [Godot native visual workflow #39659157626](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39659157626), source commit `eb183d02a92460f9518d66d11b0282b611695f7d`. This capture produces five genuine original 960×640 Godot 4.7.2 PNGs from the First Wake pilot, with identical Ender/Ionia anchors, viewport, scene/deck settings and walk phase 0. One is the original placeholder baseline; four select corresponding Ender/Ionia east, west, south, and north SVG/raster candidates.

The original PNG bytes were recovered from the authenticated private runner job log, independently SHA-256 recomputed and copied as Git blobs under this private draft only. `manifest.json` contains source commit, workflow, job, byte length, SHA-256 and Git blob IDs. `fourway-contact-sheet.svg` embeds the four original image bytes displayed at half size for human comparison; **its 480×320 display panels are not separate/native-rendered 480×320 screenshots**. Review the PNGs at their original 960×640 for 1× pixel quality.

**Objective technical checks:** identical actor positions in every capture, exactly one facing each, independent Ender and Ionia image pixels, genuine renderer output, and distinct changes vs same-position placeholder baseline. The test logs changed pixel-byte counts, but these are NOT art quality scores.

**Visual inspection findings (provisional):** original east Ender is visibly slimmer/more pixel-detailed than the later west/front/back SVGs. Equipment presentation also changes across orientations (back-carry vs vertically visible hand/staff). Ionia's east/west faces are not clearly profiled at this scale; they look substantially like the rear-facing silhouette, so distinct pixels alone cannot establish directional readability. Their hair and garment texture are far more elaborate than Ender's simplified three directional views. The dock's 2.5D paint and game feel still require creator review.

**Do not infer:** final source-likeness adherence, correct staff physical handling, sufficient anatomy/lighting/occlusion, coherent East/West Ionia side profiles, acceptance, full Godot migration, release. Keep draft branches and artifact hashes unmerged, private and fail-closed.

`VISUAL_ACCEPTANCE=PENDING`, `STAFF_CONTINUITY=NOT_ACCEPTED`, `IONIA_SIDE_DIRECTION_READABILITY=NOT_ESTABLISHED`, `FIELD_PACK_READINESS=NOT_READY`, `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`, `RELEASE=NOT_AUTHORIZED`.
