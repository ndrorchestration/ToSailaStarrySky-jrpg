# Aetherwake — Five-Person Cold-Playtest Protocol (draft)

**Status:** proposed research protocol; no participants recruited, sessions performed or outcomes claimed. Applies only to draft PR #330's standalone Godot scene, not to production art/canon or any release candidate.

## Purpose and consent
Test whether an unfamiliar player can understand the first ten minutes without coaching, feel agency, and notice a consequence. Invite a small, diverse set of five consenting adults with varied JRPG familiarity and input/accessibility preferences. Tell participants that the game is unfinished, observations are about the prototype (not player skill), participation is voluntary, and they may stop or skip questions. Do not record personal identifiers, voice, screens, or raw input without separate explicit consent. Never upload local trace events automatically.

## Facilitator preparation
1. Confirm exact Git commit, native Godot version, OS, display scale, controller/keyboard, and any accessibility settings. Launch `res://scenes/vertical_slice_review.tscn` directly, **not** the default pilot scene.
2. Confirm reduced motion defaults on; text is legible; Ionia review art remains default-hidden; Defender #293 installer is not used.
3. Explain movement controls only if the player cannot infer them; record any intervention verbatim as a usability failure signal, not a player failure.
4. Observe without leading the player. For each milestone, timestamp the first attempt, success and any confusion; use opt-in local-only trace only with permission.
5. Afterward, ask the same open questions and record de-identified notes. Do not call the data representative or statistically conclusive.

## Milestones and observation sheet
| Milestone | Target hypothesis | Record |
| --- | --- | --- |
| First control | Player can move within 60 seconds | Seconds to first voluntary movement; instructions requested |
| Signal clue | Player locates and uses E on SIGNAL | Seconds, missed interactions, signage clarity |
| Ionia dialogue | Player recognizes Ionia and understands two options | Can paraphrase options without coaching |
| Encounter | Player notices pulse telegraph and uses guard meaningfully | Misread cues, number of retries, why they acted |
| Return payoff | Player returns to SIGNAL and notices change | Spontaneous reaction; can name the consequence |
| Emotional resonance | At least one moment prompts curiosity, care or surprise | Exact volunteered wording, not facilitator interpretation |

## Exit questions
- What were you trying to do at each point, and where were you unsure?
- What did the signal and Ionia's choice mean to you?
- What did you think would happen when the pulse gathered?
- What changed after your decision, and did it feel earned?
- Which moment, if any, made you want to continue?
- Was anything visually, audibly, physically or cognitively uncomfortable?
- What one thing should change before you would recommend another test?

## Decision rubric
**P0 blocker:** any soft-lock, forced story branch, missing input recovery, unreadable essential cue, or trace enabled without consent. **P1 comprehension:** two or more participants miss the same affordance or misinterpret the telegraph; revise before adding content. **P1 delight:** fewer than three spontaneously report a memorable moment; test stronger feedback and character specificity. **P2 polish:** cosmetic requests not obstructing comprehension. The denominators and thresholds are hypotheses, not population estimates; include counterexamples and quote context.

## Evidence and documentation hygiene
For each session, record an anonymous session number, build SHA, controls, accessibility options, observed milestone timestamps, interventions, and the participant's own paraphrase. Keep any locally exported notes private and minimize retention. Do not attach personal data to GitHub issues. Aggregate the five sessions only after all are complete; preserve negative feedback. Report **NOT TESTED** until real sessions occur. Reconcile priorities with the pending JRPG Deep Research report, creator art approval, and the separate #326/#328/#329 technical evidence.
