# Chapter 1 consolidated review candidate — October 18, 2026

One candidate integrates the current-main visual lineage and recent opening fixes for review. This is not a release or visual/player acceptance.

## Source lineage
- Protected main: 7364d43c202b2186e2d4eb3c752367afe61ee408.
- Current-main visual/title/HUD lineage through draft #287: afbb2b63ab5dfe810dadf859e177011452af06f0.
- Opening controller, input, motion, complete dialogue pagination and replay reset through draft #285: d4a37b960526ee08a9ca6ab3c2420ed4701d18ab.
- Selected dock bridge and dialogue-stature intent from #288/#289 through a73abe0f7f256c4729412f19a8495fd804463e0c. Old V46 branch history is not merged.

## Integration decisions
Keep newer grapheme-aware HUD clipping and both sets of workflow checks. Port only the dock bridge implementation/test and dialogue-stature behavior. Preserve this lineage's exploration scales of 1.95 (Ender) and 1.88 (NPC), including during dialogue; do not import older 2.55/2.45 absolute scales. Keep the subtitle-free desktop title and staged manifest checks.
The Windows packaging contract initially failed because its README-heading assertion required LF-only input. Accept LF or CRLF for that exact heading, preserving all title assertions. An incidental comment/log encoding issue was corrected before commit.

## Verification
Twelve focused Node contracts pass: visual stage, bridge, stature, projected world, narrative fallback, measured HUD bounds, exploration/input, floor cue, motion, narrative pagination, replay reset, desktop packaging.
Two physical-keyboard opening routes pass with no browser errors; replay is explicitly initiated by the production startGame entrypoint, not a visible menu click.
Full npm smoke passes, including world/combat/flight checks. Desktop staging and staged title/main assertions pass. Diff whitespace check passes.
Same-system read-only source review found no critical or important scoped regression. Exact committed-head hosted checks and capture results must be recorded separately.

## Review boundary
Candidate and provisional artwork stays unaccepted. Creator visual review, independent human player acceptance, Windows installer/launch verification for this combined candidate and release authorization remain open.
The old draft PRs remain provenance; no automatic closure or merge. This review candidate does not authorize recruitment changes, progression changes, a ship rescale, public deployment or release.
