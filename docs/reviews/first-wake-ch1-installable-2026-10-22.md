# First Wake Chapter 1 installable preview — Windows verification receipt
**Date:** 2026-10-22  
**Package source:** `ef3e1237ecc6558079e3cb9cbda5dcc786ac593a`  
**PR:** #331 (draft/unmerged)  
**Scope:** owner-playtest packaging evidence only; not public release acceptance.

## Package
`Aetherwake-First-Wake-Chapter1-Installable-Windows.zip`

- Size: **215,824,790 bytes**
- ZIP SHA-256: `a1ba423d032c7852ceea86b2b5741dfee0b8e19fb72a03850c49c58c87276ba1`
- Packaged `Aetherwake.exe` SHA-256: `d2c4bf77efac18684c0114262df53d3b767550deb8f40956381073788a6e4efe`
- `Install-Aetherwake.cmd` SHA-256: `e75c3625e17804917bd385ea024caebc62a357528a3f0035cf22f85230a3e0af`
- `Uninstall-Aetherwake.cmd` SHA-256: `d71615fd0a2c1f688f86678e9d0f83a2409121d65a644dee655abb05e0563a8f`

## Build and gameplay contracts
On authorized Windows host `neontic`:

- `test:first-wake-opening` → **PASS**
- `test:desktop-package` → **PASS**
- canonical Playwright smoke path → **PASS**
- `package:windows` → **PASS**
- safe-player wrapper generator → **PASS**

The package is built from the existing fuller First Wake runtime, not the smaller Godot review slice. It includes the authored First Wake opening, Ender beginning alone, Lyra joining, exploration/dialogue/quest systems, airship/world seams exercised by smoke, and current combat/progression.

## Branding correction
The retired **“The Last Solarpunk Airship”** subtitle was removed from:

- root desktop manifest title;
- staged NW.js manifest title;
- title-screen runtime text;
- README heading.

The installed `package.nw/package.json` was checked and reports the canonical window title **AETHERWAKE**. The live installed game opened a responsive Aetherwake window.

## Install verification
The exact ZIP was extracted fresh and `Install-Aetherwake.cmd` executed.

Observed:

- per-user install directory created under `%LOCALAPPDATA%\Programs\Aetherwake`;
- exact packaged runtime copied;
- Desktop shortcut created;
- Start Menu shortcut created;
- installed `Aetherwake.exe` launched and displayed a responsive Aetherwake window;
- no administrator elevation requested;
- no NSIS executable or uninstaller used.

The older environment-variable first-frame receipt did **not** appear through this wrapper launch context. This is recorded as a limitation rather than converted into a pass. The same source had already passed the full canonical runtime smoke path, and installed-window launch was directly observed.

## Uninstall verification
The first QA pass found a real portability bug: the initial uninstaller assumed `%USERPROFILE%\Desktop`, which fails when Desktop is redirected to OneDrive. That build was rejected before publication.

The generator was repaired to resolve Windows' actual Desktop known folder. The rebuilt exact package then passed:

- uninstall command exit 0;
- install directory removed;
- redirected Desktop shortcut removed;
- Start Menu folder removed;
- preexisting Start Menu state used for QA was restored afterward.

Result: **SAFE_INSTALL_UNINSTALL_CYCLE=PASS**.

## Microsoft Defender
No exclusions, allowlisting, protection disabling, or execution bypasses were used.

Microsoft Defender custom scans on the final exact package reported **no threats** for:

- `Install-Aetherwake.cmd`;
- `Uninstall-Aetherwake.cmd`;
- packaged `Aetherwake.exe`;
- final installable ZIP.

This does **not** reclassify or close issue #293. The earlier NSIS `Trojan:Win32/Bearfoos.A!ml` observation remains preserved and unresolved. The new package deliberately avoids that NSIS route.

## Boundary
This package is a **pre-alpha First Wake / Chapter 1 preview** for owner playtesting. It is not the final completed Chapter 1, completed Godot migration, creator visual acceptance, human/player acceptance, public release authorization, or resolution of issue #293.
