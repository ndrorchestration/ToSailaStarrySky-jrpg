# Native Windows verification

Run from PowerShell on a Windows machine with licensed Unreal Engine 5.8 installed:

```powershell
powershell -ExecutionPolicy Bypass -File unreal/Tools/Verify-Unreal.ps1 -EngineRoot "C:\Program Files\Epic Games\UE_5.8"
```

This script fails closed if the engine is absent, build fails, the automation process fails, or an expected JSON report is missing/incomplete. It records logs and Git HEAD under `unreal/Saved/MigrationEvidence` (do not commit logs). It is **not** a substitute for native graphics captures, a playable level, installer checks or full QA. `-SkipTests` is a diagnostic option and must not count as release verification. The editor's report schema may need adjustment based on an actual engine run; no run is claimed here.
