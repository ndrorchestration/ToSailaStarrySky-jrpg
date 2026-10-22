# First Wake native local save/load — Windows verification
**Date:** 2026-10-22  
**Exact exercised/package source:** `fe52a2b0d1bc770a5920f9bd48dfb2d5748d9d54`  
**Parent:** draft PR #343 native Formula Review preview  
**Scope:** private native-preview evidence; not public release acceptance.

## Player-facing save/load
The native Chapter I preview now exposes:
- `F5` — save durable Chapter I progress;
- `F9` — load the local Chapter I save.

The slot is stored under Godot's per-user data directory. Dialogue cursor and Formula Review combat remain transient and are deliberately excluded from durable saves.

## Local save store
`first_wake_chapter1_save_store.gd` uses the versioned fail-closed Chapter I save codec as semantic authority.

Write path:
1. reject semantically invalid snapshots before filesystem mutation;
2. write JSON to `.tmp`;
3. parse + semantically validate the temp generation;
4. preserve the previous valid primary as `.bak`;
5. promote the verified temp generation to primary;
6. re-read + validate the promoted primary.

Load path:
- valid primary → load primary;
- corrupt/missing primary + valid backup → recover backup;
- no valid primary or backup → fail closed without mutating the live scene.

The JSON parser uses `JSON.parse()` error results rather than `JSON.parse_string()`, so an expected corrupt-primary recovery does not emit misleading engine ERROR logs.

## Exact Godot 4.7.2 verification — PASS
At exact source `fe52a2b...` on authorized Windows host:
- static Godot Windows preview package contract: PASS;
- local save-store temp/backup/recovery contract: PASS;
- real-scene local save/load + backup recovery: PASS;
- authored content/dialogue/FSM/save codec/save scene: PASS through export gate;
- production JRPG stat model/formula review controller/scene: PASS through export gate;
- Windows export contract: PASS.

Real-scene filesystem test proves:
- Crossing state can be saved;
- a second valid generation creates a previous-generation backup;
- Formula Review can be open before load;
- corrupt newest primary recovers the prior valid Crossing generation;
- load closes Formula Review/dialogue transient state;
- exploration resumes after restore;
- a missing slot fails without mutating live Chapter I state.

## Exact native Windows export
`Aetherwake-First-Wake-Godot-Preview.exe`
- size: **113,597,584 bytes**
- SHA-256: `f9858af84a3f969f3034f13ba5d416608f1c5063c2e8a9952111f85c83809c00`

## Exact installable ZIP
`Aetherwake-First-Wake-Godot-Native-Preview-Windows.zip`
- size: **42,395,134 bytes**
- SHA-256: `8e7fbe33d2eb043f21902ff2dc4be61749f3875131952842cb8e65bee4620478`
- packaged EXE SHA-256: `f9858af84a3f969f3034f13ba5d416608f1c5063c2e8a9952111f85c83809c00`
- install wrapper SHA-256: `c9e75b1deb541c3433ef170ca48a694e02910016a0e08220579d674d7fc6106c`
- uninstall wrapper SHA-256: `c62428deb7fe59e52f32a3b43fac8a0b61e7136597eff9eade51e981122c3e4f`
- packaged README save/load controls: PASS.

## Defender + install custody — PASS
No administrator elevation, NSIS, Defender exclusion/allowlisting, protection disabling, or execution-policy bypass was used.

Microsoft Defender custom scans reported no threats for:
- install wrapper;
- uninstall wrapper;
- packaged executable;
- exact ZIP.

Exact ZIP:
- per-user install: PASS;
- Desktop + Start Menu shortcuts: PASS;
- responsive native launch: PASS;
- title `Aetherwake - First Wake Chapter I Native Preview`;
- uninstall while game remained running: PASS;
- install directory, process, shortcuts and temporary cleanup copy removed.

Result: `GODOT_SAVE_PREVIEW_EXACT_PACKAGE_QA=PASS`.

## Boundaries
This establishes durable single-slot Chapter I continuity for the native preview. It does not establish:
- multiple production save slots/cloud saves;
- durable canonical production-combat encounter state;
- canonical enemy/hazard combat binding;
- party-wide combat parity;
- final visual acceptance;
- external player acceptance;
- hosted exact-head verification;
- issue #293 resolution;
- public release authorization.
