# Field Silhouette Card Generator

The human recognition kit must use a fixed, exact-head input. Generate those cards from the **production** field idle strips only after the mechanical completeness gate passes:

`python scripts/build-field-silhouette-cards.py --exact-head <40-character-SHA>`

The generator reads the first 64×96 frame from each protagonist's production `field-idle.png`, converts every visible pixel to solid black while preserving transparency, and writes five cards plus a hashed manifest under:

`art-staging/field-silhouette-review/<exact-head>/`

The manifest records the exact head, source-strip SHA-256 values, output-card SHA-256 values, and the fixed frame-selection rule. Do not manually redraw, crop differently, rescale, or alter individual silhouettes after generation.

If production strips are absent, malformed, fully opaque, or empty, generation fails closed. Current provisional strips are deliberately **not** the default input and must not be substituted for production evidence.

The resulting cards remain test inputs only. They do not themselves establish recognition or field-art admission; participant results must still pass `npm run score:field-silhouette-recognition`.
