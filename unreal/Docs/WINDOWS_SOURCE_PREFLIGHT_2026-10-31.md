# Windows native-environment preflight — 2026-10-31

**Evidence scope: actual Windows PowerShell and Git commands, no Unreal compilation.**

## Host inspected
- Authorized Desktop Commander device: neontic (Windows, PowerShell).
- Engine directories observed: `C:\Program Files\Epic Games\UE_5.3`. The required `UE_5.8` engine directory was **not present** among installed Epic versions.
- Git and Python were found.
- An existing local Git checkout remained untouched. A separate detached worktree was created at `C:\Users\Admin\Documents\Codex\TSTSS-Unreal-Source-QA-20261031` from this branch; exact checkout HEAD `95224513f4c1af6afa4f4ad7363007d3a32bca0e`.

## Observed command results
- PowerShell `System.Management.Automation.Language.Parser.ParseFile` on `unreal/Tools/Verify-Unreal.ps1`: **0 syntax errors**.
- Scanned `Private/**/*Tests.cpp` for `IMPLEMENT_SIMPLE_AUTOMATION_TEST` declarations: **17 files / 25 test IDs / 25 unique IDs**.
- Legacy fixed test slot `tstss_automation_roundtrip_v1` absent from `TSTSSRulesTests.cpp` after this branch's change.
- `git diff --check HEAD^ HEAD`: **exit 0**, no whitespace errors.
- `git status --porcelain`: empty, worktree clean.

## What changed on this branch
The older `TSTSS.Save.RoundTripFirstWakeAndParty` test now uses `tstss_qa_` plus a per-run GUID. It refuses an occupied slot and attempts cleanup on a failed initial save, avoiding repeated-test collisions or accidental overwrites. It remains a test-only change, not a production save-schema modification.

## Admission status
- **PASS:** source-only Windows preflight checks listed above.
- **NOT RUN:** UE 5.8 UHT, Editor/Game C++ compile, Unreal automation suite, first playable map, physics/cinematic render, installer, crash-resilient save/load.
- The installed UE 5.3 version must **not** be used to claim 5.8 success. Exact-head 5.8 build and native test receipts remain required.

Review the authored startup Ender data asset and integrate the real First Wake vertical slice before any merge or public release. Main and the playable Godot reference are unchanged.
