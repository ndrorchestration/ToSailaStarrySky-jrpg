# First Wake checkpoint requires a valid party — October 31, 2026

## Source defect
The prior Explorer `SaveFirstWake` path could write a fresh version-2 slot with a fully empty `PartyRoster` if live party data had not been initialized. Subsequent reload would have no playable party stats. This issue is separate from the existing-slot overwrite bug addressed in #627.

## Fix and compatibility
`UTSTSSSaveGame::CanCheckpointParty` requires a structurally valid save payload and either an explicitly initialized live party or a nonempty, validated existing saved roster. `ATSTSSExplorerCharacter::SaveFirstWake` calls this gate before any story mutation or disk write. The subsequent `CapturePartyRoster` still rejects invalid live stats. Thus:
- New slot + no initialized party: reject without writing an empty checkpoint.
- New slot + valid initialized live party: allow capture and write.
- Existing compatible slot + saved nonempty roster + live uninitialized: allow story-only save, preserving saved stats.
- Existing slot + invalid schema or roster: reject, not overwrite.
- Existing legacy empty-party slot + no initialized live party: reject; a valid live party can rehabilitate this slot through the existing capture path. No silent data synthesis.

Added `TSTSS.Save.CheckpointRequiresParty` Unreal automation coverage for these policies and unsupported schema refusal. The save format remains version 2.

## Important development dependency
**The Unreal prototype still lacks canonical new-game party initialization.** The Explorer must obtain an explicitly valid Ender roster from the authoritative character/stats design before a first new-slot save can succeed. Do not invent final Ender statistics or declare save-ready simply because the precondition prevents bad data. This is a deliberate fail-closed gate until native integration is complete.

## Verification
Source changes committed on a draft branch; **Unreal Engine 5.8 native compile and test execution not performed**. Run exact-commit Windows Editor and Game builds, per-test automation reports, then a true first-session / save / combat / reload gameplay test. Exercise failed writes, crash recovery and preservation of equipment/inventory independently.
No main merge, canon alterations, art acceptance, or release.
