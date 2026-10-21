# Ionia side-body garment volume V4 ? REVIEW ONLY

Provenance: this isolated candidate starts at draft PR #321 head `3288cf1e501dc53a32c2b7b53c07519f694718b3` and preserves V3 and V2 sources without overwriting them. No production sprite pack or canonical art is modified.

**Problem found in actual Windows GPU captures:** Ionia east/west average torso span 16.8 screen pixels across six gait phases; south=34.0 and north=28.5. The side silhouettes are anatomically readable but visually underweight relative to her front/back clothing volume. This is a scene-scale comparison, not a subjective artistic score.

**Small reversible v4 art study:** selectively widen the five *upper-body, coat, shoulders/arms and satchel* SVG groups by factor 1.26 around the true local source x=25.6 (corresponding to frame-local x=256 after existing +230.4px correction). Keep hair, face, eye/nose, lower legs, boots and movement phase anchors byte-equivalent in their source-region rasterization. Six frames are retained for east and west. Original V3 assets are preserved for rollback, and only the two opt-in Ionia pilot preloads change.

**Native Windows A/B study:** Godot 4.7.2 official portable Windows build verified against SHA-256 `731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953`, using native Intel Iris Xe OpenGL 3.3. At identical actor positions and game scale, east/west torso span rose from 16.8px to 20.5px (+21.8%) averaged across six gait frames. This improves visual clothing/body volume relative to the front/back studies, while remaining a proper side silhouette and retaining foot anchors. Aesthetic approval not established.

Automated checks: six distinct imported phases, source-cell dimensions, six V4 groups per direction, source waist span bounded above and below V3, exact unchanged head and foot-region raster data vs V3, existing Godot movement/dock/visual tests and creator-approved Ender provenance. Windows and hosted native 960?640 renderer screenshots and SHA-256 evidence must be attached before review admission.

`VISUAL_ACCEPTANCE=PENDING`, `IONIA_V4_ART=UNAPPROVED`, `FIELD_PACK_READINESS=NOT_READY`, `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`, `RELEASE=NOT_AUTHORIZED`. Do not merge or change canonical assets.
