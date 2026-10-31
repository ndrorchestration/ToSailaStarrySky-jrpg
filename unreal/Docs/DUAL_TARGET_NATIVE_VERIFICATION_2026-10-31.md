# Unreal 5.8: dual target build / native receipt protocol (October 31, 2026)

**Status:** source code and script updated, **NOT run with native Unreal tooling**. This is a prerequisite for a real Chapter I vertical slice, not proof of a playable or beautiful result.

## What changed
- `Tools/Verify-Unreal.ps1` checks `Engine/Build/Build.version` and fails if the provided editor toolchain is not Unreal Engine 5.8.
- Builds the `ToSailTheStarrySkyEditor` Win64 Development target. Optional `-BuildGameTarget` additionally builds `ToSailTheStarrySky` Win64 Development, with a separate `game-target-build.log` receipt. This checks C++ game target viability, **not cooking, packaging, executable installation or Windows Defender QA**.
- Runs the officially documented automation command `-ExecCmds="Automation RunTest TSTSS;Quit"` and retains fail-closed JSON report name/state/error/warning checks. A native Editor automation test is not a rendered screenshot or physics proof.

## Execution
On a trusted Windows machine with UE 5.8 and the branch checked out cleanly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File unreal/Tools/Verify-Unreal.ps1 -EngineRoot "C:\\Program Files\\Epic Games\\UE_5.8" -BuildGameTarget
```

This path is an **example** and must match the actual installed engine. Logs and `head.txt` should be stored in `unreal/Saved/MigrationEvidence`. Any missing toolchain, incorrect version, nonzero compiler status, missing or mismatched tests, warnings or missing results must fail.

## Why this speeds development
Studio-style vertical-slice verification checks both the Editor environment used by tools and the Windows game target used by players, before attempting expensive scenic assets and a launcher. A separate renderer-enabled gameplay scene gate must follow, especially for the approved Ionia-first story, real ocean buoyancy, party data and save/resume. The existing Godot First Wake remains playable while Unreal is not.

**Scope boundary:** New script branches remain draft/unmerged. No native compile or performance measurements are asserted. Do not promote prior placeholder ship geometry or any character reference atlases as final art.
