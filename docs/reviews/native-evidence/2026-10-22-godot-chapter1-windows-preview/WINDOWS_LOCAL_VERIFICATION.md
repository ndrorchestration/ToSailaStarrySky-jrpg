# First Wake Chapter I native Godot Windows preview — exact verification
**Date:** 2026-10-22  
**Exact package source:** `355423841df86a2e8d9742c209aae73ad391b2df`  
**Base:** PR #339 / `feat/godot-first-wake-save-codec-20261022`  
**Scope:** private native-migration owner preview; not parity-complete replacement or public release.

## Toolchain custody
Godot editor:
- version: `4.7.2.stable.official.ed1daf0bf`
- Windows editor used from the previously verified local tool installation.

Official matching export templates:
- asset: `Godot_v4.7.2-stable_export_templates.tpz`
- GitHub-reported size: **1,281,349,702 bytes**
- locally observed size: **1,281,349,702 bytes**
- GitHub SHA-256: `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`
- locally calculated SHA-256: `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`
- installed template version: `4.7.2.stable`
- Windows release template: `windows_release_x86_64.exe`, 109,268,480 bytes
- Windows debug template: `windows_debug_x86_64.exe`, 103,176,704 bytes

Only the matching Windows templates and `version.txt` were extracted into the 4.7.2 template directory.

## Exact pre-export gates — PASS
The final consolidated exact-head run passed:
- native Windows package static safety contract;
- Chapter I packaged-content authority contract;
- four authored five-line contact dialogue cursor contract;
- **real-scene dialogue gate** (Wakeheart/Ionia dialogue gates progression and movement);
- Chapter I FSM contract;
- fail-closed versioned save-codec contract;
- real-scene save/restore contract with invalid-snapshot rejection;
- real Chapter I review-scene traversal through Signal → Crossing → Contact → Choice → Wake → Done;
- Windows preview main-scene/export-surface contract.

The exported preview boots directly into:
`res://scenes/first_wake_chapter1_player_preview.tscn`.

## Exact native executable — PASS
Artifact:
`Aetherwake-First-Wake-Godot-Preview.exe`

- size: **113,492,464 bytes**
- SHA-256: `97984a39e1e080b1140c1cf3e8f4676c418414289053625142f03ee01338f728`
- Microsoft Defender custom scan: **PASS / no threat reported**
- real responsive launch: **PASS**
- live window title: `Aetherwake - First Wake Chapter I Native Preview`

An initial export attempt successfully packed resources but the wrapper observed the output before it became visible. The exporter now uses a bounded 10-second post-export file-observation window. The final exact-head build passed with no timing dependence.

## Exact installable ZIP — PASS
Artifact:
`Aetherwake-First-Wake-Godot-Native-Preview-Windows.zip`

- size: **42,292,984 bytes**
- SHA-256: `6a1f4d716217b4380d6f064bacfa90def3707ba2d756973a683dd6ed8c4ae2ec`
- `Install-Aetherwake-Godot-Preview.cmd` SHA-256: `c9e75b1deb541c3433ef170ca48a694e02910016a0e08220579d674d7fc6106c`
- `Uninstall-Aetherwake-Godot-Preview.cmd` SHA-256: `c62428deb7fe59e52f32a3b43fac8a0b61e7136597eff9eade51e981122c3e4f`

Microsoft Defender custom scans: **PASS / no threats reported** for:
- install wrapper;
- uninstall wrapper;
- exact packaged native executable;
- exact final ZIP.

No Defender exclusion, allowlisting, disabled protection, execution-policy bypass, NSIS, or administrator elevation was used.

## Exact install / live launch — PASS
The final ZIP was freshly extracted and installed to the separate per-user path:
`%LOCALAPPDATA%\Programs\Aetherwake-Godot-Native-Preview`.

Verified:
- installed executable present and SHA-256 matched the source executable;
- installed uninstaller present;
- Desktop shortcut present;
- Start Menu shortcut present;
- responsive native Godot window observed;
- window title `Aetherwake - First Wake Chapter I Native Preview`.

This path is intentionally separate from the current NW.js owner build.

## Running-app uninstall — PASS
Two real wrapper defects were found and repaired during verification:

1. the first installer copied only the executable, not the uninstaller;
2. the first installed uninstaller stopped the game and removed shortcuts but could leave its own install directory behind.

The final wrapper now:
- installs the uninstaller with the native executable;
- hands uninstall to a temporary self-copy outside the install directory;
- stops only the exact installed preview executable;
- removes Desktop and Start Menu shortcuts;
- retries recursive install-directory removal for a bounded interval;
- fails closed if the directory remains;
- removes the temporary cleanup copy only after success.

Final exact-head result:
- running game process removed;
- install directory removed;
- Desktop shortcut removed;
- Start Menu entry removed;
- temporary cleanup copy removed.

Result:
`FINAL_RUNNING_APP_UNINSTALL=PASS`  
`AETHERWAKE_GODOT_NATIVE_CONSOLIDATED_EXACT_QA=PASS`

## Boundaries
This is the first fully exported/installable **native Godot Chapter I migration preview**, but it is not yet the parity-complete replacement for PR #336.

Still unresolved in the native line:
- production combat formulas/encounter scene parity;
- full final character sprite/animation pipeline;
- final 2.5D environment/cinematic treatment;
- creator visual acceptance;
- external player acceptance;
- hosted GitHub Actions execution where jobs still fail before steps on this stack;
- issue #293 disposition;
- public release authorization.

PR #336 remains the fuller rollback/current packaged Chapter I owner build. This native preview exists to let the creator install and directly play the migrated Godot path while parity work continues.
