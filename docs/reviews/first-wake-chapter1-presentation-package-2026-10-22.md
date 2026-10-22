# First Wake Chapter I presentation package — exact Windows verification
**Date:** 2026-10-22  
**Exact package source:** `028aa008f423b03f07f96b62d731fba2dc700f37`  
**Draft PR:** #335  
**Scope:** private owner-playtest package evidence only.

## Release gates
The safe-player package build from the exact source passed:

- authored First Wake opening contract;
- Chapter I cohesion contract;
- player-guidance contract;
- readability contract;
- presentation contract;
- desktop package contract;
- full Playwright smoke;
- NW.js Windows x64 package build.

The presentation branch also produced a fresh seven-frame 960×640 player-evidence set with no browser errors. The reviewed frames show the revised title, authored opening sky/ship composition, world context rail, settled Ionia dialogue, and unobstructed combat entry. Visual acceptance remains pending.

## Exact package
`Aetherwake-First-Wake-Chapter1-Installable-Windows.zip`

- size: **215,827,913 bytes**
- ZIP SHA-256: `1338e4bd0c0a1de18a2caf924111221dbd257a1287b03eda416c078ab54c437a`
- packaged `Aetherwake.exe` SHA-256: `d2c4bf77efac18684c0114262df53d3b767550deb8f40956381073788a6e4efe`
- `Install-Aetherwake.cmd` SHA-256: `e75c3625e17804917bd385ea024caebc62a357528a3f0035cf22f85230a3e0af`
- `Uninstall-Aetherwake.cmd` SHA-256: `00482957670dfc7e3c005f79e2c0ddf5aec2e5d12f0bf88a67c53240be180765`

## Defender — PASS
Without exclusions, allowlisting, protection disabling, or execution-policy bypass, Microsoft Defender custom scans reported no threats for the final:

- install wrapper;
- uninstall wrapper;
- packaged executable;
- complete ZIP.

This does not resolve or reclassify issue #293. The held NSIS path remains separate and is not invoked by this package.

## Exact install / live launch — PASS
The final ZIP was freshly extracted and its packaged install wrapper executed.

Verified:
- per-user install under `%LOCALAPPDATA%\Programs\Aetherwake`;
- Desktop shortcut present;
- Start Menu shortcut present;
- installed manifest title = `AETHERWAKE`;
- live responsive window title = `AETHERWAKE`.

## Running-app uninstall — PASS
A QA pass intentionally invoked the packaged uninstaller while the game remained running.

An earlier package attempt exposed a real self-directory deletion bug: the delayed cleanup shell inherited the install directory as its current working directory. The generator was corrected to leave the install directory before delayed removal.

The rebuilt exact package then verified:
- installed Aetherwake process terminated by the scoped wrapper;
- install directory removed;
- Desktop shortcut removed;
- Start Menu entry removed;
- no installed Aetherwake process remained;
- preexisting QA Start Menu state restored afterward.

Result: `PR335_EXACT_PACKAGE_QA=PASS`.

## Boundaries
This establishes a technically verified private owner-playtest candidate. It does not establish creator visual acceptance, external human/player acceptance, completed Godot migration, public release authorization, or resolution of issue #293.
