# V5 Ionia art + conversation pause convergence — review only

**2026-10-21.** This is an isolated integration draft, not a merge of the upstream independent PRs or an admission to production.

## Two verified independent sources

- Artwork: exact parent PR #325 `1f472177bcac83ed326fadcf752f161ce0659747` (Ionia V5 front/rear study, V4 east/west; all hidden behind opt-in character review keys).
- Interaction: separately developed PR #322 `059685bb51034cc1d140c8ccbdf93484d1ebaa20` (dialogue pause/resume, guarding T/Y route teleport, native regression). PR #322 is based on the older #321 lineage and cannot be represented as already contained in #325.

## Smallest compatible integration

Reapply only the original PR #322 `pilot_actor.gd` actor-pause state, `first_wake.gd` dialogue close/pause-state handler, and its unchanged `dialogue_pause_test.gd` / `capture_dialogue_pause.gd` to an independent branch from #325. Do **not** overwrite the new Ionia V5 texture mappings with the old #321 ones. Reuse the existing Godot 4.7.2 digest-verified native workflows, adding the dialogue test and native paused/resumed capture. Confirm that four-direction 6-phase Ionia review, Ender staff/idle/dock visuals, scene 960×640 captures, and dialogue no-teleport/paused motion all pass on **one exact head**.

The originally observed issue was movement of Ender and the Ionia diagnostic route during dialogue, with route keys changing state. The solution pauses both actor physics callbacks; returns frame index to zero during conversation without changing route/position; E/Escape resumes; T and Y cannot reset the route while dialogue is open. Label wrapping is for the pilot visual-review dialogue only. This is not newly drawn idle/listening artwork or main story-route acceptance.

## Reversible boundaries

No quest, save, combat, canonical map, original source-art admission, production engine migration, protected branch merge or release. Revert the integration branch to return to two separately reviewable proposals. The first failed test/renderer run on this integration must be retained, not erased.

`VISUAL_ACCEPTANCE=PENDING`, `IONIA_V5_ART=UNAPPROVED`, `DIALOGUE_INTEGRATION_ADMISSION=PENDING`, `FIELD_PACK_READINESS=NOT_READY`, `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`, `RELEASE=NOT_AUTHORIZED`; Defender #293 remains a hard hold.
