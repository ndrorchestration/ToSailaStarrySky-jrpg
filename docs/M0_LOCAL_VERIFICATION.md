# M0 local verification fallback

GitHub-hosted Actions for the private Aetherwake repository currently fail before checkout with `runner_id=0` and zero steps. This local lane exists so runner allocation does not force the project to weaken its verification contract.

## Command

From a Windows checkout of the exact candidate branch:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-m0-local.ps1
```

Optional development-only skips:

```powershell
.\scripts\verify-m0-local.ps1 -SkipInstall
.\scripts\verify-m0-local.ps1 -SkipBrowserInstall
.\scripts\verify-m0-local.ps1 -SkipWindowsPackage
```

A skipped Windows package is **not** release verification.

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

`M0_LOCAL_VERIFICATION=PASS_WITH_HUMAN_VISUAL_REVIEW_PENDING`

That state is intentionally **not** the same as final M0 acceptance. Human review of the rendered matrix is still required.

## Title audio

The title MP3 is governed separately. If the exact source has not yet been admitted to the checkout, first use:

```powershell
npm run admit:title-audio -- --source "C:\path\to\Aetherwake - Skyward Arpeggio Main Title.mp3"
```

The admission tool verifies the exact governed SHA-256 and byte size before copying or promoting anything. A mismatch fails closed.

For exact-head claims, commit the admitted canonical asset + generated manifest/runtime-registry changes before running the final verification lane.
