# Unreal 5.8 verification: exact test identity gate (2026-10-31)

**Status: source committed, not yet executed on Windows with Unreal.** The verification process may report PASS only on genuine native build + complete TSTSS editor test evidence, at a pinned clean Git head.

## Production-quality practice applied

Epic's Unreal Engine 5.8 automation reports export `index.json` with `tests[].fullTestPath`, `state`, `errors`, `warnings`, `succeeded`, `failed`, `notRun`, and `inProcess`. Refer to [Epic: Review Test Results](https://dev.epicgames.com/documentation/unreal-engine/review-test-results-in-unreal-engine) and [Epic: Run Automation Tests](https://dev.epicgames.com/documentation/unreal-engine/run-automation-tests-in-unreal-engine).

Prior `Verify-Unreal.ps1` admitted at least a count of successful tests, which could accept *different* tests than those authored or overlook warning states. The updated runner compares discovered `TSTSS.*` test names with report identities, refuses missing/extra/duplicate test names, and requires each expected test's state to be `Success` with zero errors/warnings. Summary `failed`, `notRun`, `succeededWithWarnings`, and optional `inProcess` must be zero. Missing report = failure.

## Separation of evidence
1. **Source-lint check**: PowerShell and code inspected; no Unreal runtime claims.
2. **Native unit/feature test**: UE5.8 Win64 Editor target compiled, per-test JSON accepted at exact SHA.
3. **Native level functional test**: real ship/sea overlap and stability in an authored map. NullRHI unit tests **do not** prove visuals or buoyancy.
4. **Visual performance test**: renderer-enabled native screenshots, gameplay footage, Unreal Insights CPU/GPU frame pacing, memory and VRAM on specified Windows hardware.
5. **Player acceptance**: uninterrupted Ionia-first Chapter I sequence, save/resume, creator-correct characters, player review. Separate from code/test pass.

## Additional improvement opportunities
- Use Unreal Functional Testing for full-map collision, quest, and save/reload; Gauntlet becomes useful once there's a real packaged game session to automate, not as premature infrastructure.
- Use Epic's screenshot comparison test tooling for repeatable reference/actual captures, keeping human art direction approval separate.
- Audit all newly introduced test IDs before merging stacked PRs #608/#615/#616/#617/#618. Discard obsolete sibling PR #614 synthetic water-success tests; retain its negative save-restore cases already adapted in #618.
- Prevent test scripts from marking compiler or native launch PASS without actual engine binaries, complete logs and exact-SHA receipts.
- Allocate artist time to one real playable hero scene after native integration, rather than expanding study-only ship and biome mockups.

No approvals, main merges, build results, packaged performance or release permissions are asserted.
