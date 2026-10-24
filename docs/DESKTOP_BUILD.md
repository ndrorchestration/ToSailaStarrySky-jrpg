# To Sail the Starry Sky — Windows Desktop Build Contract

**Historical installer identity:** Aetherwake. The project has been renamed, but executable/setup/installed-location names are intentionally unchanged pending backwards-compatibility verification. **This is a technical build contract, not a recommendation to download a current Windows package.** [Defender security issue #293](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/293) remains unresolved: never restore, whitelist, execute or distribute the specifically detected QA uninstaller.

To Sail the Starry Sky retains its HTTP-served browser path for development and automated smoke testing. The intended player-facing design is a packaged NW.js desktop build, subject to exact-build security, QA and human approval.

## Historical installation flow (NOT current release approval)

The desktop window opens at **1440×960** by default. Maximizing the window enlarges the game further while preserving its 3:2 aspect ratio. **Alt+Enter** or **F11** toggles true NW.js fullscreen; **Escape** exits fullscreen. The internal 960×640 coordinate system stays unchanged so authored UI, combat positions, and input geometry remain stable.


1. For a separately approved, verified historical Windows package only, obtain **Aetherwake-Setup.exe** from the appropriate reviewed release source.
2. Run the installer and choose the install location if needed.
3. Launch the historically named Aetherwake application from the created desktop or Start Menu shortcut after independent security clearance.

The standard installer installs the packaged runtime per-user under `%LOCALAPPDATA%\\Programs\\Aetherwake`, does not require administrator elevation, and does not require Python, PowerShell, a manually started HTTP server, or opening an HTML file.

**Historical fallback:** **Aetherwake-Windows.zip** was published for manual extraction. Keep extracted files together. Do not execute it as an unreviewed substitute for a security-cleared installer.

Do not use superseded self-extracting/SFX artifacts. If Windows Defender flags an artifact, do not whitelist or bypass it; preserve the exact detection name and SHA-256 for a false-positive report.

## Historical technical checkpoint — 2026-10-06

The exact Preview 0.1 candidate identified at that historical checkpoint was PR #250 head `46f50c581d992bf581bb6b6d7961a9421b8b779d`.

Technical evidence on that exact source is green:

- hosted smoke run `37557721548`: **SUCCESS**;
- current-head seven-frame evidence captured locally on NeonPC with no browser errors;
- title-ready evidence now shows the actual title/menu;
- the earlier opaque cyan/teal scanline failure is not reproduced;
- local packaged `Aetherwake.exe` reached runtime-ready + first-frame on NeonPC;
- Windows workflow-dispatch run `37559269564`: **SUCCESS**;
- no-admin installer build: **PASS**;
- exact installed-candidate launch: **PASS** with `DESKTOP_RENDER_READINESS=PASS`;
- portable ZIP verification: **PASS**;
- SHA-256 manifest generation: **PASS**;
- prerelease publication: **PASS**;
- published installer re-download, hash verification, isolated install, and installed launch on NeonPC: **PASS**.

Published candidate hashes:

```text
7feb6de364264617095a59dd9329a99ebfa77a144b0f5887a7ae7ff064f6221d  Aetherwake-Setup.exe
4c6efc6ea1cecf6468fb983fd8ff5fd5d0ce8645262779551841f663c5326173  Aetherwake-Windows.zip
```

At that checkpoint, human/player acceptance remained pending. **Current** release admission also requires review of later security findings, asset rights and any newer package candidate. Technical PASS for an older exact SHA does not establish present Windows package security, visual approval or player acceptance. The exact protocol and acceptance boundary are documented in `docs/PREVIEW_0_1_ACCEPTANCE.md`.

The GitHub Actions artifact-quota issue remains open as infrastructure debt. Historical local/RDC evidence could support review of that specific candidate but cannot be transferred to newer builds or treated as current host availability.

## For maintainers

The production desktop layout intentionally follows the same structural pattern used by RPG Maker MV/NW.js games such as the Memories reference: the NW.js launcher/runtime lives at the package root, a minimal root `package.json` points to `www/index-embedded.html`, and the game payload lives under `www/`. Development files, tests, docs, and npm tooling are not part of the player runtime.

The release-critical path is intentionally a **single pinned Windows job**. This avoids a previously demonstrated GitHub Actions artifact-storage/quota failure mode and ensures the bytes that are published are the same bytes that were built and tested.

The job performs, in order:

1. lockfile install and desktop packaging contract;
2. staged Memories-style NW.js Windows build;
3. portable ZIP creation;
4. NSIS installer compilation;
5. clean per-user installer execution;
6. launch the installed `Aetherwake.exe` and require an application-level readiness marker proving `setup()` completed and a 960×640 first frame rendered;
7. portable ZIP layout verification;
8. SHA-256 generation;
9. release publication only for manual/tagged release runs.

No `upload-artifact` / `download-artifact` transfer is on the release-critical path. The maintainer-local Windows script remains the independent fallback when hosted runners are unavailable.

Local build requirements:

- Node.js 22+
- npm
- NSIS for installer compilation
- Windows for final install/launch verification

Local commands:

~~~powershell
.\scripts\build-windows-release.ps1
~~~

The local release script runs the desktop contract, builds the Windows runtime, compiles the NSIS installer, installs it into a clean temporary directory, launches the installed game, requires a runtime-ready + completed-first-frame marker with the expected 960×640 canvas, and writes SHA-256 hashes. It is the maintainer fallback when hosted CI cannot allocate runners.

## Launch contract

The desktop shell must:

- launch `www/index-embedded.html` from a minimal launcher-root `package.json`;
- keep the launcher/runtime separate from the `www/` game payload;
- exclude development-only files from the player runtime;
- preserve the 960×640 logical render surface while presenting it at 1440×960 by default and scaling it responsively to the largest 3:2 area available when resized/maximized/fullscreen;
- expose native NW.js fullscreen through Alt+Enter and F11, with Escape returning to windowed mode;
- run without Python or a separately started HTTP server;
- keep the browser-served path available as a fallback;
- build Aetherwake-Setup.exe plus Aetherwake-Windows.zip in the same Windows job that verifies them;
- avoid GitHub Actions artifact storage/transfer on the release-critical path;
- publish only after the exact candidate passes a real Windows install plus application-level runtime-ready/first-frame smoke;
- install per-user without requiring administrator elevation or the pre-install startup confirmation;
- publish Aetherwake-Windows.zip as the manual fallback;
- fail visibly if packaging or the entry point is invalid.

The packaged build does not change gameplay semantics. The internal game coordinate system remains 960×640, while the player-facing desktop window defaults to 1440×960 and the canvas scales proportionally with the window.
