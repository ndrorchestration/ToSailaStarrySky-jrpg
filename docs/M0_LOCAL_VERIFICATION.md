# M0 local verification fallback

GitHub-hosted Actions for the private Aetherwake repository currently fail before checkout with `runner_id=0` and zero steps. This local lane exists so runner allocation does not force the project to weaken its verification contract.

## Command

From a Windows checkout of the exact candidate branch with a **clean working tree**. The verifier fails closed if Git HEAD provenance is unavailable or if uncommitted changes are present, so local results cannot be mistaken for exact-head evidence:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-m0-local.ps1
```

Optional development-only skips:

```powershell
.\scripts\verify-m0-local.ps1 -SkipInstall
.\scripts\verify-m0-local.ps1 -SkipBrowserInstall
.\scripts\verify-m0-local.ps1 -SkipWindowsPackage
```

All three skip switches are **development-only**. A run using `-SkipInstall`, `-SkipBrowserInstall`, or `-SkipWindowsPackage` can never produce a passing M0-local result. Windows-package omission exits with `M0_LOCAL_VERIFICATION=INCOMPLETE_REQUIRED_GATE_SKIPPED`; prerequisite omissions exit with `M0_LOCAL_VERIFICATION=INCOMPLETE_REQUIRED_PREREQUISITE_SKIPPED`.

## What it runs

The script executes the M0 persistence, First Wake benchmark, semantic input/controller, accessibility rendering, governed audio, and world-authority contract gates; then it runs:

- ordinary browser smoke;
- live First Wake benchmark;
- live controller-parity smoke;
- 54-frame accessibility visual matrix;
- exact Windows package/install/save-restart verifier unless explicitly skipped.

It requires the visual matrix manifest to contain exactly **54 captures** and `HUMAN_REVIEW_REQUIRED`.

## Output

Machine-readable summary:

`artifacts/m0-local-verification/summary.json`

The summary records the checkout HEAD, working-tree status, each gate and exit code, visual-matrix status, and Windows package result.

A successful script exits with:

`M0_LOCAL_VERIFICATION=PASS_WITH_MANUAL_ACCEPTANCE_PENDING`

The summary also records two manual acceptance dependencies:

- `accessibilityVisualReview = PENDING_HUMAN_REVIEW`;
- `uncoachedExternalPlayer = NOT_RUN`, routed to `docs/M0_EXTERNAL_PLAYTEST.md` and `docs/m0-external-playtest-record.template.json`.

That state is intentionally **not** the same as final M0 acceptance. Human review of the rendered matrix **and** a candidate-bound uncoached external-player completion pass are still required.

## Title audio

The title MP3 is governed separately during development, but **final local M0 and Windows release verification now fail closed unless it is admitted and Git-tracked**. If the exact source has not yet been admitted to the checkout, first use:

```powershell
npm run admit:title-audio -- --source "C:\path\to\Aetherwake - Skyward Arpeggio Main Title.mp3"
```

The admission tool verifies the exact governed SHA-256 and byte size before copying or promoting anything. A mismatch fails closed.

For exact-head claims, commit the admitted canonical asset + generated manifest/runtime-registry changes before running the final verification lane.

The strict M0 readiness gate is `npm run test:m0-title-audio-ready`. It requires `repositoryStatus=admitted`, `runtimeRegistration=true`, completed repository transfer, the exact Git-tracked canonical MP3, and the governed SHA-256/byte count. Development-safe silent fallback remains valid outside final M0 verification.
