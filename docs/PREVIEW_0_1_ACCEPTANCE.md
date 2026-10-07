# Aetherwake Preview 0.1 — Human Acceptance Protocol

**Status:** exact technical candidate verified; human/player acceptance not yet run.

## Exact candidate binding

Use only this candidate for the current Preview 0.1 acceptance run:

```text
SOURCE_SHA=46f50c581d992bf581bb6b6d7961a9421b8b779d
PR=250
WINDOWS_RUN=37559269564
INSTALLER=Aetherwake-Setup.exe
INSTALLER_SHA256=7feb6de364264617095a59dd9329a99ebfa77a144b0f5887a7ae7ff064f6221d
PORTABLE_ZIP=Aetherwake-Windows.zip
PORTABLE_ZIP_SHA256=4c6efc6ea1cecf6468fb983fd8ff5fd5d0ce8645262779551841f663c5326173
TECHNICAL_CANDIDATE_VERIFICATION=PASS
HUMAN_REVIEW=NOT_RUN
VISUAL_ACCEPTANCE=PENDING
HUMAN_PLAYER_ACCEPTANCE=PENDING
```

If the source SHA or installer hash changes, this binding is invalid and technical verification must be repeated before a new human acceptance run.

## Reviewer eligibility

For formal acceptance, use a human reviewer who did not build or debug this exact candidate and has not been coached on the route, puzzle/clue order, hazard locations, combat solution, save behavior, final choice, or ending.

A creator self-test is useful for defect discovery but does **not** establish `HUMAN_PLAYER_ACCEPTANCE=PASS`.

## Uncoached instruction

Give the reviewer the installer and only this instruction:

> Install and play Chapter 1. Use the controls the game presents. Tell us where you become confused, blocked, or stop trusting what the game is asking you to do.

Do not answer route/progression questions during the run. Confusion is evidence and should be recorded.

## Required observations

### 1. Install and launch

- [ ] Installer completes without administrator elevation.
- [ ] Aetherwake launches as a standalone window.
- [ ] Window can be resized/maximized.
- [ ] Title/menu identity is recognizable.

### 2. Opening comprehension

- [ ] New Game starts without coaching.
- [ ] Opening progression is understandable.
- [ ] Lyra/Ionia progression is discovered naturally enough to continue.
- [ ] Required investigation/progression gates are understandable from play.

### 3. World objective

- [ ] Current objective is identifiable after the opening.
- [ ] Quest/journal information is understandable when needed.

### 4. Combat

- [ ] Required encounters can be reached.
- [ ] Combat reads as understandable stat/ability actions.
- [ ] Defeat/retry behavior does not strand the run.
- [ ] Required hazards can be cleared without developer intervention.

### 5. Persistence

- [ ] Reach or create a valid save.
- [ ] Close Aetherwake completely.
- [ ] Relaunch the installed game.
- [ ] Continue restores a sensible playable state.

### 6. Chapter resolution

- [ ] Required CONTACT/conversation progression is understandable.
- [ ] Final choice can be made without coaching.
- [ ] WAKE/DONE resolution is understandable.
- [ ] Replay/return behavior works.

### 7. Presentation

- [ ] No blocking blank/purple screen.
- [ ] No unreadable text or overlay blocks progression.
- [ ] Music transitions do not block/confuse play.
- [ ] No visible debug/developer-only behavior intrudes.

## Defect record

For every defect, record:

- severity;
- what the player was doing;
- reproduction steps;
- expected behavior;
- actual behavior;
- whether developer intervention was required.

## Reviewer record

```text
Reviewer name/stable alias:
Date/time:
Approximate play time:
Uncoached run: YES / NO
```

## Blocking-defect decision

A formal PASS requires all of the following:

- no installation/launch blocker;
- no progress blocker requiring developer intervention;
- no usable-save loss/corruption;
- no materially unintelligible required path;
- no crash/hard lock;
- no defect invalidating the exact candidate binding;
- run remained uncoached.

## Gameplay acceptance result

Use one final result:

```text
HUMAN_PLAYER_ACCEPTANCE=PASS
```

or

```text
HUMAN_PLAYER_ACCEPTANCE=FAIL
```

A failure must list the blocking defect(s).

## Separate seven-frame visual review

The exact-current-head evidence packet contains:

```text
00-title-ready.png
01-arrival-horizon.png
02-lyra-join.png
03-ender-lyra-party.png
04-world-handoff.png
05-captain-ionia-dialogue.png
06-combat-entry.png
manifest.json
```

Review the seven frames for readability, continuity, correct speaker/context, coherent progression, and blocking visual defects.

Use exactly one visual-review disposition:

```text
HUMAN_REVIEW=PASS
HUMAN_REVIEW=FAIL
HUMAN_REVIEW=NEEDS_WORK
```

Do not infer `VISUAL_ACCEPTANCE=PASS` or `HUMAN_PLAYER_ACCEPTANCE=PASS` from automated capture or developer inspection.

## Promotion boundary

Until the human/player result is recorded:

- PR #250 may be technically ready for review but must not be treated as human-accepted.
- Do not rebind the historical Google Drive one-click launchers to this candidate solely because technical verification passed.
- Do not widen Preview 0.1 with unrelated feature work.
- GitHub Actions artifact-quota debt may remain open independently; the current human review packet can be supplied through the exact local/RDC handoff.
