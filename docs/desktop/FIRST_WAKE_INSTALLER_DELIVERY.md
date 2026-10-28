# To Sail the Starry Sky — click-to-install Windows game delivery

**2026-10-28 — NOT YET PUBLISHED.** This is the build/proof design for a later creator-authorized **native Godot** Windows prerelease, not the older Aetherwake/NW.js installer or Lyra-first Godot preview ZIP.

## Player contract

After a genuinely verified installer release, the repository README will have **Download for Windows** linking directly to the release asset `ToSailTheStarrySky-Setup.exe`. The player downloads it, double-clicks, installs to `%LOCALAPPDATA%\Programs\ToSailTheStarrySky-FirstWake`, and launches via Start menu or desktop shortcut. It runs in a standalone **resizable/maximizable native Godot window** with a normal title bar; F11 or Alt+Enter toggles fullscreen. No browser, command line, Python, PowerShell, Node or Godot editor required. The game has Ender→Ionia hiring and engineering, physically verified *local 2D* splashdown with actual 3D ship presentation, player-controlled reserve inspection, and separate F5/F9 postflight checkpoint. The player must still be told the game is a **First Wake playable preview**, not a complete JRPG.

## Implemented in draft installer pipeline

- `godot/project.godot` preserves the new `res://scenes/first_wake_game.tscn` startup, explicitly normal bordered/resizable window.
- `godot/scripts/first_wake_game.gd` handles native fullscreen controls without depending on a browser.
- `scripts/build-first-wake-godot-installer.ps1` requires genuine pinned Godot **4.7.2** Windows editor and official release templates already installed on the build machine, runs editor import + actual end-to-end Godot `first_wake_game_entry_test.gd`, exports the **embedded-PCK** `ToSailTheStarrySky.exe` and compiles original `ToSailTheStarrySky-Setup.exe` using NSIS. It creates `SHA256SUMS.txt`. It does not upload or release.
- `packaging/windows/ToSailTheStarrySky.nsi` installs without admin, includes only game executable, creates Start/Desktop shortcuts and an uninstall entry in the install directory, and only deletes explicitly owned binaries/marker/shortcuts. Save files under Godot user data survive uninstall; no broad recursive deletion.
- The existing `.github/workflows/godot-exact-windows-qa.yml` retains its separate **Defender real-time host security gate unchanged**, and adds an **independent functional proof** in its Windows-functional job: compile the Setup.exe, silent install to an isolated account-local app path, verify installed binary SHA-256 matches source export, observe the launched game's native window, then uninstall and verify app files removed. It explicitly reports `DEFENDER_QA=NOT_ESTABLISHED` and `PUBLIC_RELEASE_AUTHORIZED=NO`. **Functional proof is not security certification**, particularly on a runner whose Defender real-time protection is disabled.
- `tests/first-wake-installer-contract.test.js` confirms non-admin install, original entry point, no destructive uninstall, explicit sign/Defender/publication claims, and window controls. The old NW.js desktop delivery remains separate.

## Windows installer UX and ownership hardening (additional draft pass)

The player-facing setup now has a **welcome / folder selection / progress / finish** sequence and an optional **Launch To Sail the Starry Sky** checkbox on its final screen. The per-user installation is also registered under **Windows Settings → Installed apps**, so the Uninstall action is discoverable without hunting for files. Godot's normal native title bar stays resizable and maximizable; F11/Alt+Enter toggles full-screen and restores the *previous* maximized/windowed state.

Safety: an existing install folder, already occupied desktop/Start shortcut or matching registered application causes the installer to **refuse to overwrite**. In this preview line, uninstall before reinstalling or choose another empty destination. The uninstaller checks its versioned ownership marker, deletes only this preview's executable, shortcuts and uninstall registration, leaves other files and Godot save data intact, and avoids recursive deletion. No administrator access is requested.

The new **exact Windows functional proof** must inspect the installed executable's real native window styles, maximize and restore it using Windows' own API, verify both shortcuts resolve to the installed executable, verify Windows Installed apps metadata, confirm repeat setup refuses to overwrite a working installation, and confirm shortcuts and registry records are cleaned by uninstall. This is a **functional QA layer**, distinct from the still-unmet Defender-on custody and code-signing requirements. A modern setup screen, functional install proof and a valid SHA-256 are not sufficient on their own for public release.

## Why the Defender failure matters

