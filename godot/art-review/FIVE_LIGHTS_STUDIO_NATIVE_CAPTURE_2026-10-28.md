# Five Lights Motion Studio — authentic native visual capture

- **Exact rendered source:** `2968eac30f2b0c312b5d55964686d125657b40c6` (draft PR #563).
- **GitHub Actions job:** [Native Godot 4.7.2 source motion + GL render](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40646536599), PASS.
- **Original native framebuffer:** 960 × 640 PNG, SHA-256 `cd2b7db435a9f92b10923a7c55089c5c6f322fb8a5bbd8af61bc5e8f6724ea50`. Captured with official Godot 4.7.2 GL under Xvfb. Full PNG is runner-local because of the documented artifact-custody limit.
- **Stored inspection preview:** [480 × 320 lossy JPEG](../review-evidence/five-lights-motion-studio-native-preview-480x320.jpg), created by downscaling the same native framebuffer in Godot. This is not a replacement for the source PNG.
- **Source inputs:** unapproved four-way atlases for all five; Lyra/Aepex/Reson are unchanged Git blobs from PR #487; Ender/Ionia inherited unchanged from PR #555.
- **Technical observation:** all five sprites visible at once, rendering at the studio's actual chosen scale. Six-phase/four-direction and motion tests PASS.
- **Art critique:** characters are visibly small and draft-detail; environment is a simple atmospheric night-harbor treatment. This does **not** match the creator's high-detail aspirational composition or establish approved proportions, hair, costume, facial detail, source footplants, sprite-to-portrait consistency, cinematic lighting, or production admission.
- **Do not conflate:** the creator-uploaded poster is a visual target, not this captured Godot frame. No claim is made that its portraits or decorative labels are actual native sprites.

## Next visual upgrade gates

1. Inspect true-size native frame and actual moving frame at target resolution; revise actor review scale/lighting only after confirming actual legibility.
2. Authored pixel/paint cleanup of all 120 frames, especially hair/face/costume detail and direction continuity; do not replace known creator appearance anchors.
3. Validate animator-defined stance contacts and film a real moving actor with the revised sprite, then test controlled occlusion/environment color.
4. Only after creator approval, integrate into canonical Chapter I with correct recruitment gates; game and Windows release status remain HOLD.
