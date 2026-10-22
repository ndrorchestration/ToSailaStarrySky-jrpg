# First Wake Chapter I world-depth package — exact Windows verification
**Date:** 2026-10-22  
**Exact package source:** `0b7ade6edf788238cc37283287600f48f94f20db`  
**Draft PR:** #336  
**Scope:** private owner-playtest package evidence only.

## Release/build gates — PASS
The safe-player build from exact source `0b7ade6...` passed:

- First Wake opening contract;
- Chapter I cohesion contract;
- player-guidance contract;
- readability contract;
- presentation contract;
- world-depth presentation contract;
- desktop-package contract;
- full Playwright smoke;
- NW.js Windows x64 build.

Fresh 960×640 evidence from the same branch was directly inspected before packaging. It showed the revised Wake Dock terrain/berth treatment and the new staged combat presentation with Ender and the Sky-Predator both fully visible. Creator visual acceptance remains pending.

## Exact package
Artifact: `Aetherwake-First-Wake-Chapter1-Installable-Windows.zip`

- size: **215,830,019 bytes**
- ZIP SHA-256: `4e16ee1a0a2bc0cf803c4a1d9147fe2903bec1e50da863b0a7879734d3a46028`
- packaged `Aetherwake.exe` SHA-256: `d2c4bf77efac18684c0114262df53d3b767550deb8f40956381073788a6e4efe`
- `Install-Aetherwake.cmd` SHA-256: `e75c3625e17804917bd385ea024caebc62a357528a3f0035cf22f85230a3e0af`
- `Uninstall-Aetherwake.cmd` SHA-256: `00482957670dfc7e3c005f79e2c0ddf5aec2e5d12f0bf88a67c53240be180765`

## Microsoft Defender — PASS
Without exclusions, allowlisting, protection disabling, or execution-policy bypass, Microsoft Defender custom scans reported no threats for:

- final install wrapper;
- final uninstall wrapper;
- packaged executable;
- exact final ZIP.

This does not resolve or reclassify issue #293. The held NSIS path remains separate and unused.

## Exact install / live launch — PASS
The final ZIP was freshly extracted and installed per-user.

Verified:
- installed under `%LOCALAPPDATA%\Programs\Aetherwake`;
- Desktop shortcut present;
- Start Menu shortcut present;
- installed manifest title = `AETHERWAKE`;
- live responsive window title = `AETHERWAKE`.

## Running-app uninstall — PASS
The packaged uninstaller was invoked while Aetherwake remained running.

Verified:
- installed Aetherwake process terminated by the scoped wrapper;
- install directory removed;
- Desktop shortcut removed;
- Start Menu entry removed;
- no installed Aetherwake process remained;
- preexisting QA Start Menu state restored afterward.

Result: `PR336_EXACT_PACKAGE_QA=PASS`.

## Hosted boundary
GitHub Actions run `39808806652`, job `119929141321`, is reported failed with **no step list**. Hosted execution is therefore **NOT ESTABLISHED**. The red job is not treated as a gameplay/test failure, green acceptance, or evidence that local verification transferred to hosted CI.

## Boundaries
This establishes a technically verified private owner-playtest candidate only. It does not establish creator visual acceptance, external human/player acceptance, final environment or character art, completed Godot migration, public release authorization, or issue #293 resolution.
