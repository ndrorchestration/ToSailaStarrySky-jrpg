# M0 uncoached external-player playtest protocol

Status: **MANUAL BLOCKING EVIDENCE / NOT A SUBSTITUTE FOR AUTOMATED OR WINDOWS PACKAGE GATES**

This protocol owns the manual comprehension gate in `docs/first-wake-benchmark.json`. It exists because automated tests can prove state integrity and deterministic behavior, but cannot prove that a new player understands what Aetherwake is asking them to do.

A passing developer smoke test or local M0 run cannot substitute for this manual comprehension evidence. Automated verification and external-player comprehension answer different questions and both remain required where the benchmark marks them blocking.

## Candidate binding

Before the session, record:
- exact Git commit SHA;
- exact standalone Windows build/installer identity;
- installer SHA-256 when available;
- whether the exact candidate has already passed the applicable local/package verification lanes.

Do not reuse observations from a different build as evidence for the current candidate.

## Participant boundary

Use a participant who has not been coached through the current First Wake flow.

Before play:
- explain only how to launch the supplied standalone build;
- do not explain objectives, controls, combat strategy, quest order, save/load behavior, or expected story beats;
- do not give repository, browser, debug-console, or implementation instructions.

If intervention becomes necessary, record it immediately. The session may continue for diagnostic value, but an intervention means the run does not satisfy the uncoached completion gate.

## Required observed path

The participant should attempt, without live coaching:

1. install/launch the standalone Windows candidate;
2. begin through New Game or Continue as appropriate;
3. understand the current objective from the game itself;
4. progress through the representative First Wake exploration/contact path;
5. make combat choices for intelligible reasons rather than random selection;
6. create a manual save;
7. close the game process;
8. relaunch and restore the save correctly;
9. encounter or deliberately exercise at least one non-happy-path state and recover using player-facing affordances;
10. complete the bounded First Wake Choice → WAKE experience;
11. reach the representative Dragonfly/open-sky traversal state when included in the candidate.

## Observer rules

Record facts, not interpretations, during the run:
- what the participant tried;
- where they hesitated;
- what they said they believed the objective/action would do;
- any intervention and its exact reason;
- defects, soft-locks, misleading prompts, stale objectives, or inaccessible controls.

Do not silently convert confusion into a tutorial suggestion during the session.

## Blocking pass criteria

The manual gate may be recorded as `PASS` only when all of the following are true:
- no live creator/developer coaching was required;
- install/launch succeeded from the supplied standalone candidate;
- the player understood what to do next from in-game information;
- combat choices were made for understandable tactical reasons;
- save → close → relaunch → load restored the expected state;
- at least one non-happy-path state was recovered from without intervention;
- the representative First Wake slice was completed;
- no blocker or state-corruption defect invalidated the run.

A run with intervention, browser/repository dependence, corrupted persistence, or an unrecoverable progression failure is not a pass.

## Evidence record

Copy `docs/m0-external-playtest-record.template.json` for each candidate/participant run. Keep `result` as `NOT_RUN` until the session actually occurs. Valid terminal values are:
- `PASS`
- `FAIL`
- `INVALIDATED`

Do not promote this gate from manual evidence to automated evidence.

## Evidence validation

A completed PASS record must be validated against the exact release provenance file used for the participant build:

```powershell
npm run validate:external-playtest -- --record ".\path\to\completed-playtest.json" --release-evidence ".\path\to\RELEASE_EVIDENCE.json"
```

The validator fails closed unless:
- the playtest commit matches the release evidence source Git HEAD;
- the release-evidence SHA-256 matches the exact evidence file reviewed;
- installer filename and SHA-256 match the release evidence;
- the candidate was actually player-verified as a standalone Windows build;
- the participant had no prior Aetherwake exposure or gameplay instructions beyond launch;
- all required observed-path results are explicitly true;
- objective comprehension, combat reasoning, and non-happy-path recovery evidence are recorded;
- no live intervention occurred;
- no blocking defect remains;
- completion time, observer identity, review time, and explicit `PASS` are recorded.

A validator PASS proves integrity/completeness of the evidence record. It does not automate or replace the human participant session.
