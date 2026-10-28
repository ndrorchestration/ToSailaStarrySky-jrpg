# First Wake CI incident reconciliation — 2026-10-28

**Authority:** read-only GitHub Actions logs, exact-head job records, PR metadata and source comparison. **Scope:** review-only; no merge, rerun, release, or Windows acceptance.

## Findings and evidence
| Failure class | Historical failure | Verified correction / boundary |
|---|---|---|
| Windows exact QA | Four distinct Windows QA jobs failed at `Preflight unchanged Defender custody requirements`; logs report `DEFENDER_ANTIVIRUS_ENABLED=True` and `DEFENDER_REALTIME_ENABLED=False`, with `WINDOWS_QA_HOST_DEFENDER_REALTIME_DISABLED`. | Host security prerequisite, **not** proof of gameplay or installer failure. Functional prerequisites succeed independently on representative jobs. Defender-on acceptance remains **BLOCKED**. |
| Ionia local berth capture | [Run 40665762503](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40665762503): native output printed `TSTSS_BERTH_GL_CAPTURE_PASS frames=5`; workflow expected `frames=3`. | Draft [PR #579](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/579) updates assertion and capture contract to five frames; exact-head [render 40670306658](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40670306658), [native 40670306627](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40670306627) and smoke 40670306864 **SUCCESS**. |
| Tidal visual rig collider assertion | [Run 40662312132](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40662312132) reported `ship's verified physics collider removed`. | Test previously assumed literal node name `CollisionShape2D`. Draft [PR #564](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/564), head `701eac388cf8e7899ca753dd8a8e3ce502ce65bf`, instead locates a child by `CollisionShape2D` class and **retains** the `RectangleShape2D` 144×34 invariant. [Native run 40663228468](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40663228468) **SUCCESS**, render 40663228292 and smoke 40663228376 **SUCCESS**. |
| Preview export entry | [Run 40636103437](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40636103437) rejected native preview main scene. | Draft [PR #547](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/547), head `eae84a63d370d64bc5a11b049df4abb958301394`, changes `run/main_scene` to `res://scenes/first_wake_game.tscn` with explicit allowlist retaining the legacy preview. [Native 40636277938](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40636277938), render 40636277999 and smoke 40636277957 **SUCCESS**. |

[PR #550](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/550) separately demonstrates native Windows functional installation, visible window and uninstall, without publishing the installer or establishing Defender-on acceptance. **Functional proof ≠ security certification, artistic approval, creator approval, integration proof or public-release authorization.**

## Integration and release gates

- All named fixes are demonstrated on **their own exact PR heads**, not on a verified shared Chapter 1 integration SHA. Draft PRs remain unmerged. Independently successful heads do not establish cross-branch compatibility.
- Pin one integration baseline; inspect dependency ancestry and overlapping files for #547, #564, #579 and installer #550. Reconcile collider class/type/144×34 size, original physical water/berth sensors, Ionia-first chronology, save isolation, five-frame GL capture and startup scene allowlist.
- Verify combined native gameplay, real OpenGL capture, smoke, save, story and physics on the **same SHA** before claiming integration.
- Keep independent Defender real-time/event-log custody fail-closed on a compliant Windows host. Do not bypass, suppress, or mark full Windows QA green on functional-only results. Signing, representative hardware and human/player/art acceptance remain separate.
- Inbox maintenance: 560 matching GitHub failure messages were archived (not deleted) in Gmail. This is not a GitHub run-state change.

**Disposition:** Historical native signatures individually corrected and exact-head tested; combined integration **NOT VERIFIED**; Windows security **BLOCKED**; production release **NOT AUTHORIZED**.