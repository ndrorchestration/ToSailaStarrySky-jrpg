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
