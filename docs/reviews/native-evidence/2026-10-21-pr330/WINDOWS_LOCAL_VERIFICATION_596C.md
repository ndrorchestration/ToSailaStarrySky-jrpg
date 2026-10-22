# PR #330 — Windows operator-local verification at 596c253
**Date:** 2026-10-21 / **Scope:** operator-local engineering evidence only

## Exact subject
- PR: #330, draft/unmerged
- Head: `596c2534bb260360c59447045b609cb90e1492be`
- Host: authorized Windows device `neontic`
- Checkout: disposable `C:\Temp\aetherwake-pr330-verify`
- Godot: `4.7.2.stable.official.ed1daf0bf`
- Official archive: `Godot_v4.7.2-stable_win64.exe.zip`
- Godot release SHA-512 manifest value:
  `83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993`
- Verification: local archive SHA-512 matched the official release `SHA512-SUMS.txt`.

## Asset-independent native contracts — PASS
Run with the verified Windows Godot binary:
- `vertical_slice_choice_state_test.gd` → `AETHERWAKE_CHOICE_STATE_PASS`
- `vertical_slice_echo_encounter_test.gd` → `AETHERWAKE_ECHO_ENCOUNTER_PASS`
- `vertical_slice_prompt_model_test.gd` → `AETHERWAKE_PROMPT_MODEL_PASS`
- `vertical_slice_input_policy_test.gd` → `AETHERWAKE_INPUT_POLICY_PASS`
- `vertical_slice_signal_audio_test.gd` → `AETHERWAKE_SIGNAL_AUDIO_PASS`

These establish, within this local environment, deterministic exclusive choice state; meaningful guard→echo→quiet-strike counterplay; failure risk when ignoring telegraphs; stage-aware binding-sensitive prompts; keyboard/controller defaults that preserve custom remaps; and generation of distinct original question/answer PCM streams.

## Scene contracts — PASS after a full editor filesystem/import scan
The first disposable-checkout scene attempt failed before assertions because `.godot/imported` texture cache entries had not been created. This was an environment/import-cache problem, not a failed gameplay assertion.

After creating the project cache and running the verified editor long enough to complete its filesystem/import scan, the following exact-head scene tests passed:
- `vertical_slice_review_test.gd` → `AETHERWAKE_VERTICAL_SLICE_PASS: real scene, exclusive paths, readable challenge, pause/resume and two payoffs`
- `vertical_slice_accessibility_test.gd` → `AETHERWAKE_ACCESSIBILITY_PASS: text, motion, trace opt-out, dialogue cancel, safe challenge retry`

Godot printed ObjectDB leak warnings at test-process exit (8 instances in one run; 2 in the other). These did not change exit status or assertions, but should be treated as a cleanup-quality follow-up rather than silently ignored.

## Hosted CI classification
GitHub Actions checks at the current review branch are red because jobs are not being started. Exact check annotations state:

> The job was not started because recent account payments have failed or your spending limit needs to be increased.

This is an account/billing execution block. It is **not** a hosted test result. Hosted exact-head verification remains NOT ESTABLISHED until billing/limit is resolved and jobs actually execute.

## Boundaries
- No merge or release.
- No creator visual acceptance.
- No production field-pack admission.
- No change to Defender issue #293.
- No assertion that the prototype is fun, beautiful, balanced, or independently validated merely because the engineering contracts pass.
- Prior #326, #328 and #329 art/gait evidence remains separate.
