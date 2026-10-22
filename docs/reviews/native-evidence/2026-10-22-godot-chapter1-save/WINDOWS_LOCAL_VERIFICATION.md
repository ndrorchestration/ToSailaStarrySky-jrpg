# Godot First Wake Chapter I save codec — Windows local verification
**Date:** 2026-10-22  
**Exact codec PASS head:** `ca43d7ff88a9285b6eb150180e385c03c9ab3e71`  
**Exact real-scene restore PASS head:** `fa4dd6e60a92c2dca122b9436dae4b88c81dfbf0`  
**Stack:** PR #338 native authored-content/dialogue migration  
**Scope:** migration save-state contract, not a production filesystem/cloud save implementation.

## Durable state now covered
The native Chapter I migration now has a versioned, fail-closed save codec:

`res://scripts/first_wake_chapter1_save_codec.gd`

Schema:
`aetherwake.first-wake.chapter1.v1`

Durable fields:
- Chapter I stage;
- completed Signal IDs;
- completed Crossing hazard IDs;
- contacts met;
- Ionia decision-boundary join state;
- selected choice path + injected outcome variant;
- epilogue ID;
- explicit Chapter I completion flag;
- legacy resolver inputs: hull integrity, morale, engine integration.

Intentionally **not** persisted:
- open dialogue;
- dialogue line cursor;
- pending interaction IDs;
- transient UI labels/panels;
- render/evidence state.

## Fail-closed validation
Restore rejects:
- unknown schema versions;
- invalid stage names;
- unknown or duplicate Signal/hazard/contact IDs;
- impossible stage/prerequisite combinations;
- invalid choice path/variant;
- Done without a real epilogue ID/completion state;
- resolver stats outside 0–100.

Validation occurs before scene mutation.

## Local PASS
Godot 4.7.2:

`AETHERWAKE_GODOT_CHAPTER1_SAVE_PASS: versioned partial/done round-trip and fail-closed tamper rejection`

This test proves:
- partial Signal progress round-trips;
- a complete path-C Chapter I state round-trips exactly;
- Ender + Lyra + Ionia desired-party target survives restore;
- resolver stats survive restore;
- transient dialogue/UI keys are absent;
- tampered/impossible snapshots fail closed.

At the final exact scene head:

`AETHERWAKE_GODOT_CHAPTER1_SAVE_SCENE_PASS: real scene restores Wake state/stats and rejects invalid snapshots without mutation`

The real review scene was progressed to path-C Wake, saved with non-default resolver stats, mutated to Done, then restored back to Wake. Verified:
- path + variant preserved;
- Ender + Lyra + Ionia target preserved;
- resolver stats preserved;
- dialogue/pending interaction state cleared;
- player control restored at Wake;
- invalid restore returned false and left the current scene snapshot unchanged.

## Boundary
This is a deterministic serialization/restore contract. It does **not** yet establish:
- filesystem slot management;
- autosave UX;
- atomic file replacement/recovery;
- save migration beyond schema v1;
- production combat state persistence;
- settings persistence;
- cloud saves;
- Windows Godot packaging.

Current best downloadable Windows Chapter I remains PR #336. No merge, public release, creator visual acceptance, or issue #293 resolution is implied.
