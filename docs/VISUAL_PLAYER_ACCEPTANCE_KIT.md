# Aetherwake Chapter 1 ? Visual Player Acceptance Kit

Status: **G4 HUMAN EVIDENCE PROCEDURE**

This procedure is intentionally separate from developer review. A participant should use the exact candidate build without being coached on what the visuals are supposed to communicate.

## Participants
- Minimum: **5** people who did not implement the current visual tranche.
- Session: **20 minutes** each.
- Use the same exact-head packaged candidate for every participant.
- Do not explain character names, the Dragonfly, controls, or intended art direction before the session beyond normal launch instructions.

## Evidence bundle
Record for each participant:
1. candidate commit / package hash;
2. session start/end;
3. whether help was requested and what help was given;
4. eight 1?5 visual scores;
5. same-game blind test result;
6. Dragonfly recall result;
7. free-response confusion/unfinished notes.

## 20-minute session prompts
Ask only after play unless the participant is blocked:
- What did you look at first on the title screen?
- Who appears to be the protagonist?
- What is the airship called?
- What do you think you are supposed to do next?
- Which part looked most finished?
- Which part looked most unfinished?
- In combat, where did you look first?
- Did any UI cover something you wanted to see?
- Did any scene look like it belonged to a different game?

## Blind same-game test
Show the seven exact-head evidence frames in randomized order alongside three unrelated decoy JRPG/fantasy screenshots that are legally usable for internal testing. Ask which screenshots belong to the same game.

Pass rule: participant correctly groups at least **80%** of the seven Aetherwake frames as one game family. Final package rule: at least **80% of participants** pass.

## Dragonfly recognition / recall
After the play session, remove the game from view and ask:
- What was the ship called?
- Describe its silhouette in one sentence.
- Choose the Dragonfly from a small silhouette set if available.

Pass rule: participant names or unambiguously recalls the Dragonfly and identifies the silhouette. Final package rule: **?80%** participant pass rate.

## Weighted visual score
Use 1?5 integer or half-point scores:

| Category | Weight | Floor |
|---|---:|---:|
| Cohesion | 20% | 4.0 |
| Readability | 20% | 4.0 |
| Appeal | 15% | 3.5 |
| Identity | 15% | 4.0 |
| World depth | 10% | 3.5 |
| Character quality | 10% | 3.5 |
| Ship quality | 5% | 4.0 |
| Production credibility | 5% | 4.0 |

Final visual acceptance requires:
- weighted group average **?4.0**;
- every category group average at or above its floor;
- same-game participant pass rate **?80%**;
- Dragonfly participant pass rate **?80%**;
- no unresolved severity-1 visual/readability blocker;
- technical visual performance verifier remains PASS on the exact candidate.

## Result file
Create `visual-acceptance-results.json` from `docs/visual-acceptance-template.json`, then run:

`npm run score:visual-acceptance`

The scorer is fail-closed: incomplete participant/category data does not produce a PASS.

## G4 authority boundary
Automated visual tests, screenshots, and developer scoring can prepare G4 but cannot close it. G4 closes only from the exact candidate's human evidence plus the technical gates.
