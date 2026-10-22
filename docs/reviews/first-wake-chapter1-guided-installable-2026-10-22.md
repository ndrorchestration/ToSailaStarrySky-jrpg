# First Wake Chapter I guided installable preview — Windows verification receipt
**Date:** 2026-10-22  
**Exact package source:** `3d0d478c4e92b69a1898a5172546a3d6894430ad`  
**Draft PR:** #333  
**Scope:** owner-playtest package verification; not public release acceptance.

## What this candidate adds over the earlier installable preview
- explicit Chapter I completion after the existing Signal → Crossing → Contact → Choice → Wake quest arc;
- Ionia joins the canonical active party at the authored storm/shield decision boundary;
- Crossing derives completion from the actual three-hazard contract, removing a stale fourth-hazard access;
- dynamic **NEXT** guidance in world HUD and Quest Log;
- clearer Signal, Crossing, Contact and Choice objectives;
- retired opaque cyan scanline regression removed; optional CRT scanlines remain off by default;
- canonical title remains **AETHERWAKE**;
- non-NSIS per-user install/uninstall path retained and hardened.

## Release gates — PASS
The safe-player package generator ran from exact source `3d0d478...` and passed:

- `test:first-wake-opening`
- `test:first-wake-chapter1`
- `test:first-wake-guidance`
- `test:desktop-package`
- full Playwright `test:smoke`
- NW.js Windows package build

The browser smoke exercises the real Chapter I quest state machine through Signal, all three Crossing hazards, Contact, Ionia recruitment, path choice, Wake, and explicit `chapterOneComplete=true` epilogue.

## Exact package
Artifact: `Aetherwake-First-Wake-Chapter1-Installable-Windows.zip`

- size: **215,825,909 bytes**
- ZIP SHA-256: `dd5e9dce43e92145416e2a9c65e12e01ca67753f0c57ed5a71faba52f02f70bb`
- packaged `Aetherwake.exe` SHA-256: `d2c4bf77efac18684c0114262df53d3b767550deb8f40956381073788a6e4efe`
- `Install-Aetherwake.cmd` SHA-256: `e75c3625e17804917bd385ea024caebc62a357528a3f0035cf22f85230a3e0af`
- `Uninstall-Aetherwake.cmd` SHA-256: `f7e2602708c7faa91a6ab7a54f91eaf02a5078a765bada11c91ffc7b3c6dd602`

## Microsoft Defender — PASS
Without exclusions, allowlisting, disabling protection, or execution-policy bypass, Microsoft Defender custom scans reported no threats for:

- final install wrapper;
- final uninstall wrapper;
- packaged `Aetherwake.exe`;
- exact final ZIP.

This does **not** close or reclassify issue #293. The earlier NSIS Bearfoos detection remains preserved; this package does not invoke NSIS.

## Exact install / live launch — PASS
The exact ZIP was extracted fresh and installed per-user.

Verified:
- installed under `%LOCALAPPDATA%\Programs\Aetherwake`;
- Desktop shortcut present;
- Start Menu shortcut present;
- installed manifest title = `AETHERWAKE`;
- live installed window title = `AETHERWAKE`;
- responsive game process observed.

## Running-app uninstall — PASS
QA intentionally ran the packaged uninstaller while Aetherwake was still running.

The earlier wrapper behavior could leave the install directory locked by detached NW.js child processes. The final candidate hardens uninstall by scoping process termination to `Aetherwake.exe` whose executable path is inside its own install directory before delayed deletion.

Final exact candidate:
- running Aetherwake processes under the install directory terminated;
- install directory removed;
- redirected Desktop shortcut removed;
- Start Menu entry removed;
- no installed Aetherwake process remained;
- preexisting QA Start Menu state restored after test.

Result: `RUNNING_APP_UNINSTALL=PASS` and `PR333_EXACT_PACKAGE_QA=PASS`.

## Boundaries
This establishes an owner-download/install/play candidate for the current **First Wake Chapter I pre-alpha**. It does not establish final visual acceptance, external player acceptance, completed Godot migration, public release authorization, or issue #293 resolution.
