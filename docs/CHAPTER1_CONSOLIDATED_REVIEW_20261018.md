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

## Exact-head verification addendum — October 19, 2026 UTC

This section supersedes **only** the original "Verification" section's pending exact-head evidence
as a current-status statement. The original scope and source-lineage history remain intact.
No review, human acceptance, release, or protected-branch promotion is implied.

### Signed follow-up lineage and first-failure custody
- Current [draft PR #290](https://github.com/ndrorchestration/aetherwake-jrpg/pull/290)
  is OPEN / UNMERGED at signed head `15183c941c89852d1ea5f346119b7f463c9891b2`,
  protected-main base `7364d43c202b2186e2d4eb3c752367afe61ee408`.
  Earlier signed `e5ae903` and original consolidation commits remain historical.
- [Signed commit `00178789`](https://github.com/ndrorchestration/aetherwake-jrpg/commit/00178789c6a3dbfb1a2a8a24a2226f7d5ba7cfdd)
  repositions the opening toast above lower narrative dialogue with a contrast panel
  and corrects both HTML page titles to `Aetherwake`. Existing overlay/desktop
  regression tests cover these boundaries.
- Preserve the [first failed hosted smoke run `39186884185`](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39186884185)
  at `00178789`: a short physical-keyboard route exited the Lyra scene before
  the canvas-render objective witness had sampled visible `FIND LYRA`.
  An exact-source screenshot showed the production copy; this was a test
  observation-timing defect, not established missing gameplay copy.
- [Signed `15183c9` helper-only correction](https://github.com/ndrorchestration/aetherwake-jrpg/commit/15183c941c89852d1ea5f346119b7f463c9891b2)
  waits for actual rendered `FIND LYRA` canvas evidence at the correct Lyra
  exploration state, preserving physical input, four authored Lyra lines, party
  and replay gates.
- [Exact-head hosted smoke run `39187305492`](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39187305492)
  at signed `15183c9` completed **SUCCESS**. The earlier failure stays recorded.

### Exact-head private evidence and limitations
- Current-head clean-source owner-local Chromium capture reports **10 PNG frames,
  zero browser page errors**; manifest SHA-256
  `46daff5f9cdc126745b84cddd151da2a66d8f9c550245907be823a7a94a63e64`.
  A private owner-only gallery loaded ten of ten images. Same-system capture is
  **not** human visual acceptance or an independent player trial.
- Hosted Actions artifact publication remains quota-blocked under
  [issue #222](https://github.com/ndrorchestration/aetherwake-jrpg/issues/222);
  private evidence is not a hosted artifact.
- An **isolated NSIS v3.13 compiler** was subsequently found on the authorized
  Windows host and answered its version check. This corrects the earlier
  absence-from-standard-install-paths preflight, but **does not** establish a
  current-head installer build, installation, launch, or human acceptance.
- Quiet-dock H is a browser-injected design illustration checked at *earlier*
  `e5ae903`, **not** a committed component or validated navigation scheme
  at the current `15183c9` head.
- `VISUAL_ACCEPTANCE=PENDING`; `FIELD_ART=NOT_READY`;
  `HUMAN_PLAYER_ACCEPTANCE=PENDING`; `WINDOWS_INSTALLER_ACCEPTANCE=PENDING`;
  `PROMOTION=NOT_AUTHORIZED`. No release or public deployment occurred.
