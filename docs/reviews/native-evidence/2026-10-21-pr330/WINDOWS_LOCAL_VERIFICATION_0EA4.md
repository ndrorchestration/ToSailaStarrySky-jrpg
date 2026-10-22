# PR #330 — current-code Windows verification at 0ea4a805
**Date:** 2026-10-22 · **Scope:** operator-local engineering and renderer evidence only

## Exact subject
- Draft PR: #330
- Verified code head: `0ea4a8058139fe34452b491ed14020735dfaca21`
- Current PR head at verification start: `f44e8053dd19f1aaa476faea2926733f48305235`; comparison showed it was **two documentation commits ahead** of the verified code head, with no runtime/code differences.
- Authorized host: `neontic`
- Disposable checkout: `C:\Temp\aetherwake-pr330-verify`
- Godot: `4.7.2.stable.official.ed1daf0bf`
- Renderer: OpenGL 3.3 Compatibility, Intel Iris Xe

This receipt supersedes older statements that `1d45e7c`, `596c2534`, or `641867dd` were the latest locally exercised code/render heads. Those earlier receipts remain valid historical evidence for their exact subjects.

## Native contract suite — PASS
Each test was run separately against exact code head `0ea4a805...` and exited 0:

- `vertical_slice_choice_state_test.gd` → `AETHERWAKE_CHOICE_STATE_PASS`
- `vertical_slice_echo_encounter_test.gd` → `AETHERWAKE_ECHO_ENCOUNTER_PASS`
- `vertical_slice_prompt_model_test.gd` → `AETHERWAKE_PROMPT_MODEL_PASS`
- `vertical_slice_input_policy_test.gd` → `AETHERWAKE_INPUT_POLICY_PASS`
- `vertical_slice_signal_audio_test.gd` → `AETHERWAKE_SIGNAL_AUDIO_PASS`
- `vertical_slice_accessibility_test.gd` → `AETHERWAKE_ACCESSIBILITY_PASS`
- `vertical_slice_review_test.gd` → `AETHERWAKE_VERTICAL_SLICE_PASS`

The tests cover deterministic exclusive choice state, strategic guard→echo→quiet-strike counterplay and blind-attack failure risk, contextual prompts, binding-aware keyboard/controller defaults with custom-remap preservation, original procedural question/answer PCM generation, reduced motion/text sizing/local trace opt-out/history/cancel/retry, and the real scene's two outcome paths.

## Exact-code native renderer — PASS
The real Windows renderer was then run directly against the same code head:
`Godot_v4.7.2-stable_win64.exe --path godot --rendering-driver opengl3 --resolution 960x640 --script res://tests/capture_vertical_slice_review.gd`

All six native screenshots were generated and the renderer assertion passed:

| State | SHA-256 |
| --- | --- |
| Discovery | `bad4c2ff4ec133466fd6583f96fa3d1b9f368c40cf372043064ee5b032738156` |
| Ionia choice | `2b64bdbea69b666fefb7968fcf16ed22e88eb431bb852652e9632258b4580168` |
| Dialogue history | `bdc3ec6feeb50a374300c593929127974f8c8be46c5b49b282ccc485431798b5` |
| Encounter GUARD warning | `0e21dc8a1040e3777e728036698cebba07989e3c797b960333782f2b0dacfbf4` |
| Echo-ready STRIKE state | `4091bd9f6c092a550ee097d8dfe4f7f6827780750838eb62b8ddb4425e3c4116` |
| Beacon + distant-vessel payoff | `1c85b8448a8679acd97ab63d7d9b1ac6cc127b04c010a6a0a04464cc30babc04` |

Renderer assertion:
`AETHERWAKE_SLICE_NATIVE_RENDER_PASS: discovery, dialogue, dialogue-history, guard warning, echo-ready and payoff are visually distinct 960x640 frames`.

This closes the local evidence gap between the prior renderer head and the current code head. It is engineering/visual-review evidence, **not creator artistic acceptance or external player validation**.

## Hosted CI status
GitHub Actions jobs on the review branch continue to terminate before exposing steps or logs. The PR's prior check annotations record an account billing/spending-limit execution block. This receipt does not convert those red hosted checks into passes; **hosted exact-head verification remains NOT ESTABLISHED until GitHub jobs actually execute**.

## Research state
The 69-source JRPG/GameDev/Reddit/accessibility research run is now complete and has a separate decision reconciliation. Adopted direction remains strategic-prediction combat, compact purposeful space, binding-aware controls, dialogue history, original recurring signal motif, visible choice consequences and consent-aware testing. Research evidence is not canon, player delight evidence, or release authority.

## Boundaries
No merge, creator art/canon acceptance, production field-pack admission, Defender #293 disposition, protected-main change, independent validation or release authorization is established by this receipt.
