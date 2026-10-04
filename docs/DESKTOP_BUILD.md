# Aetherwake Windows desktop build

Aetherwake retains its HTTP-served browser path for development and automated smoke testing. The supported player-facing path is a packaged NW.js desktop build.

## For players

The desktop window opens at **1440×960** by default. Maximizing the window enlarges the game further while preserving its 3:2 aspect ratio. **Alt+Enter** or **F11** toggles true NW.js fullscreen; **Escape** exits fullscreen. The internal 960×640 coordinate system stays unchanged so authored UI, combat positions, and input geometry remain stable.


1. Download **Aetherwake-Setup.exe** from a Windows desktop release.
2. Run the installer and choose the install location if needed.
3. Launch Aetherwake from the created desktop or Start Menu shortcut.

The standard installer installs the packaged runtime per-user under `%LOCALAPPDATA%\\Programs\\Aetherwake`, does not require administrator elevation, and does not require Python, PowerShell, a manually started HTTP server, or opening an HTML file.

**Fallback:** **Aetherwake-Windows.zip** is also published for manual extraction. Extract the ZIP completely, then run **Aetherwake.exe** from the extracted folder. Keep the extracted files together.

Do not use superseded self-extracting/SFX artifacts. If Windows Defender flags an artifact, do not whitelist or bypass it; preserve the exact detection name and SHA-256 for a false-positive report.

## Current verification state — 2026-10-03

- Hosted checkpoint `ff83d023f9633119f24723ab5ab7c53566b38a60` passed browser smoke run `37139742677`.
- The same checkpoint passed Windows packaging run `37139742595`: staged runtime contract, NW.js build, direct-output package discovery, portable ZIP, per-user NSIS installer, exact-candidate install/launch, `DESKTOP_RENDER_READINESS=PASS`, portable layout, and SHA-256 generation.
- Release publication was skipped because this was an ordinary push rather than a tagged or manually dispatched release.
- The local fallback script remains available and now uses the same direct-or-nested executable discovery rule as hosted CI.
- Technical verification is green. Human/player acceptance and visual acceptance remain pending; tests and readiness markers do not establish aesthetic approval.

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
