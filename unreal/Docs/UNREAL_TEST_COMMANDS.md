# Unreal verification — NOT YET EXECUTED

Run against a real Windows machine with Unreal Engine 5.8 installed; replace engine path as needed.

1. Generate IDE project files from `unreal/ToSailTheStarrySky.uproject`.
2. Build `ToSailTheStarrySkyEditor Win64 Development` with UnrealBuildTool.
3. Run Editor automation tests using:
   `UnrealEditor-Cmd.exe <absolute-path-to-uproject> -unattended -nop4 -nullrhi -ExecCmds="Automation RunTests TSTSS; Quit" -log`
4. Archive compiler log, automation report and exact commit SHA. A process exit alone is insufficient; inspect per-test results and failures.
5. Run a renderer-enabled scene capture separately. NullRHI proves no visuals.
6. Package a Windows development build only after native runtime/asset imports are verified.

Current code-only scope: First Wake milestone ordering, deterministic combat transactions, basic versioned SaveGame validation. There is no native map, cooked character asset, robust save migration/serialization, or installer on this branch yet. Do not represent the tests as passing until executed.

Testability follow-up: implement round-trip save/load, mirrored Godot combat fixtures and screenshot comparisons, then enforce Windows CI build gates.

## New round-trip regression
The `TSTSS.Save.RoundTripFirstWakeAndParty` editor automation test writes to a dedicated test slot, loads it, checks version, First Wake beat, and Ender's party fields, then deletes the test slot. If that slot already exists, the test fails closed and avoids overwriting it. Run in an isolated test profile/workspace: interrupted test execution could leave the dedicated slot behind. A passing test will not establish crash-atomic writes, corrupt-save repair, or Godot-save compatibility.

## Blocking review gates
- Run UnrealHeaderTool and Win64 editor compilation before any claim that the C++ classes build.
- Verify automation reports rather than only the command exit code; tests added here are not executed by committing them.
- Confirm test cleanup, PIE interaction/camera, true physical First Wake events, and Blueprint milestone hook behavior.
- Capture native UE renderer stills/video and obtain artistic approval of imported cast; prior approved reference artwork is not a rigged character asset.
- Keep migration PR draft and Godot playable until a working Windows packaged build is tested.

## Automation fixture crash-safety gate — 2026-10-30

`TSTSS.Combat.AbilityAuthorization` now aborts its test early if combat initialization or the expected successful action fails, and validates roster size before indexing result entries. This avoids a secondary invalid-array-access failure obscuring the original failed assertion. **The updated test has not been executed in Unreal Engine 5.8.** Collect an exact-SHA Win64 compile log and Editor automation report before interpreting this as a passing test or promoting the draft.
