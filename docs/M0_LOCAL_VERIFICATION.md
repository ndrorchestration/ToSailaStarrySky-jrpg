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
- 58-frame accessibility visual matrix;
- exact Windows package/install verifier unless explicitly skipped, including normal save-restart restoration and simulated primary-loss recovery from a surviving `.bak`.

It requires the visual matrix manifest to contain exactly **58 captures** and `HUMAN_REVIEW_REQUIRED`.

## Output

Machine-readable summary:

`artifacts/m0-local-verification/summary.json`

The summary records the checkout HEAD, working-tree status, each gate and exit code, visual-matrix status, and Windows package result. The Windows package result is not sufficient unless the installed candidate proves both `DESKTOP_SAVE_RESTART=PASS` and `DESKTOP_SAVE_BACKUP_ONLY_RECOVERY=PASS`. It also binds the exact visual-manifest SHA-256, release-evidence SHA-256, release source commit, installer SHA-256, and portable-ZIP SHA-256 so a passing local run is a single candidate evidence packet rather than a collection of unbound PASS markers.

A successful script exits with:

`M0_LOCAL_VERIFICATION=PASS_WITH_MANUAL_ACCEPTANCE_PENDING`

The summary also records two manual acceptance dependencies:

- `accessibilityVisualReview = PENDING_HUMAN_REVIEW`, routed to `docs/M0_ACCESSIBILITY_VISUAL_REVIEW.md` and `docs/m0-accessibility-visual-review.template.json`;
- `uncoachedExternalPlayer = NOT_RUN`, routed to `docs/M0_EXTERNAL_PLAYTEST.md` and `docs/m0-external-playtest-record.template.json`.

That state is intentionally **not** the same as final M0 acceptance. Human review of the rendered matrix **and** a candidate-bound uncoached external-player completion pass are still required.

## Title audio

The title MP3 is governed separately during development, but **final local M0 and Windows release verification now fail closed unless it is admitted and Git-tracked**. If the exact source has not yet been admitted to the checkout, use the governed Windows handoff wrapper from a clean branch checkout:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\admit-title-audio.ps1 -Source "C:\path\to\Aetherwake - Skyward Arpeggio Main Title.mp3" -Commit
```

The wrapper invokes the underlying admission tool, verifies the exact governed SHA-256 and byte size, stages **only** the canonical MP3 + governed manifest + generated runtime registry, rejects unexpected staged paths, runs the strict M0 readiness gate, creates a fixed-scope admission commit, verifies the working tree is clean, then reruns readiness against the committed candidate.

Omit `-Commit` only for diagnostic/development use; that leaves the verified three-file admission staged and reports `COMMIT_REQUIRED=true`.

For exact-head M0 claims, use the committed form before running the final verification lane.

The strict M0 readiness gate is `npm run test:m0-title-audio-ready`. It requires `repositoryStatus=admitted`, `runtimeRegistration=true`, completed repository transfer, the exact Git-tracked canonical MP3, and the governed SHA-256/byte count. Development-safe silent fallback remains valid outside final M0 verification.

## Manual acceptance packets

A technically successful local M0 run still exits as `PASS_WITH_MANUAL_ACCEPTANCE_PENDING`. It now prepares both remaining human gates against the exact candidate:

- Accessibility review packet:
  - `artifacts/accessibility-visual-matrix/review-index.html`
  - `artifacts/accessibility-visual-matrix/human-review.json`
- Uncoached external-player packet:
  - `artifacts/m0-external-playtest/observer-guide.html`
  - `artifacts/m0-external-playtest/external-playtest.json`

The external-playtest packet is generated **only after** the exact Windows package/install/save-restart lane succeeds and `local-release/RELEASE_EVIDENCE.json` is present. It binds the playtest record to the exact source commit, installer SHA-256, installer filename, build ID, and release-evidence SHA-256 while leaving `playerVerifiedStandalone=false` and `result=NOT_RUN` until the human session occurs.

The local summary records these packet paths but never upgrades either manual gate automatically.

## One-command operator lane

For the normal Windows operator path, use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-m0-operator.ps1 -TitleAudioSource "C:\path\to\Aetherwake - Skyward Arpeggio Main Title.mp3"
```

The operator lane requires a named branch and clean checkout. It first runs the strict M0 title-audio readiness gate, which verifies the canonical MP3 exists, is Git-tracked, and matches the governed byte count/SHA-256 in addition to manifest/runtime admission state. If strict readiness fails, it performs the governed committed admission using the supplied exact source and then runs the full exact-head local M0 verifier. It skips admission only when the strict readiness gate actually passes.

A successful technical run emits:

`M0_OPERATOR_LANE=TECHNICAL_PASS_MANUAL_ACCEPTANCE_PENDING`

It does **not** mean final M0 acceptance. The command verifies that the M0 summary remains `PASS_WITH_MANUAL_ACCEPTANCE_PENDING`, accessibility remains `PENDING_HUMAN_REVIEW`, the external-player gate remains `NOT_RUN`, and the candidate-bound manual review packets were generated. It prints the exact paths for the accessibility review and external playtest artifacts.


## Final M0 acceptance

After the technical operator lane passes and both human records are completed as explicit `PASS`, run:

```powershell
npm run validate:m0-acceptance -- --summary ".\artifacts\m0-local-verification\summary.json" --accessibility-review ".\artifacts\accessibility-visual-matrix\human-review.json" --matrix-dir ".\artifacts\accessibility-visual-matrix" --external-playtest ".\artifacts\m0-external-playtest\external-playtest.json" --release-evidence ".\local-release\RELEASE_EVIDENCE.json"
```

The validator first requires the technical summary to remain `PASS_WITH_MANUAL_ACCEPTANCE_PENDING`, requires the current checkout to be the exact same Git HEAD with no tracked or staged source drift, then verifies that the visual manifest, accessibility review, release evidence, installer identity, portable ZIP identity, and external-player record all bind to that same exact Git commit and hashes. It invokes the dedicated accessibility-review and external-playtest validators rather than bypassing them.

Only after both human evidence records independently validate as `PASS` does it write:

`artifacts/m0-local-verification/M0_ACCEPTANCE.json`

That acceptance record fingerprints the technical summary, visual manifest, accessibility review, release evidence, installer, portable ZIP, and external-playtest evidence. Before the human reviews occur, this command must fail closed and no final M0 acceptance record is admissible.
