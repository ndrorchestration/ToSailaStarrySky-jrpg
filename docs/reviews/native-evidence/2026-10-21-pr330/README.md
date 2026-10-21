# PR #330 — native playability visual review (2026-10-21)

**Exact renderer source:** commit `e6a90171e5c45b0070801339b8a46f8619846559`, [native render run 39693632623](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39693632623), job `119545609327`, Godot 4.7.2 OpenGL3/Xvfb, native 960×640 viewport. This is review-only evidence, **not** creator acceptance or a production screenshot.

## Native lossless PNG receipt ledger
| State | Dimensions | Original PNG bytes | Logged SHA-256 |
| --- | --- | ---: | --- |
| Discovery | 960×640 | 62,385 | `111ba68aaf1827b328830b0b0812145b2aee79d63e9382f02055acc08231ac6b` |
| Ionia dialogue choice | 960×640 | 61,222 | `a7bec866d37a17e9afba1903d380f3b7516ba788cb44bc32433964740dc2c5bf` |
| Beacon payoff | 960×640 | 64,367 | `cd566fc497622d95cc25444af44fe5621ce8084f022135b8d5e04e9f7e2754aa` |

Each original full-frame PNG was emitted through the private `AW_NATIVE_CROP_BEGIN/DATA/END` log channel; the independent receipt parser recovered all three complete base64 streams with **byte counts matching** the receipt. The native renderer's test confirmed the dialogue and payoff lower-UI pixel regions differ from the prior states. The screenshot files themselves were not published as Actions artifacts (existing storage-quota hold). SHA values above are the native source receipts, not an assertion of independent cryptographic verification.

## Direct inspection at actual 960×640
- The existing reversible 2.5D dock stage materially improves the scene over the first flat-background candidate: graded sky, sun, clouds, distant terrain, water, planks, rail, lanterns, props and structural depth are all visible.
- Ender and Ionia **placeholder silhouettes** remain distinct and centered on the dock; the review does not turn on unapproved Ionia candidate SVGs or replace the approved Ender source.
- Discovery marker, dialogue choice, and beacon outcome are visibly distinguishable. Header and two-line bottom text are legible at this native size; labels supplement color.
- **Still incomplete:** the gold beacon change is too abstract to carry a final emotional payoff, the player and Ionia do not yet have approved expressive close-up animations in this scene, there is no authored music/audio or NPC reaction, and the text UI needs real accessibility/controller and external comprehension testing. Treat the richer dock as a presentation hypothesis, not an approved world map.

## Next visual gate
Seek creator review of the signal motif, character-to-background scale, UI density, lighting tone and payoff readability. Run actual moving-player captures and five-person cold playtest before claiming that this is fun or beautiful. Do not conflate visual screenshots with gait validation from #328/#329, character art admission from #326, or release/security authorization (#293).
