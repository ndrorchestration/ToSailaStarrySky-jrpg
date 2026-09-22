# Aetherwake Windows desktop build

Aetherwake retains its HTTP-served browser path for development and automated smoke testing. The supported player-facing path is a packaged NW.js desktop build.

## For players

1. Download **Aetherwake-Setup.exe** from a Windows desktop release.
2. Run the installer and choose the install location if needed.
3. Launch Aetherwake from the created desktop or Start Menu shortcut.

The standard installer installs the packaged runtime per-user under `%LOCALAPPDATA%\\Programs\\Aetherwake`, does not require administrator elevation, and does not require Python, PowerShell, a manually started HTTP server, or opening an HTML file.

**Fallback:** **Aetherwake-Windows.zip** is also published for manual extraction. Extract the ZIP completely, then run **Aetherwake.exe** from the extracted folder. Keep the extracted files together.

Do not use superseded self-extracting/SFX artifacts. If Windows Defender flags an artifact, do not whitelist or bypass it; preserve the exact detection name and SHA-256 for a false-positive report.

## Current verification state — 2026-09-22

- Memories-style launcher correction merged at `304835c12555e35061870a54d61f7c95996d0bdd`.
- Staging validation confirms the production manifest shape is `package.json → main: www/index-embedded.html`, with the game payload under `www/`.
- Runtime-resource audit confirms the loading artwork used at boot is embedded as a data URI; there is no required external `img/system/Loading.png` file to package.
- Hosted GitHub Actions verification is currently blocked before checkout. Windows package run `35692454573` attempt 2 ended with `runner_id: 0`, `steps: []`; browser smoke run `35692454657` is the same class of zero-runner failure.
- These are runner-admission/infrastructure failures. They do **not** establish that current code tests passed or failed.
- No fresh installer is player-authorized until the exact candidate completes a real Windows install/launch verification. Historical CI-green packaging results remain provenance only and must not be substituted for this current gate.

## For maintainers

The production desktop layout intentionally follows the same structural pattern used by RPG Maker MV/NW.js games such as the Memories reference: the NW.js launcher/runtime lives at the package root, a minimal root `package.json` points to `www/index-embedded.html`, and the game payload lives under `www/`. Development files, tests, docs, and npm tooling are not part of the player runtime.

The release path is intentionally split into three gates:

1. **Build candidate on Linux.** NW.js produces the Windows x64 runtime, then NSIS creates a conventional per-user installer. The portable ZIP, installer, and SHA-256 manifest are retained as a candidate artifact.
2. **Verify on Windows.** A pinned Windows runner downloads that exact candidate, silently installs it into a clean directory, verifies `Aetherwake.exe` exists, launches it, and requires the process to remain alive through the launch smoke. The portable ZIP layout is checked too.
3. **Publish only after verification.** Tagged/manual releases cannot publish until the Windows verification job passes.

This means Windows runner availability is no longer required to *create and preserve* the Windows candidate, but an installer is never represented as verified without an actual Windows install/launch test.

Local build requirements:

- Node.js 22+
- npm
- NSIS for installer compilation
- Windows for final install/launch verification

Local commands:

~~~powershell
.\scripts\build-windows-release.ps1
~~~

The local release script runs the desktop contract, builds the Windows runtime, compiles the NSIS installer, installs it into a clean temporary directory, launches the installed game for a 10-second smoke, and writes SHA-256 hashes. It is the maintainer fallback when hosted CI cannot allocate runners.

## Launch contract

The desktop shell must:

- launch `www/index-embedded.html` from a minimal launcher-root `package.json`;
- keep the launcher/runtime separate from the `www/` game payload;
- exclude development-only files from the player runtime;
- preserve the 960×640 initial canvas;
- run without Python or a separately started HTTP server;
- keep the browser-served path available as a fallback;
- build and preserve Aetherwake-Setup.exe plus Aetherwake-Windows.zip before verification;
- publish the installer only after the exact candidate passes a real Windows install/launch smoke;
- install per-user without requiring administrator elevation or the pre-install startup confirmation;
- publish Aetherwake-Windows.zip as the manual fallback;
- fail visibly if packaging or the entry point is invalid.

The packaged build does not change gameplay semantics; it supplies the desktop runtime container.
