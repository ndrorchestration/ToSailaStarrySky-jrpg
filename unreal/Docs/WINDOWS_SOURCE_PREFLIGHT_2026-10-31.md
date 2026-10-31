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


## Follow-up environment verification (same date)
- The `UE_5.8` directory now exists at `C:\Program Files\Epic Games\UE_5.8`, but a direct directory listing shows **only `.egstore`**. Therefore `Engine/Build/Build.version`, `Engine/Build/BatchFiles/Build.bat`, and `Engine/Binaries/Win64/UnrealEditor-Cmd.exe` are absent. It is **installer staging, not an installed engine**.
- Invoking `Verify-Unreal.ps1 -EngineRoot 'C:\Program Files\Epic Games\UE_5.8' -SkipTests -BuildGameTarget` produced the expected fail-closed preflight error: `Missing Unreal Build.bat at C:\Program Files\Epic Games\UE_5.8\Engine\Build\BatchFiles\Build.bat`. No compilation was attempted.
- Visual Studio's `vswhere.exe -all -products * -format json` returned `[]`; no compatible MSVC install or Windows SDK was detected in standard locations. Epic UE 5.8 requires at least Visual Studio 2022 17.14 / MSVC 14.38 and Windows SDK 10.0.22621.0; recommended Visual Studio 2026 / MSVC 14.50, per its official 5.8 release notes.
- `winget show --id Microsoft.VisualStudio.2022.BuildTools --exact` found version 17.14.44. A noninteractive installation command requesting the C++ build workload was launched on the authorized Windows machine; **the command only reached the installer download stage in the observed output, so its completion and component readiness must be rechecked**.
- Continue only after checking engine version/Build.bat/Editor-Cmd, `vswhere` toolchain inventory, Windows SDK and available disk. Do not run old UE 5.3 binaries and do not infer a UE 5.8 PASS from the presence of `.egstore`.


## Repeatable preflight now checked on Windows
`unreal/Tools/Test-UE58Readiness.ps1` is a read-only readiness gate for the pinned engine, Visual Studio C++ toolchain and Windows SDK. It reports the individual requirements as JSON with `-Json` and returns exit code **2** if any are missing. The script does not download/install an engine or start a compile.

Executed on the connected `neontic` Windows computer from isolated checkout `dc4ed9af6168aa3fc0d44ffe477a3580ae6e2407`:
- PowerShell parser: **0** syntax errors.
- `EngineVersionFile=false`, `EngineBuildBatch=false`, `EngineEditorCommand=false`, `EngineVersionIs58=false`.
- `VsWherePresent=true`, `MsvcToolchainPresent=false`, `WindowsSdkIncludePresent=false`.
- `ReadyForPinnedBuild=false`, **readiness exit=2** (expected blocked status).
- Visual Studio installer continued to show `Starting package install...`, without verified completion.

Only when readiness is true should `Verify-Unreal.ps1 -EngineRoot 'C:\Program Files\Epic Games\UE_5.8' -BuildGameTarget` be used for native evidence. A green readiness result alone is not a compile or game test.
