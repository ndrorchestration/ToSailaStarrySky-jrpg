# First Wake Chapter I cohesion package — Windows verification receipt
**Date:** 2026-10-22  
**Exact package source:** `36d0eb59cf4cedf311ce780a6442202028c00bf9`  
**Draft PR:** #332, stacked on #331  
**Scope:** owner-playtest engineering evidence only.

## Chapter I runtime changes
This candidate preserves the authored opening and existing quest body, but closes several cohesion gaps:

- Crossing now uses the actual **three-hazard** contract; stale `crossingHazards[3]` access is removed.
- quest log/HUD and advancement derive their hazard denominator from `crossingHazards.length`.
- Captain Ionia becomes playable through canonical `AetherPartyState.recruitCharacter('ionia')` when Contact resolves into the storm/shield Choice.
- Wake completion sets `chapterOneComplete=true`.
- the ending explicitly renders **CHAPTER I COMPLETE** and preserves the established auroral-lane crew gate.

## Automated verification
At exact source `36d0eb59...` on authorized Windows host `neontic`:

- `test:first-wake-opening` — **PASS**
- `test:first-wake-chapter1` — **PASS**
- `test:desktop-package` — **PASS**
- full Playwright `test:smoke` — **PASS**
- `package:windows:safe-player` — **PASS**

The browser smoke now additionally drives the real quest FSM through:
`Signal → three Crossing hazards → Contact → Ionia join → path C Choice → Wake → done`.

It verifies:
- active party at Choice is `ender|lyra|ionia`;
- Ionia's canonical roster record is playable;
- the selected path reaches `wake`;
- the ending reaches `done`;
- `chapterOneComplete === true`;
- a real epilogue is selected.

## Exact Windows package
`Aetherwake-First-Wake-Chapter1-Installable-Windows.zip`

- size: **215,825,264 bytes**
- ZIP SHA-256: `b5d440900266f33e9f83180f569976364e7a2f27a4b6bd6e6155c5bc0f66c912`
- packaged `Aetherwake.exe` SHA-256: `d2c4bf77efac18684c0114262df53d3b767550deb8f40956381073788a6e4efe`
- `Install-Aetherwake.cmd` SHA-256: `e75c3625e17804917bd385ea024caebc62a357528a3f0035cf22f85230a3e0af`
- `Uninstall-Aetherwake.cmd` SHA-256: `d71615fd0a2c1f688f86678e9d0f83a2409121d65a644dee655abb05e0563a8f`

## Microsoft Defender
Final custom scans reported **no threats** for:
- exact install wrapper;
- exact uninstall wrapper;
- packaged `Aetherwake.exe`;
- exact ZIP.

No Defender exclusions, allowlisting, protection disabling, or execution-policy bypass was used. Issue #293 remains scoped to the older NSIS route and is not reclassified by this result.

## Install / launch / uninstall verification
The exact ZIP was extracted and installed through `Install-Aetherwake.cmd`.

Verified:
- per-user install under `%LOCALAPPDATA%\Programs\Aetherwake`;
- Desktop shortcut present;
- Start Menu shortcut present;
- packaged manifest title exactly `AETHERWAKE`;
- responsive installed window observed as `Aetherwake - Ender`.

The QA harness' use of `Start-Process -Wait` on the wrapper can remain attached after the wrapper launches the NW.js process; this is a harness/shell behavior, not a game launch failure. Installed state was therefore verified independently before terminating only the harness.

Then the exact installed `Uninstall-Aetherwake.cmd` was exercised:
- exit code 0;
- install directory removed;
- redirected Desktop shortcut removed;
- Start Menu folder removed;
- preexisting Start Menu state restored after QA.

Result: **CHAPTER1_COHESION_INSTALL_UNINSTALL=PASS**.

## Boundary
This is materially closer to a coherent playable Chapter I than the prior package, but remains pre-alpha. It does not establish final visual acceptance, complete content/polish parity with the long-term Chapter I vision, completed Godot migration, public release authorization, or resolution of issue #293.
