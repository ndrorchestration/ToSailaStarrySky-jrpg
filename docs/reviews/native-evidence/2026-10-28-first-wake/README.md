# Chapter I — authentic Godot renderer receipts for the README

**Status:** DRAFT-ONLY VISUAL REVIEW, NOT FINAL ART ACCEPTANCE. Original source is the genuine native Godot 4.7.2 workflow [run #40648637058](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40648637058), job `122683255813`, executing the candidate source commit `4d18fece404062f1630e0ea0633b934fdd07ac4c`. Source gameplay/tests were already vetted in the upstream stacked Chapter I drafts; the capture remains a deterministic authoring fixture, not an uncoached playthrough.

The [README native six-frame contact sheet](chapter1-six-native-stage-frames.svg) holds the six **original full 960×640 PNG payloads losslessly embedded in SVG**. Their PNG bytes were reconstructed from the bounded Actions capture log, SHA-256 independently recomputed on each reconstructed buffer, and matched to the hashes written by native Godot for the source files. No resampling, retouching, color changes, upscaling, or new imagery was introduced. SVG scales each PNG to fit presentation cards; original PNG pixels remain preserved as embedded image data.

| Scene reference (in display order) | Original native PNG filename | Size (bytes) | PNG SHA-256 |
|---|---|---:|---|
| Ship afloat after local physics water contact | `first-wake-waterborne-review-native-960x640.png` | 35,843 | `58363df1d539fd5faff660bdd8091cbbac4d03774b77e18da7377eb96043c754` |
| Berth reached and lines secured | `first-wake-berth-secured-native-960x640.png` | 41,753 | `8186a73280d1e5e9bbdf71340b8d96ff56c84ab13fccb5acceb74019ddec463a` |
| Safe family arrival before Lyra joins party | `first-wake-family-meeting-native-960x640.png` | 56,005 | `3998588ead17e2f8074746506541bc813d2ef19a20dcf96faf49f308ab192791` |
| Provisional quay cache | `first-wake-salvage-quay-before-native-960x640.png` | 58,822 | `7e797cba79264e0f24187f0de37fc397179b994d9525112b354cefb8432d3eba` |
| Separate provisional stores annex | `first-wake-salvage-depot-native-960x640.png` | 59,192 | `0ec1fd6c54bcd165c6296fa64c0dd93cf0a6911a8bad250c18a16d16178a5b02` |
| Material-return workshop; installation still pending | `first-wake-salvage-installed-pending-native-960x640.png` | 70,439 | `25b059f6fc80b6285ad5d4e4342138eb2a0076f673a9736cb095131b713ea8ca` |

## Visual QA findings from direct inspection

The genuine native screenshots demonstrate **scene state and interaction implementation**, not cinematic presentation. The current **waterborne Aureate Wake** is represented by a simple flat hull polygon with no detailed ship silhouette, environmental material pass, foam, wake/water shader or cinematic camera response visible in the captured frame. The **family scene** stages Lyra and Talen as plain colored rectangular markers, alongside the clue stations; the characters are not implemented there as production-quality sprites. The **stores annex** uses basic gray rectangular architecture and untextured pickup props. Ender has a recognizable directional sprite, but environmental staging does not yet match the visual bible.

**Production art gate:** before these scenes belong in a marketing gallery or receive an artistic PASS, replace placeholder ship, environment, Lyra/Talen and material assets; implement considered light, ocean surface, weather, material response, camera composition, scene depth and character animation; capture current gameplay again; and obtain creator/human visual review. Native test success must not be mistaken for artistic acceptance.

## Interpretation and limitations

- The flight/water scene is a **local RigidBody2D + Area2D physics review**; neither a planet-scale ocean nor production ship model is verified.
- The quay and annex are **temporary geometry** with no approved geography, transport method, final material names or reusable art approval.
- Lyra's family meeting is a scripted dialogue staging scene with a noncombat child, not production character sprites, voice acting or emotionally validated final dialogue.
- The engine-room frame is before installation and the mandatory failed restart, **not** proof of real fuel chemistry or flight/Resonance authorization.
- The v3 save/resume feature is validated separately and **not visually depicted by these images**.
- The images are genuinely rendered, but no creative-direction/human/player acceptance or public installer signing has been granted. [Draft source PR #561](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/561) remains unmerged; the independent Windows Defender custody gate remains blocked.

The contact sheet is suitable for **draft README development transparency**, not marketing as a finished playable product. For individual review, archive a trusted full PNG as its own versioned object on a separate authorized production-media pass; this sheet does not substitute for an editable asset source pipeline or for independent screenshot access.