The current GitHub-hosted `windows-2022` exact custody job has reported `DEFENDER_ANTIVIRUS_ENABLED=True` but `DEFENDER_REALTIME_ENABLED=False`. Its failure is a **runner security prerequisite**, not a gameplay/rendering fault. **Do not silence or bypass this security test to publish an installer.** Continue to run functional export/install/window/uninstall tests independently; obtain a clean Defender-on Windows runner or a trusted maintainer machine for the exact installer scan, detailed receipts, runtime test, and creator/player review. The present installer is **unsigned** until publisher Authenticode signing and verification are explicitly arranged; Windows SmartScreen/reputation warnings are possible even for legitimate unsigned binaries. Do not ask players to disable Defender.

## Promotion gates before adding an actual downloadable link to README

1. Exact source/head pinned; Godot native full test + true main-scene first-flight checkpoint run pass, plus actual native 2.5D viewport screenshots inspected.
2. Same source has Windows exported EXE, actual Setup.exe compilation, clean install, normal resizable/maximized window, first rendered frame, input and F5/F9 save/restart, uninstall; installer SHA-256 recorded.
3. Full source/installer Defender-on security scan and trustworthy source provenance; signed installer or explicitly accepted unsigned-risk preview with clear expectations (publisher approval).
4. Independent player on real target Windows PC performs full first-flight / postflight playtest, accessibility + key remapping, tested window maximize/fullscreen, performance, graphics and audio.
5. **User explicitly approves a tagged prerelease/release/public deployment.** Only then attach the verified installer with `SHA256SUMS.txt` to a real GitHub Release and add the exact **existing** asset URL under **Download for Windows** in the repository README. Never link a fabricated, older Aetherwake, draft/unpublished or unverified installer.

**This branch and all installer output are development-only.** The Windows packaging CI currently retains output runner-locally; it is not an installer download destination. No release, latest-asset alias or public README button has been published at this stage.

## Windows installer security evidence — 2026-10-28

The **real NSIS Windows installer** is compiled from the native Godot First Wake branch and undergoes install, launch, real Win32 window maximize/restore, shortcuts, Installed Apps registry, repeat-install refusal and uninstall QA. [Exact-head Windows run #40648288232](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40648288232) confirms Windows functional job **SUCCESS** at SHA `3821a624be769e56eefdd505893be4187c8d2d6e`; installer runner-local SHA-256 `e50e0a6927b45ad476927266598946701bfd5a77cc456329f394effe52b8da5d`. This is not a security-release approval or downloadable asset.

Two GitHub Windows images were tested for Defender-on security custody:

- [Windows 2022 restoration probe #40647882552](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40647882552): antivirus ON, realtime OFF; attempted restoration removed whole-drive exclusions but realtime stayed **OFF**. Fail-closed rejection.
- [Windows 2025 read-only probe #40651271403](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40651271403): antivirus ON, realtime **OFF**, two whole-drive exclusions. Fail-closed rejection.

Both hosted environments fail the current required Defender-on custody prerequisite. These temporary probes were removed from the proposed installer branch after their evidence was recorded. The **original exact Windows Defender custody preflight remains unchanged**, so security failure still blocks release.

### Trusted Defender-on Windows alternative (staged, unverified)

The new `scripts/verify-first-wake-installer-defender.ps1` checks the source SHA, active Defender realtime protection, whole-drive exclusions, scan-ID and exact-file-matched start/completion Defender events, detections and SHA-256 of **both** the Godot game executable and the actual NSIS `ToSailTheStarrySky-Setup.exe`. It records Authenticode status and emits a local JSON receipt with `publicReleaseAuthorized=false`. It does not sign, upload, promote or publish.

The optional `trusted-installer-defender-qa` job is gated to the repository owner's own PR plus explicit `trusted-defender-on` label, and needs an online reviewed self-hosted Windows X64 runner labeled `defender-on` with configured `TSTSS_GODOT_EXE` and `TSTSS_NSIS_EXE`. The runner independently checks Defender status; its label is not proof. **No suitable trusted runner has been verified.** Running the same build/scan locally on an authorized, protected Windows computer is a possible alternative.

### After security verification and creator approval

Publish the exact verified `ToSailTheStarrySky-Setup.exe` to an approved GitHub Release, check its asset SHA-256, and add a **single direct Windows installer download** link to README. The player then double-clicks the setup and launches the native Godot game without Godot, ZIP extraction, a browser, or command-line tooling. No link should be published before that specific binary and release asset actually exist.
