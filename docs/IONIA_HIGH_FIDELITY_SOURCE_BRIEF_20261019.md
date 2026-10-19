# Ionia: high-fidelity anime field-art source commission (2026-10-19)

**BLOCKING ORIGINAL ART REQUIRED — no source admitted.** This is an executable art handoff, not a completed drawing or approval. Related P0 fast-track issue #297 and draft #298.

## Correct source identity
Ionia is **28 years old**, the Aureate Wake's captain and caretaker; shoulder-length **curly blonde** hair; adult commanding posture, readable blue eyes and mature proportions. Reference creator's approved canon and portrait, **not** older 26-year-old collage labels or the unapproved procedural-chibi look. Apparel: original navy/white/gold captain layers as a *reviewable direction* (not pre-approved costume); distinct captain rank, epaulettes, trousers/boots and accessories. Do not copy another JRPG's designs or assume Dragonfly equals the Aureate Wake.

## What the current prototype failed
- Procedural alpha sprite under `art-staging/field/ionia/review/`: face/head/curl shape is too geometric and chibi. Coat texture/material has minimal tonal depth, silhouette and motion lack expressive appeal.
- Source is 192x288 *scaled procedural geometry*; native 64x96 reduction does not introduce anime quality. The new v2 curl/coat sway improves motion only.
- Current source has six provisional walk poses, **one static idle**; talk/focus/attack multi-frame production is absent.
- Game scene physically anchors actors on an optional timber span but still has a painted-world seam. These are separate issues.

## New production artwork deliverables
1. **Original authored turnaround**: consistent full-body front, 3/4, profile and rear, including hair curl volume, outfit back panels and emblem/gear. Image can be illustrative; production source must have a clean transparent cutout and separate pose frames; PNG/RGBA originals plus editable layered source when feasible.
2. **Style-critical single-frame pilot**: hand-render one sharply readable 64x96 **gameplay-scale** silhouette preserving anime eye/face design and curled hair against the First Wake dock; draw source at least 3x the target, then deliberately retouch the 64x96 cell. Do not generate dozens of frames from an unapproved single pose.
3. **Directional walking**: six distinct physically ordered frames/side, other viewing directions supplied as individually drawn art; consistent toe/heel anchor and arm counter-swing, curl inertia, coat-tail follow-through, recognizable staff/weapon only where canon requires it.
4. **Other animations** (after character pilot approval): idle 8, talk 4, focus 6, attack 8, walk 6 at documented timing; demonstrate genuine distinct frames, not static duplication or automatic rotations.
5. **Runtime check**: same 960x640 logical dock/world/dialogue views beside Ender's PR #262 art at matched physical size, with clear rail/door/craft geometry and believable ground plane. Native-resolution in-scene before/after must show a visually **material** improvement.
6. **Provenance**: source file SHA-256, art author/origin, working revision, exact frame atlas layout, crop per frame, screen-shots manifest, revision and explicit creator acceptance record.

## Non-negotiable visual review questions
- Does Ionia unmistakably read as an *adult anime captain* rather than chibi or generic blonde NPC?
- Do silhouette and coat materials match Ender's colorful, shaded and original visual vocabulary?
- Is the full-body source visually strong at both source size and 64x96 final cell, with coherent light direction?
- Are all six walk frames anatomically ordered with constant foot anchors and no distracting pose jitter?
- Is the sprite in actual playable 2.5D scenery, not an infographic labeled 'final'?
- Has the creator approved the candidate and the field-pack admission separately?

**Stop condition:** do not re-run exhaustive CI or create an admission PR until the artwork passes a direct before/after native gameplay review. Keep PR #298 draft, `FIELD_PACK_READINESS=NOT_READY`, `VISUAL_ACCEPTANCE=PENDING`, `HUMAN_PLAYER_ACCEPTANCE=PENDING`, no release.

## Rejected false evidence
The colorful infographic generated during the October 19 discussion is an **aspirational promotional mockup** with inaccurate 'final' labels and a long straight-haired Ionia design. It is not a confirmed canonical Ionia likeness, executable atlas, engine screenshot, verified 32-frame pack, or test result. Do not import it as source or mark checkboxes complete.
